import 'dart:async';

import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/models/palette.dart';
import 'package:miniature_paint_finder/data/sample_data.dart';

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
    final paintColor = int.parse(paint.colorHex.substring(1), radix: 16);

    return SampleData.getPaints()
        .where((p) {
          if (p.id == paint.id) return false;
          if (p.brand == paint.brand) return false;

          final pColor = int.parse(p.colorHex.substring(1), radix: 16);
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
