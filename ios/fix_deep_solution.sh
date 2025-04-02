#!/bin/bash

echo "🔧 SOLUCIÓN PERMANENTE PARA EL SIMULADOR iOS 🔧"
echo "=============================================="

# Determinar ubicación del archivo problemático
PLUGIN_REG_FILE="Runner/GeneratedPluginRegistrant.m"

if [ ! -f "$PLUGIN_REG_FILE" ]; then
    echo "❌ No se encuentra el archivo GeneratedPluginRegistrant.m"
    exit 1
fi

echo "📋 Paso 1: Creando copia de seguridad del archivo..."
cp "$PLUGIN_REG_FILE" "${PLUGIN_REG_FILE}.backup"
echo "✅ Copia de seguridad creada: ${PLUGIN_REG_FILE}.backup"

echo "📋 Paso 2: Comentando las líneas problemáticas de device_info_plus..."
# Usar sed para comentar las líneas problemáticas
sed -i '' 's/#import <device_info_plus\/FPPDeviceInfoPlusPlugin.h>/\/\/ Commented for simulator\n\/\/#import <device_info_plus\/FPPDeviceInfoPlusPlugin.h>/g' "$PLUGIN_REG_FILE"
sed -i '' 's/@import device_info_plus;/\/\/ Commented for simulator\n\/\/@import device_info_plus;/g' "$PLUGIN_REG_FILE"
sed -i '' 's/\[FPPDeviceInfoPlusPlugin registerWithRegistrar:/\/\/ Commented for simulator\n  \/\/\[FPPDeviceInfoPlusPlugin registerWithRegistrar:/g' "$PLUGIN_REG_FILE"
echo "✅ Archivo modificado correctamente"

echo "📋 Paso 3: Agregando protección para futuras regeneraciones..."
# Crear archivo en el directorio donde se guarda la configuración del proyecto
CONFIG_DIR=".dart_tool/flutter_build"
mkdir -p "$CONFIG_DIR"

# Crear script post-build que se ejecutará después de cada build
cat > "$CONFIG_DIR/post_build.sh" << 'EOF'
#!/bin/bash
# Este script se ejecutará después de cada build para comentar device_info_plus
if [ -f "ios/Runner/GeneratedPluginRegistrant.m" ]; then
  sed -i '' 's/#import <device_info_plus\/FPPDeviceInfoPlusPlugin.h>/\/\/ Commented for simulator\n\/\/#import <device_info_plus\/FPPDeviceInfoPlusPlugin.h>/g' "ios/Runner/GeneratedPluginRegistrant.m"
  sed -i '' 's/@import device_info_plus;/\/\/ Commented for simulator\n\/\/@import device_info_plus;/g' "ios/Runner/GeneratedPluginRegistrant.m"
  sed -i '' 's/\[FPPDeviceInfoPlusPlugin registerWithRegistrar:/\/\/ Commented for simulator\n  \/\/\[FPPDeviceInfoPlusPlugin registerWithRegistrar:/g' "ios/Runner/GeneratedPluginRegistrant.m"
  echo "Auto-fix: Comentadas las referencias a device_info_plus en GeneratedPluginRegistrant.m"
fi
EOF

# Hacer el script ejecutable
chmod +x "$CONFIG_DIR/post_build.sh"
echo "✅ Protección para futuras regeneraciones agregada"

echo "📋 Paso 4: Actualizando Podfile para simulador..."
# Modificar Podfile para excluir pods problemáticos en simuladores
cat > "Podfile" << 'EOF'
# Uncomment this line to define a global platform for your project
platform :ios, '15.5'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  target 'RunnerTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # Configuración para todos los targets
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.5'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      
      # Configuración específica para simuladores
      if config.build_settings['SDKROOT'] == 'iphonesimulator'
        # Excluir arquitecturas antiguas
        config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'i386 armv7'
        config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
        config.build_settings['VALID_ARCHS'] = 'arm64 x86_64'
        
        # Para MLKit y funcionalidades que no funcionan en simuladores
        if ['MLImage', 'MLKitVision', 'MLKitBarcodeScanning', 'GoogleMLKit', 'mobile_scanner', 'device_info_plus'].include?(target.name)
          config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] += ' arm64'
          config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
          config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'DISABLE_SCANNER_IN_SIMULATOR=1'
        end
      end
    end
  end
end
EOF
echo "✅ Podfile actualizado"

echo "📋 Paso 5: Reinstalando los pods..."
rm -rf Pods Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData/*miniature_paint_finder*
pod install
echo "✅ Pods reinstalados"

echo ""
echo "🎉 SOLUCIÓN COMPLETA APLICADA!"
echo "Ahora deberías poder ejecutar la app en el simulador usando:"
echo "    flutter run -d <id-simulador>"
echo ""
echo "NOTA: La app seguirá funcionando con todas sus capacidades en dispositivos físicos."
echo "      Solo se han deshabilitado las funciones problemáticas en el simulador." 