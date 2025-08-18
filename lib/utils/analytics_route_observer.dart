import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:miniature_paint_finder/services/mixpanel_service.dart';

/// Un observador de rutas que automáticamente registra eventos de navegación en Mixpanel
class AnalyticsRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  final MixpanelService _analytics = MixpanelService.instance;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) {
      _trackScreenView(route);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute is PageRoute) {
      _trackScreenView(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute is PageRoute && route is PageRoute) {
      _trackScreenView(previousRoute);
    }
  }

  void _trackScreenView(PageRoute<dynamic> route) {
    try {
      final String screenName = _getScreenName(route);
      _analytics.trackScreen(screenName);
    } catch (e) {
      // No propagamos el error para no interrumpir la navegación
    }
  }

  String _getScreenName(PageRoute<dynamic> route) {
    // Intenta obtener el nombre de la ruta a partir de settings.name
    final String? routeName = route.settings.name;

    // Si hay un nombre de ruta explícito, úsalo
    if (routeName != null && routeName.isNotEmpty) {
      return routeName;
    }

    // En caso contrario, usa el nombre de la clase del widget principal
    // Nota: No podemos acceder directamente al widget, así que usamos el nombre de la ruta
    // o un nombre genérico basado en hashCode si no hay nombre
    return 'Screen-${route.hashCode}';
  }
}

// Crea una instancia global para usar en MaterialApp
final analyticsRouteObserver = AnalyticsRouteObserver();
// Clave global para tener acceso al contexto del navigator
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
