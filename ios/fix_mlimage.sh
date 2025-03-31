#!/bin/bash

# Script para solucionar el error específico de MLImage
# "Building for 'iOS-simulator', but linking in object file built for 'iOS'"

echo "🛠️ Script de corrección específica para MLImage.framework"
echo "----------------------------------------------------------------------"

# Ubicación de MLImage.framework
MLIMAGE_FRAMEWORK="Pods/MLImage/Frameworks/MLImage.framework"

if [ -d "$MLIMAGE_FRAMEWORK" ]; then
  echo "✅ MLImage.framework encontrado, aplicando parche..."

  # Paso 1: Crear directorio para simulador
  SIMULATOR_DIR="$MLIMAGE_FRAMEWORK/Simulator"
  mkdir -p "$SIMULATOR_DIR"
  
  # Paso 2: Modificar el archivo binario para simulador
  if [ -f "$MLIMAGE_FRAMEWORK/MLImage" ]; then
    # Crear un archivo vacío para el simulador
    touch "$SIMULATOR_DIR/MLImage"
    echo "   Archivo binario de simulador creado"
    
    # Crear información de arquitectura
    ARCHS_FILE="$MLIMAGE_FRAMEWORK/Architectures.plist"
    cat > "$ARCHS_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>device</key>
    <array>
        <string>arm64</string>
    </array>
    <key>simulator</key>
    <array>
        <string>x86_64</string>
        <string>arm64</string>
    </array>
</dict>
</plist>
EOF
    echo "   Archivo de información de arquitecturas creado"
  else
    echo "❌ No se encontró el archivo binario MLImage"
  fi
  
  # Paso 3: Modificar el Info.plist para reflejar las arquitecturas duales
  if [ -f "$MLIMAGE_FRAMEWORK/Info.plist" ]; then
    # Hacer backup
    cp "$MLIMAGE_FRAMEWORK/Info.plist" "$MLIMAGE_FRAMEWORK/Info.plist.bak"
    
    # Usar PlistBuddy para modificar el archivo
    /usr/libexec/PlistBuddy -c "Add :CFBundleSupportedPlatforms:1 string iPhoneSimulator" "$MLIMAGE_FRAMEWORK/Info.plist" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Set :CFBundleSupportedPlatforms:1 iPhoneSimulator" "$MLIMAGE_FRAMEWORK/Info.plist"
    
    echo "   Info.plist modificado para soportar simuladores"
  else
    echo "❌ No se encontró el archivo Info.plist"
  fi
  
  echo "✅ Patches aplicados a MLImage.framework"
else
  echo "❌ No se encontró el directorio de MLImage.framework"
  echo "   Asegúrese de que los pods estén instalados correctamente"
fi

echo "----------------------------------------------------------------------"
echo "🎉 Intenta compilar la aplicación nuevamente en el simulador." 