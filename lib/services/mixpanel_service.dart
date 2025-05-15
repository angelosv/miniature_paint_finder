import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/widgets.dart';

class MixpanelService {
  static const String _token =
      '570d806261b36af574266b6256137b0d'; // Token de Mixpanel
  static MixpanelService? _instance;
  Mixpanel? _mixpanel;
  bool _initialized = false;
  String? _deviceId;
  String? _appVersion;
  String? _deviceModel;
  String? _osVersion;

  // Singleton pattern
  static MixpanelService get instance => _instance ??= MixpanelService._();

  MixpanelService._();

  bool get isInitialized => _initialized;

  // Getter para la versión de la app
  String get appVersion => _appVersion ?? 'unknown';

  // Getter para el ID del dispositivo
  String? get deviceId => _deviceId;

  Future<void> init() async {
    if (_initialized) return;

    try {
      // Inicializar Mixpanel con timeout para evitar bloqueos
      _mixpanel = await Mixpanel.init(
        _token,
        optOutTrackingDefault: false,
        trackAutomaticEvents: true,
      ).timeout(
        Duration(seconds: 3), // Reducimos el timeout a 3 segundos
        onTimeout: () {
          debugPrint('⚠️ Mixpanel initialization timed out after 3 seconds');
          throw TimeoutException('Mixpanel initialization timed out');
        },
      );

      // Obtener información del dispositivo de manera no bloqueante
      unawaited(_getDeviceInfo());

      // Marcar como inicializado aunque falten detalles del dispositivo
      _initialized = true;
      debugPrint(
        '✅ Mixpanel initialized with token: ${_token.substring(0, 8)}...',
      );

      // Tracking de instalación en segundo plano para no bloquear la UI
      unawaited(trackInstall());
    } catch (e) {
      debugPrint('❌ Error initializing Mixpanel: $e');
      // Establecer mixpanel a null para que los métodos _safeTrack sepan que falló
      _mixpanel = null;
      _initialized = false;
      // No volvemos a lanzar excepciones para evitar romper la app
    }
  }

  Future<void> _getDeviceInfo() async {
    try {
      // Obtener información del paquete (versión de la app)
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

      // Obtener información del dispositivo
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

      // Establecer propiedades de superposición para todas las llamadas
      _setSuperProperties();
    } catch (e) {
      debugPrint('Error getting device info: $e');
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

      // También establecemos estas propiedades individualmente
      properties.forEach((key, value) {
        _mixpanel!.getPeople().set(key, value);
      });
    }
  }

