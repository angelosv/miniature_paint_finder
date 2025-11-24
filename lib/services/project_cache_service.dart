import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:miniature_paint_finder/models/project.dart';
import 'package:miniature_paint_finder/repositories/project_repository.dart';

/// Servicio de cache offline-first para proyectos con sincronización automática
///
/// Este servicio implementa:
/// - Cache persistente local que funciona sin internet
/// - Queue de operaciones pendientes para sincronizar
/// - Sincronización automática en background cuando hay conexión
/// - Resolución básica de conflictos (last-write-wins)
/// - Estado de sincronización para mostrar en la UI
class ProjectCacheService extends ChangeNotifier {
  final ProjectRepository _projectRepository;
  final Connectivity _connectivity = Connectivity();

  // Cache keys
  static const String _keyProjectItems = 'projects_cache_items';
  static const String _keyPendingOperations = 'projects_cache_pending_ops';
  static const String _keyLastSyncTimestamp = 'projects_cache_last_sync';
  static const String _keyProjectTimestamp = 'projects_cache_timestamp';

  // TTL en minutos para el cache
  static const int _projectCacheTTL = 60; // 60 minutos
  static const int _syncRetryInterval = 5; // 5 minutos entre reintentos

  // Cache en memoria
  List<Project>? _cachedProjects;
  DateTime? _lastCacheUpdate;

  // Queue de operaciones pendientes
  final List<Map<String, dynamic>> _pendingOperations = [];

  // Estados
  bool _isInitialized = false;
  bool _isSyncing = false;
  bool _hasConnection = true;
  Timer? _syncTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  ProjectCacheService(this._projectRepository);

  /// Getters para los estados
  bool get isInitialized => _isInitialized;
  bool get isSyncing => _isSyncing;
  bool get hasConnection => _hasConnection;
  bool get hasPendingOperations => _pendingOperations.isNotEmpty;
  int get pendingOperationsCount => _pendingOperations.length;
  List<Project>? get cachedProjects => _cachedProjects;

  /// Inicializa el cache service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔧 Initializing project cache service...');

      // Cargar datos del cache local SOLAMENTE (no bloquear con API)
      await _loadProjectsFromCache();
      await _loadPendingOperations();

      // Verificar conectividad
      await _checkConnectivity();

      // Configurar listener de conectividad
      _setupConnectivityListener();

      // Programar sincronización periódica
      _scheduleSyncTimer();

      _isInitialized = true;
      debugPrint('✅ Project cache service initialized');

