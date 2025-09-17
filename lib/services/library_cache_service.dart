import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:miniature_paint_finder/services/paint_api_service.dart';

/// Servicio de cache inteligente para optimizar la carga de datos de la library
///
/// Este servicio implementa diferentes estrategias de cache:
/// - Cache persistente para marcas y categorías (duran más tiempo)
/// - Cache temporal para pinturas con TTL configurable
/// - Actualización automática en background
/// - Precarga de datos al iniciar la app
class LibraryCacheService extends ChangeNotifier {
  final PaintApiService _apiService;

  // Cache keys
  static const String _keyBrands = 'library_cache_brands';
  static const String _keyCategories = 'library_cache_categories';
  static const String _keyBrandsTimestamp = 'library_cache_brands_timestamp';
  static const String _keyCategoriesTimestamp =
      'library_cache_categories_timestamp';
  static const String _keyPaintsPrefix = 'library_cache_paints_';
  static const String _keyPaintsTimestampPrefix =
      'library_cache_paints_timestamp_';

  // TTL en minutos
  static const int _brandsCacheTTL = 24 * 60; // 24 horas
  static const int _categoriesCacheTTL = 24 * 60; // 24 horas
  static const int _paintsCacheTTL = 60; // 1 hora

  // Cache en memoria
  List<Map<String, dynamic>>? _cachedBrands;
  List<Map<String, dynamic>>? _cachedCategories;
  final Map<String, Map<String, dynamic>> _cachedPaints = {};
  final Map<String, DateTime> _paintsTimestamps = {};

  // Estados
  bool _isInitialized = false;
  bool _isPreloading = false;

  LibraryCacheService(this._apiService);

  /// Getters para los estados
  bool get isInitialized => _isInitialized;
  bool get isPreloading => _isPreloading;

  /// Inicializa el cache y precarga datos esenciales
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isPreloading = true;
      notifyListeners();

      // Precargar marcas y categorías (datos esenciales)
      await Future.wait([_loadBrandsFromCache(), _loadCategoriesFromCache()]);

      // Si no hay datos en cache, cargar del API
      if (_cachedBrands == null || _cachedCategories == null) {
        await _preloadEssentialData();
      }

      _isInitialized = true;

