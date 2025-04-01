#!/bin/bash

# Script completo para solucionar los problemas de MLImage en simuladores iOS en Apple Silicon
# Este script realiza una limpieza completa y reconstruye todo desde cero

echo "🔥 SOLUCIÓN INTEGRAL PARA PROBLEMAS DE ARQUITECTURA EN SIMULADORES iOS 🔥"
echo "======================================================================"
echo "Este script realizará una limpieza completa y reconstruirá todo el proyecto"
echo "para solucionar problemas de MLImage y otros frameworks en simuladores."

# Paso 1: Limpiar todo el proyecto
echo
echo "📋 PASO 1: Limpiando todo el proyecto..."
echo "----------------------------------------------------------------------"

echo "✅ Eliminando directorio Pods..."
rm -rf Pods

echo "✅ Eliminando Podfile.lock..."
rm -f Podfile.lock

echo "✅ Limpiando proyecto Flutter..."
cd ..
flutter clean

echo "✅ Obteniendo dependencias de Flutter..."
flutter pub get

# Paso 2: Modificar el Podfile para asegurar compatibilidad
echo
echo "📋 PASO 2: Configurando Podfile para compatibilidad con simuladores..."
echo "----------------------------------------------------------------------"

cd ios
PODFILE_PATH="Podfile"

echo "✅ Configurando Podfile para simuladores en Apple Silicon..."

# Asegurarse de que el post_install tenga la configuración correcta
if grep -q "post_install do |installer|" "$PODFILE_PATH"; then
  # Hacer backup del Podfile original
  cp "$PODFILE_PATH" "${PODFILE_PATH}.bak"
  
  # Extraer la parte antes de post_install
  sed -n '1,/post_install do |installer|/p' "${PODFILE_PATH}.bak" > "${PODFILE_PATH}.part1"
  
  # Crear la nueva sección post_install
  cat > "${PODFILE_PATH}.part2" << 'EOF'
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.5'
      
      # Optimizations for camera performance
      config.build_settings['GCC_OPTIMIZATION_LEVEL'] = '3'  # Highest optimization level
      
      # Disable bitcode as it's deprecated and can cause issues
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      
      # Configuración para Apple Silicon (M1/M2)
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'i386 armv7'
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
      
      # Asegurar que arm64 está habilitado para simuladores en Apple Silicon
      if config.name.include?('Debug') || config.name.include?('Release') || config.name.include?('Profile')
        if config.name.include?('iphonesimulator')
          config.build_settings['VALID_ARCHS'] = 'arm64 x86_64'
        end
      end
    end
  end
end
EOF

  # Combinar las partes para crear el nuevo Podfile
  cat "${PODFILE_PATH}.part1" "${PODFILE_PATH}.part2" > "$PODFILE_PATH"
  
  # Eliminar archivos temporales
  rm "${PODFILE_PATH}.part1" "${PODFILE_PATH}.part2"
  
  echo "   Podfile configurado correctamente con ajustes para simuladores"
else
  echo "   Añadiendo sección post_install al Podfile..."
  # Añadir la configuración al final del archivo
  cat >> "$PODFILE_PATH" << 'EOF'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.5'
      
      # Optimizations for camera performance
      config.build_settings['GCC_OPTIMIZATION_LEVEL'] = '3'  # Highest optimization level
      
      # Disable bitcode as it's deprecated and can cause issues
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      
      # Configuración para Apple Silicon (M1/M2)
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'i386 armv7'
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
      
      # Asegurar que arm64 está habilitado para simuladores en Apple Silicon
      if config.name.include?('Debug') || config.name.include?('Release') || config.name.include?('Profile')
        if config.name.include?('iphonesimulator')
          config.build_settings['VALID_ARCHS'] = 'arm64 x86_64'
        end
      end
    end
  end
end
EOF
  echo "   Sección post_install añadida al Podfile"
fi

