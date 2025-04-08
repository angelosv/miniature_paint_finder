import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/models/paint.dart';
import 'package:miniature_paint_finder/services/paint_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Controlador para manejar la lógica de la pantalla de wishlist
class WishlistController extends ChangeNotifier {
  /// Servicio para acceder a datos de pinturas
  final PaintService _paintService;

  /// Lista de elementos en la wishlist
  List<Map<String, dynamic>> _wishlistItems = [];

  /// Estados de la carga
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  /// Constructor que recibe el servicio
  WishlistController(this._paintService);

  /// Getters para acceder a los datos desde la UI
  List<Map<String, dynamic>> get wishlistItems => _wishlistItems;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _wishlistItems.isEmpty;

  /// Cargar la wishlist desde la API
  Future<void> loadWishlist() async {
    print('🔄 WishlistController: Iniciando carga de wishlist');
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      String token = "token"; // Fallback token for testing
      bool usingFallbackToken = true;

      // Get Firebase token if available
      try {
        print('🔐 WishlistController: Intentando obtener token de Firebase...');
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          print(
            '👤 WishlistController: Usuario autenticado: ${user.email ?? 'No email'}',
          );
          final idToken = await user.getIdToken();
          if (idToken != null) {
            token = idToken;
            usingFallbackToken = false;
            print(
              '✅ WishlistController: Token de Firebase obtenido correctamente',
            );
          } else {
            print(
              '⚠️ WishlistController: Token de Firebase es null, usando token de respaldo',
            );
          }
        } else {
          print(
            '⚠️ WishlistController: No hay usuario autenticado, usando token de respaldo',
          );
        }
      } catch (e) {
        print('❌ WishlistController: Error al obtener token de Firebase: $e');
        print('⚠️ WishlistController: Usando token de respaldo para continuar');
      }

      if (usingFallbackToken) {
        print(
          '⚠️ WishlistController: Usando token de respaldo para la petición de wishlist',
        );
      }

      print('🔄 WishlistController: Obteniendo datos de wishlist...');
      final wishlistItems = await _paintService.getWishlistPaints(token);
      print(
        '✅ WishlistController: Datos de wishlist obtenidos: ${wishlistItems.length} elementos',
      );

      _wishlistItems = wishlistItems;
    } catch (e) {
      print('❌ WishlistController: Error al cargar wishlist: $e');
      _hasError = true;
      _errorMessage = 'Error al cargar wishlist: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
      print(
        '🏁 WishlistController: Finalizada carga de wishlist (${_hasError ? 'con errores' : 'exitosa'})',
      );
    }
  }

  /// Eliminar un elemento de la wishlist
  Future<bool> removeFromWishlist(String paintId, String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      String token = "token"; // Fallback token for testing
      bool usingFallbackToken = true;

      // Get Firebase token if available
      try {
        print(
          '🔐 WishlistController: Intentando obtener token de Firebase para eliminar pintura...',
        );
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          print(
            '👤 WishlistController: Usuario autenticado: ${user.email ?? 'No email'}',
          );
          final idToken = await user.getIdToken();
          if (idToken != null) {
            token = idToken;
            usingFallbackToken = false;
            print(
              '✅ WishlistController: Token de Firebase obtenido correctamente',
            );
          } else {
            print(
              '⚠️ WishlistController: Token de Firebase es null, usando token de respaldo',
            );
          }
        } else {
          print(
            '⚠️ WishlistController: No hay usuario autenticado, usando token de respaldo',
          );
        }
      } catch (e) {
        print('❌ WishlistController: Error al obtener token de Firebase: $e');
        print('⚠️ WishlistController: Usando token de respaldo para continuar');
      }

      if (usingFallbackToken) {
        print(
          '⚠️ WishlistController: Usando token de respaldo para eliminar de wishlist',
        );
      }

      print(
        '🔄 WishlistController: Eliminando pintura de wishlist (ID: $id)...',
      );
      final result = await _paintService.removeFromWishlist(paintId, id, token);

      if (result) {
        print(
          '✅ WishlistController: Pintura eliminada de wishlist correctamente',
        );
        // Actualizar la lista local
        _wishlistItems.removeWhere((item) => item['id'] == id);
        notifyListeners();
        return true;
      } else {
        print('❌ WishlistController: Error al eliminar pintura de wishlist');
        return false;
      }
    } catch (e) {
      print('❌ WishlistController: Excepción al eliminar de wishlist: $e');
      _hasError = true;
      _errorMessage = 'Error al eliminar de wishlist: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Actualizar la prioridad de un elemento en la wishlist
  Future<bool> updatePriority(
    String paintId,
    String id,
    bool isPriority,
  ) async {
    try {
      String token = "token"; // Fallback token for testing
      bool usingFallbackToken = true;

      // Get Firebase token if available
      try {
        print(
          '🔐 WishlistController: Intentando obtener token de Firebase para actualizar prioridad...',
        );
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          print(
            '👤 WishlistController: Usuario autenticado: ${user.email ?? 'No email'}',
          );
          final idToken = await user.getIdToken();
          if (idToken != null) {
            token = idToken;
            usingFallbackToken = false;
            print(
              '✅ WishlistController: Token de Firebase obtenido correctamente',
            );
          } else {
            print(
              '⚠️ WishlistController: Token de Firebase es null, usando token de respaldo',
            );
          }
        } else {
          print(
            '⚠️ WishlistController: No hay usuario autenticado, usando token de respaldo',
          );
        }
      } catch (e) {
        print('❌ WishlistController: Error al obtener token de Firebase: $e');
        print('⚠️ WishlistController: Usando token de respaldo para continuar');
      }

      if (usingFallbackToken) {
        print(
          '⚠️ WishlistController: Usando token de respaldo para actualizar prioridad',
        );
      }

      print(
        '🔄 WishlistController: Actualizando prioridad de pintura (ID: $id) a: ${isPriority ? 'Prioritaria' : 'Normal'}',
      );
      final result = await _paintService.updateWishlistPriority(
        paintId,
        id,
        isPriority,
        token,
      );

      if (result) {
        print('✅ WishlistController: Prioridad actualizada correctamente');

        // Actualizar el elemento en la lista local
        final index = _wishlistItems.indexWhere((item) => item['id'] == id);
        if (index != -1) {
          _wishlistItems[index]['isPriority'] = isPriority;
          notifyListeners();
        }

        return true;
      } else {
        print('❌ WishlistController: Error al actualizar prioridad');
        return false;
      }
    } catch (e) {
      print('❌ WishlistController: Excepción al actualizar prioridad: $e');
      return false;
    }
  }

  /// Añadir una pintura a la wishlist
  Future<bool> addToWishlist(Paint paint, bool isPriority) async {
    try {
      print(
        '🔄 WishlistController: Añadiendo ${paint.name} a wishlist con prioridad: ${isPriority ? 'Alta' : 'Normal'}',
      );
      final result = await _paintService.addToWishlist(paint, isPriority);

      if (result) {
        print('✅ WishlistController: Pintura añadida a wishlist correctamente');
        await loadWishlist(); // Recargar la lista completa para obtener el ID generado
        return true;
      } else {
        print('❌ WishlistController: Error al añadir pintura a wishlist');
        return false;
      }
    } catch (e) {
      print('❌ WishlistController: Excepción al añadir a wishlist: $e');
      return false;
    }
  }
}
