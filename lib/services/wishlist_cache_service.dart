import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/services/paint_service.dart';

/// Servicio de cache offline-first para la wishlist con sincronización automática
///
/// Este servicio implementa:
/// - Cache persistente local que funciona sin internet
/// - Queue de operaciones pendientes para sincronizar
/// - Sincronización automática en background cuando hay conexión
/// - Resolución básica de conflictos (last-write-wins)
/// - Estado de sincronización para mostrar en la UI
class WishlistCacheService extends ChangeNotifier {
  final PaintService _paintService;
  final Connectivity _connectivity = Connectivity();

  // Cache keys
  static const String _keyWishlistItems = 'wishlist_cache_items';
  static const String _keyPendingOperations = 'wishlist_cache_pending_ops';
  static const String _keyLastSyncTimestamp = 'wishlist_cache_last_sync';
  static const String _keyWishlistTimestamp = 'wishlist_cache_timestamp';

  // TTL en minutos para el cache
  static const int _wishlistCacheTTL =
      60; // 60 minutos (más tiempo que inventory)
  static const int _syncRetryInterval = 5; // 5 minutos entre reintentos

  // Cache en memoria
  List<Map<String, dynamic>>? _cachedWishlist;
  DateTime? _lastCacheUpdate;

  // Queue de operaciones pendientes
  final List<Map<String, dynamic>> _pendingOperations = [];

  // Estados
  bool _isInitialized = false;
  bool _isSyncing = false;
  bool _hasConnection = true;
  Timer? _syncTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  WishlistCacheService(this._paintService);

  /// Getters para los estados
  bool get isInitialized => _isInitialized;
  bool get isSyncing => _isSyncing;
  bool get hasConnection => _hasConnection;
  bool get hasPendingOperations => _pendingOperations.isNotEmpty;
  int get pendingOperationsCount => _pendingOperations.length;
  List<Map<String, dynamic>>? get cachedWishlist => _cachedWishlist;

  /// Inicializa el cache service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔧 Initializing wishlist cache service...');

      // Cargar datos del cache local
      await _loadWishlistFromCache();
      await _loadPendingOperations();

      // Verificar conectividad
      await _checkConnectivity();

      // Configurar listener de conectividad
      _setupConnectivityListener();

      // Programar sincronización periódica
      _scheduleSyncTimer();

      _isInitialized = true;
      debugPrint('✅ Wishlist cache service initialized');

