import 'package:miniature_paint_finder/utils/env.dart';

/// Constantes con los endpoints de la API para la aplicación Miniature Paint Finder
class ApiEndpoints {
  /// Base URL para todas las llamadas API
  static final String baseUrl = '${Env.apiBaseUrl}';

  static String get guestLogic => '/flags/guest-logic';

  /// Endpoints relacionados con pinturas
  static String get paints => '/paints';
  static String get brands => '/brands';
  static String get matchColor => '/match-color';
  static String get extractColors => '/extract-colors';

  /// Endpoints relacionados con autenticación
  static String get auth => '/auth';

  /// Endpoints relacionados con usuario
  static String get palettes => '/palettes';
  static String get userPalettes => '/palettes';
  static String get inventory => '/inventory';
  static String get wishlist => '/wishlist';

  /// Endpoints relacionados con otras entidades
  static String get user => '/user';
  static String get sets => '/sets';
  static String get register => '/auth/register';
  static String get login => '/auth/login';
  static String get logout => '/auth/logout';
  static String get me => '/auth/me';
  static String get imageUpload => '/image/upload';

  /// Construye un endpoint para obtener una pintura específica por ID
  static String paintById(String id) => '/paints/$id';

  /// Construye un endpoint para pinturas por marca
  static String paintsByBrand(String brand) => '/paints/brand/$brand';

  /// Construye un endpoint para pinturas por categoría
  static String paintsByCategory(String category) =>
      '/paints/category/$category';

  /// Construye un endpoint para buscar pinturas
  static String searchPaints(String query) => '/paints/search?q=$query';

  /// Construye un endpoint para pinturas por código de barras
  static String paintsByBarcode(String barcode) => '/paints/barcode/$barcode';

  /// Construye un endpoint para pinturas por color
  static String paintsByColor(String hex, {double threshold = 0.1}) =>
      '/paints/color/$hex?threshold=$threshold';

  /// Construye un endpoint para una paleta específica por ID
  static String paletteById(String id) => '/palettes/$id';

  /// Construye un endpoint para añadir una pintura a una paleta
  static String addPaintToPalette(String paletteId) =>
      '/palettes/$paletteId/paints';

  /// Construye un endpoint para una marca específica por ID
  static String brandById(String id) => '/brands/$id';

  /// Construye un endpoint para un conjunto específico por ID
  static String setById(String id) => '/sets/$id';

  /// Construye un endpoint para remover una pintura de una paleta
  static String removePaintFromPalette(String paletteId, String paintId) =>
      '/palettes/$paletteId/paints/$paintId';
}
