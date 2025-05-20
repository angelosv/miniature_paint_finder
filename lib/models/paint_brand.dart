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
    // Extraer la cuenta de pinturas de diferentes campos posibles
    int extractPaintCount() {
      if (json.containsKey('paintCount') && json['paintCount'] != null) {
        if (json['paintCount'] is int) {
          return json['paintCount'];
        } else {
          return int.tryParse(json['paintCount'].toString()) ?? 0;
        }
      } else if (json.containsKey('paint_count') &&
          json['paint_count'] != null) {
        if (json['paint_count'] is int) {
          return json['paint_count'];
        } else {
          return int.tryParse(json['paint_count'].toString()) ?? 0;
        }
      } else if (json.containsKey('paints_count') &&
          json['paints_count'] != null) {
        if (json['paints_count'] is int) {
          return json['paints_count'];
        } else {
          return int.tryParse(json['paints_count'].toString()) ?? 0;
        }
      } else if (json.containsKey('count') && json['count'] != null) {
        if (json['count'] is int) {
          return json['count'];
        } else {
          return int.tryParse(json['count'].toString()) ?? 0;
        }
      }
      return 0;
    }

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
      paintCount: extractPaintCount(),
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
      'paintCount': paintCount,
    };
  }
}
