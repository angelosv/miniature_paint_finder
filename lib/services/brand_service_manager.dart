import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:miniature_paint_finder/utils/env.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:miniature_paint_finder/models/paint.dart';

/// Servicio de gestión de marcas con caché local y persistencia
class BrandServiceManager {
  /// Singleton instance
  static final BrandServiceManager _instance = BrandServiceManager._internal();

  /// Factory constructor para obtener la instancia singleton
  factory BrandServiceManager() => _instance;

  /// Constructor privado
  BrandServiceManager._internal();

  /// Mapa de marcas (nombre a id)
  final Map<String, String> _brands = {};

  /// Mapa inverso (id a nombre)
  final Map<String, String> _brandNames = {};

  /// Estado de carga
  bool _isLoaded = false;

  /// Completer para manejar cargas simultáneas
  Completer<bool>? _loadingCompleter;

  /// Clave para la caché
  static const String _cacheKey = 'brands_cache_v2';

  /// Tiempo de expiración de la caché en horas
  static const int _cacheExpirationHours = 24;

  /// Verifica si las marcas están cargadas
  bool get isLoaded => _isLoaded;

  /// Inicializa y carga las marcas
  Future<bool> initialize() async {
    // Si ya están cargadas, retornar éxito
    if (_isLoaded && _brands.isNotEmpty) {
      print('✅ BrandManager: Marcas ya cargadas (${_brands.length} variantes)');
      return true;
    }

    // Si hay una carga en curso, esperar
    if (_loadingCompleter != null) {
      print('⏳ BrandManager: Esperando carga en curso...');
      return await _loadingCompleter!.future;
    }

    _loadingCompleter = Completer<bool>();

    try {
      // Intentar cargar desde caché
      final bool cacheSuccess = await _loadFromCache();
      if (cacheSuccess) {
        _isLoaded = true;
        print('✅ BrandManager: Marcas cargadas desde caché');
        _loadingCompleter!.complete(true);
        return true;
      }

      // Si no hay caché o falló, cargar desde API
      final bool apiSuccess = await _loadFromApi();
      if (apiSuccess) {
        await _saveToCache();
        _isLoaded = true;
        print('✅ BrandManager: Marcas cargadas desde API');
        _loadingCompleter!.complete(true);
        return true;
      }

      print('❌ BrandManager: No se pudieron cargar las marcas');
      _loadingCompleter!.complete(false);
      return false;
    } catch (e) {
      print('❌ BrandManager: Error cargando marcas: $e');
      _loadingCompleter!.complete(false);
      return false;
    } finally {
      _loadingCompleter = null;
    }
  }

