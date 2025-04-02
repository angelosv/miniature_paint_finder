#!/bin/bash

echo "🔧 Arreglando el problema de simuladores iOS para MLImage y escáner de códigos 🔧"
echo "======================================================================"

# Limpieza inicial
echo "📋 PASO 1: Limpieza de pods y archivos generados..."
echo "------------------------------------------------------"
rm -rf Pods
rm -rf Podfile.lock
rm -rf .symlinks
rm -rf Flutter/Flutter.podspec
rm -rf Flutter/ephemeral

# Forzar regeneración de archivos Flutter
echo "📋 PASO 2: Regenerando archivos Flutter..."
echo "------------------------------------------------------"
cd ..
flutter clean
flutter pub get

# Instalar pods con la nueva configuración
echo "📋 PASO 3: Instalando pods con la configuración actualizada..."
echo "------------------------------------------------------"
cd ios
pod install

echo ""
echo "✅ Proceso completado. Ahora debería poder ejecutar en simuladores."
echo "    Si todavía hay problemas, intente ejecutar la app desde Xcode."
echo "    Para ejecutar en simulador: flutter run -d <id-simulador>"
echo "    Para ejecutar en dispositivo físico: flutter run -d <id-dispositivo>"
echo "" 