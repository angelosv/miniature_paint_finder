class Paint {
  final String id;
  final String name;
  final String brand;
  final String colorHex;
  final String category;
  final bool isMetallic;
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

  // Convert to JSON
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

  // Create from JSON
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
