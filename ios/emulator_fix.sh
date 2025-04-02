#!/bin/bash

echo "🔧 Preparando el proyecto para ejecutar en simuladores iOS 🔧"
echo "============================================================"

# Limpieza de archivos generados
echo "📋 Paso 1: Limpiando archivos generados..."
rm -rf Pods
rm -rf Podfile.lock
rm -rf .symlinks
rm -rf Flutter/Flutter.podspec
rm -rf Flutter/ephemeral
echo "✅ Limpieza completada"

# Ejecutar Flutter pub get para regenerar archivos
echo ""
echo "📋 Paso 2: Regenerando archivos Flutter..."
cd ..
flutter clean
flutter pub get
echo "✅ Regeneración completada"

# Instalar pods
echo ""
echo "📋 Paso 3: Instalando pods con la configuración modificada..."
cd ios
pod install
echo "✅ Instalación completada"

echo ""
echo "🎉 ¡Proceso finalizado!"
echo "Para ejecutar en el simulador usa: flutter run"
echo "NOTA: La funcionalidad de escaneo de códigos estará desactivada en el simulador"
echo "      pero funcionará normalmente en dispositivos físicos." 