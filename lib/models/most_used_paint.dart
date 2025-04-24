class MostUsedPaint {
  final String brandId;
  final String paintId;
  final int count;
  final bool inInventory;
  final bool inWhitelist;
  final String? inventoryId;
  final String? wishlistId;
  final PaintDetail paint;
  final BrandDetail brand;
  final List<PaletteInfo> paletteInfo;

  MostUsedPaint({
    required this.brandId,
    required this.paintId,
    required this.count,
    required this.inInventory,
    required this.inWhitelist,
    this.inventoryId,
    this.wishlistId,
    required this.paint,
    required this.brand,
    required this.paletteInfo,
  });

  factory MostUsedPaint.fromJson(Map<String, dynamic> json) {
    return MostUsedPaint(
      brandId: json['brand_id'] as String,
      paintId: json['paint_id'] as String,
      count: json['count'] as int,
      inInventory: json['in_inventory'] as bool,
      inWhitelist: json['in_whitelist'] as bool,
      inventoryId: json['inventory_id'] as String?,
      wishlistId: json['wishlist_id'] as String?,
      paint: PaintDetail.fromJson(json['paint'] as Map<String, dynamic>),
      brand: BrandDetail.fromJson(json['brand'] as Map<String, dynamic>),
      paletteInfo:
          (json['palette_info'] as List<dynamic>)
              .map((e) => PaletteInfo.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}

class PaintDetail {
  final String name;
  final String code;
  final String set;
  final int r, g, b;
  final String hex;
  final String colorUrl;
  final String barcode;
  // plus timestamps if you need...

  PaintDetail({
    required this.name,
    required this.code,
    required this.set,
    required this.r,
    required this.g,
    required this.b,
    required this.hex,
    required this.colorUrl,
    required this.barcode,
  });

  factory PaintDetail.fromJson(Map<String, dynamic> json) {
    return PaintDetail(
      name: json['name'] as String,
      code: json['code'] as String,
      set: json['set'] as String,
      r: json['r'] as int,
      g: json['g'] as int,
      b: json['b'] as int,
      hex: json['hex'] as String,
      colorUrl: json['color'] as String,
      barcode: json['barcode'] as String,
    );
  }
}

class BrandDetail {
  final String name;
  final String logoUrl;

  BrandDetail({required this.name, required this.logoUrl});

  factory BrandDetail.fromJson(Map<String, dynamic> json) {
    return BrandDetail(
      name: json['name'] as String,
      logoUrl: json['logo_url'] as String,
    );
  }
}

class PaletteInfo {
  final String id;
  final String name;
  final DateTime createdAt;

  PaletteInfo({required this.id, required this.name, required this.createdAt});

  factory PaletteInfo.fromJson(Map<String, dynamic> json) {
    return PaletteInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
