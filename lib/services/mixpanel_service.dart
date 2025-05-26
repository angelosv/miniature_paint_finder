import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/widgets.dart';

class MixpanelService {
  static const String _token = '570d806261b36af574266b6256137b0d';
  static MixpanelService? _instance;
  Mixpanel? _mixpanel;
  bool _initialized = false;
  String? _deviceId;
  String? _appVersion;
  String? _deviceModel;
  String? _osVersion;

  static MixpanelService get instance => _instance ??= MixpanelService._();

  MixpanelService._();

  bool get isInitialized => _initialized;
  String get appVersion => _appVersion ?? 'unknown';
  String? get deviceId => _deviceId;

  Future<void> init() async {
    if (_initialized) return;

    try {
      _mixpanel = await Mixpanel.init(
        _token,
        optOutTrackingDefault: false,
        trackAutomaticEvents: true,
      ).timeout(
        Duration(seconds: 3),
        onTimeout: () {
          throw TimeoutException('Mixpanel initialization timed out');
        },
      );

      unawaited(_getDeviceInfo());
      _initialized = true;

      _mixpanel?.track(
        'Debug_Initialization_Test',
        properties: {
          'timestamp': DateTime.now().toIso8601String(),
          'successful': true,
        },
      );

      unawaited(trackInstall());
    } catch (e) {
      _mixpanel = null;
      _initialized = false;
    }
  }

  Future<void> _getDeviceInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

