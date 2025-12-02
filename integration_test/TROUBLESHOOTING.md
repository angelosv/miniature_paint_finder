# E2E Testing Troubleshooting Guide

## 🚨 Problemas Conocidos y Soluciones

### 1. **Error: Google Fonts - AssetManifest.json**

**Problema:**
```
Error: google_fonts was unable to load font Poppins-Regular because the following exception occurred:
Unable to load asset: "AssetManifest.json".
```

**Causa:** 
Los tests de integración no pueden acceder al `AssetManifest.json` necesario para Google Fonts.

**Soluciones:**

#### Opción A: Usar Fuentes del Sistema (Recomendado para Tests)
```dart
// En el tema de la app para tests
theme: ThemeData(
  fontFamily: 'SF Pro Text', // iOS
  // o 'Roboto' para Android
),
```

#### Opción B: Configurar Assets para Tests
```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/fonts/
  fonts:
    - family: Poppins
      fonts:
        - asset: assets/fonts/Poppins-Regular.ttf
```

#### Opción C: Deshabilitar Google Fonts en Tests
```dart
// Usar variable de entorno
if (kIsWeb || Platform.environment['FLUTTER_TEST'] == 'true') {
  // Usar fuentes del sistema
} else {
  // Usar Google Fonts
}
```

### 2. **Error: Could not build the application for the simulator**

**Problema:**
La app no se puede compilar para el simulador durante los tests.

**Soluciones:**

#### Verificar Dependencias
```bash
flutter doctor -v
flutter clean
flutter pub get
```

#### Verificar Simulador
```bash
xcrun simctl list devices
xcrun simctl boot "iPhone 15 Pro"
```

#### Especificar Dispositivo
```bash
flutter test integration_test/simple_test.dart -d "DEVICE_ID"
```

### 3. **Error: Timeout en Tests**

**Problema:**
Los tests fallan por timeout.

**Soluciones:**

#### Aumentar Timeout
```bash
flutter test integration_test/simple_test.dart --timeout=120s
```

#### En el Código
```dart
testWidgets('Test name', (tester) async {
  await tester.pumpAndSettle(Duration(seconds: 10));
}, timeout: Timeout(Duration(minutes: 2)));
```

### 4. **Error: Multiple devices connected**

**Problema:**
```
More than one device connected; please specify a device with the '-d <deviceId>' flag
```

**Solución:**
```bash
# Listar dispositivos
flutter devices

# Ejecutar con dispositivo específico
flutter test integration_test/simple_test.dart -d "iPhone 16 Pro"
```

### 5. **Error: Firebase not initialized**

**Problema:**
Firebase no se inicializa correctamente en tests.

**Solución:**
```dart
// En setUp o al inicio del test
await Firebase.initializeApp();
```

### 6. **Error: Provider not found**

**Problema:**
Los providers no están disponibles en el contexto de test.

**Solución:**
```dart
// Envolver el test con providers necesarios
await tester.pumpWidget(
  MultiProvider(
    providers: [
      // ... providers necesarios
    ],
    child: MaterialApp(home: WidgetToTest()),
  ),
);
```

## 🛠️ Configuración Recomendada para Tests

### 1. **Estructura de Test Básica**
```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Test Group', () {
    setUp(() async {
      // Configuración antes de cada test
    });

    tearDown(() async {
      // Limpieza después de cada test
    });

    testWidgets('Test description', (tester) async {
      // Código del test
    });
  });
}
```

### 2. **Configuración de Dispositivo**
```bash
# Iniciar simulador específico
xcrun simctl boot "iPhone 15 Pro"

# Verificar que está corriendo
xcrun simctl list devices | grep Booted
```

### 3. **Variables de Entorno para Tests**
```bash
export FLUTTER_TEST=true
export INTEGRATION_TEST=true
```

### 4. **Configuración de Timeout**
```dart
// En test_config.dart
static const Duration defaultTimeout = Duration(seconds: 30);
static const Duration longTimeout = Duration(minutes: 2);
```

## 🔧 Comandos Útiles

### Debugging
```bash
# Logs detallados
flutter test integration_test/simple_test.dart --verbose

# Con dispositivo específico
flutter test integration_test/simple_test.dart -d "iPhone 15 Pro" --verbose

# Solo compilar sin ejecutar
flutter build ios --debug --simulator
```

### Limpieza
```bash
# Limpiar proyecto
flutter clean
flutter pub get

# Limpiar simulador
xcrun simctl erase all
```

### Información del Sistema
```bash
# Estado de Flutter
flutter doctor -v

# Dispositivos disponibles
flutter devices

# Información del simulador
xcrun simctl list devices
```

## 📊 Estado Actual de los Tests

### ✅ **Funcionando**
- Estructura básica de tests E2E
- Configuración de CI/CD (GitHub Actions)
- Scripts de ejecución
- Helpers y utilidades
- Datos de prueba (mock data)

### ⚠️ **Problemas Conocidos**
- Google Fonts en entorno de testing
- Algunos imports y dependencias
- Configuración específica de dispositivos

### 🔄 **En Progreso**
- Solución para Google Fonts
- Optimización de timeouts
- Configuración de assets para tests

## 🎯 **Próximos Pasos**

1. **Resolver Google Fonts**: Implementar solución con fuentes del sistema
2. **Configurar Assets**: Asegurar que todos los assets estén disponibles
3. **Optimizar Performance**: Reducir tiempos de carga
4. **Documentar Casos de Uso**: Crear ejemplos específicos
5. **Automatizar Setup**: Script para configuración automática

## 📞 **Soporte**

Si encuentras problemas adicionales:

1. **Revisar logs detallados** con `--verbose`
2. **Verificar configuración** con `flutter doctor`
3. **Limpiar proyecto** con `flutter clean`
4. **Consultar documentación** de Flutter Testing
5. **Crear issue** en el repositorio con logs completos

---

**Última actualización**: $(date)
**Versión de Flutter**: 3.38.2
**Estado**: En desarrollo activo