      // Cargar wishlist automáticamente desde la DB al inicializar
      if (_hasConnection) {
        debugPrint('🔄 Loading initial wishlist from database...');
        try {
          // Obtener token del usuario actual (Firebase Auth)
          final token = await _getAuthToken();
          final items = await _paintService.getWishlistPaints(token);

          if (items.isNotEmpty) {
            _cachedWishlist = items;
            _lastCacheUpdate = DateTime.now();
            await _saveWishlistToCache(items);
            debugPrint(
              '✅ Initial wishlist loaded and cached (${items.length} items)',
            );
          } else {
            debugPrint('ℹ️ No wishlist items found in database');
          }
        } catch (e) {
          debugPrint('❌ Error loading initial wishlist: $e');
        }

        // Intentar sincronización de operaciones pendientes
        if (_pendingOperations.isNotEmpty) {
          unawaited(_syncWithBackend());
        }
      }
    } catch (e) {
      debugPrint('❌ Error initializing wishlist cache service: $e');
    }

    notifyListeners();
  }

  /// Obtiene la wishlist (cache-first, luego API si es necesario)
  Future<List<Map<String, dynamic>>> getWishlist({
    bool forceRefresh = false,
    String? searchQuery,
    String? brandFilter,
    String? paletteFilter,
    int? priorityFilter,
  }) async {
    try {
      // Si tenemos cache válido y no forzamos refresh, retornarlo
      if (!forceRefresh && _cachedWishlist != null && _isCacheValid()) {
        debugPrint(
          '✅ Returning cached wishlist (${_cachedWishlist!.length} items)',
        );
        return _filterWishlist(
          _cachedWishlist!,
          searchQuery,
          brandFilter,
          paletteFilter,
          priorityFilter,
        );
      }

      // Si no hay conexión, usar solo cache
      if (!_hasConnection) {
        debugPrint('📱 No connection - using cached wishlist only');
        return _cachedWishlist ?? [];
      }

      debugPrint('🔄 Loading wishlist from API...');

      // Cargar del API
      final token = await _getAuthToken();
      final items = await _paintService.getWishlistPaints(token);

      // Actualizar cache
      _cachedWishlist = items;
      _lastCacheUpdate = DateTime.now();
      await _saveWishlistToCache(items);

      debugPrint('✅ Wishlist loaded and cached (${items.length} items)');

      notifyListeners();
      return _filterWishlist(
        items,
        searchQuery,
        brandFilter,
        paletteFilter,
        priorityFilter,
      );
    } catch (e) {
      debugPrint('❌ Error loading wishlist: $e');

      // Fallback al cache aunque esté expirado
      if (_cachedWishlist != null) {
        debugPrint('⚠️ Returning expired cache as fallback');
        return _filterWishlist(
          _cachedWishlist!,
          searchQuery,
          brandFilter,
          paletteFilter,
          priorityFilter,
        );
      }

      return [];
    }
  }

  /// Agrega un item a la wishlist (optimistic update)
  Future<bool> addToWishlist(Paint paint, int priority, {String? notes}) async {
    try {
      debugPrint('➕ Adding to wishlist: ${paint.id} (priority: $priority)');

      // Crear operación pendiente
      final operation = {
        'type': 'add',
        'paintId': paint.id,
        'priority': priority,
        'notes': notes ?? '',
        'timestamp': DateTime.now().toIso8601String(),
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'paint': paint.toJson(), // Guardar paint completo para UI optimista
      };

      // Optimistic update - agregar al cache local inmediatamente
      if (_cachedWishlist != null) {
        // Verificar si ya existe
        final existingIndex = _cachedWishlist!.indexWhere(
          (item) => (item['paint'] as Map<String, dynamic>)['id'] == paint.id,
        );

        if (existingIndex >= 0) {
          // Actualizar prioridad existente
          _cachedWishlist![existingIndex] = {
            ..._cachedWishlist![existingIndex],
            'priority': priority,
            'notes': notes ?? '',
            'isPriority': priority > 0,
          };
        } else {
          // Crear nuevo item
          final newItem = {
            'id': operation['id'],
            'paint': paint.toJson(),
            'priority': priority,
            'notes': notes ?? '',
            'isPriority': priority > 0,
            'addedAt': DateTime.now(), // Keep as DateTime in memory
            'brand': {'name': paint.brand, 'logo_url': paint.brandLogo},
            'palettes': <String>[],
          };
          _cachedWishlist!.add(newItem);
        }
      }

      // Agregar a la queue de operaciones pendientes
      _pendingOperations.add(operation);
      await _savePendingOperations();

      notifyListeners();

      // Intentar sincronizar inmediatamente si hay conexión
      if (_hasConnection) {
        unawaited(_syncWithBackend());
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error adding to wishlist: $e');
      return false;
    }
  }

  /// Actualiza la prioridad de un item de la wishlist (optimistic update)
  Future<bool> updateWishlistPriority(
    String paintId,
    String wishlistId,
    int priority, {
    String? notes,
  }) async {
    try {
      debugPrint('✏️ Updating wishlist item: $paintId (priority: $priority)');

      // Crear operación pendiente
      final operation = {
        'type': 'update',
        'paintId': paintId,
        'wishlistId': wishlistId,
        'priority': priority,
        'notes': notes,
        'timestamp': DateTime.now().toIso8601String(),
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      // Optimistic update - actualizar cache local inmediatamente
      if (_cachedWishlist != null) {
        final itemIndex = _cachedWishlist!.indexWhere(
          (item) =>
              item['id'] == wishlistId ||
              (item['paint'] as Map<String, dynamic>)['id'] == paintId,
        );

        if (itemIndex >= 0) {
          _cachedWishlist![itemIndex] = {
            ..._cachedWishlist![itemIndex],
            'priority': priority,
            'notes': notes ?? _cachedWishlist![itemIndex]['notes'],
            'isPriority': priority > 0,
          };
        }
      }

      // Agregar a la queue de operaciones pendientes
      _pendingOperations.add(operation);
      await _savePendingOperations();

      notifyListeners();

      // Intentar sincronizar inmediatamente si hay conexión
      if (_hasConnection) {
        unawaited(_syncWithBackend());
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error updating wishlist priority: $e');
      return false;
    }
  }

  /// Elimina un item de la wishlist (optimistic update)
  Future<bool> removeFromWishlist(String paintId, String wishlistId) async {
    try {
      debugPrint('🗑️ Removing from wishlist: $paintId');

      // Crear operación pendiente
      final operation = {
        'type': 'delete',
        'paintId': paintId,
        'wishlistId': wishlistId,
        'timestamp': DateTime.now().toIso8601String(),
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      // Optimistic update - eliminar del cache local inmediatamente
      if (_cachedWishlist != null) {
        _cachedWishlist!.removeWhere(
          (item) =>
              item['id'] == wishlistId ||
              (item['paint'] as Map<String, dynamic>)['id'] == paintId,
        );
      }

      // Agregar a la queue de operaciones pendientes
      _pendingOperations.add(operation);
      await _savePendingOperations();

      notifyListeners();

      // Intentar sincronizar inmediatamente si hay conexión
      if (_hasConnection) {
        final token = await _getAuthToken();
        await _paintService.removeFromWishlist(paintId, wishlistId, token);
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error removing from wishlist: $e');
      return false;
    }
  }

  /// Fuerza la sincronización con el backend
  Future<void> forceSync() async {
    await _syncWithBackend();
  }

  /// Limpia todo el cache y operaciones pendientes
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Limpiar cache en memoria
      _cachedWishlist = null;
      _lastCacheUpdate = null;
      _pendingOperations.clear();

      // Limpiar cache persistente
      await prefs.remove(_keyWishlistItems);
      await prefs.remove(_keyPendingOperations);
      await prefs.remove(_keyLastSyncTimestamp);
      await prefs.remove(_keyWishlistTimestamp);

      debugPrint('🗑️ Wishlist cache cleared');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error clearing wishlist cache: $e');
    }
  }

  // Métodos privados

  List<Map<String, dynamic>> _filterWishlist(
    List<Map<String, dynamic>> items,
    String? searchQuery,
    String? brandFilter,
    String? paletteFilter,
    int? priorityFilter,
  ) {
    var filteredItems = items;

    if (searchQuery != null && searchQuery.isNotEmpty) {
      filteredItems =
          filteredItems.where((item) {
            final paint = item['paint'] as Map<String, dynamic>;
            return paint['name'].toString().toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ||
                paint['brand'].toString().toLowerCase().contains(
                  searchQuery.toLowerCase(),
                );
          }).toList();
    }

    if (brandFilter != null && brandFilter != 'All') {
      filteredItems =
          filteredItems.where((item) {
            final paint = item['paint'] as Map<String, dynamic>;
            return paint['brand'].toString() == brandFilter;
          }).toList();
    }

    if (priorityFilter != null) {
      filteredItems =
          filteredItems
              .where(
                (item) => (item['priority'] as int? ?? 0) == priorityFilter,
              )
              .toList();
    }

    return filteredItems;
  }

  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;

    final now = DateTime.now();
    final difference = now.difference(_lastCacheUpdate!).inMinutes;

    return difference < _wishlistCacheTTL;
  }

  Future<void> _loadWishlistFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_keyWishlistItems);
      final timestampMs = prefs.getInt(_keyWishlistTimestamp);

      if (cachedData != null) {
        final List<dynamic> decoded = json.decode(cachedData);

        // Convert string dates back to DateTime objects
        _cachedWishlist =
            decoded
                .map((item) {
                  final Map<String, dynamic> processedItem = Map.from(item);

                  // Convert addedAt string back to DateTime if present
                  if (processedItem['addedAt'] is String) {
                    try {
                      processedItem['addedAt'] = DateTime.parse(
                        processedItem['addedAt'] as String,
                      );
                    } catch (e) {
                      // If parsing fails, use current time as fallback
                      processedItem['addedAt'] = DateTime.now();
                    }
                  } else if (processedItem['addedAt'] == null) {
                    // If no addedAt field, use current time
                    processedItem['addedAt'] = DateTime.now();
                  }

                  return processedItem;
                })
                .cast<Map<String, dynamic>>()
                .toList();

        if (timestampMs != null) {
          _lastCacheUpdate = DateTime.fromMillisecondsSinceEpoch(timestampMs);
        }

        debugPrint(
          '✅ Wishlist loaded from cache (${_cachedWishlist!.length} items)',
        );
      }
    } catch (e) {
      debugPrint('❌ Error loading wishlist from cache: $e');

      // Si hay error de parsing, limpiar cache corrupto
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_keyWishlistItems);
        await prefs.remove(_keyWishlistTimestamp);
        debugPrint('🧹 Corrupted wishlist cache cleared, will reload from API');

        _cachedWishlist = null;
        _lastCacheUpdate = null;
      } catch (clearError) {
        debugPrint('❌ Error clearing corrupted wishlist cache: $clearError');
      }
    }
  }

  Future<void> _saveWishlistToCache(List<Map<String, dynamic>> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert DateTime objects to strings before saving
      final serializableItems =
          items.map((item) {
            final Map<String, dynamic> serializable = Map.from(item);

            // Convert addedAt DateTime to string if present
            if (serializable['addedAt'] is DateTime) {
              serializable['addedAt'] =
                  (serializable['addedAt'] as DateTime).toIso8601String();
            }

            return serializable;
          }).toList();

      await prefs.setString(_keyWishlistItems, json.encode(serializableItems));
      await prefs.setInt(
        _keyWishlistTimestamp,
        DateTime.now().millisecondsSinceEpoch,
      );

      debugPrint('✅ Wishlist saved to cache (${items.length} items)');
    } catch (e) {
      debugPrint('❌ Error saving wishlist to cache: $e');
    }
  }

  Future<void> _loadPendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingData = prefs.getString(_keyPendingOperations);

      if (pendingData != null) {
        final List<dynamic> decoded = json.decode(pendingData);
        _pendingOperations.clear();
        _pendingOperations.addAll(decoded.cast<Map<String, dynamic>>());

        debugPrint(
          '📋 Loaded ${_pendingOperations.length} pending wishlist operations',
        );
      }
    } catch (e) {
      debugPrint('❌ Error loading pending wishlist operations: $e');
    }
  }

  Future<void> _savePendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _keyPendingOperations,
        json.encode(_pendingOperations),
      );
    } catch (e) {
      debugPrint('❌ Error saving pending wishlist operations: $e');
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      _hasConnection = connectivityResult.first != ConnectivityResult.none;
      debugPrint(
        '📶 Wishlist connectivity status: ${_hasConnection ? 'Online' : 'Offline'}',
      );
    } catch (e) {
      debugPrint('❌ Error checking connectivity: $e');
      _hasConnection = false;
    }
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      results,
    ) {
      final wasOffline = !_hasConnection;
      _hasConnection = results.first != ConnectivityResult.none;

      debugPrint(
        '📶 Wishlist connectivity changed: ${_hasConnection ? 'Online' : 'Offline'}',
      );

      // Si acabamos de conectarnos y tenemos operaciones pendientes, sincronizar
      if (wasOffline && _hasConnection && _pendingOperations.isNotEmpty) {
        debugPrint(
          '🔄 Connection restored - syncing pending wishlist operations...',
        );
        unawaited(_syncWithBackend());
      }

      notifyListeners();
    });
  }

  void _scheduleSyncTimer() {
    _syncTimer = Timer.periodic(Duration(minutes: _syncRetryInterval), (timer) {
      if (_hasConnection && _pendingOperations.isNotEmpty) {
        unawaited(_syncWithBackend());
      }
    });
  }

  Future<void> _syncWithBackend() async {
    if (_isSyncing || !_hasConnection) return;

    try {
      _isSyncing = true;
      notifyListeners();

      debugPrint('🔄 Starting wishlist sync with backend...');

      // Procesar operaciones pendientes en orden
      final operationsToProcess = List<Map<String, dynamic>>.from(
        _pendingOperations,
      );
      final completedOperations = <String>[];

      for (final operation in operationsToProcess) {
        try {
          await _processOperation(operation);
          completedOperations.add(operation['id'] as String);
          debugPrint('✅ Wishlist operation completed: ${operation['type']}');
        } catch (e) {
          debugPrint(
            '❌ Failed to process wishlist operation ${operation['type']}: $e',
          );
          // Si falla una operación, continuamos con las siguientes
        }
      }

      // Remover operaciones completadas
      _pendingOperations.removeWhere(
        (op) => completedOperations.contains(op['id']),
      );
      await _savePendingOperations();

      // Actualizar cache con datos del servidor
      await getWishlist(forceRefresh: true);

      debugPrint(
        '✅ Wishlist sync completed (${completedOperations.length}/${operationsToProcess.length} operations)',
      );
    } catch (e) {
      debugPrint('❌ Error during wishlist sync: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _processOperation(Map<String, dynamic> operation) async {
    final type = operation['type'] as String;

    switch (type) {
      case 'add':
        final paintData = operation['paint'] as Map<String, dynamic>;
        final paint = Paint.fromJson(paintData);
        await _paintService.addToWishlistDirect(
          paint,
          operation['priority'] as int,
          '', // userId se maneja internamente en PaintService
        );
        break;

      case 'update':
        // Actualizar prioridad usando el método existente
        await _paintService.updateWishlistPriority(
          operation['paintId'] as String,
          operation['wishlistId'] as String,
          (operation['priority'] as int) > 0,
          '', // token se maneja internamente
          operation['priority'] as int,
        );
        break;

      case 'delete':
        final token = await _getAuthToken();
        await _paintService.removeFromWishlist(
          operation['paintId'] as String,
          operation['wishlistId'] as String,
          token,
        );
        break;

      default:
        throw Exception('Unknown wishlist operation type: $type');
    }
  }

  /// Obtiene el token de autenticación del usuario actual
  Future<String> _getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    final token = await user.getIdToken();
    if (token == null) {
      throw Exception('Failed to get auth token');
    }
    return token;
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }
}
