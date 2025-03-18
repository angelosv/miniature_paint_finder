import 'package:flutter/material.dart';

class ColorChip extends StatelessWidget {
  final Color color;
  final String label;

  const ColorChip({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(backgroundColor: color, radius: 12),
      label: Text(label),
    );
  }
}
