import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para gestionar las marcas oficiales de pinturas
class BrandService {
  /// Singleton instance
  static final BrandService _instance = BrandService._internal();

  /// Factory constructor para obtener la instancia singleton
  factory BrandService() => _instance;

  /// Constructor interno privado
  BrandService._internal();

  /// Mapa de marcas oficiales (nombre a id)
  final Map<String, String> brands = {};

  /// Mapa inverso (id a nombre)
  final Map<String, String> brandNames = {};

  /// Estado de carga de marcas
  bool _isLoaded = false;

  /// Completer para manejar múltiples llamadas
  Completer<bool>? _loadingCompleter;

  /// Clave para almacenar en SharedPreferences
  static const String _cacheKey = 'official_brands_data';

  /// Tiempo de expiración de la caché en horas
  static const int _cacheExpirationHours = 24;

  /// Método para verificar si las marcas están cargadas
  bool get isLoaded => _isLoaded;

  /// Inicializa y carga las marcas oficiales
  Future<bool> initialize() async {
    if (_isLoaded && brands.isNotEmpty) {
      print('✅ Marcas ya están cargadas (${brands.length} variantes)');
      return true;
    }

    return await loadBrands();
  }

  /// Carga las marcas oficiales, primero de caché y luego de API si es necesario
  Future<bool> loadBrands() async {
    try {
      // Si ya hay una carga en curso, esperamos su resultado
      if (_loadingCompleter != null) {
        print('🔄 Ya hay una carga de marcas en curso, esperando...');
        return await _loadingCompleter!.future;
      }

      // Iniciamos un nuevo proceso de carga
      _loadingCompleter = Completer<bool>();

      // Primero intentamos cargar desde la caché
      if (await _loadFromCache()) {
        _isLoaded = true;
        _loadingCompleter!.complete(true);
        return true;
      }

      // Si no hay caché o falló, cargamos desde la API
      if (await _loadFromApi()) {
        // Guardamos en caché para futuras sesiones
        await _saveToCache();
        _isLoaded = true;
        _loadingCompleter!.complete(true);
        return true;
      }

      // Si todo falló
      _loadingCompleter!.complete(false);
      return false;
    } catch (e) {
      print('❌ Error cargando marcas: $e');
      if (_loadingCompleter != null && !_loadingCompleter!.isCompleted) {
        _loadingCompleter!.complete(false);
      }
      return false;
    } finally {
      // Limpiamos el completer
      if (_loadingCompleter != null && !_loadingCompleter!.isCompleted) {
        _loadingCompleter!.complete(false);
      }
      _loadingCompleter = null;
    }
  }

  /// Carga las marcas desde la caché local
  Future<bool> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString(_cacheKey);

      if (cachedData == null || cachedData.isEmpty) {
        print('📝 No se encontró caché de marcas');
        return false;
      }

      // Decodificar la caché JSON
      final Map<String, dynamic> data = json.decode(cachedData);

      // Verificar que tenga todos los campos necesarios
      if (!data.containsKey('timestamp') ||
          !data.containsKey('brands') ||
          !data.containsKey('brand_names')) {
        print('⚠️ Caché de marcas con formato inválido');
        return false;
      }

      // Verificar si la caché ha expirado
      final int timestamp = data['timestamp'];
      final DateTime cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(cacheTime);

      if (difference.inHours > _cacheExpirationHours) {
        print('⏰ Caché de marcas expirada (${difference.inHours} horas)');
        return false;
      }

      // Cargar los datos
      brands.clear();
      brandNames.clear();

      final Map<String, dynamic> brandsMap = data['brands'];
      final Map<String, dynamic> brandNamesMap = data['brand_names'];

      brandsMap.forEach((key, value) {
        brands[key] = value.toString();
      });

      brandNamesMap.forEach((key, value) {
        brandNames[key] = value.toString();
      });

      print('✅ Marcas cargadas desde caché (${brands.length} variantes)');
      print('📅 Fecha de la caché: ${cacheTime.toIso8601String()}');

