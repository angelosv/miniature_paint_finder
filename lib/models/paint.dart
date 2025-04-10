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

  /// Manufacturer brand ID
  final String? brandId;

  /// Paint category (e.g., 'Base', 'Layer', 'Shade', 'Technical')
  final String category;

  /// Whether the paint has metallic finish
  final bool isMetallic;

  /// Whether the paint is transparent/translucent
  final bool isTransparent;

  /// List of palettes this paint belongs to
  final List<String>? palettes;

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
    this.brandId,
    required this.category,
    this.isMetallic = false,
    this.isTransparent = false,
    this.palettes = const [],
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
      'brandId': brandId,
      'category': category,
      'isMetallic': isMetallic,
      'isTransparent': isTransparent,
      'palettes': palettes,
    };
  }

  /// Create a Paint object from JSON data
  factory Paint.fromJson(Map<String, dynamic> json) {
    print('🔍 JSON recibido para Paint: $json'); // Debug log
    final brandId = json['brandId']?.toString();
    print('🔍 brandId extraído: $brandId'); // Debug log
    
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
      brandId: brandId,
      category: json['category'] as String? ?? '',
      isMetallic: json['isMetallic'] as bool? ?? false,
      isTransparent: json['isTransparent'] as bool? ?? false,
      palettes: (json['palettes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
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
    List<String> palettes = const [],
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
      palettes: palettes,
    );
  }
}
