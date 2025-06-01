import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/services/mixpanel_service.dart';

/// Mixin para implementar tracking de pantallas en StatefulWidget
mixin ScreenAnalyticsMixin<T extends StatefulWidget> on State<T> {
  final MixpanelService _analytics = MixpanelService.instance;
  String get screenName => widget.runtimeType.toString();

  @override
  void initState() {
    super.initState();
    _trackScreenView();
  }

  void _trackScreenView() {
    try {
      _analytics.trackScreen(screenName);
    } catch (e) {
      // No propagamos el error para no interrumpir la UI
    }
  }

  /// Utilidad para trackear eventos personalizados
  void trackEvent(String eventName, [Map<String, dynamic>? properties]) {
    try {
      _analytics.trackEvent(eventName, properties);
    } catch (e) {
      // No propagamos el error para no interrumpir la UI
    }
  }
}

/// Widget que automáticamente trackea la vista de una pantalla
class AnalyticsScreen extends StatefulWidget {
  final Widget child;
  final String screenName;

  const AnalyticsScreen({
    Key? key,
    required this.child,
    required this.screenName,
  }) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    MixpanelService.instance.trackScreen(widget.screenName);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Extensión para agregar tracking de eventos a cualquier widget
extension AnalyticsExtension on Widget {
  /// Envuelve el widget con tracking de analytics
  Widget withAnalytics(String screenName) {
    return AnalyticsScreen(screenName: screenName, child: this);
  }
}
