import 'dart:async';

import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/models/palette.dart';
import 'package:miniature_paint_finder/data/sample_data.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Tipo de entrada de inventario
enum InventoryEntryType {
  /// Pintura nueva/sin usar
  new_paint,

  /// Pintura usada parcialmente
  used,

  /// Pintura casi vacía
  almost_empty,
}

/// Servicio para gestionar las operaciones relacionadas con pinturas
class PaintService {
  /// Lista de pinturas en inventario
  Map<String, Map<String, dynamic>> _inventory = {};

  /// Lista de pinturas en wishlist
  Map<String, Map<String, dynamic>> _wishlist = {};

  /// Paletas del usuario
  List<Palette> _userPalettes = [];

  /// Constructor
  PaintService() {
    _loadDemoData();
  }

  /// Carga datos de demostración para pruebas
  void _loadDemoData() {
    // Agregar algunas pinturas al inventario para demo
    final samplePaints = SampleData.getPaints();
    for (int i = 0; i < samplePaints.length; i += 3) {
      final paint = samplePaints[i];
      _inventory[paint.id] = {
        'quantity': (i % 5) + 1,
        'note': i % 2 == 0 ? 'Demo note for ${paint.name}' : null,
        'addedAt': DateTime.now().subtract(Duration(days: i)),
        'type': InventoryEntryType.values[i % 3].toString(),
      };
    }

    // Agregar algunas pinturas a la wishlist para demo
    for (int i = 1; i < samplePaints.length; i += 4) {
      final paint = samplePaints[i];
      _wishlist[paint.id] = {
        'isPriority': i % 2 == 0,
        'addedAt': DateTime.now().subtract(Duration(days: i)),
      };
    }

    // Usar las paletas de muestra
    _userPalettes = SampleData.getPalettes();
  }

  /// Verifica si una pintura está en el inventario
  bool isInInventory(String paintId) {
    return _inventory.containsKey(paintId);
  }

  /// Obtiene la cantidad de una pintura en el inventario
  int? getInventoryQuantity(String paintId) {
    return _inventory[paintId]?['quantity'] as int?;
  }

  /// Verifica si una pintura está en la wishlist
  bool isInWishlist(String paintId) {
    return _wishlist.containsKey(paintId);
  }

  /// Obtiene las paletas que contienen una pintura específica
  List<Palette> getPalettesContainingPaint(String paintId) {
    return _userPalettes.where((palette) {
      // Simulamos la contención de la pintura para demo
      // En una implementación real, verificaríamos si la paleta contiene la pintura
      return palette.id.hashCode % 2 == paintId.hashCode % 2;
    }).toList();
  }

  /// Agrega una pintura al inventario
  Future<bool> addToInventory(
    Paint paint,
    int quantity, {
    String? note,
    InventoryEntryType type = InventoryEntryType.new_paint,
  }) async {
    // Simulamos una operación asíncrona
    await Future.delayed(const Duration(milliseconds: 300));

    _inventory[paint.id] = {
      'quantity': quantity,
      'note': note,
      'addedAt': DateTime.now(),
      'type': type.toString(),
    };

    return true;
  }

  /// Actualiza una pintura en el inventario
  Future<bool> updateInventory(
    Paint paint,
    int quantity, {
    String? note,
    InventoryEntryType? type,
  }) async {
    // Simulamos una operación asíncrona
    await Future.delayed(const Duration(milliseconds: 300));

    if (!_inventory.containsKey(paint.id)) {
      return false;
    }

    final entry = _inventory[paint.id]!;
    entry['quantity'] = quantity;

    if (note != null) {
      entry['note'] = note;
    }

    if (type != null) {
      entry['type'] = type.toString();
    }

    return true;
  }

  /// Agrega una pintura a la wishlist
  Future<bool> addToWishlist(Paint paint, bool isPriority) async {
    // Simulamos una operación asíncrona
    await Future.delayed(const Duration(milliseconds: 300));

    _wishlist[paint.id] = {'isPriority': isPriority, 'addedAt': DateTime.now()};

    return true;
  }