      // Si hay operaciones pendientes, sincronizar en background (no bloquear)
      if (_hasConnection && _pendingOperations.isNotEmpty) {
        unawaited(_syncWithBackend());
      }
    } catch (e) {
      debugPrint('❌ Error initializing project cache service: $e');
    }

    notifyListeners();
  }

  /// Obtiene los proyectos (cache-first, luego API si es necesario)
  Future<List<Project>> getProjects({
    bool forceRefresh = false,
    int limit = 10,
    int page = 1,
  }) async {
    try {
      // Si tenemos cache válido y no forzamos refresh, retornarlo
      if (!forceRefresh && _cachedProjects != null && _isCacheValid()) {
        debugPrint(
          '✅ Returning cached projects (${_cachedProjects!.length} items)',
        );
        return _cachedProjects!;
      }

      // Si no hay conexión, usar solo cache
      if (!_hasConnection) {
        debugPrint('📱 No connection - using cached projects only');
        return _cachedProjects ?? [];
      }

      debugPrint('🔄 Loading projects from API...');

      // Cargar del API
      final result = await _projectRepository.getUserProjects(
        limit: 1000, // Cargar todos los proyectos
        page: 1,
      );

      // Parse projects from the result
      final projectsData = result['projects'] as List<dynamic>? ?? [];
      final projects = projectsData
          .map((item) => Project.fromJson(item as Map<String, dynamic>))
          .toList();

      // Actualizar cache
      _cachedProjects = projects;
      _lastCacheUpdate = DateTime.now();
      await _saveProjectsToCache(projects);

      debugPrint('✅ Projects loaded and cached (${projects.length} items)');

      notifyListeners();
      return projects;
    } catch (e) {
      debugPrint('❌ Error loading projects: $e');

      // Fallback al cache aunque esté expirado
      if (_cachedProjects != null) {
        debugPrint('⚠️ Returning expired cache as fallback');
        return _cachedProjects!;
      }

      return [];
    }
  }

  /// Obtiene un proyecto por ID (cache-first)
  Future<Project?> getProjectById(String projectId) async {
    try {
      // Buscar en cache primero
      if (_cachedProjects != null) {
        final cachedProject = _cachedProjects!.firstWhere(
          (p) => p.id == projectId,
          orElse: () => throw Exception('Not found in cache'),
        );
        
        // Si encontramos en cache y es válido, retornar
        if (_isCacheValid()) {
          debugPrint('✅ Project found in cache: $projectId');
          return cachedProject;
        }
      }

      // Si no hay conexión, usar cache aunque esté expirado
      if (!_hasConnection && _cachedProjects != null) {
        try {
          return _cachedProjects!.firstWhere((p) => p.id == projectId);
        } catch (e) {
          return null;
        }
      }

      // Cargar del API
      debugPrint('🔄 Loading project from API: $projectId');
      final project = await _projectRepository.getById(projectId);

      // Actualizar en cache
      if (_cachedProjects != null && project != null) {
        final index = _cachedProjects!.indexWhere((p) => p.id == projectId);
        if (index >= 0) {
          _cachedProjects![index] = project;
        } else {
          _cachedProjects!.add(project);
        }
        await _saveProjectsToCache(_cachedProjects!);
      }

      return project;
    } catch (e) {
      debugPrint('❌ Error loading project: $e');
      return null;
    }
  }

  /// Crea un nuevo proyecto (optimistic update)
  Future<bool> createProject(Project project) async {
    try {
      debugPrint('➕ Creating project: ${project.name}');

      // Crear operación pendiente
      final operation = {
        'type': 'create',
        'project': project.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      // Optimistic update - agregar al cache local inmediatamente
      if (_cachedProjects != null) {
        _cachedProjects!.insert(0, project); // Agregar al inicio
      } else {
        _cachedProjects = [project];
      }
      await _saveProjectsToCache(_cachedProjects!);

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
      debugPrint('❌ Error creating project: $e');
      return false;
    }
  }

  /// Actualiza un proyecto (optimistic update)
  Future<bool> updateProject(Project project) async {
    try {
      debugPrint('✏️ Updating project: ${project.id}');

      // Crear operación pendiente
      final operation = {
        'type': 'update',
        'project': project.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      // Optimistic update - actualizar cache local inmediatamente
      if (_cachedProjects != null) {
        final index = _cachedProjects!.indexWhere((p) => p.id == project.id);
        if (index >= 0) {
          _cachedProjects![index] = project;
          await _saveProjectsToCache(_cachedProjects!);
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
      debugPrint('❌ Error updating project: $e');
      return false;
    }
  }

  /// Elimina un proyecto (optimistic update)
  Future<bool> deleteProject(String projectId) async {
    try {
      debugPrint('🗑️ Deleting project: $projectId');

      // Crear operación pendiente
      final operation = {
        'type': 'delete',
        'projectId': projectId,
        'timestamp': DateTime.now().toIso8601String(),
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      // Optimistic update - eliminar del cache local inmediatamente
      if (_cachedProjects != null) {
        _cachedProjects!.removeWhere((p) => p.id == projectId);
        await _saveProjectsToCache(_cachedProjects!);
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
      debugPrint('❌ Error deleting project: $e');
      return false;
    }
  }

  /// Agrega un item a un proyecto (paint, palette, image)
  Future<bool> addProjectItem({
    required String projectId,
    required String table,
    required String tableId,
    required String brandId,
  }) async {
    try {
      debugPrint('➕ Adding item to project: $projectId ($table: $tableId)');

      // Crear operación pendiente
      final operation = {
        'type': 'addItem',
        'projectId': projectId,
        'table': table,
        'tableId': tableId,
        'brandId': brandId,
        'timestamp': DateTime.now().toIso8601String(),
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      };

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
      debugPrint('❌ Error adding project item: $e');
      return false;
    }
  }

  /// Elimina un item de un proyecto
  Future<bool> deleteProjectItem({required String itemId}) async {
    try {
      debugPrint('🗑️ Deleting project item: $itemId');

      // Crear operación pendiente
      final operation = {
        'type': 'deleteItem',
        'itemId': itemId,
        'timestamp': DateTime.now().toIso8601String(),
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      };

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
      debugPrint('❌ Error deleting project item: $e');
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
      _cachedProjects = null;
      _lastCacheUpdate = null;
      _pendingOperations.clear();

      // Limpiar cache persistente
      await prefs.remove(_keyProjectItems);
      await prefs.remove(_keyPendingOperations);
      await prefs.remove(_keyLastSyncTimestamp);
      await prefs.remove(_keyProjectTimestamp);

      debugPrint('🗑️ Project cache cleared');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error clearing project cache: $e');
    }
  }

  // Métodos privados

  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;

    final now = DateTime.now();
    final difference = now.difference(_lastCacheUpdate!).inMinutes;

    return difference < _projectCacheTTL;
  }

  Future<void> _loadProjectsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_keyProjectItems);
      final timestampMs = prefs.getInt(_keyProjectTimestamp);

      if (cachedData != null) {
        final List<dynamic> decoded = json.decode(cachedData);
        _cachedProjects = decoded.map((item) => Project.fromJson(item)).toList();

        if (timestampMs != null) {
          _lastCacheUpdate = DateTime.fromMillisecondsSinceEpoch(timestampMs);
        }

        debugPrint(
          '✅ Projects loaded from cache (${_cachedProjects!.length} items)',
        );
      }
    } catch (e) {
      debugPrint('❌ Error loading projects from cache: $e');

      // Si hay error de parsing, limpiar cache corrupto
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_keyProjectItems);
        await prefs.remove(_keyProjectTimestamp);
        debugPrint('🧹 Corrupted cache cleared, will reload from API');

        _cachedProjects = null;
        _lastCacheUpdate = null;
      } catch (clearError) {
        debugPrint('❌ Error clearing corrupted cache: $clearError');
      }
    }
  }

  Future<void> _saveProjectsToCache(List<Project> projects) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _keyProjectItems,
        json.encode(projects.map((p) => p.toJson()).toList()),
      );
      await prefs.setInt(
        _keyProjectTimestamp,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('❌ Error saving projects to cache: $e');
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

        debugPrint('📋 Loaded ${_pendingOperations.length} pending operations');
      }
    } catch (e) {
      debugPrint('❌ Error loading pending operations: $e');
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
      debugPrint('❌ Error saving pending operations: $e');
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      _hasConnection = connectivityResult.first != ConnectivityResult.none;
      debugPrint(
        '📶 Connectivity status: ${_hasConnection ? 'Online' : 'Offline'}',
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
        '📶 Connectivity changed: ${_hasConnection ? 'Online' : 'Offline'}',
      );

      // Si acabamos de conectarnos y tenemos operaciones pendientes, sincronizar
      if (wasOffline && _hasConnection && _pendingOperations.isNotEmpty) {
        debugPrint('🔄 Connection restored - syncing pending operations...');
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

      debugPrint('🔄 Starting project sync with backend...');

      // Procesar operaciones pendientes en orden
      final operationsToProcess = List<Map<String, dynamic>>.from(
        _pendingOperations,
      );
      final completedOperations = <String>[];

      for (final operation in operationsToProcess) {
        try {
          await _processOperation(operation);
          completedOperations.add(operation['id'] as String);
          debugPrint('✅ Operation completed: ${operation['type']}');
        } catch (e) {
          debugPrint('❌ Failed to process operation ${operation['type']}: $e');
          // Si falla una operación, continuamos con las siguientes
        }
      }

      // Remover operaciones completadas
      _pendingOperations.removeWhere(
        (op) => completedOperations.contains(op['id']),
      );
      await _savePendingOperations();

      // Actualizar cache con datos del servidor
      await getProjects(forceRefresh: true);

      debugPrint(
        '✅ Project sync completed (${completedOperations.length}/${operationsToProcess.length} operations)',
      );
    } catch (e) {
      debugPrint('❌ Error during project sync: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _processOperation(Map<String, dynamic> operation) async {
    final type = operation['type'] as String;

    switch (type) {
      case 'create':
        final projectData = operation['project'] as Map<String, dynamic>;
        final project = Project.fromJson(projectData);
        await _projectRepository.create(project);
        break;

      case 'update':
        final projectData = operation['project'] as Map<String, dynamic>;
        final project = Project.fromJson(projectData);
        await _projectRepository.update(project);
        break;

      case 'delete':
        await _projectRepository.delete(operation['projectId'] as String);
        break;

      case 'addItem':
        await _projectRepository.addProjectItem(
          projectId: operation['projectId'] as String,
          table: operation['table'] as String,
          tableId: operation['tableId'] as String,
          brandId: operation['brandId'] as String,
        );
        break;

      case 'deleteItem':
        await _projectRepository.deleteProjectItem(
          itemId: operation['itemId'] as String,
        );
        break;

      default:
        throw Exception('Unknown operation type: $type');
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }
}
