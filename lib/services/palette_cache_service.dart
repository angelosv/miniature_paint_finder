import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Color;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/palette.dart';
import '../models/paint.dart';
import '../services/paint_service.dart';
import '../services/palette_service.dart';

/// Cache service for palette operations with offline-first approach
/// Provides optimistic updates and automatic background synchronization
class PaletteCacheService extends ChangeNotifier {
  // Cache configuration
  static const String _CACHE_KEY = 'palette_cache';
  static const String _CACHE_TIMESTAMP_KEY = 'palette_cache_timestamp';
  static const String _PENDING_OPERATIONS_KEY = 'palette_pending_operations';
  static const Duration _CACHE_TTL = Duration(minutes: 60); // 60-minute TTL

  // Services
  final PaintService _paintService = PaintService();
  final PaletteService _paletteService = PaletteService();

  // Internal state
  List<Palette>? _cachedPalettes;
  DateTime? _lastCacheUpdate;
  bool _isInitialized = false;
  bool _isSyncing = false;
  bool _hasConnection = true;
  List<Map<String, dynamic>> _pendingOperations = [];

  // Pagination state
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalPalettes = 0;
  int _limit = 10;

  // Stream subscriptions
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _syncTimer;

  /// Constructor
  PaletteCacheService() {
    _initializeService();
  }

  /// Public getters
  bool get isInitialized => _isInitialized;
  bool get isSyncing => _isSyncing;
  List<Palette>? get cachedPalettes => _cachedPalettes;
  DateTime? get lastCacheUpdate => _lastCacheUpdate;
  bool get hasConnection => _hasConnection;
  List<Map<String, dynamic>> get pendingOperations => _pendingOperations;

  // Pagination getters
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalPalettes => _totalPalettes;
  int get limit => _limit;

