#!/bin/bash

# Script para cambiar a la rama QA y configurar automáticamente
set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Cambiando a rama QA y configurando ambiente...${NC}"

# Verificar si la rama QA existe
if git show-ref --verify --quiet refs/heads/qa; then
    echo -e "${BLUE}📍 Cambiando a rama existente 'qa'${NC}"
    git checkout qa
else
    echo -e "${YELLOW}⚠️  Rama 'qa' no existe. Creándola desde la rama actual...${NC}"
    git checkout -b qa
fi

# Configurar automáticamente el ambiente
echo -e "${BLUE}🔧 Configurando ambiente para QA...${NC}"
cp config/qa.env .env

# Mostrar la configuración aplicada
echo -e "${GREEN}✅ Configuración QA aplicada:${NC}"
echo -e "${YELLOW}$(cat .env)${NC}"

echo -e "${GREEN}🚀 ¡Listo! Ahora estás en la rama QA con la configuración correcta${NC}"
echo -e "${BLUE}💡 Para volver a tu rama anterior, usa: git checkout -${NC}"
