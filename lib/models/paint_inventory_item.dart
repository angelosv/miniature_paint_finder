import 'package:miniature_paint_finder/models/paint.dart';

/// A model representing a paint item in the user's inventory.
///
/// This combines a [Paint] object with inventory-specific data such as:
/// - Current stock quantity
/// - User notes about the paint
///
/// This model supports immutability by providing a [copyWith] method
/// to create modified copies instead of directly changing properties.
class PaintInventoryItem {
  /// The paint information (color, brand, name, etc.)
  final Paint paint;

  /// The current quantity in stock (0 = out of stock)
  final int stock;

  /// User-provided notes about this paint
  final String notes;

  /// Creates a new paint inventory item.
  ///
  /// [paint] is required, [stock] defaults to 0, and [notes] defaults to an empty string.
  const PaintInventoryItem({
    required this.paint,
    this.stock = 0,
    this.notes = '',
  });

  /// Creates a copy of this item with the specified fields replaced with new values.
  ///
  /// This supports immutability by allowing creation of new objects with modified properties
  /// instead of directly changing the properties of existing objects.
  ///
  /// Example:
  /// ```dart
  /// final updatedItem = item.copyWith(stock: item.stock + 1);
  /// ```
  PaintInventoryItem copyWith({Paint? paint, int? stock, String? notes}) {
    return PaintInventoryItem(
      paint: paint ?? this.paint,
      stock: stock ?? this.stock,
      notes: notes ?? this.notes,
    );
  }

  /// Creates a paint inventory item from JSON data.
  factory PaintInventoryItem.fromJson(Map<String, dynamic> json) {
    return PaintInventoryItem(
      paint: Paint.fromJson(json['paint'] as Map<String, dynamic>),
      stock: json['stock'] as int,
      notes: json['notes'] as String,
    );
  }

  /// Converts this paint inventory item to a JSON object.
  Map<String, dynamic> toJson() {
    return {'paint': paint.toJson(), 'stock': stock, 'notes': notes};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaintInventoryItem && other.paint.id == paint.id;
  }

  @override
  int get hashCode => paint.id.hashCode;
}
