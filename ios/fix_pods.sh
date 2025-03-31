#!/bin/bash

# Script para corregir problemas de arquitectura en mobile_scanner para Apple Silicon
# Ejecutar después de cada 'pod install' o 'pod update'

PODSPEC_PATH="Pods/Local Podspecs/mobile_scanner.podspec.json"
PODFILE_PATH="Podfile"

echo "🛠️ Script de corrección de problemas de arquitectura para simuladores en Apple Silicon"
echo "----------------------------------------------------------------------"

# Paso 1: Corregir mobile_scanner
if [ -f "$PODSPEC_PATH" ]; then
  echo "✅ Corrigiendo configuración de arquitectura en mobile_scanner..."
  # Reemplaza la configuración de EXCLUDED_ARCHS para simuladores
  sed -i '' 's/"EXCLUDED_ARCHS\[sdk=iphonesimulator\*\]": "i386 armv7 arm64"/"EXCLUDED_ARCHS\[sdk=iphonesimulator\*\]": "i386 armv7"/g' "$PODSPEC_PATH"
  echo "   Configuración corregida en mobile_scanner.podspec.json"
else
  echo "❌ No se encontró el archivo podspec de mobile_scanner."
  echo "   Ejecute 'pod install' primero antes de usar este script."
fi

# Paso 2: Modificar Podfile para añadir configuración de MLImage
if [ -f "$PODFILE_PATH" ]; then
  echo "✅ Añadiendo configuración para MLImage en Podfile..."
  # Comprobar si la configuración ya existe
  if grep -q "config.build_settings\['ONLY_ACTIVE_ARCH'\] = 'YES'" "$PODFILE_PATH"; then
    echo "   La configuración ya existe en el Podfile."
  else
    # Añadir configuración de post_install si no existe
    if ! grep -q "post_install do |installer|" "$PODFILE_PATH"; then
      echo "" >> "$PODFILE_PATH"
      echo "post_install do |installer|" >> "$PODFILE_PATH"
      echo "  installer.pods_project.targets.each do |target|" >> "$PODFILE_PATH"
      echo "    target.build_configurations.each do |config|" >> "$PODFILE_PATH"
      echo "      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.5'" >> "$PODFILE_PATH"
      echo "      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'i386 armv7'" >> "$PODFILE_PATH"
      echo "      if config.name == 'Debug-iphonesimulator' || config.name == 'Release-iphonesimulator' || config.name == 'Profile-iphonesimulator'" >> "$PODFILE_PATH"
      echo "        config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'" >> "$PODFILE_PATH"
      echo "      end" >> "$PODFILE_PATH"
      echo "    end" >> "$PODFILE_PATH"
      echo "  end" >> "$PODFILE_PATH"
      echo "end" >> "$PODFILE_PATH"
      echo "   Configuración de post_install añadida al Podfile."
    else
      echo "   post_install ya existe en el Podfile. No se modificó."
    fi
  fi
else
  echo "❌ No se encontró el archivo Podfile."
fi

# Paso 3: Corregir problemas de MLImage compilando para la arquitectura activa
echo "✅ Corrigiendo configuración específica de MLImage para simuladores Apple Silicon..."

# Crear archivo de configuración específico para MLImage
MLIMAGE_FIX="Pods/MLImage/MLImage.xcodeproj/xcshareddata/xcschemes"
mkdir -p "$MLIMAGE_FIX"

# Crear archivo de esquema para forzar la arquitectura correcta
cat > "$MLIMAGE_FIX/MLImage.xcscheme" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1240"
   version = "1.3">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "4A275EFB74B5108E589AEEB7E8D5997B"
               BuildableName = "MLImage"
               BlueprintName = "MLImage"
               ReferencedContainer = "container:MLImage.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <BuildActionEntries>
      <BuildActionEntry
         buildForProfiling = "YES"
         buildForTesting = "YES"
         buildForRunning = "YES"
         buildForArchiving = "YES">
         <BuildableReference
            BuildableIdentifier = 'primary'
            BlueprintIdentifier = '4A275EFB74B5108E589AEEB7E8D5997B'
            BuildableName = 'MLImage'
            BlueprintName = 'MLImage'
            ReferencedContainer = 'container:MLImage.xcodeproj'>
         </BuildableReference>
      </BuildActionEntry>
   </BuildActionEntries>
   <TestAction
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES"
      buildConfiguration = "Debug">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      buildConfiguration = "Debug"
      allowLocationSimulation = "YES">
      <CommandLineArguments>
         <CommandLineArgument
            argument = ""
            isEnabled = "YES">
         </CommandLineArgument>
      </CommandLineArguments>
   </LaunchAction>
</Scheme>
EOF

echo "   Archivo de esquema creado para MLImage."

# Paso 4: Modificar la configuración del proyecto Pods
PODS_XCCONFIG="Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig"
if [ -f "$PODS_XCCONFIG" ]; then
  echo "✅ Modificando configuración de Pods para permitir arquitectura arm64 en simuladores..."
  # Agregar configuración para permitir arm64 en simuladores
  if ! grep -q "EXCLUDED_ARCHS[sdk=iphonesimulator*] =" "$PODS_XCCONFIG"; then
    echo "EXCLUDED_ARCHS[sdk=iphonesimulator*] = i386 armv7" >> "$PODS_XCCONFIG"
    echo "ONLY_ACTIVE_ARCH = YES" >> "$PODS_XCCONFIG"
    echo "   Configuración añadida a Pods-Runner.debug.xcconfig"
  else
    echo "   La configuración ya existe en el archivo xcconfig."
  fi
else
  echo "❌ No se encontró el archivo xcconfig de Pods-Runner."
fi

# Paso 5: Reinstalar los pods para aplicar los cambios
echo "✅ Reinstalando pods para aplicar todos los cambios..."
pod install

echo "----------------------------------------------------------------------"
echo "🎉 Proceso completado. Intenta compilar la aplicación nuevamente en el simulador."
echo "   Si persisten los problemas, prueba con: flutter clean && flutter pub get && cd ios && pod install && ./fix_pods.sh" 