      return true;
    } catch (e) {
      print('❌ Error cargando marcas desde caché: $e');
      return false;
    }
  }

  /// Carga las marcas desde la API
  Future<bool> _loadFromApi() async {
    try {
      final baseUrl = 'https://paints-api.reachu.io/api';
      final url = Uri.parse('$baseUrl/brand');

      print('🌐 Cargando marcas desde API: $url');

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        print('❌ Error cargando marcas desde API: ${response.statusCode}');
        print('   Respuesta: ${response.body}');
        return false;
      }

      final List<dynamic> brandsList = json.decode(response.body);
      print('✅ API retornó ${brandsList.length} marcas');

      // Limpiar los mapas existentes
      brands.clear();
      brandNames.clear();

      // Procesar cada marca
      for (final brand in brandsList) {
        if (brand['id'] == null || brand['name'] == null) {
          continue;
        }

        final String id = brand['id'];
        final String name = brand['name'];

        // Mapeo principal (nombre a id)
        brands[name.toLowerCase()] = id;

        // Mapeo inverso (id a nombre)
        brandNames[id] = name;

        // Crear variantes para mejorar el matching

        // - Sin "The" al principio
        if (name.toLowerCase().startsWith('the ')) {
          brands[name.toLowerCase().substring(4)] = id;
        }

        // - Versión con guiones
        brands[name.toLowerCase().replaceAll(' ', '-')] = id;

        // - Versión con guiones bajos
        brands[name.toLowerCase().replaceAll(' ', '_')] = id;
      }

      // Agregar casos especiales conocidos
      _addSpecialCases();

      print(
        '✅ Marcas procesadas: ${brands.length} variantes de ${brandNames.length} marcas',
      );
      return true;
    } catch (e) {
      print('❌ Error cargando marcas desde API: $e');
      return false;
    }
  }

  /// Agrega casos especiales y variantes conocidas
  void _addSpecialCases() {
    // The Army Painter y variantes
    if (brandNames.containsKey('Army_Painter')) {
      final id = 'Army_Painter';
      brands['warpaints'] = id;
      brands['warpaints primer'] = id;
      brands['warpaints air'] = id;
      brands['warpaints metallics'] = id;
      brands['warpaints quickshade'] = id;
    }

    // Citadel y variantes
    if (brandNames.containsKey('Citadel_Colour')) {
      final id = 'Citadel_Colour';
      brands['citadel'] = id;
      brands['games workshop'] = id;
      brands['gw'] = id;
    }

    // Otras marcas comunes
    final Map<String, List<String>> commonVariants = {
      'Vallejo': ['vallejo model color', 'vallejo game color', 'vmc', 'vgc'],
      'AK': ['ak interactive'],
      'Scale75': ['scale 75'],
      'P3': ['privateer press', 'formula p3'],
    };

    commonVariants.forEach((id, variants) {
      if (brandNames.containsKey(id)) {
        for (final variant in variants) {
          brands[variant] = id;
        }
      }
    });
  }

  /// Guarda las marcas en caché local
  Future<bool> _saveToCache() async {
    try {
      if (brands.isEmpty || brandNames.isEmpty) {
        print('⚠️ No hay marcas para guardar en caché');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();

      // Preparar los datos
      final Map<String, dynamic> cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'brands': brands,
        'brand_names': brandNames,
      };

      // Serializar y guardar
      final String serialized = json.encode(cacheData);
      await prefs.setString(_cacheKey, serialized);

      print('💾 Marcas guardadas en caché (${brands.length} variantes)');
      return true;
    } catch (e) {
      print('❌ Error guardando marcas en caché: $e');
      return false;
    }
  }

  /// Obtiene el ID correcto de una marca a partir de su nombre
  String? getBrandId(String brandName) {
    if (brandName.isEmpty) return null;

    // Convertir a minúsculas para buscar
    final String searchName = brandName.toLowerCase();

    // Verificar match directo
    if (brands.containsKey(searchName)) {
      return brands[searchName];
    }

    // Buscar coincidencias parciales
    for (final entry in brands.entries) {
      if (entry.key.contains(searchName) || searchName.contains(entry.key)) {
        return entry.value;
      }
    }

    // Casos especiales conocidos
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

  /// Comprueba si un brand_id es oficial
  bool isOfficialBrandId(String brandId) {
    return brandNames.containsKey(brandId);
  }

  /// Obtiene el nombre oficial de una marca a partir de su ID
  String? getBrandName(String brandId) {
    return brandNames[brandId];
  }

  /// Obtiene todos los brand IDs oficiales
  List<String> getAllBrandIds() {
    return brandNames.keys.toList();
  }

  /// Obtiene todas las marcas oficiales con su nombre e ID
  List<Map<String, String>> getAllBrands() {
    return brandNames.entries
        .map((entry) => {'id': entry.key, 'name': entry.value})
        .toList();
  }

  /// Verifica y corrige un brand_id
  String validateAndCorrectBrandId(String brandId, String? brandName) {
    // Si el brand_id es oficial, lo usamos directamente
    if (isOfficialBrandId(brandId)) {
      return brandId;
    }

    // Si tenemos un nombre de marca, intentamos obtener el ID correcto
    if (brandName != null && brandName.isNotEmpty) {
      final String? correctId = getBrandId(brandName);
      if (correctId != null) {
        return correctId;
      }
    }

    // Intentamos corregir casos comunes
    if (brandId.contains('Army') ||
        brandId.toLowerCase().contains('warpaint')) {
      return 'Army_Painter';
    }

    if (brandId.contains('Citadel')) {
      return 'Citadel_Colour';
    }

    // Si no podemos corregirlo, devolvemos el original (pero puede fallar en el API)
    return brandId;
  }
}
