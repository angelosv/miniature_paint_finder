/// Model representing a miniature paint product
class Paint {
  /// Unique identifier for the paint
  final String id;

  /// Name of the paint color
  final String name;

  /// Manufacturer brand name
  final String brand;

  /// Hexadecimal color code representation
  final String colorHex;

  /// Paint category (e.g., 'Base', 'Layer', 'Shade', 'Technical')
  final String category;

  /// Whether the paint has metallic finish
  final bool isMetallic;

  /// Whether the paint is transparent/translucent
  final bool isTransparent;

  Paint({
    required this.id,
    required this.name,
    required this.brand,
    required this.colorHex,
    required this.category,
    this.isMetallic = false,
    this.isTransparent = false,
  });

  /// Convert to JSON representation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'colorHex': colorHex,
      'category': category,
      'isMetallic': isMetallic,
      'isTransparent': isTransparent,
    };
  }

  /// Create a Paint object from JSON data
  factory Paint.fromJson(Map<String, dynamic> json) {
    return Paint(
      id: json['id'],
      name: json['name'],
      brand: json['brand'],
      colorHex: json['colorHex'],
      category: json['category'],
      isMetallic: json['isMetallic'] ?? false,
      isTransparent: json['isTransparent'] ?? false,
    );
  }
}
