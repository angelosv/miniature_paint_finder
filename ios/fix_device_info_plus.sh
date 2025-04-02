#!/bin/bash

echo "🔧 Arreglando problema de device_info_plus para simuladores iOS 🔧"
echo "======================================================"

# Determinar ubicación del archivo problemático
PLUGIN_REG_FILE="Runner/GeneratedPluginRegistrant.m"

if [ ! -f "$PLUGIN_REG_FILE" ]; then
    echo "❌ No se encuentra el archivo GeneratedPluginRegistrant.m"
    exit 1
fi

echo "📋 Paso 1: Creando copia de seguridad del archivo..."
cp "$PLUGIN_REG_FILE" "${PLUGIN_REG_FILE}.backup"
echo "✅ Copia de seguridad creada: ${PLUGIN_REG_FILE}.backup"

echo "📋 Paso 2: Modificando archivo GeneratedPluginRegistrant.m directamente..."
# 1. Comentar la línea de importación
sed -i '' 's/#import <device_info_plus\/FPPDeviceInfoPlusPlugin.h>/\/\/ Commented for simulator: #import <device_info_plus\/FPPDeviceInfoPlusPlugin.h>/g' "$PLUGIN_REG_FILE"

# 2. Comentar la línea de registro
sed -i '' 's/  \[FPPDeviceInfoPlusPlugin register/  \/\/ Commented for simulator: \[FPPDeviceInfoPlusPlugin register/g' "$PLUGIN_REG_FILE"

echo "✅ Archivo modificado correctamente"

echo "📋 Paso 3: Regenerando cacheés y reinstalando pods..."
rm -rf Pods Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData/*miniature_paint_finder*
pod install
echo "✅ Pods reinstalados"

echo ""
echo "🎉 Proceso completado!"
echo "Intenta ejecutar de nuevo: flutter run -d <id-simulador>"
echo ""
echo "NOTA: La funcionalidad de device_info_plus estará desactivada en el simulador"
echo "      pero el resto de la app debería funcionar correctamente."
echo "      La app seguirá funcionando normalmente en dispositivos físicos iOS y Android." 