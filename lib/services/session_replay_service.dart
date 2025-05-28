import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';

class SessionReplayService {
  static const MethodChannel _channel = MethodChannel(
    'com.miniaturepaintfinder/session_replay',
  );
  static SessionReplayService? _instance;
  bool _initialized = false;
  String? _deviceId;
  String? _deviceModel;
  String? _osVersion;

  static SessionReplayService get instance =>
      _instance ??= SessionReplayService._();

  SessionReplayService._();

  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;

    try {
      debugPrint('🎬 SessionReplayService: Starting initialization...');
      await _getDeviceInfo();

      // Initialize session replay on iOS
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        debugPrint('🎬 SessionReplayService: Calling iOS initialization...');
        await _channel.invokeMethod('initializeSessionReplay');
        debugPrint('🎬 SessionReplayService: iOS initialization completed');
      } else {
        debugPrint(
          '🎬 SessionReplayService: Not on iOS, skipping initialization',
        );
      }

      _initialized = true;
      debugPrint('✅ SessionReplayService: Initialization successful');
    } catch (e) {
      _initialized = false;
      debugPrint('❌ SessionReplayService: Failed to initialize: $e');
    }
  }

  Future<void> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceId = iosInfo.identifierForVendor;
        _deviceModel = iosInfo.model;
        _osVersion = iosInfo.systemVersion;
        debugPrint(
          '🎬 SessionReplayService: Device info - Model: $_deviceModel, OS: $_osVersion',
        );
      }
    } catch (e) {
      debugPrint('❌ SessionReplayService: Failed to get device info: $e');
    }
  }

  Future<void> startRecording() async {
    if (!_initialized) {
      debugPrint(
        '🎬 SessionReplayService: Not initialized, initializing first...',
      );
      await init();
    }

    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        debugPrint('🎬 SessionReplayService: Starting recording...');
        await _channel.invokeMethod('startRecording');
        debugPrint('✅ SessionReplayService: Recording started successfully');
      } else {
        debugPrint(
          '🎬 SessionReplayService: Not on iOS, skipping start recording',
        );
      }
    } catch (e) {
      debugPrint('❌ SessionReplayService: Failed to start recording: $e');
    }
  }

  Future<void> stopRecording() async {
    if (!_initialized) {
      debugPrint(
        '🎬 SessionReplayService: Not initialized, cannot stop recording',
      );
      return;
    }

    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        debugPrint('🎬 SessionReplayService: Stopping recording...');
        await _channel.invokeMethod('stopRecording');
        debugPrint('✅ SessionReplayService: Recording stopped successfully');
      } else {
        debugPrint(
          '🎬 SessionReplayService: Not on iOS, skipping stop recording',
        );
      }
    } catch (e) {
      debugPrint('❌ SessionReplayService: Failed to stop recording: $e');
    }
  }

  Future<void> setUserIdentifier(String userId) async {
    if (!_initialized) {
      debugPrint(
        '🎬 SessionReplayService: Not initialized, initializing first...',
      );
      await init();
    }

    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        debugPrint('🎬 SessionReplayService: Setting user identifier: $userId');
        await _channel.invokeMethod('setUserIdentifier', {'userId': userId});
        debugPrint('✅ SessionReplayService: User identifier set successfully');
      } else {
        debugPrint(
          '🎬 SessionReplayService: Not on iOS, skipping set user identifier',
        );
      }
    } catch (e) {
      debugPrint('❌ SessionReplayService: Failed to set user identifier: $e');
    }
  }

  Future<void> markViewAsSensitive(String viewId) async {
    if (!_initialized) return;

    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        debugPrint(
          '🎬 SessionReplayService: Marking view as sensitive: $viewId',
        );
        await _channel.invokeMethod('markViewAsSensitive', {'viewId': viewId});
        debugPrint('✅ SessionReplayService: View marked as sensitive');
      }
    } catch (e) {
      debugPrint(
        '❌ SessionReplayService: Failed to mark view as sensitive: $e',
      );
    }
  }

  Future<void> markViewAsSafe(String viewId) async {
    if (!_initialized) return;

    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        debugPrint('🎬 SessionReplayService: Marking view as safe: $viewId');
        await _channel.invokeMethod('markViewAsSafe', {'viewId': viewId});
        debugPrint('✅ SessionReplayService: View marked as safe');
      }
    } catch (e) {
      debugPrint('❌ SessionReplayService: Failed to mark view as safe: $e');
    }
  }

  Future<String?> getReplayId() async {
    if (!_initialized) return null;

    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        debugPrint('🎬 SessionReplayService: Getting replay ID...');
        final result = await _channel.invokeMethod('getReplayId');
        debugPrint('🎬 SessionReplayService: Replay ID: $result');
        return result as String?;
      }
    } catch (e) {
      debugPrint('❌ SessionReplayService: Failed to get replay ID: $e');
    }
    return null;
  }

  Future<void> captureScreenshot() async {
    if (!_initialized) return;

    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        debugPrint('📸 SessionReplayService: Capturing screenshot...');
        await _channel.invokeMethod('captureScreenshot');
        debugPrint('✅ SessionReplayService: Screenshot captured');
      }
    } catch (e) {
      debugPrint('❌ SessionReplayService: Failed to capture screenshot: $e');
    }
  }
}
