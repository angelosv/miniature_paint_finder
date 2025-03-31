#!/bin/bash

# Script para solucionar problemas comunes de construcción en iOS
# Especialmente para equipos con Apple Silicon (M1/M2/M3)

echo "🛠️ Herramienta de solución de problemas de iOS para Miniature Paint Finder 🛠️"
echo "=========================================================================="
echo

# Verificar si estamos en un Mac con Apple Silicon
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
  echo "✅ Detectado Mac con Apple Silicon ($ARCH)"
  IS_APPLE_SILICON=true
else
  echo "ℹ️ Detectado Mac con Intel ($ARCH)"
  IS_APPLE_SILICON=false
fi

# Función para limpiar el proyecto
clean_project() {
  echo
  echo "🧹 Limpiando el proyecto..."
  echo "----------------------------"
  
  # Volver al directorio principal del proyecto Flutter
  cd ..
  
  echo "- Ejecutando flutter clean..."
  flutter clean
  
  echo "- Obteniendo dependencias de Flutter..."
  flutter pub get
  
  # Volver al directorio iOS
  cd ios
  
  echo "- Eliminando carpeta Pods..."
  rm -rf Pods
  
  echo "- Eliminando Podfile.lock..."
  rm -f Podfile.lock
  
  echo "✅ Limpieza completada"
}

# Función para verificar y configurar el Podfile
setup_podfile() {
  echo
  echo "📝 Verificando configuración del Podfile..."
  echo "-----------------------------------------"
  
  # Verificar si tiene la configuración correcta para Apple Silicon
  if grep -q "VALID_ARCHS.*arm64.*x86_64" "Podfile"; then
    echo "✅ El Podfile ya tiene configuración para Apple Silicon"
  else
    echo "⚠️ Configuración para Apple Silicon no encontrada en el Podfile"
    echo "- Se recomienda revisar el Podfile según las instrucciones en docs/SETUP_GUIDE.md"
  fi
}

# Función para instalar pods
install_pods() {
  echo
  echo "📦 Instalando pods..."
  echo "--------------------"
  
  pod install
  
  echo "✅ Pods instalados"
}

# Función para arreglar MLImage.framework
fix_mlimage() {
  echo
  echo "🔧 Arreglando MLImage.framework..."
  echo "--------------------------------"
  
  if [ -d "Pods/MLImage/Frameworks/MLImage.framework" ]; then
    echo "- Encontrado MLImage.framework"
    
    # Hacer backup del binario original si existe y no hay backup aún
    if [ -f "Pods/MLImage/Frameworks/MLImage.framework/MLImage" ] && [ ! -f "Pods/MLImage/Frameworks/MLImage.framework/MLImage.original" ]; then
      echo "- Haciendo backup del binario original..."
      cp "Pods/MLImage/Frameworks/MLImage.framework/MLImage" "Pods/MLImage/Frameworks/MLImage.framework/MLImage.original"
    fi
    
    if [ -f "Pods/MLImage/Frameworks/MLImage.framework/MLImage.original" ]; then
      echo "- Extrayendo arquitectura arm64 del binario original..."
      xcrun lipo -thin arm64 "Pods/MLImage/Frameworks/MLImage.framework/MLImage.original" -output "Pods/MLImage/Frameworks/MLImage.framework/MLImage" 2>/dev/null
      
      # Verificar si el comando anterior funcionó
      if [ $? -eq 0 ]; then
        echo "- Configurando permisos de ejecución..."
        chmod +x "Pods/MLImage/Frameworks/MLImage.framework/MLImage"
        echo "✅ MLImage.framework corregido correctamente"
      else
        echo "⚠️ Error al extraer arquitectura arm64 del binario"
        echo "- Creando un binario vacío como alternativa..."
        dd if=/dev/zero of="Pods/MLImage/Frameworks/MLImage.framework/MLImage" bs=64 count=1 >/dev/null 2>&1
        chmod +x "Pods/MLImage/Frameworks/MLImage.framework/MLImage"
      fi
      
      # Crear carpeta de módulos y archivo modulemap
      echo "- Configurando módulos para MLImage..."
      mkdir -p "Pods/MLImage/Frameworks/MLImage.framework/Modules"
      cat > "Pods/MLImage/Frameworks/MLImage.framework/Modules/module.modulemap" << 'EOF'
framework module MLImage {
  umbrella header "MLImage.h"
  export *
  module * { export * }
}
EOF
      echo "✅ Configuración de módulos completada"
    else
      echo "⚠️ No se encontró el binario original de MLImage"
    fi
  else
    echo "ℹ️ No se encontró MLImage.framework (¿ya instalaste los pods?)"
  fi
}

# Función para verificar el estado de mobile_scanner
check_mobile_scanner() {
  echo
  echo "🔍 Verificando mobile_scanner..."
  echo "-----------------------------"
  
  if [ -f "Pods/Local Podspecs/mobile_scanner.podspec.json" ]; then
    echo "- Encontrado podspec de mobile_scanner"
    
    # Verificar si tiene arm64 en EXCLUDED_ARCHS
    if grep -q "EXCLUDED_ARCHS.*arm64" "Pods/Local Podspecs/mobile_scanner.podspec.json"; then
      echo "⚠️ mobile_scanner excluye arm64 para simuladores"
      echo "- Haciendo backup del archivo original..."
      cp "Pods/Local Podspecs/mobile_scanner.podspec.json" "Pods/Local Podspecs/mobile_scanner.podspec.json.bak"
      
      echo "- Corrigiendo configuración..."
      sed -i '' 's/"EXCLUDED_ARCHS\[sdk=iphonesimulator\*\]": "i386 armv7 arm64"/"EXCLUDED_ARCHS\[sdk=iphonesimulator\*\]": "i386 armv7"/g' "Pods/Local Podspecs/mobile_scanner.podspec.json"
      echo "✅ mobile_scanner.podspec.json corregido"
    else
      echo "✅ mobile_scanner ya tiene la configuración correcta"
    fi
  else
    echo "ℹ️ No se encontró el podspec de mobile_scanner (¿ya instalaste los pods?)"
  fi
}

# Menú principal
while true; do
  echo
  echo "📋 Menú Principal"
  echo "================"
  echo "1) Limpiar proyecto completamente"
  echo "2) Verificar configuración de Podfile"
  echo "3) Instalar pods"
  echo "4) Arreglar MLImage.framework"
  echo "5) Verificar y corregir mobile_scanner"
  echo "6) Solución completa (ejecutar todas las opciones anteriores)"
  echo "0) Salir"
  echo
  read -p "Selecciona una opción: " option
  
  case $option in
    1)
      clean_project
      ;;
    2)
      setup_podfile
      ;;
    3)
      install_pods
      ;;
    4)
      fix_mlimage
      ;;
    5)
      check_mobile_scanner
      ;;
    6)
      clean_project
      setup_podfile
      install_pods
      fix_mlimage
      check_mobile_scanner
      install_pods
      
      echo
      echo "✅ Solución completa aplicada"
      echo "----------------------------"
      echo "- Si la aplicación sigue sin funcionar, consulta docs/SETUP_GUIDE.md"
      echo "- O ejecuta 'flutter run -v' para obtener más detalles sobre el error"
      ;;
    0)
      echo
      echo "🔚 Saliendo del script"
      exit 0
      ;;
    *)
      echo "❌ Opción no válida"
      ;;
  esac
done 