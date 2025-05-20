import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A simplified analytics service that provides a non-blocking interface
/// for tracking events in the app. This implementation avoids direct
/// dependencies on Mixpanel to prevent authentication flow issues.
class MixpanelService {
  static final MixpanelService _instance = MixpanelService._internal();
  bool _initialized = false;
  bool _enabled = true;

  /// Factory constructor to return the singleton instance
  factory MixpanelService() => _instance;

  /// Private constructor
  MixpanelService._internal();

  /// Initialize the analytics service
  Future<void> init() async {
    if (_initialized) return;

    debugPrint('📊 MixpanelService: Initializing in non-blocking mode');

    // Intentionally using a microtask to avoid blocking the UI
    await Future.microtask(() async {
      try {
        // We're not actually initializing Mixpanel here to avoid issues
        _initialized = true;
        debugPrint('📊 MixpanelService: Successfully initialized');
      } catch (e) {
        debugPrint('📊 MixpanelService: Error initializing - $e');
        // Automatically disable on error
        _enabled = false;
      }
    });
  }

  /// Track a custom event
  void trackEvent(String eventName, [Map<String, dynamic>? properties]) {
    if (!_enabled) return;

    try {
      // Log the event in debug mode but don't actually send anything
      debugPrint(
        '📊 MixpanelService: Track event "$eventName" with properties: $properties',
      );
    } catch (e) {
      // Silently catch any errors to avoid disrupting app flow
      debugPrint('📊 MixpanelService error: $e');
    }
  }

  /// Track screen view
  void trackScreen(String screenName) {
    if (!_enabled) return;

    try {
      // Use a microtask to ensure analytics doesn't block navigation
      Future.microtask(() {
        trackEvent('Screen View', {'screen': screenName});
      });
    } catch (e) {
      // Silently catch any errors to avoid disrupting app flow
      debugPrint('📊 MixpanelService screen tracking error: $e');
    }
  }

  /// Identify user
  void identify(String userId, [Map<String, dynamic>? properties]) {
    if (!_enabled) return;

    debugPrint(
      '📊 MixpanelService: Identify user "$userId" with properties: $properties',
    );
  }

  /// Reset user data - useful for sign out
  void reset() {
    if (!_enabled) return;

    debugPrint('📊 MixpanelService: Reset user data');
  }

  /// Create a placeholder for future implementation
  void setUserProperty(String property, dynamic value) {
    if (!_enabled) return;

    debugPrint('📊 MixpanelService: Set user property "$property" = $value');
  }

  /// Disable tracking temporarily
  void disable() {
    _enabled = false;
    debugPrint('📊 MixpanelService: Tracking disabled');
  }

  /// Enable tracking
  void enable() {
    _enabled = true;
    debugPrint('📊 MixpanelService: Tracking enabled');
  }
}
