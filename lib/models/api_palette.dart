import 'package:flutter/material.dart';

class ApiPalette {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<ApiPalettePaint> palettesPaints;
  final String? image;

  ApiPalette({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.palettesPaints,
    this.image,
  });

  factory ApiPalette.fromJson(Map<String, dynamic> json) {
    return ApiPalette(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
      palettesPaints: (json['palettes_paints'] as List)
          .map((paint) => ApiPalettePaint.fromJson(paint))
          .toList(),
      image: json['image'],
    );
  }
}

class ApiPalettePaint {
  final String id;
  final String paletteId;
  final String paintId;
  final String? brandId;
  final String imageColorPicksId;
  final DateTime addedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ApiImageColorPick imageColorPicks;
  final ApiPaint? paint;

  ApiPalettePaint({
    required this.id,
    required this.paletteId,
    required this.paintId,
    this.brandId,
    required this.imageColorPicksId,
    required this.addedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.imageColorPicks,
    this.paint,
  });

  factory ApiPalettePaint.fromJson(Map<String, dynamic> json) {
    return ApiPalettePaint(
      id: json['id'],
      paletteId: json['palette_id'],
      paintId: json['paint_id'],
      brandId: json['brand_id'],
      imageColorPicksId: json['image_color_picks_id'],
      addedAt: DateTime.parse(json['added_at']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      imageColorPicks: ApiImageColorPick.fromJson(json['image_color_picks']),
      paint: json['paint'] != null ? ApiPaint.fromJson(json['paint']) : null,
    );
  }
}

class ApiImageColorPick {
  final String userId;
  final String imagePath;
  final DateTime createdAt;

  ApiImageColorPick({
    required this.userId,
    required this.imagePath,
    required this.createdAt,
  });

  factory ApiImageColorPick.fromJson(Map<String, dynamic> json) {
    return ApiImageColorPick(
      userId: json['user_id'],
      imagePath: json['image_path'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class ApiPaint {
  final String name;
  final String code;
  final String set;
  final int r;
  final int g;
  final int b;
  final String hex;
  final String color;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String nameLower;

  ApiPaint({
    required this.name,
    required this.code,
    required this.set,
    required this.r,
    required this.g,
    required this.b,
    required this.hex,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    required this.nameLower,
  });

  factory ApiPaint.fromJson(Map<String, dynamic> json) {
    return ApiPaint(
      name: json['name'],
      code: json['code'],
      set: json['set'],
      r: json['r'],
      g: json['g'],
      b: json['b'],
      hex: json['hex'],
      color: json['color'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      nameLower: json['name_lower'],
    );
  }
} 