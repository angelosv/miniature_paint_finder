import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/services/mixpanel_service.dart';

/// Route observer that tracks screen views for analytics
class AnalyticsRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  final MixpanelService _analytics = MixpanelService();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) {
      // Track screen view when route is pushed
      _trackScreenView(route);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute is PageRoute) {
      // Track screen view when route is replaced
      _trackScreenView(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute is PageRoute && route is PageRoute) {
      // Track screen view when returning to previous route
      _trackScreenView(previousRoute);
    }
  }

  /// Extract the screen name from route and track it
  void _trackScreenView(PageRoute<dynamic> route) {
    try {
      // Extract meaningful name from route
      String? screenName = _extractScreenName(route);

      if (screenName != null) {
        // Use a microtask to ensure it doesn't interfere with navigation
        Future.microtask(() {
          try {
            // Only track if we have a screen name
            _analytics.trackScreen(screenName);
          } catch (e) {
            // Silently catch errors
            debugPrint('Analytics route observer error: $e');
          }
        });
      }
    } catch (e) {
      // Silently catch any errors to avoid disrupting navigation
      debugPrint('AnalyticsRouteObserver error: $e');
    }
  }

  /// Extract a readable name from the route
  String? _extractScreenName(PageRoute<dynamic> route) {
    // Get settings name if available
    final String? name = route.settings.name;

    if (name != null && name.isNotEmpty) {
      return name;
    }

    // Fall back to the route's runtimeType
    final routeType = route.runtimeType.toString();

    // Extract clean name from route type
    if (routeType.contains('_')) {
      // Handle routes with underscore
      final parts = routeType.split('_');
      if (parts.length > 1) {
        return parts[0];
      }
    }

    return routeType;
  }
}

// Create a global instance to use in MaterialApp
final analyticsRouteObserver = AnalyticsRouteObserver();
