import 'package:flutter/material.dart';

/// Model representing a miniature paint product
class Paint {
  /// Unique identifier for the paint
  final String id;

  /// Name of the paint color
  final String name;

  /// Hexadecimal color code representation
  final String hex;

  /// Paint set
  final String set;

  /// Paint code
  final String code;

  /// Red component of the color
  final int r;

  /// Green component of the color
  final int g;

  /// Blue component of the color
  final int b;

  /// Manufacturer brand name
  final String brand;

  /// Paint category (e.g., 'Base', 'Layer', 'Shade', 'Technical')
  final String category;

  /// Whether the paint has metallic finish
  final bool isMetallic;

  /// Whether the paint is transparent/translucent
  final bool isTransparent;

  Paint({
    required this.id,
    required this.name,
    required this.hex,
    required this.set,
    required this.code,
    required this.r,
    required this.g,
    required this.b,
    required this.brand,
    required this.category,
    this.isMetallic = false,
    this.isTransparent = false,
  });

  /// Convert to JSON representation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'hex': hex,
      'set': set,
      'code': code,
      'r': r,
      'g': g,
      'b': b,
      'brand': brand,
      'category': category,
      'isMetallic': isMetallic,
      'isTransparent': isTransparent,
    };
  }

  /// Create a Paint object from JSON data
  factory Paint.fromJson(Map<String, dynamic> json) {
    return Paint(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      hex: json['hex'] as String? ?? '',
      set: json['set'] as String? ?? '',
      code: json['code'] as String? ?? '',
      r: json['r'] as int? ?? 0,
      g: json['g'] as int? ?? 0,
      b: json['b'] as int? ?? 0,
      brand: json['brand'] as String? ?? '',
      category: json['category'] as String? ?? '',
      isMetallic: json['isMetallic'] as bool? ?? false,
      isTransparent: json['isTransparent'] as bool? ?? false,
    );
  }

  Color toColor() {
    return Color.fromRGBO(r, g, b, 1);
  }

  /// Helper method to create a Paint object from hex color
  static Paint fromHex({
    required String id,
    required String name,
    required String brand,
    required String hex,
    required String category,
    required String set,
    required String code,
    bool isMetallic = false,
    bool isTransparent = false,
  }) {
    // Convert hex to RGB
    final hexColor = hex.startsWith('#') ? hex.substring(1) : hex;
    final r = int.parse(hexColor.substring(0, 2), radix: 16);
    final g = int.parse(hexColor.substring(2, 4), radix: 16);
    final b = int.parse(hexColor.substring(4, 6), radix: 16);

    return Paint(
      id: id,
      name: name,
      brand: brand,
      hex: hex,
      category: category,
      set: set,
      code: code,
      r: r,
      g: g,
      b: b,
      isMetallic: isMetallic,
      isTransparent: isTransparent,
    );
  }
}