  /// Elimina una pintura de la wishlist
  Future<bool> removeFromWishlist(
    String paintId,
    String _id,
    String token,
  ) async {
    final baseUrl = 'https://paints-api.reachu.io/api';

    final url = Uri.parse('$baseUrl/wishlist/$_id');

    print('📤 DELETE Wishlist request: $url');

    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print(
        '📥 DELETE Wishlist response [${response.statusCode}]: ${response.body}',
      );

      if (response.statusCode == 200) {
        // Mantén actualizado el estado local
        if (_wishlist.containsKey(paintId)) {
          _wishlist.remove(paintId);
        }
        return true;
      } else {
        print(
          '❌ Error al eliminar de wishlist: Código ${response.statusCode}, Respuesta: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('⚠️ Excepción al eliminar de wishlist: $e');
      rethrow;
    }
  }

  /// Actualiza la prioridad de una pintura en la wishlist
  Future<bool> updateWishlistPriority(
    String paintId,
    String wishlistId,
    bool isPriority,
    String token,
  ) async {
    // final baseUrl = 'http://10.0.2.2:8000';

    final baseUrl = 'https://paints-api.reachu.io/api';
    final url = Uri.parse('$baseUrl/wishlist/$wishlistId');

    // Convierte el valor booleano a backend (0 = prioridad, -1 = quitar)
    final priorityValue = isPriority ? 0 : -1;

    final requestBody = {'priority': priorityValue};
    print('📤 PATCH Wishlist priority request: $url');
    print('📤 Request body: ${jsonEncode(requestBody)}');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print(
        '📥 PATCH Wishlist priority response [${response.statusCode}]: ${response.body}',
      );

      if (response.statusCode == 200) {
        // Actualiza el estado local
        if (_wishlist.containsKey(paintId)) {
          _wishlist[paintId]!['isPriority'] = isPriority;
        }
        return true;
      } else {
        print(
          '❌ Error actualizando prioridad: Código ${response.statusCode}, Respuesta: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('⚠️ Excepción al actualizar prioridad: $e');
      rethrow;
    }
  }

  /// Obtiene todas las pinturas de la wishlist
  Future<List<Map<String, dynamic>>> getWishlistPaints(String token) async {
    final baseUrl = 'https://paints-api.reachu.io/api';
    final url = Uri.parse('$baseUrl/wishlist');

    print('📤 GET Wishlist request: $url');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 GET Wishlist response [${response.statusCode}]');

      if (response.statusCode == 200) {
        print('✅ Wishlist obtenida correctamente');
        // Solo logueamos la estructura de la respuesta, no todo el cuerpo para evitar logs muy largos
        final Map<String, dynamic> jsonData = json.decode(response.body);
        print('📊 Estructura de respuesta: ${jsonData.keys.toList()}');
        print(
          '📊 Total de elementos en la wishlist: ${jsonData["whitelist"]?.length ?? 0}',
        );
      } else {
        print(
          '❌ Error al obtener wishlist: Código ${response.statusCode}, Respuesta: ${response.body}',
        );
        throw Exception(
          'Failed to fetch wishlist (${response.statusCode}): ${response.body}',
        );
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch wishlist (${response.statusCode}): ${response.body}',
        );
      }

      final Map<String, dynamic> jsonData = json.decode(response.body);
      final List<dynamic> wishlist = jsonData['whitelist'];

      final List<Map<String, dynamic>> result = [];

      for (final item in wishlist) {
        final paintJson = item['paint'];
        final brandJson = item['brand'];
        final createdAt = item['created_at'];

        // Parse hex to get rgb components
        final hexColor =
            paintJson['hex'].startsWith('#')
                ? paintJson['hex'].substring(1)
                : paintJson['hex'];
        final r = int.parse(hexColor.substring(0, 2), radix: 16);
        final g = int.parse(hexColor.substring(2, 4), radix: 16);
        final b = int.parse(hexColor.substring(4, 6), radix: 16);

        final paint = Paint(
          id: paintJson['code'],
          name: paintJson['name'],
          brand: brandJson['name'],
          hex: paintJson['hex'],
          set: paintJson['set'] ?? 'Unknown',
          code: paintJson['code'],
          r: r,
          g: g,
          b: b,
          category: paintJson['set'] ?? 'Unknown',
          isMetallic: false,
          isTransparent: false,
        );

        result.add({
          'id': item['id'],
          'paint': paint,
          'isPriority': item['priority'] != null,
          'priority': item['priority'],
          'addedAt': DateTime.fromMillisecondsSinceEpoch(
            createdAt['_seconds'] * 1000,
          ),
        });
      }

      // Ordenar por prioridad (null al final) y luego por fecha de agregado
      result.sort((a, b) {
        final aPriority = a['priority'] ?? 9999;
        final bPriority = b['priority'] ?? 9999;

        if (aPriority != bPriority) {
          return aPriority.compareTo(bPriority);
        }

        return (b['addedAt'] as DateTime).compareTo(a['addedAt'] as DateTime);
      });

      print('✅ Procesados ${result.length} elementos de la wishlist');
      return result;
    } catch (e) {
      print('⚠️ Excepción al obtener la wishlist: $e');
      rethrow;
    }
  }

  /// Agrega una pintura a una paleta
  Future<bool> addToPalette(Paint paint, Palette palette) async {
    // Simulamos una operación asíncrona
    await Future.delayed(const Duration(milliseconds: 300));

    // En una implementación real, agregaríamos la pintura a la paleta
    // Aquí solo simulamos éxito
    return true;
  }

  /// Busca equivalencias de una pintura en otras marcas
  Future<List<Paint>> findEquivalents(Paint paint) async {
    // Simulamos una operación asíncrona
    await Future.delayed(const Duration(milliseconds: 500));

    // Para demo, devolvemos pinturas con colores similares
    final paintColor = int.parse(paint.hex.substring(1), radix: 16);

    return SampleData.getPaints()
        .where((p) {
          if (p.id == paint.id) return false;
          if (p.brand == paint.brand) return false;

          final pColor = int.parse(p.hex.substring(1), radix: 16);
          final diff = (paintColor - pColor).abs();

          // Aceptamos pinturas con una diferencia de color menor a cierto umbral
          return diff < 1000000;
        })
        .take(5) // Limitamos a 5 resultados
        .toList();
  }

  /// Obtiene las paletas del usuario
  List<Palette> getUserPalettes() {
    return _userPalettes;
  }

  /// Crea una nueva paleta
  Future<Palette> createPalette(String name, List<Color> colors) async {
    // Simulamos una operación asíncrona
    await Future.delayed(const Duration(milliseconds: 300));

    final palette = Palette(
      id: 'palette-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      imagePath: 'assets/images/placeholder.jpg',
      colors: colors,
      createdAt: DateTime.now(),
    );

    _userPalettes.add(palette);
    return palette;
  }
}