      final deviceInfo = DeviceInfoPlugin();

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceId = iosInfo.identifierForVendor;
        _deviceModel = iosInfo.model;
        _osVersion = iosInfo.systemVersion;
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceId = androidInfo.id;
        _deviceModel = androidInfo.model;
        _osVersion = androidInfo.version.release;
      }

      _setSuperProperties();
    } catch (e) {
      // Silently handle device info errors
    }
  }

  void _setSuperProperties() {
    if (_mixpanel != null) {
      final Map<String, dynamic> properties = {
        'app_version': _appVersion ?? 'unknown',
        'device_model': _deviceModel ?? 'unknown',
        'os_version': _osVersion ?? 'unknown',
        'platform': defaultTargetPlatform.toString().split('.').last,
        'device_id': _deviceId,
        'screen_width':
            WidgetsBinding.instance.window.physicalSize.width /
            WidgetsBinding.instance.window.devicePixelRatio,
        'screen_height':
            WidgetsBinding.instance.window.physicalSize.height /
            WidgetsBinding.instance.window.devicePixelRatio,
        'device_pixel_ratio': WidgetsBinding.instance.window.devicePixelRatio,
        'locale': WidgetsBinding.instance.window.locale.toString(),
        'is_dark_mode':
            WidgetsBinding.instance.window.platformBrightness ==
            Brightness.dark,
      };

      _mixpanel!.registerSuperProperties(properties);
      properties.forEach((key, value) {
        _mixpanel!.getPeople().set(key, value);
      });
    }
  }

  Future<void> identify(String userId) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    if (_mixpanel != null) {
      try {
        _mixpanel!.identify(userId);
        final people = _mixpanel!.getPeople();
        people.set('\$name', userId);
        people.set('\$last_login', DateTime.now().toIso8601String());
        people.set('user_id', userId);
        people.set('identified_at', DateTime.now().toIso8601String());
        people.increment('\$session_count', 1.0);
      } catch (e) {
        // Silently handle identification errors
      }
    }
  }

  Future<void> identifyUserWithDetails({
    required String userId,
    String? name,
    String? email,
    String? phoneNumber,
    String? authProvider,
    bool isNewUser = false,
    Map<String, dynamic>? additionalUserProperties,
  }) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    if (_mixpanel != null) {
      try {
        _mixpanel!.identify(userId);
        final people = _mixpanel!.getPeople();

        if (name != null) people.set('\$name', name);
        if (email != null) people.set('\$email', email);
        if (phoneNumber != null) people.set('\$phone', phoneNumber);

        people.set('user_id', userId);
        people.set('last_login', DateTime.now().toIso8601String());
        if (authProvider != null) people.set('auth_provider', authProvider);
        people.set('app_version', _appVersion);
        people.set(
          'platform',
          defaultTargetPlatform.toString().split('.').last,
        );
        people.set('device_model', _deviceModel);
        people.set('os_version', _osVersion);

        if (isNewUser) {
          people.set('created_at', DateTime.now().toIso8601String());
          people.set('is_new_user', true);
        }

        if (additionalUserProperties != null) {
          additionalUserProperties.forEach((key, value) {
            people.set(key, value);
          });
        }

        people.increment('\$session_count', 1.0);

        trackEvent('User Identified', {
          'user_id': userId,
          'has_name': name != null,
          'has_email': email != null,
          'has_phone': phoneNumber != null,
          'auth_provider': authProvider,
          'is_new_user': isNewUser,
        });
      } catch (e) {
        // Silently handle identification errors
      }
    }
  }

  Future<void> updateUserProperty(String property, dynamic value) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    if (_mixpanel != null) {
      try {
        _mixpanel!.getPeople().set(property, value);
      } catch (e) {
        // Silently handle property update errors
      }
    }
  }

  Future<void> incrementUserProperty(String property, double value) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    if (_mixpanel != null) {
      try {
        _mixpanel!.getPeople().increment(property, value);
      } catch (e) {
        // Silently handle increment errors
      }
    }
  }

  Future<void> appendToUserList(String property, dynamic value) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    if (_mixpanel != null) {
      try {
        _mixpanel!.getPeople().append(property, value);
      } catch (e) {
        // Silently handle append errors
      }
    }
  }

  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    if (_mixpanel != null) {
      try {
        properties.forEach((key, value) {
          _mixpanel!.getPeople().set(key, value);
        });
      } catch (e) {
        // Silently handle property setting errors
      }
    }
  }

  Future<void> trackUserAction(
    String action, [
    Map<String, dynamic>? properties,
  ]) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    final Map<String, dynamic> actionProperties = {
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
      ...?properties,
    };

    _safeTrack('User Action', actionProperties);
  }

  Future<void> trackError(
    String errorType,
    String errorMessage, [
    Map<String, dynamic>? additionalInfo,
  ]) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    final Map<String, dynamic> errorProperties = {
      'error_type': errorType,
      'error_message': errorMessage,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalInfo,
    };

    _safeTrack('Error', errorProperties);
  }

  Future<void> trackPerformance(
    String metricName,
    int valueMs, [
    Map<String, dynamic>? context,
  ]) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    final Map<String, dynamic> perfProperties = {
      'metric_name': metricName,
      'value_ms': valueMs,
      'timestamp': DateTime.now().toIso8601String(),
      ...?context,
    };

    _safeTrack('Performance', perfProperties);
  }

  Future<void> trackFeatureUsage(
    String featureName, [
    Map<String, dynamic>? usageInfo,
  ]) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    final Map<String, dynamic> featureProperties = {
      'feature': featureName,
      'timestamp': DateTime.now().toIso8601String(),
      ...?usageInfo,
    };

    _safeTrack('Feature Usage', featureProperties);
  }

  Future<void> trackInstall() async {
    if (!_initialized || _mixpanel == null) {
      await init();
    }

    if (_mixpanel != null && _deviceId != null) {
      final distinctId = _mixpanel!.getDistinctId();

      _mixpanel!.track(
        'App Installed',
        properties: {
          'device_id': _deviceId,
          'first_seen': DateTime.now().toIso8601String(),
          'distinct_id': distinctId,
        },
      );
    }
  }

  Future<void> _safeTrack(
    String eventName,
    Map<String, dynamic>? properties,
  ) async {
    if (!_initialized || _mixpanel == null) {
      try {
        await init().timeout(
          Duration(seconds: 1),
          onTimeout: () {
            throw TimeoutException('Mixpanel re-initialization timed out');
          },
        );
      } catch (e) {
        return;
      }
    }

    if (_mixpanel == null) return;

    try {
      final Map<String, dynamic> enrichedProperties = {
        'timestamp': DateTime.now().toIso8601String(),
        ...?properties,
      };

      _mixpanel!.track(eventName, properties: enrichedProperties);
    } catch (e) {
      // Silently handle tracking errors
    }
  }

  Future<void> trackActiveUser() async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    _safeTrack('Active User', {'timestamp': DateTime.now().toIso8601String()});
  }

  Future<void> trackScreen(String screenName) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    _safeTrack('Screen View', {
      'screen_name': screenName,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> trackEvent(
    String eventName, [
    Map<String, dynamic>? properties,
  ]) async {
    try {
      if (!_initialized || _mixpanel == null) {
        await init().catchError((e) {});
      }

      final Map<String, dynamic> enrichedProperties = {
        'timestamp': DateTime.now().toIso8601String(),
        ...?properties,
      };

      if (_mixpanel != null) {
        _mixpanel!.track(eventName, properties: enrichedProperties);
      }
    } catch (e) {
      _trackEventAsync(eventName, properties);
    }
  }

  void _trackEventAsync(String eventName, [Map<String, dynamic>? properties]) {
    Future.microtask(() async {
      try {
        await _safeTrack(eventName, properties);
      } catch (e) {
        // Silently handle async tracking errors
      }
    });
  }

  Future<void> logout() async {
    if (_initialized && _mixpanel != null) {
      try {
        final Map<String, dynamic> logoutProperties = {
          'logout_timestamp': DateTime.now().toIso8601String(),
          'user_id_before_reset': await _mixpanel!.getDistinctId(),
        };
        await _safeTrack('User Logged Out', logoutProperties);
      } catch (e) {
        // Silently handle logout tracking errors
      }
    }

    if (_mixpanel != null) {
      try {
        await _mixpanel!.reset();
      } catch (e) {
        // Silently handle reset errors
      }
    }
  }

  Future<void> trackPaintSearch(
    String searchTerm,
    int resultsCount, [
    Map<String, dynamic>? additionalInfo,
  ]) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    final Map<String, dynamic> searchProperties = {
      'search_term': searchTerm,
      'results_count': resultsCount,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalInfo,
    };

    _safeTrack('Paint Search', searchProperties);
  }

  Future<void> trackPaintView(
    String paintId,
    String paintName,
    String brand, [
    Map<String, dynamic>? additionalInfo,
  ]) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    final Map<String, dynamic> viewProperties = {
      'paint_id': paintId,
      'paint_name': paintName,
      'brand': brand,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalInfo,
    };

    _safeTrack('Paint View', viewProperties);
  }

  Future<void> trackPaintAddedToInventory(
    String paintId,
    String paintName,
    String brand,
  ) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    final Map<String, dynamic> addProperties = {
      'paint_id': paintId,
      'paint_name': paintName,
      'brand': brand,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _safeTrack('Paint Added To Inventory', addProperties);

    try {
      _mixpanel!.getPeople().increment('paints_in_inventory', 1);
      _mixpanel!.getPeople().append('brands_owned', brand);
    } catch (e) {
      // Silently handle inventory tracking errors
    }
  }

  Future<void> trackPaintRemovedFromInventory(
    String paintId,
    String paintName,
    String brand,
  ) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    final Map<String, dynamic> removeProperties = {
      'paint_id': paintId,
      'paint_name': paintName,
      'brand': brand,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _safeTrack('Paint Removed From Inventory', removeProperties);

    try {
      _mixpanel!.getPeople().increment('paints_in_inventory', -1);
    } catch (e) {
      // Silently handle inventory tracking errors
    }
  }

  Future<void> trackPaintAddedToWishlist(
    String paintId,
    String paintName,
    String brand,
  ) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    final Map<String, dynamic> wishlistProperties = {
      'paint_id': paintId,
      'paint_name': paintName,
      'brand': brand,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _safeTrack('Paint Added To Wishlist', wishlistProperties);

    try {
      _mixpanel!.getPeople().increment('paints_in_wishlist', 1);
    } catch (e) {
      // Silently handle wishlist tracking errors
    }
  }

  Future<void> trackColorSearch(String hexColor, int resultsCount) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    final Map<String, dynamic> colorSearchProperties = {
      'hex_color': hexColor,
      'results_count': resultsCount,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _safeTrack('Color Search', colorSearchProperties);
  }

  Future<void> trackBarcodeScanned(
    String barcode,
    bool paintFound, [
    String? paintName,
    String? brand,
  ]) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    final Map<String, dynamic> barcodeProperties = {
      'barcode': barcode,
      'paint_found': paintFound,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (paintFound && paintName != null) {
      barcodeProperties['paint_name'] = paintName;
    }

    if (paintFound && brand != null) {
      barcodeProperties['brand'] = brand;
    }

    _safeTrack('Barcode Scanned', barcodeProperties);
  }

  Future<void> trackPaletteCreated(String paletteName, int colorCount) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    final Map<String, dynamic> paletteProperties = {
      'palette_name': paletteName,
      'color_count': colorCount,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _safeTrack('Palette Created', paletteProperties);

    try {
      _mixpanel!.getPeople().increment('palettes_created', 1);
    } catch (e) {
      // Silently handle palette tracking errors
    }
  }

  Future<void> trackBarcodeNotFound(
    String barcode, {
    String? contextScreen,
    String? brandGuess,
  }) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    final Map<String, dynamic> properties = {
      'barcode': barcode,
      'screen': contextScreen,
      'brand_guess': brandGuess,
      'timestamp': DateTime.now().toIso8601String(),
      'app_version': _appVersion,
      'device_model': _deviceModel,
      'platform': defaultTargetPlatform.toString().split('.').last,
    };

    _safeTrack('Barcode Not Found', properties);

    try {
      _mixpanel!.getPeople().increment('barcodes_not_found_count', 1.0);
      _mixpanel!.getPeople().append('barcodes_not_found', barcode);
    } catch (e) {
      // Silently handle barcode tracking errors
    }
  }

  Future<void> trackScannerActivity(
    String activityType, {
    String? barcode,
    String? paintId,
    String? paintName,
    String? errorDetails,
    int? scanDurationMs,
  }) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    final Map<String, dynamic> properties = {
      'activity_type': activityType,
      'barcode': barcode,
      'paint_id': paintId,
      'paint_name': paintName,
      'error_details': errorDetails,
      'scan_duration_ms': scanDurationMs,
      'timestamp': DateTime.now().toIso8601String(),
      'device_model': _deviceModel,
      'os_version': _osVersion,
      'platform': defaultTargetPlatform.toString().split('.').last,
      'app_version': _appVersion,
    };

    _safeTrack('Scanner Activity', properties);

    try {
      if (activityType == 'success') {
        _mixpanel!.getPeople().increment('successful_scans', 1.0);
      } else if (activityType == 'error') {
        _mixpanel!.getPeople().increment('failed_scans', 1.0);
      }
    } catch (e) {
      // Silently handle scanner tracking errors
    }
  }

  Future<void> trackPaintInteraction(
    String paintId,
    String paintName,
    String brand,
    String interactionType, {
    String? source,
    Map<String, dynamic>? additionalData,
  }) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    final Map<String, dynamic> properties = {
      'paint_id': paintId,
      'paint_name': paintName,
      'brand': brand,
      'interaction_type': interactionType,
      'source': source,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    };

    _safeTrack('Paint Interaction', properties);

    try {
      if (interactionType == 'viewed' || interactionType == 'searched') {
        _mixpanel!.getPeople().increment('paints_viewed_count', 1.0);
      }

      _mixpanel!.getPeople().append('brands_interacted', brand);

      if (interactionType == 'viewed') {
        final recentViewKey = 'recent_paints_$brand';
        _mixpanel!.getPeople().append(recentViewKey, '$paintId:$paintName');
      }
    } catch (e) {
      // Silently handle paint interaction tracking errors
    }
  }

  Future<void> trackColorSearchDetailed(
    String hexColor,
    int resultsCount, {
    bool fromCamera = false,
    String? selectedPaintId,
    String? selectedPaintName,
    String? selectedBrand,
    int? searchDurationMs,
  }) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    final Map<String, dynamic> properties = {
      'hex_color': hexColor,
      'results_count': resultsCount,
      'source': fromCamera ? 'camera' : 'manual',
      'selected_paint': selectedPaintId != null,
      'selected_paint_id': selectedPaintId,
      'selected_paint_name': selectedPaintName,
      'selected_brand': selectedBrand,
      'search_duration_ms': searchDurationMs,
      'timestamp': DateTime.now().toIso8601String(),
      'app_version': _appVersion,
    };

    _safeTrack('Color Search Details', properties);

    try {
      _mixpanel!.getPeople().increment('color_searches', 1.0);
      _mixpanel!.getPeople().append('colors_searched', hexColor);
    } catch (e) {
      // Silently handle color search tracking errors
    }
  }

  Future<void> trackInventoryActivity(
    String activityType, {
    int? itemsAffected,
    String? filterCriteria,
    int? timeTakenSeconds,
    Map<String, dynamic>? additionalInfo,
  }) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    final Map<String, dynamic> properties = {
      'activity_type': activityType,
      'items_affected': itemsAffected,
      'filter_criteria': filterCriteria,
      'time_taken_seconds': timeTakenSeconds,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalInfo,
    };

    _safeTrack('Inventory Activity', properties);

    try {
      if (activityType == 'bulk_add' && itemsAffected != null) {
        _mixpanel!.getPeople().increment('inventory_bulk_adds', 1.0);
        _mixpanel!.getPeople().increment(
          'total_paints_added',
          itemsAffected.toDouble(),
        );
      } else if (activityType == 'export') {
        _mixpanel!.getPeople().increment('inventory_exports', 1.0);
        _mixpanel!.getPeople().set(
          'last_inventory_export',
          DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      // Silently handle inventory activity tracking errors
    }
  }

  Future<void> trackOnboardingProgress(
    String stage,
    bool completed, {
    int? timeSpentSeconds,
    String? skippedReason,
  }) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    final Map<String, dynamic> properties = {
      'stage': stage,
      'completed': completed,
      'time_spent_seconds': timeSpentSeconds,
      'skipped_reason': skippedReason,
      'timestamp': DateTime.now().toIso8601String(),
      'app_version': _appVersion,
    };

    _safeTrack('Onboarding Progress', properties);

    try {
      if (completed) {
        _mixpanel!.getPeople().append('onboarding_stages_completed', stage);
        _mixpanel!.getPeople().set('onboarding_stage_$stage', true);
      } else if (skippedReason != null) {
        _mixpanel!.getPeople().append('onboarding_stages_skipped', stage);
        _mixpanel!.getPeople().set('skipped_stage_$stage', skippedReason);
      }
    } catch (e) {
      // Silently handle onboarding tracking errors
    }
  }

  Future<void> trackPlatformSpecificIssue(
    String feature,
    String issueDescription, {
    Map<String, dynamic>? technicalDetails,
  }) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    final Map<String, dynamic> properties = {
      'feature': feature,
      'issue': issueDescription,
      'platform': defaultTargetPlatform.toString().split('.').last,
      'os_version': _osVersion,
      'device_model': _deviceModel,
      'timestamp': DateTime.now().toIso8601String(),
      'app_version': _appVersion,
      ...?technicalDetails,
    };

    _safeTrack('Platform Specific Issue', properties);
  }

  Future<void> trackSessionStart() async {
    try {
      if (_initialized && _mixpanel != null) {
        final sessionStartTimestamp = DateTime.now();

        final Map<String, dynamic> properties = {
          'timestamp': sessionStartTimestamp.toIso8601String(),
          'local_time':
              '${sessionStartTimestamp.hour}:${sessionStartTimestamp.minute}',
          'day_of_week': sessionStartTimestamp.weekday,
          'platform': defaultTargetPlatform.toString().split('.').last,
          'device_model': _deviceModel,
          'app_version': _appVersion,
        };

        _mixpanel!.track('Session Start', properties: properties);

        Future.microtask(() {
          try {
            if (_mixpanel != null) {
              _mixpanel!.getPeople().set(
                'last_session_start',
                sessionStartTimestamp.toIso8601String(),
              );
              _mixpanel!.getPeople().increment('session_count', 1.0);
            }
          } catch (e) {
            // Silently handle session tracking errors
          }
        });
      } else {
        Future.microtask(() async {
          await init().catchError((_) {});
          if (_mixpanel != null) {
            _safeTrack('Session Start', {
              'timestamp': DateTime.now().toIso8601String(),
              'delayed_initialization': true,
            });
          }
        });
      }
    } catch (e) {
      // Silently handle session start errors
    }
  }

  Future<void> trackSessionEnd(DateTime sessionStartTime) async {
    try {
      if (_initialized && _mixpanel != null) {
        final sessionEndTime = DateTime.now();
        final sessionDurationSeconds =
            sessionEndTime.difference(sessionStartTime).inSeconds;

        final Map<String, dynamic> properties = {
          'session_duration_seconds': sessionDurationSeconds,
          'start_timestamp': sessionStartTime.toIso8601String(),
          'end_timestamp': sessionEndTime.toIso8601String(),
        };

        _mixpanel!.track('Session End', properties: properties);

        Future.microtask(() {
          try {
            if (_mixpanel != null) {
              _mixpanel!.getPeople().set(
                'last_session_end',
                sessionEndTime.toIso8601String(),
              );
              _mixpanel!.getPeople().set(
                'last_session_duration_seconds',
                sessionDurationSeconds,
              );
              _mixpanel!.getPeople().increment(
                'total_time_in_app_seconds',
                sessionDurationSeconds.toDouble(),
              );
            }
          } catch (e) {
            // Silently handle session end tracking errors
          }
        });
      }
    } catch (e) {
      // Silently handle session end errors
    }
  }

  Future<void> trackPaintSubmission(
    String paintName,
    String brand,
    String barcode, {
    String? hexColor,
    String? category,
    bool isMetallic = false,
    bool isTransparent = false,
    Map<String, dynamic>? additionalDetails,
  }) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    final Map<String, dynamic> properties = {
      'paint_name': paintName,
      'brand': brand,
      'barcode': barcode,
      'hex_color': hexColor,
      'category': category,
      'is_metallic': isMetallic,
      'is_transparent': isTransparent,
      'timestamp': DateTime.now().toIso8601String(),
      'app_version': _appVersion,
      'platform': defaultTargetPlatform.toString().split('.').last,
      ...?additionalDetails,
    };

    _safeTrack('Paint Submission', properties);

    try {
      _mixpanel!.getPeople().increment('paints_submitted_count', 1.0);
      _mixpanel!.getPeople().append('paints_submitted', '$paintName ($brand)');
      _mixpanel!.getPeople().append('barcodes_submitted', barcode);
    } catch (e) {
      // Silently handle paint submission tracking errors
    }
  }

  Future<void> trackScreenTime(
    String screenName,
    int durationSeconds, {
    Map<String, dynamic>? screenContext,
  }) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    final Map<String, dynamic> properties = {
      'screen_name': screenName,
      'duration_seconds': durationSeconds,
      'timestamp': DateTime.now().toIso8601String(),
      ...?screenContext,
    };

    _safeTrack('Screen Time', properties);

    try {
      _mixpanel!.getPeople().increment(
        'screen_time_$screenName',
        durationSeconds.toDouble(),
      );
    } catch (e) {
      // Silently handle screen time tracking errors
    }
  }

  Future<void> trackAverageUsageTime(
    double averageMinutesPerDay,
    int daysRecorded,
  ) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    final Map<String, dynamic> properties = {
      'average_minutes_per_day': averageMinutesPerDay,
      'days_recorded': daysRecorded,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _safeTrack('Average Usage Time', properties);

    try {
      _mixpanel!.getPeople().set(
        'average_daily_usage_minutes',
        averageMinutesPerDay,
      );
      _mixpanel!.getPeople().set(
        'average_calculation_date',
        DateTime.now().toIso8601String(),
      );
      _mixpanel!.getPeople().set(
        'average_calculation_days_sample',
        daysRecorded,
      );
    } catch (e) {
      // Silently handle usage time tracking errors
    }
  }

  Future<void> trackUserBehavior(
    String behaviorType,
    String action, {
    int? count,
    int? durationSeconds,
    Map<String, dynamic>? behaviorDetails,
  }) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    final Map<String, dynamic> properties = {
      'behavior_type': behaviorType,
      'action': action,
      'count': count,
      'duration_seconds': durationSeconds,
      'timestamp': DateTime.now().toIso8601String(),
      ...?behaviorDetails,
    };

    _safeTrack('User Behavior', properties);

    try {
      if (count != null && count > 0) {
        _mixpanel!.getPeople().increment(
          'behavior_${behaviorType}_${action}_count',
          count.toDouble(),
        );
      }

      _mixpanel!.getPeople().set('last_behavior_$behaviorType', action);
      _mixpanel!.getPeople().set(
        'last_behavior_${behaviorType}_time',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      // Silently handle behavior tracking errors
    }
  }

  Future<void> trackVisitCount(int visitCount, int daysSinceFirstVisit) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    final Map<String, dynamic> properties = {
      'visit_count': visitCount,
      'days_since_first_visit': daysSinceFirstVisit,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _safeTrack('Visit Count', properties);

    try {
      _mixpanel!.getPeople().set('total_visits', visitCount);
      _mixpanel!.getPeople().set('days_since_first_visit', daysSinceFirstVisit);
      _mixpanel!.getPeople().set(
        'average_visits_per_day',
        daysSinceFirstVisit > 0 ? visitCount / daysSinceFirstVisit : visitCount,
      );
    } catch (e) {
      // Silently handle visit count tracking errors
    }
  }

  Future<void> trackUsageFrequency(
    String frequencyType,
    int visitsInPeriod,
    int activeDaysInPeriod,
  ) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    final Map<String, dynamic> properties = {
      'frequency_type': frequencyType,
      'visits_in_period': visitsInPeriod,
      'active_days_in_period': activeDaysInPeriod,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _safeTrack('Usage Frequency', properties);

    try {
      _mixpanel!.getPeople().set('${frequencyType}_visits', visitsInPeriod);
      _mixpanel!.getPeople().set(
        '${frequencyType}_active_days',
        activeDaysInPeriod,
      );

      if (frequencyType == 'daily' && visitsInPeriod >= 5) {
        _mixpanel!.getPeople().set('user_frequency_category', 'daily_user');
      } else if (frequencyType == 'weekly' && visitsInPeriod >= 3) {
        _mixpanel!.getPeople().set('user_frequency_category', 'weekly_user');
      } else {
        _mixpanel!.getPeople().set(
          'user_frequency_category',
          'occasional_user',
        );
      }
    } catch (e) {
      // Silently handle frequency tracking errors
    }
  }

  Future<bool> isWorking() async {
    try {
      if (!_initialized || _mixpanel == null) {
        await init().timeout(
          Duration(seconds: 2),
          onTimeout: () {
            throw TimeoutException(
              'Mixpanel initialization timed out during check',
            );
          },
        );
      }

      if (_mixpanel == null) {
        return false;
      }

      await _mixpanel!
          .track(
            'Mixpanel_Diagnostic',
            properties: {
              'timestamp': DateTime.now().toIso8601String(),
              'diagnostic_id': DateTime.now().millisecondsSinceEpoch.toString(),
            },
          )
          .timeout(
            Duration(seconds: 2),
            onTimeout: () {
              throw TimeoutException(
                'Mixpanel tracking timed out during check',
              );
            },
          );

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> restart() async {
    _initialized = false;
    _mixpanel = null;

    try {
      await init().timeout(Duration(seconds: 5));
      return await isWorking();
    } catch (e) {
      return false;
    }
  }

  Future<bool> runDiagnostics() async {
    if (!_initialized || _mixpanel == null) {
      try {
        await init();
      } catch (e) {
        return false;
      }
    }

    if (!_initialized || _mixpanel == null) {
      return false;
    }

    try {
      final distinctId = await _mixpanel!.getDistinctId();
      final eventId = DateTime.now().millisecondsSinceEpoch.toString();
      final eventName = 'DIAGNOSTICO_TEST_$eventId';

      _mixpanel!.track(
        eventName,
        properties: {
          'timestamp': DateTime.now().toIso8601String(),
          'deviceId': _deviceId,
          'appVersion': _appVersion,
          'osVersion': _osVersion,
          'testId': eventId,
        },
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> setupAutoUserIdentification(
    Stream<dynamic> authStateChanges,
  ) async {
    authStateChanges.listen((user) async {
      if (user != null) {
        await _handleUserAuthenticated(user);
      } else {
        await _handleUserLoggedOut();
      }
    });
  }

  Future<void> _handleUserAuthenticated(dynamic user) async {
    try {
      if (!_initialized || _mixpanel == null) {
        await init().catchError((_) {});
      }

      if (_mixpanel != null) {
        String userId;
        String? name;
        String? email;
        String? phoneNumber;
        String authProvider = 'unknown';
        Map<String, dynamic> additionalProperties = {};

        if (user.runtimeType.toString().contains('User') && user.id != null) {
          userId = user.id;
          name = user.name?.isNotEmpty == true ? user.name : null;
          email = user.email?.isNotEmpty == true ? user.email : null;
          phoneNumber = user.phoneNumber;
          authProvider = user.authProvider ?? 'unknown';

          additionalProperties.addAll({
            'creation_time': user.createdAt?.toIso8601String(),
            'last_login_time': user.lastLoginAt?.toIso8601String(),
            'profile_image': user.profileImage,
            'has_preferences': user.preferences != null,
            'preferences_count': user.preferences?.length ?? 0,
            'is_guest_user': authProvider == 'guest',
          });
        } else {
          userId =
              user.uid ??
              user.id ??
              'unknown_user_${DateTime.now().millisecondsSinceEpoch}';

          try {
            name = user.displayName;
            email = user.email;
            phoneNumber = user.phoneNumber;

            additionalProperties.addAll({
              'user_verified': user.emailVerified ?? false,
              'is_anonymous': user.isAnonymous ?? false,
              'photo_url': user.photoURL,
            });
          } catch (e) {
            // Silently handle user property extraction errors
          }
        }

        await identifyUserWithDetails(
          userId: userId,
          name: name,
          email: email,
          phoneNumber: phoneNumber,
          authProvider: authProvider,
          isNewUser: false,
          additionalUserProperties: {
            'auto_identified_at': DateTime.now().toIso8601String(),
            'identification_source': 'auth_state_change',
            ...additionalProperties,
          },
        );
      }
    } catch (e) {
      // Silently handle user authentication errors
    }
  }

  Future<void> _handleUserLoggedOut() async {
    try {
      await logout();
    } catch (e) {
      // Silently handle logout errors
    }
  }

  Future<Map<String, dynamic>> debugUserIdentification() async {
    if (!_initialized || _mixpanel == null) {
      return {
        'status': 'not_initialized',
        'mixpanel_instance': null,
        'distinct_id': null,
      };
    }

    try {
      final distinctId = await _mixpanel!.getDistinctId();
      return {
        'status': 'initialized',
        'mixpanel_instance': _mixpanel != null,
        'distinct_id': distinctId,
        'device_id': _deviceId,
        'app_version': _appVersion,
        'device_model': _deviceModel,
        'os_version': _osVersion,
        'initialized': _initialized,
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
        'mixpanel_instance': _mixpanel != null,
        'initialized': _initialized,
      };
    }
  }

  Future<void> forceUserReidentification(
    String userId, {
    String? name,
    String? email,
    String? phoneNumber,
    String? authProvider,
    Map<String, dynamic>? additionalProperties,
  }) async {
    try {
      if (!_initialized || _mixpanel == null) {
        await init();
      }

      if (_mixpanel != null) {
        await _mixpanel!.reset();

        await identifyUserWithDetails(
          userId: userId,
          name: name,
          email: email,
          phoneNumber: phoneNumber,
          authProvider: authProvider ?? 'unknown',
          isNewUser: false,
          additionalUserProperties: {
            'force_reidentified_at': DateTime.now().toIso8601String(),
            'reidentification_reason': 'manual_force',
            ...?additionalProperties,
          },
        );

        await trackEvent('Debug_User_Reidentification', {
          'user_id': userId,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      throw Exception('Failed to force reidentification: $e');
    }
  }

  Future<bool> verifyUserTracking() async {
    try {
      if (!_initialized || _mixpanel == null) {
        return false;
      }

      final distinctId = await _mixpanel!.getDistinctId();

      await _safeTrack('Debug_Tracking_Verification', {
        'verification_timestamp': DateTime.now().toIso8601String(),
        'distinct_id': distinctId,
        'device_id': _deviceId,
        'verification_id': '${DateTime.now().millisecondsSinceEpoch}',
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getUserIdentificationStats() async {
    final debug = await debugUserIdentification();

    return {
      'mixpanel_status': debug['status'],
      'current_distinct_id': debug['distinct_id'],
      'initialization_time': _initialized ? 'initialized' : 'not_initialized',
      'device_info_available': _deviceId != null,
      'tracking_verification': await verifyUserTracking(),
      'service_health': {
        'mixpanel_instance': _mixpanel != null,
        'device_id': _deviceId,
        'app_version': _appVersion,
        'device_model': _deviceModel,
        'os_version': _osVersion,
      },
    };
  }
}