  /// Initialize the service
  Future<void> _initializeService() async {
    try {
      debugPrint('🎨 Initializing PaletteCacheService...');

      // Setup connectivity monitoring
      _setupConnectivityMonitoring();
      debugPrint('🎨 Connectivity monitoring setup complete');

      // Load cached data
      await _loadCachedData();
      debugPrint(
        '🎨 Cached data loaded: ${_cachedPalettes?.length ?? 0} palettes',
      );

      // Start background sync timer
      _startSyncTimer();
      debugPrint('🎨 Background sync timer started');

      _isInitialized = true;
      debugPrint('✅ PaletteCacheService initialized successfully');

      // Load initial palettes from database automatically when connected
      if (_hasConnection) {
        debugPrint('🔄 Loading initial palettes from database...');
        try {
          final result = await _paintService.getPalettes(page: 1, limit: 100);

          if (result['palettes'] != null &&
              (result['palettes'] as List).isNotEmpty) {
            _cachedPalettes = result['palettes'] as List<Palette>;
            _currentPage = 1;
            _totalPages = result['totalPages'] as int;
            // Calculate total palettes based on response data
            if (result.containsKey('totalPalettes')) {
              _totalPalettes = result['totalPalettes'] as int;
            } else {
              _totalPalettes = _totalPages * _limit;
            }
            _lastCacheUpdate = DateTime.now();
            await _saveCachedData();
            debugPrint(
              '✅ Initial palettes loaded and cached (${_cachedPalettes!.length} items)',
            );
          } else {
            debugPrint('ℹ️ No palettes found in database');
          }
        } catch (e) {
          debugPrint('❌ Error loading initial palettes: $e');
        }

        // Process pending operations if any
        if (_pendingOperations.isNotEmpty) {
          _backgroundSync();
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error initializing PaletteCacheService: $e');
    }
  }

  /// Setup connectivity monitoring
  void _setupConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final wasConnected = _hasConnection;
      _hasConnection =
          results.isNotEmpty && results.first != ConnectivityResult.none;

      debugPrint('🌐 Connectivity changed: $_hasConnection');

      // If we just got connection, sync pending operations
      if (!wasConnected && _hasConnection) {
        debugPrint('📶 Connection restored, syncing pending operations...');
        _processPendingOperations();
      }
    });
  }

  /// Start background sync timer
  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_hasConnection && !_isSyncing) {
        _backgroundSync();
      }
    });
  }

  /// Load cached data from SharedPreferences
  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load cached palettes
      final cachedJson = prefs.getString(_CACHE_KEY);
      if (cachedJson != null) {
        final cachedData = json.decode(cachedJson);
        _cachedPalettes =
            (cachedData['palettes'] as List)
                .map((paletteJson) => Palette.fromJson(paletteJson))
                .toList();

        // Load pagination data
        _currentPage = cachedData['currentPage'] ?? 1;
        _totalPages = cachedData['totalPages'] ?? 1;
        _totalPalettes = cachedData['totalPalettes'] ?? 0;
        _limit = cachedData['limit'] ?? 10;

        debugPrint('📱 Loaded ${_cachedPalettes?.length ?? 0} cached palettes');
      }

      // Load cache timestamp
      final timestampStr = prefs.getString(_CACHE_TIMESTAMP_KEY);
      if (timestampStr != null) {
        _lastCacheUpdate = DateTime.parse(timestampStr);
      }

      // Load pending operations
      final pendingJson = prefs.getString(_PENDING_OPERATIONS_KEY);
      if (pendingJson != null) {
        _pendingOperations = List<Map<String, dynamic>>.from(
          json.decode(pendingJson),
        );
        debugPrint('⏳ Loaded ${_pendingOperations.length} pending operations');
      }
    } catch (e) {
      debugPrint('❌ Error loading cached palette data: $e');
      _cachedPalettes = [];
      _pendingOperations = [];
    }
  }

  /// Save data to cache
  Future<void> _saveCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_cachedPalettes != null) {
        final cacheData = {
          'palettes':
              _cachedPalettes!.map((palette) => palette.toJson()).toList(),
          'currentPage': _currentPage,
          'totalPages': _totalPages,
          'totalPalettes': _totalPalettes,
          'limit': _limit,
        };

        await prefs.setString(_CACHE_KEY, json.encode(cacheData));
        await prefs.setString(
          _CACHE_TIMESTAMP_KEY,
          DateTime.now().toIso8601String(),
        );
      }

      // Save pending operations
      await prefs.setString(
        _PENDING_OPERATIONS_KEY,
        json.encode(_pendingOperations),
      );
    } catch (e) {
      debugPrint('❌ Error saving cached palette data: $e');
    }
  }

  /// Check if cache is valid based on TTL
  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < _CACHE_TTL;
  }

  /// Get palettes (cache-first approach - same pattern as wishlist/inventory)
  Future<List<Palette>> getPalettes({
    bool forceRefresh = false,
    int? page,
    int? limit,
    String? searchQuery,
  }) async {
    try {
      // Si tenemos cache válido y no forzamos refresh, retornarlo (EXACT same logic as wishlist)
      if (!forceRefresh && _cachedPalettes != null && _isCacheValid()) {
        debugPrint(
          '✅ Returning cached palettes (${_cachedPalettes!.length} items)',
        );
        return _filterPalettes(_cachedPalettes!, searchQuery);
      }

      // Si no hay conexión, usar solo cache (EXACT same logic as wishlist)
      if (!_hasConnection) {
        debugPrint('📱 No connection - using cached palettes only');
        return _cachedPalettes ?? [];
      }

      // Si llegamos aquí, hay conexión y (no hay cache válido O se forzó refresh)
      // Por lo tanto, cargar del API (EXACT same logic as wishlist)
      debugPrint('🔄 Loading palettes from API...');

      final requestPage = page ?? 1;
      final requestLimit = limit ?? 100;

      final result = await _paintService.getPalettes(
        page: requestPage,
        limit: requestLimit,
      );

      // Actualizar cache
      _cachedPalettes = result['palettes'] as List<Palette>;
      _currentPage = requestPage;
      _totalPages = result['totalPages'] as int;
      // Calculate total palettes based on response data
      if (result.containsKey('totalPalettes')) {
        _totalPalettes = result['totalPalettes'] as int;
      } else {
        _totalPalettes = _totalPages * _limit;
      }
      _lastCacheUpdate = DateTime.now();

      // Save to persistent storage
      await _saveCachedData();

      debugPrint(
        '✅ Palettes loaded and cached (${_cachedPalettes!.length} items)',
      );
      notifyListeners();

      return _filterPalettes(_cachedPalettes!, searchQuery);
    } catch (e) {
      debugPrint('❌ Error loading palettes: $e');

      // Fallback al cache aunque esté expirado (EXACT same logic as wishlist)
      if (_cachedPalettes != null) {
        debugPrint('⚠️ Returning expired cache as fallback');
        return _filterPalettes(_cachedPalettes!, searchQuery);
      }

      return [];
    }
  }

  /// Filter palettes based on search query (same pattern as other cache services)
  List<Palette> _filterPalettes(List<Palette> palettes, String? searchQuery) {
    if (searchQuery == null || searchQuery.isEmpty) {
      return palettes;
    }

    return palettes.where((palette) {
      return palette.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  /// Create a new palette (optimistic update)
  Future<bool> createPalette({
    required String name,
    required String imagePath,
    required List<Color> colors,
  }) async {
    try {
      debugPrint('➕ Creating palette: $name');

      // Create optimistic palette
      final optimisticPalette = Palette(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        imagePath: imagePath,
        colors: colors,
        createdAt: DateTime.now(),
        totalPaints: colors.length,
        createdAtText: 'Just now',
      );

      // Optimistic update - add to cache immediately
      _cachedPalettes ??= [];
      _cachedPalettes!.insert(0, optimisticPalette);
      _totalPalettes++;

      // Save optimistic state
      await _saveCachedData();
      notifyListeners();

      // Create pending operation
      final operation = {
        'type': 'create',
        'tempId': optimisticPalette.id,
        'name': name,
        'imagePath': imagePath,
        'colors': colors.map((c) => c.value).toList(),
        'timestamp': DateTime.now().toIso8601String(),
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      _pendingOperations.add(operation);
      await _saveCachedData();

      debugPrint('📝 Added create operation to queue: ${operation['id']}');

      // Process immediately if connected
      if (_hasConnection) {
        _processPendingOperations();
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error creating palette: $e');
      return false;
    }
  }

  /// Delete a palette (optimistic update)
  Future<bool> deletePalette(String paletteId) async {
    try {
      debugPrint('🗑️ Deleting palette: $paletteId');

      // Find and remove from cache optimistically
      if (_cachedPalettes != null) {
        final removedPalette = _cachedPalettes!.firstWhere(
          (p) => p.id == paletteId,
          orElse: () => throw Exception('Palette not found in cache'),
        );

        _cachedPalettes!.removeWhere((p) => p.id == paletteId);
        _totalPalettes = _cachedPalettes!.length;
        notifyListeners();

        // Create pending operation
        final operation = {
          'type': 'delete',
          'paletteId': paletteId,
          'timestamp': DateTime.now().toIso8601String(),
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          // Store removed palette for potential rollback
          'removedPalette': removedPalette.toJson(),
        };

        _pendingOperations.add(operation);
        await _saveCachedData();

        debugPrint('📝 Added delete operation to queue: ${operation['id']}');

        // Process immediately if connected
        if (_hasConnection) {
          _processPendingOperations();
        }

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error deleting palette: $e');
      return false;
    }
  }

  /// Add paint to palette (optimistic update)
  Future<bool> addPaintToPalette(
    String paletteId,
    Paint paint,
    String hex,
  ) async {
    try {
      debugPrint('➕ Adding paint ${paint.name} to palette $paletteId');

      // Find palette in cache and update optimistically
      if (_cachedPalettes != null) {
        final paletteIndex = _cachedPalettes!.indexWhere(
          (p) => p.id == paletteId,
        );
        if (paletteIndex != -1) {
          final palette = _cachedPalettes![paletteIndex];

          // Create new paint selection
          final newSelection = PaintSelection(
            paintId: paint.id,
            paintName: paint.name,
            paintBrand: paint.brand,
            brandAvatar: paint.brand.isNotEmpty ? paint.brand[0] : 'P',
            matchPercentage: 100,
            colorHex: hex,
            paintColorHex: hex,
            paintBrandId: paint.brandId ?? 'unknown',
            paintBarcode: paint.code,
            paintCode: paint.code,
          );

          // Create updated palette with new paint
          final updatedPalette = Palette(
            id: palette.id,
            name: palette.name,
            imagePath: palette.imagePath,
            colors: [
              ...palette.colors,
              Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000),
            ],
            createdAt: palette.createdAt,
            paintSelections: [...(palette.paintSelections ?? []), newSelection],
            totalPaints: (palette.totalPaints) + 1,
            createdAtText: palette.createdAtText,
          );

          _cachedPalettes![paletteIndex] = updatedPalette;
          notifyListeners();
        }
      }

      // Create pending operation
      final operation = {
        'type': 'addPaint',
        'paletteId': paletteId,
        'paintId': paint.id,
        'hex': hex,
        'timestamp': DateTime.now().toIso8601String(),
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'paint': paint.toJson(),
      };

      _pendingOperations.add(operation);
      await _saveCachedData();

      debugPrint('📝 Added addPaint operation to queue: ${operation['id']}');

      // Process immediately if connected
      if (_hasConnection) {
        _processPendingOperations();
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error adding paint to palette: $e');
      return false;
    }
  }

  /// Remove paint from palette (optimistic update)
  Future<bool> removePaintFromPalette(String paletteId, String paintId) async {
    try {
      debugPrint('🗑️ Removing paint $paintId from palette $paletteId');

      // Find palette in cache and update optimistically
      if (_cachedPalettes != null) {
        final paletteIndex = _cachedPalettes!.indexWhere(
          (p) => p.id == paletteId,
        );
        if (paletteIndex != -1) {
          final palette = _cachedPalettes![paletteIndex];

          // Remove paint selection
          final updatedSelections =
              (palette.paintSelections ?? [])
                  .where((selection) => selection.paintId != paintId)
                  .toList();

          // Update colors accordingly
          final updatedColors = List<Color>.from(palette.colors);
          if (updatedColors.isNotEmpty) {
            updatedColors.removeLast(); // Simple approach - remove last color
          }

          // Create updated palette
          final updatedPalette = Palette(
            id: palette.id,
            name: palette.name,
            imagePath: palette.imagePath,
            colors: updatedColors,
            createdAt: palette.createdAt,
            paintSelections: updatedSelections,
            totalPaints: updatedSelections.length,
            createdAtText: palette.createdAtText,
          );

          _cachedPalettes![paletteIndex] = updatedPalette;
          notifyListeners();
        }
      }

      // Create pending operation
      final operation = {
        'type': 'removePaint',
        'paletteId': paletteId,
        'paintId': paintId,
        'timestamp': DateTime.now().toIso8601String(),
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      _pendingOperations.add(operation);
      await _saveCachedData();

      debugPrint('📝 Added removePaint operation to queue: ${operation['id']}');

      // Process immediately if connected
      if (_hasConnection) {
        _processPendingOperations();
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error removing paint from palette: $e');
      return false;
    }
  }

  /// Background sync
  Future<void> _backgroundSync() async {
    if (_isSyncing || !_hasConnection) return;

    try {
      _isSyncing = true;
      debugPrint('🔄 Starting background palette sync...');

      // Process pending operations first
      await _processPendingOperations();

      // Refresh cache if it's getting stale (same pattern as wishlist/inventory)
      if (!_isCacheValid()) {
        debugPrint('🔄 Refreshing stale palette cache in background...');
        try {
          final result = await _paintService.getPalettes(page: 1, limit: 100);

          if (result['palettes'] != null) {
            _cachedPalettes = result['palettes'] as List<Palette>;
            _currentPage = 1;
            _totalPages = result['totalPages'] as int;
            // Calculate total palettes based on response data
            if (result.containsKey('totalPalettes')) {
              _totalPalettes = result['totalPalettes'] as int;
            } else {
              _totalPalettes = _totalPages * _limit;
            }
            _lastCacheUpdate = DateTime.now();
            await _saveCachedData();

            debugPrint(
              '✅ Background refresh completed (${_cachedPalettes!.length} palettes)',
            );
            notifyListeners();
          }
        } catch (e) {
          debugPrint('❌ Error during background palette refresh: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Error during background palette sync: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Process pending operations
Future<void> _processPendingOperations() async {
  if (_pendingOperations.isEmpty || !_hasConnection || _isSyncing) {
    if (_pendingOperations.isNotEmpty && !_hasConnection) {
      debugPrint(
        '⏳ ${_pendingOperations.length} pending operations waiting for connection',
      );
    }
    return;
  }

  _isSyncing = true;
  debugPrint(
    '🔄 Processing ${_pendingOperations.length} pending operations...',
  );

  final operationsToProcess = List<Map<String, dynamic>>.from(
    _pendingOperations,
  );

  const operationPriority = {
    'create': 0,
    'delete': 1,
    'removePaint': 2,
    'addPaint': 3,
  };

  operationsToProcess.sort((a, b) {
    final aType = a['type'] as String? ?? '';
    final bType = b['type'] as String? ?? '';
    final aPriority = operationPriority[aType] ?? 999;
    final bPriority = operationPriority[bType] ?? 999;
    return aPriority.compareTo(bPriority);
  });
  for (final operation in operationsToProcess) {
    try {
      debugPrint(
        '🔄 Processing operation: ${operation['type']} (${operation['id']})',
      );
      await _processOperation(operation);
      _pendingOperations.remove(operation);
      debugPrint(
        '✅ Processed operation: ${operation['type']} (${operation['id']})',
      );
    } catch (e) {
      debugPrint(
        '❌ Failed to process operation ${operation['type']} (${operation['id']}): $e',
      );
      // Keep failed operations in queue for retry
      break; // Stop processing if one fails
    }
  }

   _isSyncing = false;
  // Save updated pending operations
  await _saveCachedData();

  if (_pendingOperations.isEmpty) {
    debugPrint('✅ All pending operations processed successfully');
  } else {
    debugPrint(
      '⏳ ${_pendingOperations.length} operations still pending (will retry later)',
    );
  }
}

  /// Process a single operation
  Future<void> _processOperation(Map<String, dynamic> operation) async {
    final type = operation['type'] as String;
    debugPrint('🔄 Processing palette operation: $type');

    switch (type) {
      case 'create':
        final name = operation['name'] as String;
        final imagePath = operation['imagePath'] as String;
        final colorValues = operation['colors'] as List;
        final colors = colorValues.map((v) => Color(v as int)).toList();

        debugPrint('➕ Syncing create operation for palette: $name');

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('User not authenticated');

        final token = await user.getIdToken();
        if (token == null) throw Exception('Failed to get user token');

        final result = await _paletteService.createPalette(name, token, fullResponse: true);

        if (result['executed'] != true) {
          throw Exception(
            'Failed to sync create operation: ${result['message']}',
          );
        }

        // Update cache with real ID
        final tempId = operation['tempId'] as String;
        final realId = result['data']['doc_id'] as String;

        if (_cachedPalettes != null) {
          final index = _cachedPalettes!.indexWhere((p) => p.id == tempId);
          if (index != -1) {
            final tempPalette = _cachedPalettes![index];
            _cachedPalettes![index] = Palette(
              id: realId,
              name: tempPalette.name,
              imagePath: tempPalette.imagePath,
              colors: tempPalette.colors,
              createdAt: tempPalette.createdAt,
              paintSelections: tempPalette.paintSelections,
              totalPaints: tempPalette.totalPaints,
              createdAtText: tempPalette.createdAtText,
            );
            
            // Save updated cache and notify listeners
            await _saveCachedData();
            notifyListeners();
            debugPrint('🎨 Updated optimistic palette with real ID: $realId');
          }
        }

        for (final op in _pendingOperations) {
          if (op['paletteId'] == tempId) {
            op['paletteId'] = realId;
            debugPrint('🔄 ***Updated pending operation ${op['id']} to use realId: $realId');
          }
        }
        debugPrint('✅ Created palette with ID: $realId');
        break;

      case 'delete':
        final paletteId = operation['paletteId'] as String;
        debugPrint('🗑️ Syncing delete operation for palette: $paletteId');

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('User not authenticated');

        final token = await user.getIdToken();
        if (token == null) throw Exception('Failed to get user token');

        final result = await _paletteService.deletePalette(paletteId, token);

        if (result['executed'] != true) {
          throw Exception(
            'Failed to sync delete operation: ${result['message']}',
          );
        }

        debugPrint('✅ Deleted palette: $paletteId');
        break;

      case 'addPaint':
        final paletteId = operation['paletteId'] as String;
        final paintId = operation['paintId'] as String;
        final hex = operation['hex'] as String;

        debugPrint(
          '➕ Syncing addPaint operation: $paintId to palette $paletteId',
        );

        // Use existing addPaintToPaletteById method
        final paintData = operation['paint'] as Map<String, dynamic>;
        final paint = Paint.fromJson(paintData);

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('User not authenticated');

        // Find palette name from cache
        String paletteName = paletteId; // fallback
        if (_cachedPalettes != null) {
          final palette = _cachedPalettes!.firstWhere(
            (p) => p.id == paletteId,
            orElse: () => throw Exception('Palette not found in cache'),
          );
          paletteName = palette.name;
        }

        // Ensure all parameters are non-null strings
        final safeBrandId = paint.brandId ?? 'unknown';

        final result = await _paletteService.addPaintToPaletteById(
          paletteName, // Use palette name from cache
          user.uid,
          paintId,
          safeBrandId,
        );

        if (result['executed'] != true) {
          throw Exception(
            'Failed to sync addPaint operation: ${result['message']}',
          );
        }

        debugPrint('✅ Added paint $paintId to palette $paletteName');
        break;

      case 'removePaint':
        final paletteId = operation['paletteId'] as String;
        final paintId = operation['paintId'] as String;

        debugPrint(
          '🗑️ Syncing removePaint operation: $paintId from palette $paletteId',
        );

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('User not authenticated');

        final token = await user.getIdToken();
        if (token == null) throw Exception('Failed to get user token');

        final result = await _paletteService.removePaintFromPalette(
          paletteId,
          paintId,
          token,
        );

        if (result['executed'] != true) {
          throw Exception(
            'Failed to sync removePaint operation: ${result['message']}',
          );
        }

        debugPrint('✅ Removed paint $paintId from palette $paletteId');
        break;
    }
  }

  /// Force immediate sync
  Future<void> forceSync() async {
    if (!_hasConnection) {
      debugPrint('❌ Cannot force sync - no connection available');
      return;
    }

    debugPrint('🔄 Forcing immediate sync...');
    await _backgroundSync();
  }

  /// Debug method to manually process pending operations
  Future<void> debugProcessPendingOperations() async {
    debugPrint('🔧 DEBUG: Manually processing pending operations...');
    debugPrint('🔧 DEBUG: Connection status: $_hasConnection');
    debugPrint(
      '🔧 DEBUG: Pending operations count: ${_pendingOperations.length}',
    );

    if (_pendingOperations.isNotEmpty) {
      for (int i = 0; i < _pendingOperations.length; i++) {
        final op = _pendingOperations[i];
        debugPrint(
          '🔧 DEBUG: Operation $i: ${op['type']} - ${op['id']} - ${op['timestamp']}',
        );
      }
    }

    if (_hasConnection) {
      await _processPendingOperations();
    } else {
      debugPrint(
        '🔧 DEBUG: No connection - operations will be processed when connection is restored',
      );
    }
  }

  /// Clear cache and reload
  Future<void> clearCacheAndReload() async {
    try {
      debugPrint('🧹 Clearing palette cache...');

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_CACHE_KEY);
      await prefs.remove(_CACHE_TIMESTAMP_KEY);
      await prefs.remove(_PENDING_OPERATIONS_KEY);

      _cachedPalettes = null;
      _lastCacheUpdate = null;
      _pendingOperations.clear();

      // Reload fresh data directly from API (same pattern as wishlist/inventory)
      if (_hasConnection) {
        try {
          final result = await _paintService.getPalettes(page: 1, limit: 100);

          if (result['palettes'] != null) {
            _cachedPalettes = result['palettes'] as List<Palette>;
            _currentPage = 1;
            _totalPages = result['totalPages'] as int;
            // Calculate total palettes based on response data
            if (result.containsKey('totalPalettes')) {
              _totalPalettes = result['totalPalettes'] as int;
            } else {
              _totalPalettes = _totalPages * _limit;
            }
            _lastCacheUpdate = DateTime.now();
            await _saveCachedData();

            debugPrint(
              '✅ Cache cleared and reloaded (${_cachedPalettes!.length} palettes)',
            );
          }
        } catch (e) {
          debugPrint('❌ Error reloading after cache clear: $e');
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
    }
  }

  /// Invalidate cache to force next getPalettes to fetch fresh data
  void invalidateCache() {
    debugPrint('🔄 Invalidating palette cache...');
    _lastCacheUpdate = null; // This will make _isCacheValid() return false
    notifyListeners();
  }

  /// Debug method to check cache service state
  void debugCacheState() {
    debugPrint('🔍 ========== PALETTE CACHE DEBUG ==========');
    debugPrint('🔍 Initialized: $_isInitialized');
    debugPrint('🔍 Has connection: $_hasConnection');
    debugPrint('🔍 Is syncing: $_isSyncing');
    debugPrint('🔍 Cached palettes: ${_cachedPalettes?.length ?? 0}');
    debugPrint('🔍 Pending operations: ${_pendingOperations.length}');
    debugPrint('🔍 Last cache update: $_lastCacheUpdate');
    debugPrint('🔍 Cache valid: ${_isCacheValid()}');
    debugPrint('🔍 Current page: $_currentPage/$_totalPages');
    debugPrint('🔍 Total palettes: $_totalPalettes');

    if (_cachedPalettes != null && _cachedPalettes!.isNotEmpty) {
      debugPrint('🔍 First 3 cached palettes:');
      for (int i = 0; i < _cachedPalettes!.length && i < 3; i++) {
        final palette = _cachedPalettes![i];
        debugPrint(
          '  - ${palette.name} (${palette.id}) - ${palette.totalPaints} paints',
        );
      }
    }

    if (_pendingOperations.isNotEmpty) {
      debugPrint('🔍 Pending operations:');
      for (final op in _pendingOperations) {
        debugPrint('  - ${op['type']}: ${op['id']}');
      }
    }
    debugPrint('🔍 ==========================================');
  }

  /// Test method to verify cache functionality
  Future<Map<String, dynamic>> testCacheFunctionality() async {
    final testResults = <String, dynamic>{};

    debugPrint('🧪 ========== TESTING PALETTE CACHE ==========');

    try {
      // Test 1: Check initialization
      testResults['initialization'] = _isInitialized;
      debugPrint(
        '🧪 Test 1 - Initialization: ${_isInitialized ? 'PASS' : 'FAIL'}',
      );

      // Test 2: Check connectivity
      testResults['connectivity'] = _hasConnection;
      debugPrint(
        '🧪 Test 2 - Connectivity: ${_hasConnection ? 'PASS' : 'FAIL'}',
      );

      // Test 3: Load palettes
      try {
        final palettes =
            await getPalettes(); // Use cache-first approach, don't force refresh
        testResults['load_palettes'] = {
          'success': true,
          'count': palettes.length,
          'pagination': {
            'currentPage': _currentPage,
            'totalPages': _totalPages,
            'totalPalettes': _totalPalettes,
          },
        };
        debugPrint(
          '🧪 Test 3 - Load palettes: PASS (${palettes.length} loaded)',
        );
      } catch (e) {
        testResults['load_palettes'] = {
          'success': false,
          'error': e.toString(),
        };
        debugPrint('🧪 Test 3 - Load palettes: FAIL ($e)');
      }

      // Test 4: Cache validation
      testResults['cache_valid'] = _isCacheValid();
      debugPrint(
        '🧪 Test 4 - Cache validation: ${_isCacheValid() ? 'PASS' : 'FAIL'}',
      );

      // Test 5: Test optimistic create
      try {
        final success = await createPalette(
          name: 'Test Cache Palette ${DateTime.now().millisecondsSinceEpoch}',
          imagePath: 'assets/images/placeholder.jpeg',
          colors: [Color(0xFF123456)],
        );
        testResults['optimistic_create'] = success;
        debugPrint(
          '🧪 Test 5 - Optimistic create: ${success ? 'PASS' : 'FAIL'}',
        );
      } catch (e) {
        testResults['optimistic_create'] = false;
        debugPrint('🧪 Test 5 - Optimistic create: FAIL ($e)');
      }

      // Test 6: Check pending operations
      testResults['pending_operations'] = _pendingOperations.length;
      debugPrint(
        '🧪 Test 6 - Pending operations: ${_pendingOperations.length} operations queued',
      );

      // Test 7: Test processing pending operations if any exist
      if (_pendingOperations.isNotEmpty) {
        debugPrint('🧪 Test 7 - Testing pending operation processing...');
        await debugProcessPendingOperations();
        testResults['pending_operations_processed'] =
            _pendingOperations.length == 0;
        debugPrint(
          '🧪 Test 7 - Pending operations processing: ${_pendingOperations.length == 0 ? 'PASS' : 'PARTIAL'}',
        );
      } else {
        testResults['pending_operations_processed'] = true;
        debugPrint('🧪 Test 7 - No pending operations to process: PASS');
      }

      testResults['overall_status'] = 'completed';
      debugPrint('🧪 =========== CACHE TEST COMPLETE ============');
    } catch (e) {
      testResults['overall_status'] = 'failed';
      testResults['error'] = e.toString();
      debugPrint('🧪 =========== CACHE TEST FAILED ==============');
      debugPrint('🧪 Error: $e');
    }

    return testResults;
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }
}
