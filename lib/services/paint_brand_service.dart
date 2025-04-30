import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:miniature_paint_finder/models/paint_brand.dart';
import 'package:miniature_paint_finder/utils/env.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaintBrandService {
  static final String baseUrl = '${Env.apiBaseUrl}';
  static const String CACHE_KEY = 'paint_brands_cache';
  static const int CACHE_DURATION_HOURS = 24; // Duración de la caché en horas

  Future<List<PaintBrand>> getPaintBrands() async {
    try {
      // Primero intentamos cargar desde la caché
      final cachedBrands = await _getCachedBrands();
      if (cachedBrands != null) {
        print('✅ Usando datos de marcas desde la caché local');
        return cachedBrands;
      }

      // Si no hay caché válida, llamamos al API
      print('🔄 Fetching paint brands from API...');
      final response = await http.get(Uri.parse('$baseUrl/brand'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Log details of each brand's paint count
        final brands =
            data.map((json) {
              final brand = PaintBrand.fromJson(json);
              // print(
              // '🎨 Brand: ${brand.name}, Paint Count: ${brand.paintCount}, ID: ${brand.id}',
              // );
              return brand;
            }).toList();

        // Sort brands by paintCount (descending)
        brands.sort((a, b) => b.paintCount.compareTo(a.paintCount));

        // print('📋 Brands sorted by paint count (descending)');
        // for (var brand in brands.take(5)) {
        // print('  • ${brand.name}: ${brand.paintCount} paints');
        // }

        // Calculate total paints
        final totalPaints = brands.fold(
          0,
          (sum, brand) => sum + brand.paintCount,
        );

        // Guardar en caché para uso futuro
        _saveBrandsToCache(brands);

        return brands;
      } else {
        print(
          '❌ API Error: Failed to load paint brands with status code: ${response.statusCode}',
        );
        print('📝 Response body: ${response.body}');
        throw Exception('Failed to load paint brands: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching paint brands: $e');
      throw Exception('Failed to load paint brands: $e');
    }
  }

  // Método para guardar las marcas en caché
  Future<void> _saveBrandsToCache(List<PaintBrand> brands) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Serializar la lista de marcas a JSON
      final List<Map<String, dynamic>> serializedBrands =
          brands.map((brand) => brand.toJson()).toList();

      // Añadir timestamp para control de expiración
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'brands': serializedBrands,
      };

      // Guardar en SharedPreferences
      await prefs.setString(CACHE_KEY, json.encode(cacheData));
      print('💾 Datos de marcas guardados en caché local');
    } catch (e) {
      print('⚠️ Error guardando marcas en caché: $e');
      // Si hay error al guardar caché, simplemente continuamos
    }
  }

  // Método para obtener marcas desde la caché
  Future<List<PaintBrand>?> _getCachedBrands() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(CACHE_KEY);

      if (cachedData == null) {
        print('ℹ️ No hay datos en caché');
        return null;
      }

      // Decodificar los datos
      final Map<String, dynamic> cacheMap = json.decode(cachedData);
      final timestamp = cacheMap['timestamp'] as int;
      final DateTime cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

      // Verificar si la caché ha expirado
      final cacheDuration = DateTime.now().difference(cacheTime);
      if (cacheDuration.inHours > CACHE_DURATION_HOURS) {
        print('ℹ️ Caché expirada (${cacheDuration.inHours} horas)');
        return null;
      }

      // Extraer y deserializar las marcas
      final List<dynamic> serializedBrands = cacheMap['brands'];
      final brands =
          serializedBrands
              .map((brandJson) => PaintBrand.fromJson(brandJson))
              .toList();

      print(
        '📋 Recuperadas ${brands.length} marcas desde caché (edad: ${cacheDuration.inHours}h ${cacheDuration.inMinutes % 60}m)',
      );

      // Ordenar por cantidad de pinturas (descendente)
      brands.sort((a, b) => b.paintCount.compareTo(a.paintCount));

      return brands;
    } catch (e) {
      print('⚠️ Error leyendo caché de marcas: $e');
      return null;
    }
  }

  // Método para forzar la actualización de la caché
  Future<List<PaintBrand>> refreshPaintBrands() async {
    try {
      // Limpiar caché existente
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(CACHE_KEY);
      print('🔄 Caché de marcas eliminada, forzando actualización desde API');

      // Llamar al método principal que ahora obtendrá datos frescos
      return await getPaintBrands();
    } catch (e) {
      print('❌ Error al refrescar marcas: $e');
      throw Exception('Failed to refresh paint brands: $e');
    }
  }
}
