class PaintBrand {
  final String id;
  final String name;
  final String logoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int paintCount;

  PaintBrand({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.paintCount,
  });

  factory PaintBrand.fromJson(Map<String, dynamic> json) {
    return PaintBrand(
      id: json['id'],
      name: json['name'],
      logoUrl: json['logo_url'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        json['created_at']['_seconds'] * 1000,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        json['updated_at']['_seconds'] * 1000,
      ),
      paintCount: json['paintCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo_url': logoUrl,
      'created_at': {
        '_seconds': createdAt.millisecondsSinceEpoch ~/ 1000,
        '_nanoseconds': 0,
      },
      'updated_at': {
        '_seconds': updatedAt.millisecondsSinceEpoch ~/ 1000,
        '_nanoseconds': 0,
      },
    };
  }
}
