# Guía de Configuración para Desarrolladores

Esta guía te ayudará a configurar el entorno de desarrollo para el proyecto Miniature Paint Finder y solucionar problemas comunes.

## Requisitos Previos

- Flutter SDK (última versión estable)
- Android Studio para desarrollo en Android
- Xcode (14.0 o superior) para desarrollo en iOS
- CocoaPods para dependencias de iOS
- Git

## Configuración Inicial

1. Clona el repositorio:
   ```bash
   git clone <url_del_repositorio>
   cd miniature_paint_finder
   ```

2. Obtén las dependencias de Flutter:
   ```bash
   flutter pub get
   ```

## Ejecutar en Android

Para ejecutar la aplicación en Android:

1. Conecta un dispositivo Android o inicia un emulador
2. Ejecuta la aplicación:
   ```bash
   flutter run
   ```

No se requieren configuraciones adicionales para Android.

## Ejecutar en iOS

Para ejecutar la aplicación en iOS:

1. Navega al directorio iOS del proyecto:
   ```bash
   cd ios
   ```

2. Instala las dependencias de CocoaPods:
   ```bash
   pod install
   ```

3. Vuelve al directorio principal:
   ```bash
   cd ..
   ```

4. Conecta un dispositivo iOS o inicia un simulador

5. Ejecuta la aplicación:
   ```bash
   flutter run
   ```

## Solución de Problemas en iOS (Apple Silicon)

Si estás usando una Mac con chip Apple Silicon (M1, M2, M3) y encuentras problemas relacionados con arquitecturas o con MLImage.framework, sigue estos pasos:

### Problema: "Unknown file type in MLImage.framework/MLImage"

Este es un problema común en dispositivos con Apple Silicon cuando se trabaja con frameworks binarios. Para solucionarlo:

1. Limpia completamente el proyecto:
   ```bash
   flutter clean
   cd ios
   rm -rf Pods
   rm -f Podfile.lock
   ```

2. Asegúrate de que el Podfile tiene la configuración correcta. El Podfile debería contener algo como esto en la sección `post_install`:

   ```ruby
   post_install do |installer|
     installer.pods_project.targets.each do |target|
       flutter_additional_ios_build_settings(target)
       target.build_configurations.each do |config|
         config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.5'
         
         # Optimizations for camera performance
         config.build_settings['GCC_OPTIMIZATION_LEVEL'] = '3'
         
         # Disable bitcode as it's deprecated and can cause issues
         config.build_settings['ENABLE_BITCODE'] = 'NO'
         
         # Solución para simuladores en Apple Silicon (M1/M2)
         config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'i386 armv7'
         config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
         
         # Permitir arm64 en simuladores para Apple Silicon
         if config.build_settings['SDKROOT'] == 'iphonesimulator'
           config.build_settings['VALID_ARCHS'] = 'arm64 x86_64'
         end
       end
     end
     
     # Fix para MLImage.framework - tratar específicamente las dependencias problemáticas
     installer.pods_project.targets.each do |target|
       if ['MLImage', 'MLKitVision', 'GoogleMLKit', 'mobile_scanner'].include?(target.name)
         target.build_configurations.each do |config|
           if config.name.include?('iphonesimulator')
             # Configuración específica para simuladores
             config.build_settings['VALID_ARCHS'] = 'arm64 x86_64'
             config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'i386 armv7'
             config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
           end
         end
       end
     end
   end
   ```

3. Reinstala los pods:
   ```bash
   cd ios
   pod install
   ```

4. Si todavía tienes problemas con MLImage.framework, ejecuta estos comandos:
   ```bash
   # Arreglo para MLImage en dispositivos físicos iOS
   xcrun lipo -thin arm64 Pods/MLImage/Frameworks/MLImage.framework/MLImage.original -output Pods/MLImage/Frameworks/MLImage.framework/MLImage
   chmod +x Pods/MLImage/Frameworks/MLImage.framework/MLImage
   pod install
   ```

5. Intenta ejecutar la aplicación nuevamente:
   ```bash
   cd ..
   flutter run
   ```

### Problema: "The sandbox is not in sync with the Podfile.lock"

Este error indica que hay una discrepancia entre el estado del sandbox de CocoaPods y tu archivo Podfile.lock. Para solucionarlo:

```bash
cd ios
pod install
```

### Problema: "Building for iOS-simulator, but linking in object file built for iOS"

Este error ocurre cuando tienes problemas de compatibilidad entre arquitecturas en los simuladores. Asegúrate de:

1. Tener la configuración correcta en el Podfile (como se muestra arriba)
2. Ejecutar `pod install` después de modificar el Podfile
3. Si el problema persiste, intenta limpiar y reconstruir:
   ```bash
   flutter clean
   cd ios
   rm -rf Pods
   rm -f Podfile.lock
   pod install
   cd ..
   flutter run
   ```

## Notas Adicionales

- La aplicación utiliza Firebase, pero está configurada para funcionar en modo simulado si la configuración no está disponible.
- Para el desarrollo en iOS, asegúrate de tener configurado tu equipo de desarrollo en Xcode.
- Si encuentras algún problema específico con el proyecto, reporta el error en [issues](<url_del_repositorio>/issues). 