      // Programar actualización en background si es necesario
      _scheduleBackgroundUpdates();
    } catch (e) {
      debugPrint('❌ Error initializing LibraryCacheService: $e');
    } finally {
      _isPreloading = false;
      notifyListeners();
    }
  }

  /// Obtiene las marcas (brands) con cache inteligente
  Future<List<Map<String, dynamic>>> getBrands({
    bool forceRefresh = false,
  }) async {
    try {
      // Si tenemos cache válido y no forzamos refresh, retornarlo
      if (!forceRefresh &&
          _cachedBrands != null &&
          await _isBrandsCacheValid()) {
        debugPrint(
          '✅ Returning cached brands (${_cachedBrands!.length} items)',
        );
        return _cachedBrands!;
      }

      debugPrint('🔄 Loading brands from API...');

      // Cargar del API
      final brands = await _apiService.getBrands();

      // Verificar si necesitamos obtener conteos de pinturas
      bool needsCountUpdate = false;
      for (var brand in brands) {
        if (!brand.containsKey('paint_count') || brand['paint_count'] == null) {
          needsCountUpdate = true;
          brand['paint_count'] = 0;
        }
      }

      // Obtener conteos si es necesario
      if (needsCountUpdate) {
        debugPrint('🎨 Getting paint counts for brands...');
        await Future.wait(
          brands.map((brand) async {
            try {
              final result = await _apiService.getPaints(
                brandId: brand['id'] as String,
                limit: 1,
              );
              brand['paint_count'] = result['totalPaints'] as int;
            } catch (e) {
              debugPrint(
                '❌ Error getting count for brand ${brand['name']}: $e',
              );
            }
          }),
        );
      }

      // Cachear los resultados
      _cachedBrands = brands;
      await _saveBrandsToCache(brands);

      debugPrint('✅ Brands loaded and cached (${brands.length} items)');
      return brands;
    } catch (e) {
      debugPrint('❌ Error loading brands: $e');

      // Intentar retornar cache aunque esté expirado
      if (_cachedBrands != null) {
        debugPrint('⚠️ Returning expired cache as fallback');
        return _cachedBrands!;
      }

      rethrow;
    }
  }

  /// Obtiene las categorías con cache inteligente
  Future<List<Map<String, dynamic>>> getCategories({
    bool forceRefresh = false,
  }) async {
    try {
      // Si tenemos cache válido y no forzamos refresh, retornarlo
      if (!forceRefresh &&
          _cachedCategories != null &&
          await _isCategoriesCacheValid()) {
        debugPrint(
          '✅ Returning cached categories (${_cachedCategories!.length} items)',
        );
        return _cachedCategories!;
      }

      debugPrint('🔄 Loading categories from API...');

      // Cargar del API
      final categories = await _apiService.getCategories();

      // Cachear los resultados
      _cachedCategories = categories;
      await _saveCategoriesToCache(categories);

      debugPrint('✅ Categories loaded and cached (${categories.length} items)');
      return categories;
    } catch (e) {
      debugPrint('❌ Error loading categories: $e');

      // Intentar retornar cache aunque esté expirado
      if (_cachedCategories != null) {
        debugPrint('⚠️ Returning expired cache as fallback');
        return _cachedCategories!;
      }

      rethrow;
    }
  }

  /// Obtiene pinturas con cache inteligente basado en parámetros
  Future<Map<String, dynamic>> getPaints({
    String? category,
    String? brandId,
    String? name,
    String? code,
    String? hex,
    int limit = 10,
    int? page,
    bool forceRefresh = false,
  }) async {
    try {
      // Crear clave única para estos parámetros
      final cacheKey = _generatePaintsCacheKey(
        category: category,
        brandId: brandId,
        name: name,
        code: code,
        hex: hex,
        limit: limit,
        page: page,
      );

      // Si tenemos cache válido y no forzamos refresh, retornarlo
      if (!forceRefresh &&
          _cachedPaints.containsKey(cacheKey) &&
          _isPaintsCacheValid(cacheKey)) {
        debugPrint('✅ Returning cached paints for key: $cacheKey');
        return _cachedPaints[cacheKey]!;
      }

      debugPrint('🔄 Loading paints from API with key: $cacheKey');

      // Cargar del API
      final result = await _apiService.getPaints(
        category: category,
        brandId: brandId,
        name: name,
        code: code,
        hex: hex,
        limit: limit,
        page: page,
      );

      // Cachear los resultados
      _cachedPaints[cacheKey] = result;
      _paintsTimestamps[cacheKey] = DateTime.now();
      await _savePaintsToCache(cacheKey, result);

      //debugPrint(
        //'✅ Paints loaded and cached (${result['totalPaints']} total, ${(result['paints'] as List).length} in page)',
      //);
      return result;
    } catch (e) {
      debugPrint('❌ Error loading paints: $e');
      rethrow;
    }
  }

  /// Precarga datos esenciales para un arranque rápido
  Future<void> preloadEssentialData() async {
    if (_isPreloading) return;

    try {
      _isPreloading = true;
      notifyListeners();

      await _preloadEssentialData();
    } finally {
      _isPreloading = false;
      notifyListeners();
    }
  }

  /// Limpia todo el cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Limpiar cache en memoria
      _cachedBrands = null;
      _cachedCategories = null;
      _cachedPaints.clear();
      _paintsTimestamps.clear();

      // Limpiar cache persistente
      await prefs.remove(_keyBrands);
      await prefs.remove(_keyCategories);
      await prefs.remove(_keyBrandsTimestamp);
      await prefs.remove(_keyCategoriesTimestamp);

      // Limpiar cache de pinturas
      final keys =
          prefs
              .getKeys()
              .where(
                (key) =>
                    key.startsWith(_keyPaintsPrefix) ||
                    key.startsWith(_keyPaintsTimestampPrefix),
              )
              .toList();

      for (final key in keys) {
        await prefs.remove(key);
      }

      debugPrint('🗑️ All cache cleared');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
    }
  }

  /// Actualiza el cache en background para datos frecuentemente usados
  Future<void> updateCacheInBackground() async {
    try {
      debugPrint('🔄 Starting background cache update...');

      // Actualizar marcas y categorías en background
      unawaited(getBrands(forceRefresh: true));
      unawaited(getCategories(forceRefresh: true));

      // Precargar las primeras páginas de pinturas más comunes
      final commonQueries = [
        {
          'brandId': null,
          'category': null,
          'limit': 100,
          'page': 1,
        }, // Página principal
        {
          'brandId': null,
          'category': 'Base',
          'limit': 50,
          'page': 1,
        }, // Categoría popular
        {
          'brandId': null,
          'category': 'Layer',
          'limit': 50,
          'page': 1,
        }, // Categoría popular
      ];

      for (final query in commonQueries) {
        unawaited(
          getPaints(
            brandId: query['brandId'] as String?,
            category: query['category'] as String?,
            limit: query['limit'] as int,
            page: query['page'] as int,
            forceRefresh: true,
          ),
        );
      }

      debugPrint('✅ Background cache update initiated');
    } catch (e) {
      debugPrint('❌ Error in background cache update: $e');
    }
  }

  // Métodos privados

  Future<void> _preloadEssentialData() async {
    await Future.wait([
      getBrands(),
      getCategories(),
      // Precargar primera página de pinturas
      getPaints(limit: 100, page: 1),
    ]);
  }

  String _generatePaintsCacheKey({
    String? category,
    String? brandId,
    String? name,
    String? code,
    String? hex,
    int limit = 10,
    int? page,
  }) {
    return [
      'cat:${category ?? 'all'}',
      'brand:${brandId ?? 'all'}',
      'name:${name ?? 'none'}',
      'code:${code ?? 'none'}',
      'hex:${hex ?? 'none'}',
      'limit:$limit',
      'page:${page ?? 1}',
    ].join('|');
  }

  Future<bool> _isBrandsCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_keyBrandsTimestamp);
      if (timestamp == null) return false;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(cacheTime).inMinutes;

      return difference < _brandsCacheTTL;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _isCategoriesCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_keyCategoriesTimestamp);
      if (timestamp == null) return false;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(cacheTime).inMinutes;

      return difference < _categoriesCacheTTL;
    } catch (e) {
      return false;
    }
  }

  bool _isPaintsCacheValid(String cacheKey) {
    if (!_paintsTimestamps.containsKey(cacheKey)) return false;

    final cacheTime = _paintsTimestamps[cacheKey]!;
    final now = DateTime.now();
    final difference = now.difference(cacheTime).inMinutes;

    return difference < _paintsCacheTTL;
  }

  Future<void> _loadBrandsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_keyBrands);

      if (cachedData != null && await _isBrandsCacheValid()) {
        final List<dynamic> decoded = json.decode(cachedData);
        _cachedBrands = decoded.cast<Map<String, dynamic>>();
        debugPrint(
          '✅ Brands loaded from cache (${_cachedBrands!.length} items)',
        );
      }
    } catch (e) {
      debugPrint('❌ Error loading brands from cache: $e');
    }
  }

  Future<void> _loadCategoriesFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_keyCategories);

      if (cachedData != null && await _isCategoriesCacheValid()) {
        final List<dynamic> decoded = json.decode(cachedData);
        _cachedCategories = decoded.cast<Map<String, dynamic>>();
        debugPrint(
          '✅ Categories loaded from cache (${_cachedCategories!.length} items)',
        );
      }
    } catch (e) {
      debugPrint('❌ Error loading categories from cache: $e');
    }
  }

  Future<void> _saveBrandsToCache(List<Map<String, dynamic>> brands) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyBrands, json.encode(brands));
      await prefs.setInt(
        _keyBrandsTimestamp,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('❌ Error saving brands to cache: $e');
    }
  }

  Future<void> _saveCategoriesToCache(
    List<Map<String, dynamic>> categories,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCategories, json.encode(categories));
      await prefs.setInt(
        _keyCategoriesTimestamp,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('❌ Error saving categories to cache: $e');
    }
  }

  Future<void> _savePaintsToCache(
    String cacheKey,
    Map<String, dynamic> data,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_keyPaintsPrefix$cacheKey', json.encode(data));
      await prefs.setInt(
        '$_keyPaintsTimestampPrefix$cacheKey',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('❌ Error saving paints to cache: $e');
    }
  }

  void _scheduleBackgroundUpdates() {
    // Programar actualización cada 30 minutos
    Timer.periodic(const Duration(minutes: 30), (timer) {
      if (_isInitialized) {
        unawaited(updateCacheInBackground());
      }
    });
  }
}