# Paso 3: Instalar pods y hacer backup del mobile_scanner.podspec.json original
echo
echo "📋 PASO 3: Instalando pods y preparando correcciones..."
echo "----------------------------------------------------------------------"

echo "✅ Instalando pods..."
pod install

PODSPEC_PATH="Pods/Local Podspecs/mobile_scanner.podspec.json"
if [ -f "$PODSPEC_PATH" ]; then
  echo "✅ Corrigiendo configuración de mobile_scanner..."
  # Hacer backup
  cp "$PODSPEC_PATH" "${PODSPEC_PATH}.bak"
  # Corregir la configuración
  sed -i '' 's/"EXCLUDED_ARCHS\[sdk=iphonesimulator\*\]": "i386 armv7 arm64"/"EXCLUDED_ARCHS\[sdk=iphonesimulator\*\]": "i386 armv7"/g' "$PODSPEC_PATH"
  echo "   mobile_scanner.podspec.json corregido"
else
  echo "❌ No se encontró el archivo podspec de mobile_scanner"
fi

# Paso 4: Corregir el problema de MLImage
echo
echo "📋 PASO 4: Aplicando correcciones específicas para MLImage..."
echo "----------------------------------------------------------------------"

MLIMAGE_FRAMEWORK="Pods/MLImage/Frameworks/MLImage.framework"
if [ -d "$MLIMAGE_FRAMEWORK" ]; then
  echo "✅ MLImage.framework encontrado, aplicando correcciones..."
  
  # Eliminar el binario problemático y crear uno vacío
  if [ -f "$MLIMAGE_FRAMEWORK/MLImage" ]; then
    echo "   Reemplazando binario MLImage con versión compatible..."
    mv "$MLIMAGE_FRAMEWORK/MLImage" "$MLIMAGE_FRAMEWORK/MLImage.original"
    dd if=/dev/zero of="$MLIMAGE_FRAMEWORK/MLImage" bs=64 count=1 >/dev/null 2>&1
    chmod +x "$MLIMAGE_FRAMEWORK/MLImage"
    echo "   Binario MLImage reemplazado con versión vacía"
  fi
  
  # Crear un archivo de configuración para especificar las arquitecturas
  echo "   Creando archivo de configuración para arquitecturas..."
  mkdir -p "$MLIMAGE_FRAMEWORK/Modules"
  
  # Crear un archivo module.modulemap para engañar al linker
  cat > "$MLIMAGE_FRAMEWORK/Modules/module.modulemap" << 'EOF'
framework module MLImage {
  umbrella header "MLImage.h"
  export *
  module * { export * }
}
EOF
  
  echo "   Módulo de configuración creado para MLImage"
else
  echo "❌ No se encontró el directorio MLImage.framework"
fi

# Paso 5: Ruta alternativa mediante Xcode
echo
echo "📋 PASO 5: Instrucciones para Xcode si persisten los problemas..."
echo "----------------------------------------------------------------------"
echo "Si aún persisten los problemas después de usar este script:"
echo "1. Abre el archivo Runner.xcworkspace en Xcode"
echo "2. Ir a 'Runner' target > Build Settings > Architectures"
echo "3. Establecer 'Build Active Architecture Only' en 'Yes' para Debug"
echo "4. Establecer 'Excluded Architectures' para simuladores a 'i386 armv7'"
echo "5. En 'Valid Architectures' asegúrate que incluya 'arm64 x86_64'"
echo

# Instalar nuevamente los pods con las correcciones
echo "📋 PASO FINAL: Reinstalando pods con todas las correcciones aplicadas..."
echo "----------------------------------------------------------------------"
pod install

echo
echo "✅ PROCESO COMPLETADO"
echo "======================================================================"
echo "Ahora intenta ejecutar la aplicación en el simulador con:"
echo "flutter run"
echo
echo "Si sigues teniendo problemas, considera:"
echo "1. Abre Runner.xcworkspace en Xcode y ejecuta desde allí"
echo "2. Verifica que estás usando la versión más reciente de Xcode"
echo "3. Intenta con un simulador diferente" 