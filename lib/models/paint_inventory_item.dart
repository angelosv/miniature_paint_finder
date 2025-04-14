import 'package:miniature_paint_finder/models/paint.dart';

class PaintInventoryItem {
  final String id;
  final Paint paint;
  final int stock;
  final String notes;

  /// List of palette names this paint is part of (can be null or empty)
  final List<String>? palettes;

  const PaintInventoryItem({
    required this.id,
    required this.paint,
    this.stock = 0,
    this.notes = '',
    this.palettes,
  });

  PaintInventoryItem copyWith({
    String? id,
    Paint? paint,
    int? stock,
    String? notes,
    List<String>? palettes,
  }) {
    return PaintInventoryItem(
      id: id ?? this.id,
      paint: paint ?? this.paint,
      stock: stock ?? this.stock,
      notes: notes ?? this.notes,
      palettes: palettes ?? this.palettes,
    );
  }

  factory PaintInventoryItem.fromJson(Map<String, dynamic> json) {
    return PaintInventoryItem(
      id: json['id'] as String,
      paint: Paint.fromJson(json['paint'] as Map<String, dynamic>),
      stock: json['quantity'] as int,
      notes: json['notes'] as String? ?? '',
      palettes: (json['palettes'] as List?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paint': paint.toJson(),
      'stock': stock,
      'notes': notes,
      if (palettes != null) 'palettes': palettes,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaintInventoryItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
