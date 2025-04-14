import 'package:flutter/material.dart';

/// A model representing a saved palette of colors with their matching paints
class Palette {
  /// Unique identifier for the palette
  final String id;

  /// User-given name for the palette
  final String name;

  /// Path to the image that inspired this palette
  final String imagePath;

  /// List of colors in the palette
  final List<Color> colors;

  /// When the palette was created
  final DateTime createdAt;

  /// Optional list of selected paints matching the colors in this palette
  final List<PaintSelection>? paintSelections;

  Palette({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.colors,
    required this.createdAt,
    this.paintSelections,
  });

  /// Convert color to hex string
  static String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).toUpperCase().substring(2)}';
  }

  /// Convert hex string to color
  static Color _hexToColor(String hex) {
    return Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imagePath': imagePath,
      'colors': colors.map((color) => _colorToHex(color)).toList(),
      'createdAt': createdAt.toIso8601String(),
      'paintSelections':
          paintSelections?.map((selection) => selection.toJson()).toList(),
    };
  }

  /// Create from JSON
  factory Palette.fromJson(Map<String, dynamic> json) {
    return Palette(
      id: json['id'],
      name: json['name'],
      imagePath: json['imagePath'],
      colors:
          (json['colors'] as List)
              .map((hex) => _hexToColor(hex as String))
              .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      paintSelections:
          json['paintSelections'] != null
              ? (json['paintSelections'] as List)
                  .map((item) => PaintSelection.fromJson(item))
                  .toList()
              : null,
    );
  }
}

class PaletteSimple {
  final String id;

  final String name;

  PaletteSimple({
    required this.id,
    required this.name,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  /// Create from JSON
  factory PaletteSimple.fromJson(Map<String, dynamic> json) {
    return PaletteSimple(
      id: json['id'],
      name: json['name'],
    );
  }
}

/// A model representing a selected paint for a specific color in a palette
class PaintSelection {
  /// The color this paint matches (in hex format)
  final String colorHex;

  /// ID of the selected paint
  final String paintId;

  /// Name of the selected paint
  final String paintName;

  /// Brand of the selected paint
  final String paintBrand;

  /// Avatar letter for the brand (e.g., 'C' for Citadel)
  final String brandAvatar;

  /// Match percentage (0-100)
  final int matchPercentage;

  /// The paint's actual color (might be slightly different from the target color)
  final String paintColorHex;

  PaintSelection({
    required this.colorHex,
    required this.paintId,
    required this.paintName,
    required this.paintBrand,
    required this.brandAvatar,
    required this.matchPercentage,
    required this.paintColorHex,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'colorHex': colorHex,
      'paintId': paintId,
      'paintName': paintName,
      'paintBrand': paintBrand,
      'brandAvatar': brandAvatar,
      'matchPercentage': matchPercentage,
      'paintColorHex': paintColorHex,
    };
  }

  /// Create from JSON
  factory PaintSelection.fromJson(Map<String, dynamic> json) {
    return PaintSelection(
      colorHex: json['colorHex'],
      paintId: json['paintId'],
      paintName: json['paintName'],
      paintBrand: json['paintBrand'],
      brandAvatar: json['brandAvatar'],
      matchPercentage: json['matchPercentage'],
      paintColorHex: json['paintColorHex'],
    );
  }

  /// Convert paintColorHex to a Color object
  Color get paintColor {
    return Color(int.parse(paintColorHex.substring(1), radix: 16) + 0xFF000000);
  }
}
