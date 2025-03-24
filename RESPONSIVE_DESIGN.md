# Guía de Diseño Responsivo

Esta guía explica cómo implementar y usar el sistema de diseño responsivo basado en `flutter_screenutil` que hemos integrado en la aplicación.

## Principios del Sistema Responsivo

El sistema está construido alrededor de los siguientes principios:

1. **Consistencia visual**: Los elementos de la UI deben mantener su tamaño relativo entre diferentes dispositivos.
2. **Adaptabilidad**: La UI debe adaptarse a los diferentes tamaños de pantalla y orientaciones.
3. **Facilidad de uso**: El sistema debe ser fácil de entender y aplicar para todos los desarrolladores.
4. **Reusabilidad**: Los componentes deben ser reutilizables y consistentes en toda la aplicación.

## Configuración Base

El sistema usa el iPhone 16 Pro Max (430x932) como dispositivo de referencia para el escalado. Todos los demás dispositivos se escalarán proporcionalmente en relación a éste.

```dart
// Dimensiones de referencia (iPhone 16 Pro Max)
static const Size designSize = Size(430, 932);
```

## Cómo usar el Sistema Responsivo

### 1. Tamaños de Fuente Responsivos

Para asegurar que los tamaños de fuente se escalen correctamente, usa el sufijo `.sp`:

```dart
Text(
  'Título',
  style: TextStyle(fontSize: 16.sp),
)
```

O usa nuestras constantes de ResponsiveGuidelines:

```dart
Text(
  'Título',
  style: TextStyle(fontSize: ResponsiveGuidelines.bodyLarge),
)
```

### 2. Dimensiones Responsivas

Para dimensiones que deben escalarse en relación al ancho de la pantalla, usa `.w`:

```dart
Container(
  width: 100.w,
  margin: EdgeInsets.symmetric(horizontal: 16.w),
)
```

Para dimensiones que deben escalarse en relación al alto de la pantalla, usa `.h`:

```dart
Container(
  height: 50.h,
  margin: EdgeInsets.symmetric(vertical: 8.h),
)
```

Para dimensiones que deberían mantener la misma proporción (como formas cuadradas), usa `.r`:

```dart
Container(
  width: 40.r,
  height: 40.r,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(8.r),
  ),
)
```

### 3. Espaciado y Padding Responsivos

Usa las constantes de ResponsiveGuidelines para un espaciado consistente:

```dart
// Espaciado vertical
ResponsiveGuidelines.verticalSpaceM

// Padding responsivo
Padding(
  padding: ResponsiveGuidelines.paddingM,
  child: YourWidget(),
)
```

### 4. Layouts Adaptativos

Para ajustar tu UI según el tipo de dispositivo, usa las constantes y métodos de DeviceConstants:

```dart
// Verificar tipo de dispositivo
if (DeviceConstants.isTablet(context)) {
  // Layout para tablet
} else {
  // Layout para móvil
}

// O usa el helper responsiveWidget
DeviceConstants.responsiveWidget(
  context: context,
  mobile: MobileLayout(),
  tablet: TabletLayout(),
  desktop: DesktopLayout(),
)
```

### 5. Orientación

Para manejar cambios de orientación:

```dart
if (DeviceConstants.isPortrait(context)) {
  // Layout en modo retrato
} else {
  // Layout en modo paisaje
}
```

## Estructura de Archivos

- `lib/responsive/responsive_guidelines.dart` - Constantes y utilidades para implementar responsividad
- `lib/responsive/device_constants.dart` - Constantes relacionadas con los tamaños de dispositivo y breakpoints
- `lib/main.dart` - Configuración de flutter_screenutil para toda la aplicación

## Consideraciones Importantes

1. **Uso Coherente**: Utiliza el sistema de forma coherente en todos los lugares. No mezcles valores fijos y responsivos.

2. **Testing en Múltiples Dispositivos**: Asegúrate de probar tu UI en diferentes tamaños de pantalla y orientaciones.

3. **Valores Mínimos y Máximos**: Para algunos elementos, puede ser necesario establecer valores mínimos y máximos para evitar que se vuelvan demasiado pequeños o grandes.

```dart
// Ejemplo de un tamaño con límites
final fontSize = (16.sp).clamp(12.0, 24.0);
```

4. **Tamaños de Imagen**: Para imágenes, considera usar AspectRatio para mantener las proporciones correctas.

## Migración de Código Existente

Si estás actualizando código existente, sigue estos pasos:

1. Reemplaza todos los valores fijos de tamaño de fuente por `.sp`
2. Reemplaza los anchos fijos por `.w`
3. Reemplaza las alturas fijas por `.h`
4. Reemplaza los radios y formas cuadradas por `.r`
5. Usa las constantes de ResponsiveGuidelines para espaciado y padding

## Referencias

- [Documentación de flutter_screenutil](https://pub.dev/packages/flutter_screenutil)
- [Referencia de Diseño Responsivo en Flutter](https://medium.com/@RotenKiwi/responsiveness-in-flutter-the-right-way-4f822d244aac) 