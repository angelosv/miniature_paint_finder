#!/bin/bash

# Script para configurar automáticamente el ambiente según la rama Git
set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Configurando ambiente automáticamente...${NC}"

# Obtener la rama actual
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo -e "${BLUE}📍 Rama actual: ${YELLOW}$CURRENT_BRANCH${NC}"

# Determinar el ambiente basado en la rama
if [[ "$CURRENT_BRANCH" == *"main"* ]] || [[ "$CURRENT_BRANCH" == *"master"* ]] || [[ "$CURRENT_BRANCH" == *"prod"* ]]; then
    ENV="production"
elif [[ "$CURRENT_BRANCH" == *"staging"* ]] || [[ "$CURRENT_BRANCH" == *"stage"* ]]; then
    ENV="staging"
elif [[ "$CURRENT_BRANCH" == *"qa"* ]] || [[ "$CURRENT_BRANCH" == *"test"* ]]; then
    ENV="qa"
else
    ENV="development"
fi

echo -e "${BLUE}🎯 Ambiente detectado: ${GREEN}$ENV${NC}"

# Verificar si existe el archivo de configuración
CONFIG_FILE="config/$ENV.env"
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}❌ Error: No se encontró el archivo de configuración $CONFIG_FILE${NC}"
    exit 1
fi

# Copiar el archivo de configuración
echo -e "${BLUE}📋 Copiando configuración desde $CONFIG_FILE...${NC}"
cp "$CONFIG_FILE" .env

# Mostrar la configuración aplicada
echo -e "${GREEN}✅ Configuración aplicada exitosamente:${NC}"
echo -e "${YELLOW}$(cat .env)${NC}"

echo -e "${GREEN}🚀 ¡Listo! La aplicación usará la configuración de $ENV${NC}"

