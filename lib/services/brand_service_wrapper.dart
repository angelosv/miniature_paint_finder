import 'package:miniature_paint_finder/services/brand_service.dart';
import 'package:miniature_paint_finder/models/paint.dart';

/// Wrapper para facilitar la integración de BrandService con PaintService
class BrandServiceWrapper {
  /// Instancia del servicio de marcas
  final BrandService _brandService = BrandService();

  /// Inicializa las marcas
  Future<bool> initialize() async {
    return await _brandService.initialize();
  }

  /// Determina el brand_id correcto para una pintura
  String determineBrandIdForPaint(Paint paint) {
    // Usar el BrandService para obtener el brand_id correcto
    final String? brandId = _brandService.getBrandId(paint.brand);

    if (brandId != null) {
      return brandId;
    }

    // Si el BrandService no pudo determinar el brand_id, intentamos determinar por el set
    if (paint.set != null && paint.set.isNotEmpty) {
      final String? setBasedId = _brandService.getBrandId(paint.set);
      if (setBasedId != null) {
        return setBasedId;
      }
    }

    // Intentar determinar por ID
    if (paint.id.startsWith('AK')) {
      return 'AK';
    }

    if (paint.id.startsWith('VGC') || paint.id.startsWith('VMC')) {
      return 'Vallejo';
    }

    // Color-pattern ID checks for Army Painter
    if (paint.id.contains('-brown-') ||
        paint.id.contains('-green-') ||
        paint.id.contains('-blue-') ||
        paint.id.contains('-red-') ||
        paint.id.contains('-purple-') ||
        paint.id.startsWith('husk-')) {
      return 'Army_Painter';
    }

    // Casos especiales conocidos
    String brandLower = paint.brand.toLowerCase();
    if (brandLower.contains('army') && brandLower.contains('painter') ||
        brandLower.contains('warpaint')) {
      return 'Army_Painter';
    }

    if (brandLower.contains('citadel')) {
      return 'Citadel_Colour';
    }

    // Last resort - use first word of brand or brand as is
    if (paint.brand.contains(' ')) {
      return paint.brand.split(' ')[0];
    }

    return paint.brand;
  }

  /// Verifica si un brand_id es válido y lo corrige si es necesario
  String validateAndCorrectBrandId(String brandId, String? brandName) {
    return _brandService.validateAndCorrectBrandId(brandId, brandName);
  }

  /// Verifica si un brand_id es oficial
  bool isOfficialBrandId(String brandId) {
    return _brandService.isOfficialBrandId(brandId);
  }

  /// Obtiene el nombre de una marca a partir de su ID
  String? getBrandName(String brandId) {
    return _brandService.getBrandName(brandId);
  }

  /// Obtiene todos los brand_ids oficiales
  List<String> getAllBrandIds() {
    return _brandService.getAllBrandIds();
  }
}