  /// Carga las marcas desde la API
  Future<bool> _loadFromApi() async {
    try {
      final baseUrl = '${Env.apiBaseUrl}';
      final url = Uri.parse('$baseUrl/brand');

      print('🌐 BrandManager: Cargando marcas desde API');

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        print('❌ BrandManager: Error API (${response.statusCode})');
        return false;
      }

      final List<dynamic> brandsList = json.decode(response.body);
      print('📦 BrandManager: API retornó ${brandsList.length} marcas');

      // Limpiar datos existentes
      _brands.clear();
      _brandNames.clear();

      // Procesar cada marca
      for (final brand in brandsList) {
        if (brand['id'] == null || brand['name'] == null) {
          continue;
        }

        final String id = brand['id'];
        final String name = brand['name'];

        // Mapeo principal
        _brands[name.toLowerCase()] = id;

        // Mapeo inverso
        _brandNames[id] = name;

        // Variantes para mejorar el matching

        // Sin "The" al principio
        if (name.toLowerCase().startsWith('the ')) {
          _brands[name.toLowerCase().substring(4)] = id;
        }

        // Con guiones
        _brands[name.toLowerCase().replaceAll(' ', '-')] = id;

        // Con guiones bajos
        _brands[name.toLowerCase().replaceAll(' ', '_')] = id;
      }

      // Agregar casos especiales
      _addSpecialCases();

      print(
        '✅ BrandManager: Procesadas ${_brands.length} variantes de ${_brandNames.length} marcas',
      );
      return true;
    } catch (e) {
      print('❌ BrandManager: Error cargando desde API: $e');
      return false;
    }
  }

  /// Agregar casos especiales y variantes conocidas
  void _addSpecialCases() {
    // Army Painter y variantes
    if (_brandNames.containsKey('Army_Painter')) {
      final id = 'Army_Painter';
      _brands['warpaints'] = id;
      _brands['warpaints primer'] = id;
      _brands['warpaints air'] = id;
      _brands['warpaints metallics'] = id;
      _brands['warpaints quickshade'] = id;
      _brands['warpaint'] = id;
      _brands['army painter'] = id;
      _brands['army-painter'] = id;
    }

    // Citadel y variantes
    if (_brandNames.containsKey('Citadel_Colour')) {
      final id = 'Citadel_Colour';
      _brands['citadel'] = id;
      _brands['games workshop'] = id;
      _brands['gw'] = id;
    }

    // Otras marcas comunes
    final Map<String, List<String>> commonVariants = {
      'Vallejo': ['vallejo model color', 'vallejo game color', 'vmc', 'vgc'],
      'AK': ['ak interactive'],
      'Scale75': ['scale 75'],
      'P3': ['privateer press', 'formula p3'],
    };

    for (final entry in commonVariants.entries) {
      if (_brandNames.containsKey(entry.key)) {
        for (final variant in entry.value) {
          _brands[variant] = entry.key;
        }
      }
    }
  }

  /// Carga marcas desde la caché local
  Future<bool> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cacheData = prefs.getString(_cacheKey);

      if (cacheData == null || cacheData.isEmpty) {
        print('📝 BrandManager: No hay caché disponible');
        return false;
      }

      // Decodificar JSON
      final Map<String, dynamic> data = json.decode(cacheData);

      // Verificar formato válido
      if (!data.containsKey('timestamp') ||
          !data.containsKey('brands') ||
          !data.containsKey('brand_names')) {
        print('⚠️ BrandManager: Formato de caché inválido');
        return false;
      }

      // Verificar si expiró
      final int timestamp = data['timestamp'];
      final DateTime cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final Duration age = DateTime.now().difference(cacheTime);

      if (age.inHours > _cacheExpirationHours) {
        print('⏰ BrandManager: Caché expirada (${age.inHours} horas)');
        return false;
      }

      // Cargar datos
      _brands.clear();
      _brandNames.clear();

      final Map<String, dynamic> brandsData = data['brands'];
      final Map<String, dynamic> brandNamesData = data['brand_names'];

      brandsData.forEach((key, value) {
        _brands[key] = value.toString();
      });

      brandNamesData.forEach((key, value) {
        _brandNames[key] = value.toString();
      });

      print('📚 BrandManager: Caché cargada (${_brands.length} variantes)');
      print('📅 BrandManager: Fecha caché: ${cacheTime.toIso8601String()}');

      return true;
    } catch (e) {
      print('⚠️ BrandManager: Error cargando caché: $e');
      return false;
    }
  }

  /// Guarda las marcas en caché local
  Future<bool> _saveToCache() async {
    try {
      if (_brands.isEmpty || _brandNames.isEmpty) {
        print('⚠️ BrandManager: No hay datos para guardar en caché');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();

      // Preparar datos
      final Map<String, dynamic> cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'brands': _brands,
        'brand_names': _brandNames,
      };

      // Serializar y guardar
      final String serialized = json.encode(cacheData);
      await prefs.setString(_cacheKey, serialized);

      print(
        '💾 BrandManager: Marcas guardadas en caché (${_brands.length} variantes)',
      );
      return true;
    } catch (e) {
      print('⚠️ BrandManager: Error guardando caché: $e');
      return false;
    }
  }

  /// Obtiene el ID de marca a partir del nombre
  String? getBrandId(String brandName) {
    if (brandName.isEmpty) return null;

    // Convertir a minúsculas para comparar
    final String searchName = brandName.toLowerCase();

    // Match directo
    if (_brands.containsKey(searchName)) {
      return _brands[searchName];
    }

    // Match parcial
    for (final entry in _brands.entries) {
      if (entry.key.contains(searchName) || searchName.contains(entry.key)) {
        return entry.value;
      }
    }

    // Casos especiales
    if ((searchName.contains('army') && searchName.contains('painter')) ||
        searchName.contains('warpaint')) {
      return 'Army_Painter';
    }

    if (searchName.contains('citadel') ||
        searchName.contains('gw') ||
        searchName.contains('games workshop')) {
      return 'Citadel_Colour';
    }

    return null;
  }

  /// Determina el brand_id correcto para una pintura
  String determineBrandIdForPaint(Paint paint) {
    // Intentar por el nombre de la marca
    final String? brandIdByName = getBrandId(paint.brand);
    if (brandIdByName != null) {
      return brandIdByName;
    }

    // Intentar por el set (si está disponible)
    if (paint.set != null && paint.set.isNotEmpty) {
      final String? setBasedId = getBrandId(paint.set);
      if (setBasedId != null) {
        return setBasedId;
      }
    }

    // Intentar por características del ID
    if (paint.id.startsWith('AK')) {
      return 'AK';
    }

    if (paint.id.startsWith('VGC') || paint.id.startsWith('VMC')) {
      return 'Vallejo';
    }

    // Patrones de color de Army Painter
    if (paint.id.contains('-brown-') ||
        paint.id.contains('-green-') ||
        paint.id.contains('-blue-') ||
        paint.id.contains('-red-') ||
        paint.id.contains('-purple-') ||
        paint.id.startsWith('husk-')) {
      return 'Army_Painter';
    }

    // Casos especiales por nombre
    String brandLower = paint.brand.toLowerCase();
    if ((brandLower.contains('army') && brandLower.contains('painter')) ||
        brandLower.contains('warpaint')) {
      return 'Army_Painter';
    }

    if (brandLower.contains('citadel')) {
      return 'Citadel_Colour';
    }

    // Última opción: usar la primera palabra del nombre o el nombre completo
    if (paint.brand.contains(' ')) {
      return paint.brand.split(' ')[0];
    }

    return paint.brand;
  }

  /// Verifica si un brand_id es oficial
  bool isOfficialBrandId(String brandId) {
    return _brandNames.containsKey(brandId);
  }

  /// Obtiene el nombre oficial de una marca a partir de su ID
  String? getBrandName(String brandId) {
    return _brandNames[brandId];
  }

  /// Valida y corrige un brand_id
  String validateAndCorrectBrandId(String brandId, String? brandName) {
    // Si ya es oficial, lo usamos directamente
    if (isOfficialBrandId(brandId)) {
      return brandId;
    }

    // Intentar determinar por el nombre
    if (brandName != null && brandName.isNotEmpty) {
      final String? correctId = getBrandId(brandName);
      if (correctId != null) {
        return correctId;
      }
    }

    // Corregir casos comunes
    if (brandId.contains('Army') ||
        brandId.toLowerCase().contains('warpaint')) {
      return 'Army_Painter';
    }

    if (brandId.contains('Citadel')) {
      return 'Citadel_Colour';
    }

    return brandId;
  }

  /// Obtiene la lista de todos los brand_ids oficiales
  List<String> getAllBrandIds() {
    return _brandNames.keys.toList();
  }

  /// Obtiene todas las marcas con su nombre e ID
  List<Map<String, String>> getAllBrands() {
    return _brandNames.entries
        .map((entry) => {'id': entry.key, 'name': entry.value})
        .toList();
  }
}
