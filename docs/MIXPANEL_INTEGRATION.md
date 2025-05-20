# Integración de Mixpanel en MiniaturePaintFinder

Este documento describe la integración de Mixpanel para el seguimiento de eventos en la aplicación MiniaturePaintFinder.

## Configuración

Para utilizar Mixpanel en la aplicación, se necesita:

1. Un token de proyecto Mixpanel (reemplaza `TU_TOKEN_DE_MIXPANEL` en `MixpanelService`)
2. Dependencias configuradas en `pubspec.yaml`:
   - `mixpanel_flutter: ^2.4.1`
   - `package_info_plus: ^8.3.0` (para información de versión de app)
   - `device_info_plus: ^10.1.2` (ya existente, para información del dispositivo)

## Estructura

La integración de Mixpanel consta de los siguientes componentes:

### MixpanelService

Un servicio singleton para interactuar con la API de Mixpanel, ubicado en `lib/services/mixpanel_service.dart`. Este servicio proporciona métodos para:

- Inicializar Mixpanel
- Identificar usuarios
- Trackear eventos personalizados
- Trackear pantallas
- Trackear instalaciones de la app
- Trackear usuarios activos

### AnalyticsRouteObserver

Un observador de rutas que automáticamente trackea la navegación entre pantallas, ubicado en `lib/utils/analytics_route_observer.dart`. Está configurado en `MaterialApp` para registrar cuando el usuario navega entre pantallas.

### ScreenAnalyticsMixin

Un mixin que se puede aplicar a cualquier `StatefulWidget` para facilitar el tracking de pantallas y eventos, ubicado en `lib/screens/screen_analytics.dart`. Proporciona:

- Tracking automático al mostrar una pantalla
- Método `trackEvent` para enviar eventos personalizados

## Eventos Trackeados

La integración actual trackea:

### Automáticos
- **Instalación de la app** - Al iniciar la app por primera vez en un dispositivo
- **Usuario activo** - Cada vez que se inicia la app
- **Vistas de pantalla** - Cuando el usuario navega a una nueva pantalla

### Autenticación
- **Login** - Cuando un usuario inicia sesión, con atributos:
  - `method` - El método de autenticación (Email/Password, Google, Apple)
  - `success` - Si el login fue exitoso
  - `error` - El mensaje de error (si falló)

### Navegación
- **Tab Changed** - Cuando el usuario cambia entre tabs
- **Navigation** - Cuando navega entre pantallas principales

## Ejemplo de Uso

### 1. Trackear una pantalla automáticamente con el mixin:

```dart
class MyScreenState extends State<MyScreen> with ScreenAnalyticsMixin {
  @override
  String get screenName => 'Mi Pantalla Personalizada';
  
  // El resto del código de la pantalla...
}
```

### 2. Trackear un evento personalizado:

```dart
// Desde una clase que usa ScreenAnalyticsMixin
trackEvent('Button Clicked', {'button_name': 'Submit'});

// O directamente desde cualquier parte
MixpanelService.instance.trackEvent('Button Clicked', {'button_name': 'Submit'});
```

### 3. Envolver un widget con tracking de analíticas:

```dart
MyWidget().withAnalytics('Nombre de Pantalla')
```

## Consideraciones para el Futuro

- **Propiedades de usuario**: Añadir propiedades específicas de usuario como nivel de membresía, preferencias, etc.
- **Eventos de conversión**: Trackear eventos importantes para el negocio como compras, suscripciones, etc.
- **Embudos de conversión**: Configurar embudos en Mixpanel para seguir flujos completos de usuarios
- **A/B Testing**: Implementar pruebas A/B utilizando Mixpanel
- **Segmentación**: Crear segmentos de usuarios basados en comportamiento