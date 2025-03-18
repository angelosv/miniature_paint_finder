import 'package:flutter/material.dart';

class Palette {
  final String id;
  final String name;
  final String imagePath;
  final List<Color> colors;
  final DateTime createdAt;

  Palette({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.colors,
    required this.createdAt,
  });
}
