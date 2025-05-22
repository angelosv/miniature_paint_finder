#!/bin/bash

# Configuración de las versiones
MARKETING_VERSION="1.0.4"
CURRENT_PROJECT_VERSION="3"

# Actualizar el archivo del proyecto de Xcode
sed -i '' 's/MARKETING_VERSION = [^;]*;/MARKETING_VERSION = '"$MARKETING_VERSION"';/g' Runner.xcodeproj/project.pbxproj
sed -i '' 's/CURRENT_PROJECT_VERSION = [^;]*;/CURRENT_PROJECT_VERSION = '"$CURRENT_PROJECT_VERSION"';/g' Runner.xcodeproj/project.pbxproj

# Actualizar el Info.plist directamente con valores concretos en lugar de variables
PLIST_FILE="Runner/Info.plist"
plutil -replace CFBundleShortVersionString -string "$MARKETING_VERSION" "$PLIST_FILE"
plutil -replace CFBundleVersion -string "$CURRENT_PROJECT_VERSION" "$PLIST_FILE"

echo "✅ Versiones actualizadas a $MARKETING_VERSION ($CURRENT_PROJECT_VERSION)" 