  /// Identificar al usuario (llamar cuando el usuario inicie sesión)
  Future<void> identify(String userId) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    if (_mixpanel != null) {
      try {
        // Identificar al usuario
        _mixpanel!.identify(userId);

        // Establecer propiedades en el perfil del usuario
        final people = _mixpanel!.getPeople();
        people.set('\$name', userId); // Nombre Mixpanel
        people.set('\$last_login', DateTime.now().toIso8601String());
        people.set('user_id', userId);
        people.set('identified_at', DateTime.now().toIso8601String());

        // Incrementar la sesión
        people.increment('\$session_count', 1.0);

        debugPrint('👤 User identified in Mixpanel: $userId');
      } catch (e) {
        debugPrint('❌ Error identifying user in Mixpanel: $e');
      }
    }
  }

  /// Identificar al usuario con información completa (nombre, email, etc.)
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
        // Identificar al usuario con su ID único
        _mixpanel!.identify(userId);

        // Establecer propiedades en el perfil del usuario
        final people = _mixpanel!.getPeople();

        // Propiedades estándar de Mixpanel
        if (name != null) people.set('\$name', name);
        if (email != null) people.set('\$email', email);
        if (phoneNumber != null) people.set('\$phone', phoneNumber);

        // Propiedades personalizadas
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

        // Si es un usuario nuevo, registrar fecha de creación
        if (isNewUser) {
          people.set('created_at', DateTime.now().toIso8601String());
          people.set('is_new_user', true);
        }

        // Establecer propiedades adicionales si existen
        if (additionalUserProperties != null) {
          additionalUserProperties.forEach((key, value) {
            people.set(key, value);
          });
        }

        // Incrementar contador de sesiones
        people.increment('\$session_count', 1.0);

        debugPrint('👤 User identified in Mixpanel with full details: $userId');

        // Registrar evento de identificación exitosa
        trackEvent('User Identified', {
          'user_id': userId,
          'has_name': name != null,
          'has_email': email != null,
          'has_phone': phoneNumber != null,
          'auth_provider': authProvider,
          'is_new_user': isNewUser,
        });
      } catch (e) {
        debugPrint('❌ Error identifying user with details in Mixpanel: $e');
      }
    }
  }

  /// Actualizar una propiedad específica del perfil del usuario
  Future<void> updateUserProperty(String property, dynamic value) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    if (_mixpanel != null) {
      try {
        _mixpanel!.getPeople().set(property, value);
        debugPrint('👤 User property updated in Mixpanel: $property');
      } catch (e) {
        debugPrint('❌ Error updating user property in Mixpanel: $e');
      }
    }
  }

  /// Incrementar una propiedad numérica del perfil del usuario
  Future<void> incrementUserProperty(String property, double value) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    if (_mixpanel != null) {
      try {
        _mixpanel!.getPeople().increment(property, value);
        debugPrint('👤 User property incremented in Mixpanel: $property');
      } catch (e) {
        debugPrint('❌ Error incrementing user property in Mixpanel: $e');
      }
    }
  }

  /// Añadir un valor a una lista en el perfil del usuario
  Future<void> appendToUserList(String property, dynamic value) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    if (_mixpanel != null) {
      try {
        _mixpanel!.getPeople().append(property, value);
        debugPrint('👤 Value appended to user list in Mixpanel: $property');
      } catch (e) {
        debugPrint('❌ Error appending to user list in Mixpanel: $e');
      }
    }
  }

  // Trackear propiedades del usuario
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    if (_mixpanel != null) {
      try {
        properties.forEach((key, value) {
          _mixpanel!.getPeople().set(key, value);
        });
        debugPrint('👤 User properties set in Mixpanel');
      } catch (e) {
        debugPrint('❌ Error setting user properties in Mixpanel: $e');
      }
    }
  }

  // Trackear acciones específicas del usuario
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

  // Trackear errores de la aplicación
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

  // Trackear métricas de rendimiento
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

  // Trackear uso de características
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

  // Trackear la instalación de la app
  Future<void> trackInstall() async {
    if (!_initialized || _mixpanel == null) {
      await init();
    }

    if (_mixpanel != null && _deviceId != null) {
      // Usamos distinctId para asegurar que solo registramos una instalación por dispositivo
      final distinctId = _mixpanel!.getDistinctId();

      _mixpanel!.track(
        'App Installed',
        properties: {
          'device_id': _deviceId,
          'first_seen': DateTime.now().toIso8601String(),
          'distinct_id': distinctId,
        },
      );

      debugPrint('📱 App installation tracked');
    }
  }

  // Método seguro que no falla si Mixpanel no está inicializado
  Future<void> _safeTrack(
    String eventName,
    Map<String, dynamic>? properties,
  ) async {
    // Si no está inicializado, intentar inicializar una vez más
    if (!_initialized || _mixpanel == null) {
      debugPrint(
        '⚠️ Mixpanel not initialized for event: $eventName, attempting to initialize',
      );
      try {
        // Intentar inicializar pero con un timeout muy corto para no bloquear la UI
        await init().timeout(
          Duration(seconds: 1),
          onTimeout: () {
            throw TimeoutException('Mixpanel re-initialization timed out');
          },
        );
      } catch (e) {
        debugPrint('❌ Failed to initialize Mixpanel for event: $eventName');
        return; // Si falla, simplemente salimos sin registrar el evento
      }
    }

    // Si Mixpanel sigue sin inicializarse, no registramos el evento
    if (_mixpanel == null) {
      debugPrint(
        '⚠️ Skipping event tracking: $eventName (Mixpanel not available)',
      );
      return;
    }

    try {
      // Añadir timestamp a todas las propiedades si no lo tiene
      final Map<String, dynamic> enrichedProperties = {
        'timestamp': DateTime.now().toIso8601String(),
        ...?properties,
      };

      // Enviar el evento a Mixpanel
      _mixpanel!.track(eventName, properties: enrichedProperties);
      debugPrint('📊 Event tracked: $eventName');
    } catch (e) {
      debugPrint('❌ Error tracking event $eventName: $e');
      // No relanzamos la excepción para no afectar la UI
    }
  }

  // Trackear usuario activo (llamar cuando la aplicación se inicie)
  Future<void> trackActiveUser() async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    _safeTrack('Active User', {'timestamp': DateTime.now().toIso8601String()});
  }

  // Trackear vistas de pantalla
  Future<void> trackScreen(String screenName) async {
    if (!_initialized || _mixpanel == null) {
      await init().catchError((_) {});
    }

    _safeTrack('Screen View', {
      'screen_name': screenName,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Método general para trackear eventos personalizados
  Future<void> trackEvent(
    String eventName, [
    Map<String, dynamic>? properties,
  ]) async {
    // Intenta trackear directamente (modo sincrónico)
    try {
      if (!_initialized || _mixpanel == null) {
        await init().catchError((_) {});
      }

      final Map<String, dynamic> enrichedProperties = {
        'timestamp': DateTime.now().toIso8601String(),
        ...?properties,
      };

      // Tracking inmediato (para acciones críticas como auth)
      if (_mixpanel != null) {
        _mixpanel!.track(eventName, properties: enrichedProperties);
        debugPrint('📊 Event tracked synchronously: $eventName');
      }
    } catch (e) {
      debugPrint('❌ Error en trackEvent sincrónico ($eventName): $e');
      // Intentar en segundo plano si falla el modo sincrónico
      _trackEventAsync(eventName, properties);
    }
  }

  // Método interno para trackear en segundo plano
  void _trackEventAsync(String eventName, [Map<String, dynamic>? properties]) {
    // Ejecutamos en microtask para no bloquear
    Future.microtask(() async {
      try {
        // Delegamos el trabajo al método seguro
        await _safeTrack(eventName, properties);
      } catch (e) {
        // Capturar cualquier error para no afectar la UI
        debugPrint('❌ Error en _trackEventAsync($eventName): $e');
      }
    });
  }

  // Cerrar sesión (llamar cuando el usuario cierre sesión)
  Future<void> logout() async {
    // Intentar registrar el evento de logout antes de resetear
    if (_initialized && _mixpanel != null) {
      try {
        // Crear un evento de logout para registrar la acción
        final Map<String, dynamic> logoutProperties = {
          'logout_timestamp': DateTime.now().toIso8601String(),
          'user_id_before_reset':
              await _mixpanel!.getDistinctId(), // Obtener el ID antes del reset
        };
        // Usar _safeTrack para asegurar que se intente enviar incluso si hay problemas
        await _safeTrack('User Logged Out', logoutProperties);
      } catch (e) {
        debugPrint('❌ Error tracking logout event: $e');
      }
    }

    // Proceder con el reseteo de Mixpanel
    if (_mixpanel != null) {
      try {
        await _mixpanel!.reset();
        debugPrint('👋 User session reset in Mixpanel');
      } catch (e) {
        debugPrint('❌ Error resetting Mixpanel session: $e');
      }
    } else {
      debugPrint('⚠️ Mixpanel instance was null, nothing to reset.');
    }

    // No es necesario llamar a init() aquí, ya que el objetivo es limpiar la sesión.
    // La próxima acción que requiera Mixpanel (ej. nuevo login) se encargará de inicializar si es necesario.
  }

  // MÉTODOS ESPECÍFICOS PARA TRACKING DE PINTURAS

  // Trackear búsqueda de pinturas
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

  // Trackear detalles de pintura vistos
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

  // Trackear adición de pintura al inventario
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

    // También incrementamos contador en el perfil de usuario
    try {
      _mixpanel!.getPeople().increment('paints_in_inventory', 1);
      _mixpanel!.getPeople().append('brands_owned', brand);
    } catch (e) {
      debugPrint('❌ Error updating user profile inventory stats: $e');
    }
  }

  // Trackear eliminación de pintura del inventario
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

    // Decremento del contador en el perfil
    try {
      _mixpanel!.getPeople().increment('paints_in_inventory', -1);
    } catch (e) {
      debugPrint('❌ Error updating user profile inventory stats: $e');
    }
  }

  // Trackear adición de pintura a wishlist
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

    // Incrementamos contador en el perfil
    try {
      _mixpanel!.getPeople().increment('paints_in_wishlist', 1);
    } catch (e) {
      debugPrint('❌ Error updating user profile wishlist stats: $e');
    }
  }

  // Trackear búsqueda por color
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

  // Trackear uso del escáner de código de barras
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

  // Trackear creación de paleta
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

    // Incrementamos contador en el perfil
    try {
      _mixpanel!.getPeople().increment('palettes_created', 1);
    } catch (e) {
      debugPrint('❌ Error updating user profile palette stats: $e');
    }
  }

  // MÉTODO PRIORITARIO 1: TRACKING DE BARCODES NO ENCONTRADOS
  /// Trackea cuando un usuario escanea un barcode que no se encuentra en la base de datos
  /// Esto es crucial para identificar productos que deberían añadirse al catálogo
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

    // Incrementar contador global de barcodes no encontrados
    try {
      _mixpanel!.getPeople().increment('barcodes_not_found_count', 1.0);
      // También guardar el barcode en un array para análisis posterior
      _mixpanel!.getPeople().append('barcodes_not_found', barcode);
    } catch (e) {
      debugPrint('❌ Error updating barcode stats: $e');
    }
  }

  // MÉTODO PRIORITARIO 2: ANÁLISIS DETALLADO DEL SCANNER
  /// Trackea problemas y uso del scanner de barcodes para mejorar esta funcionalidad
  Future<void> trackScannerActivity(
    String activityType, { // success, error, permission_denied, timeout
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

    if (activityType == 'success') {
      try {
        _mixpanel!.getPeople().increment('successful_scans', 1.0);
      } catch (e) {
        debugPrint('❌ Error updating scan success stats: $e');
      }
    } else if (activityType == 'error') {
      try {
        _mixpanel!.getPeople().increment('failed_scans', 1.0);
      } catch (e) {
        debugPrint('❌ Error updating scan error stats: $e');
      }
    }
  }

  // MÉTODO PRIORITARIO 3: TRACKING DE PINTURAS POPULARES
  /// Trackea interacciones con pinturas para determinar cuáles son más populares
  Future<void> trackPaintInteraction(
    String paintId,
    String paintName,
    String brand,
    String interactionType, { // viewed, searched, added, removed, favorited
    String? source, // inventory, library, scanner, search
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

    // Actualizar listas por marca en el perfil del usuario
    try {
      // Si es una interacción de vista o búsqueda, incrementar contador
      if (interactionType == 'viewed' || interactionType == 'searched') {
        _mixpanel!.getPeople().increment('paints_viewed_count', 1.0);
      }

      // Mantener un registro de marcas con las que el usuario interactúa
      _mixpanel!.getPeople().append('brands_interacted', brand);

      // Mantener un registro de pinturas vistas recientemente (últimas 20)
      // Esto es útil para recomendaciones y análisis de comportamiento
      if (interactionType == 'viewed') {
        // Mecanismo simple para evitar duplicaciones en el último día
        // Normalmente esto se haría con una operación union en el backend
        final recentViewKey = 'recent_paints_$brand';
        _mixpanel!.getPeople().append(recentViewKey, '$paintId:$paintName');
      }
    } catch (e) {
      debugPrint('❌ Error updating paint interaction stats: $e');
    }
  }

  /// Trackea búsquedas por color realizadas por el usuario
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
      // Guardar colores buscados recientemente para análisis
      _mixpanel!.getPeople().append('colors_searched', hexColor);
    } catch (e) {
      debugPrint('❌ Error updating color search stats: $e');
    }
  }

  /// Trackea actividad en el inventario para entender cómo lo usan los usuarios
  Future<void> trackInventoryActivity(
    String
    activityType, { // filter, sort, search, bulk_add, bulk_delete, export, import
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

    // Ciertas acciones pueden justificar actualizaciones al perfil
    if (activityType == 'bulk_add' && itemsAffected != null) {
      try {
        _mixpanel!.getPeople().increment('inventory_bulk_adds', 1.0);
        _mixpanel!.getPeople().increment(
          'total_paints_added',
          itemsAffected.toDouble(),
        );
      } catch (e) {
        debugPrint('❌ Error updating inventory activity stats: $e');
      }
    } else if (activityType == 'export') {
      try {
        _mixpanel!.getPeople().increment('inventory_exports', 1.0);
        _mixpanel!.getPeople().set(
          'last_inventory_export',
          DateTime.now().toIso8601String(),
        );
      } catch (e) {
        debugPrint('❌ Error updating inventory export stats: $e');
      }
    }
  }

  /// Trackea acciones específicas relacionadas con la onboarding y retención
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
      debugPrint('❌ Error updating onboarding stats: $e');
    }
  }

  /// Trackea problemas específicos de plataforma para iOS/Android
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

  // MÉTRICAS DE USO Y COMPORTAMIENTO

  /// Trackea cuando un usuario inicia una nueva sesión en la app
  /// Debe llamarse en el arranque y después de períodos largos de inactividad
  Future<void> trackSessionStart() async {
    try {
      // No inicializar Mixpanel si no está inicializado para evitar bloqueos
      if (_initialized && _mixpanel != null) {
        // Guardar timestamp de inicio para cálculos de duración
        final sessionStartTimestamp = DateTime.now();

        // Tracking directo del evento (crítico para funcionamiento correcto)
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

        // Usar una microtask para las actualizaciones de perfil que son menos críticas
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
            debugPrint('❌ Error updating session stats: $e');
          }
        });
      } else {
        // Si no está inicializado, inicializar y luego trackear
        // Pero hacerlo en segundo plano para no bloquear
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
      debugPrint('❌ Error tracking session start: $e');
    }
  }

  /// Trackea cuando un usuario finaliza una sesión
  /// Debe llamarse cuando la app pasa a segundo plano o se cierra
  Future<void> trackSessionEnd(DateTime sessionStartTime) async {
    try {
      // No inicializar Mixpanel si no está inicializado para evitar bloqueos
      if (_initialized && _mixpanel != null) {
        // Calcular duración de la sesión
        final sessionEndTime = DateTime.now();
        final sessionDurationSeconds =
            sessionEndTime.difference(sessionStartTime).inSeconds;

        // Evento principal (crítico)
        final Map<String, dynamic> properties = {
          'session_duration_seconds': sessionDurationSeconds,
          'start_timestamp': sessionStartTime.toIso8601String(),
          'end_timestamp': sessionEndTime.toIso8601String(),
        };

        _mixpanel!.track('Session End', properties: properties);

        // Actualizaciones del perfil en segundo plano
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
            debugPrint('❌ Error updating session end stats: $e');
          }
        });
      } else {
        // Si no está inicializado, hacer tracking mínimo
        debugPrint('⚠️ Session end tracked without active Mixpanel instance');
      }
    } catch (e) {
      debugPrint('❌ Error tracking session end: $e');
    }
  }

  /// Trackea cuando un usuario envía una nueva pintura para añadir a la base de datos
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

    // Actualizar estadísticas de contribución del usuario
    try {
      _mixpanel!.getPeople().increment('paints_submitted_count', 1.0);
      _mixpanel!.getPeople().append('paints_submitted', '$paintName ($brand)');
      _mixpanel!.getPeople().append('barcodes_submitted', barcode);
    } catch (e) {
      debugPrint('❌ Error updating paint submission stats: $e');
    }
  }

  /// Trackea el tiempo que un usuario permanece en una pantalla específica
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

    // Actualizar tiempo acumulado por pantalla
    try {
      _mixpanel!.getPeople().increment(
        'screen_time_$screenName',
        durationSeconds.toDouble(),
      );
    } catch (e) {
      debugPrint('❌ Error updating screen time stats: $e');
    }
  }

  /// Calcula y trackea el tiempo promedio de uso por día
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

    // Actualizar promedio en el perfil
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
      debugPrint('❌ Error updating average usage stats: $e');
    }
  }

  /// Trackea comportamientos específicos de usuario
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

    // Registrar comportamiento en perfil para segmentación
    try {
      // Incrementar contador de este comportamiento específico
      if (count != null && count > 0) {
        _mixpanel!.getPeople().increment(
          'behavior_${behaviorType}_${action}_count',
          count.toDouble(),
        );
      }

      // Guardar último comportamiento de este tipo
      _mixpanel!.getPeople().set('last_behavior_$behaviorType', action);
      _mixpanel!.getPeople().set(
        'last_behavior_${behaviorType}_time',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint('❌ Error updating behavior stats: $e');
    }
  }

  /// Trackea cuántas visitas acumula un usuario (útil para análisis de retención)
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

    // Actualizar datos de retención
    try {
      _mixpanel!.getPeople().set('total_visits', visitCount);
      _mixpanel!.getPeople().set('days_since_first_visit', daysSinceFirstVisit);
      _mixpanel!.getPeople().set(
        'average_visits_per_day',
        daysSinceFirstVisit > 0 ? visitCount / daysSinceFirstVisit : visitCount,
      );
    } catch (e) {
      debugPrint('❌ Error updating visit count stats: $e');
    }
  }

  /// Trackea frecuencia específica de uso (diario, semanal, mensual)
  Future<void> trackUsageFrequency(
    String frequencyType, // daily, weekly, monthly
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

    // Actualizar estadísticas de frecuencia
    try {
      _mixpanel!.getPeople().set('${frequencyType}_visits', visitsInPeriod);
      _mixpanel!.getPeople().set(
        '${frequencyType}_active_days',
        activeDaysInPeriod,
      );

      // Categorizar usuarios por frecuencia
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
      debugPrint('❌ Error updating frequency stats: $e');
    }
  }

  /// Método para verificar si Mixpanel está funcionando correctamente
  Future<bool> isWorking() async {
    try {
      // Si no está inicializado, intentar inicializar
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

      // Si sigue sin estar inicializado, no está funcionando
      if (_mixpanel == null) {
        return false;
      }

      // Enviar un evento de diagnóstico
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

      // Si llegamos aquí, Mixpanel está funcionando
      debugPrint('✅ Mixpanel connection verified successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Mixpanel connection check failed: $e');
      return false;
    }
  }

  /// Método para reiniciar Mixpanel si no está funcionando
  Future<bool> restart() async {
    debugPrint('🔄 Attempting to restart Mixpanel...');

    // Reiniciar el estado
    _initialized = false;
    _mixpanel = null;

    try {
      // Intentar inicializar de nuevo
      await init().timeout(Duration(seconds: 5));

      // Verificar si está funcionando
      return await isWorking();
    } catch (e) {
      debugPrint('❌ Failed to restart Mixpanel: $e');
      return false;
    }
  }
}
