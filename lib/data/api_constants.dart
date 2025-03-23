/// Constantes con los endpoints de la API para la aplicación Miniature Paint Finder
class ApiEndpoints {
  /// Base URL para todas las llamadas API
  static const String baseUrl = 'https://api.miniature-paint-finder.com/v1';

  /// Endpoints relacionados con pinturas
  static const String paints = '/paints';
  static const String brands = '/brands';
  static const String matchColor = '/match-color';
  static const String extractColors = '/extract-colors';

  /// Endpoints relacionados con autenticación
  static const String register = '/auth/register';
  static const String login = '/auth/login';

  /// Endpoints relacionados con usuario
  static const String userPalettes = '/user/palettes';
  static const String userInventory = '/user/inventory';
  static const String userWishlist = '/user/wishlist';

  /// Construye un endpoint para obtener una pintura específica por ID
  static String paintById(String id) => '$paints/$id';

  /// Construye un endpoint para pinturas por marca
  static String paintsByBrand(String brand) => '$paints/by-brand?brand=$brand';

  /// Construye un endpoint para pinturas por categoría
  static String paintsByCategory(String category) =>
      '$paints/by-category?category=$category';

  /// Construye un endpoint para buscar pinturas
  static String searchPaints(String query) => '$paints/search?q=$query';

  /// Construye un endpoint para pinturas por código de barras
  static String paintsByBarcode(String barcode) =>
      '$paints/by-barcode?code=$barcode';

  /// Construye un endpoint para pinturas por color
  static String paintsByColor(String colorHex, {double threshold = 0.1}) =>
      '$paints/by-color?hex=$colorHex&threshold=$threshold';

  /// Construye un endpoint para una paleta específica por ID
  static String paletteById(String id) => '$userPalettes/$id';

  /// Construye un endpoint para añadir una pintura a una paleta
  static String addPaintToPalette(String paletteId) =>
      '$userPalettes/$paletteId/paints';
}
