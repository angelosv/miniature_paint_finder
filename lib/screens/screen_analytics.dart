import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/services/mixpanel_service.dart';

/// A mixin to add analytics tracking capabilities to screen widgets
mixin ScreenAnalytics<T extends StatefulWidget> on State<T> {
  final MixpanelService _analytics = MixpanelService();
  String get screenName;

  @override
  void initState() {
    super.initState();
    // Track when screen is first shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackScreenView();
    });
  }

  void _trackScreenView() {
    _analytics.trackScreen(screenName);
  }

  /// Track a custom event with optional properties
  void trackEvent(String eventName, [Map<String, dynamic>? properties]) {
    _analytics.trackEvent(eventName, properties);
  }
}

/// A stateful widget that automatically tracks screen views
abstract class AnalyticsStatefulWidget extends StatefulWidget {
  const AnalyticsStatefulWidget({Key? key}) : super(key: key);
}

/// A base state class for widgets that need analytics tracking
abstract class AnalyticsState<T extends AnalyticsStatefulWidget>
    extends State<T>
    with ScreenAnalytics<T> {
  @override
  String get screenName => widget.runtimeType.toString();
}

/// A wrapper widget that tracks screen views for any child widget
class ScreenViewTracker extends StatefulWidget {
  final Widget child;
  final String screenName;

  const ScreenViewTracker({
    Key? key,
    required this.child,
    required this.screenName,
  }) : super(key: key);

  @override
  _ScreenViewTrackerState createState() => _ScreenViewTrackerState();
}

class _ScreenViewTrackerState extends State<ScreenViewTracker>
    with ScreenAnalytics<ScreenViewTracker> {
  @override
  String get screenName => widget.screenName;

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
