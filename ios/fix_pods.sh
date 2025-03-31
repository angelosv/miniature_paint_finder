#!/bin/bash

# Script para corregir problemas de arquitectura en mobile_scanner para Apple Silicon
# Ejecutar después de cada 'pod install' o 'pod update'

PODSPEC_PATH="Pods/Local Podspecs/mobile_scanner.podspec.json"

if [ -f "$PODSPEC_PATH" ]; then
  echo "Corrigiendo configuración de arquitectura en mobile_scanner..."
  # Reemplaza la configuración de EXCLUDED_ARCHS para simuladores
  sed -i '' 's/"EXCLUDED_ARCHS\[sdk=iphonesimulator\*\]": "i386 armv7 arm64"/"EXCLUDED_ARCHS\[sdk=iphonesimulator\*\]": "i386 armv7"/g' "$PODSPEC_PATH"
  echo "Configuración corregida. Mobile Scanner debería funcionar correctamente en simuladores Apple Silicon."
  
  # Reinstala los pods para aplicar los cambios
  pod install
else
  echo "Error: No se encontró el archivo podspec de mobile_scanner."
  echo "Ejecute 'pod install' primero antes de usar este script."
fi 