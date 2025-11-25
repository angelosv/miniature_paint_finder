# 🔧 Environment Setup Guide

Este documento explica cómo funciona el nuevo sistema de configuración automática de ambientes basado en ramas Git.

## 🎯 ¿Qué se implementó?

### ✅ **Sistema Completo de Variables de Entorno**

1. **Detección automática de ambiente** basada en rama Git
2. **Configuración por archivos** específicos para cada ambiente
3. **Scripts automatizados** para cambio de configuración
4. **Prioridad de configuración** bien definida
5. **Soporte completo** para todos los servicios de la app

### ✅ **Ambientes Soportados**

| Ambiente | Ramas Git | URL API | Descripción |
|----------|-----------|---------|-------------|
| **Production** | `main`, `master`, `*prod*` | `https://paints-api.reachu.io/api` | Ambiente de producción |
| **Staging** | `*staging*`, `*stage*` | `https://staging-paints-api.reachu.io/api` | Ambiente de staging |
| **QA** | `*qa*`, `*test*` | `https://paints-api.reachu.io/qa-api` | Ambiente de QA/testing |
| **Development** | Todas las demás | `https://paints-api.reachu.io/qa-api` | Ambiente de desarrollo |

## 🚀 Uso Diario

### **Configuración Automática (Recomendado)**

```bash
# Ejecutar cada vez que cambies de rama
./scripts/setup_env.sh
```

### **Cambio Rápido a QA**

```bash
# Cambiar a rama QA y configurar automáticamente
./scripts/switch_to_qa.sh
```

### **Configuración Manual**

```bash
# Para QA
cp config/qa.env .env

# Para producción  
cp config/production.env .env

# Para staging
cp config/staging.env .env

# Para desarrollo
cp config/development.env .env
```

## 🔍 Verificación

### **Ver Configuración Actual**

La configuración se muestra automáticamente en los logs de inicio:

```
🔧 App Configuration:
  Environment: Environment.development
  Git Branch: feature/projects-offline-cache
  API Base URL: https://paints-api.reachu.io/qa-api
  Debug Mode: true
  Cache TTL: 1800s
  Sync Interval: 30s
  Session Replay: true (100%)
  Logging: true
```

### **Verificar Variables de Entorno**

```bash
# Ver archivo actual
cat .env

# Ver configuración específica
cat config/qa.env
```

## ⚙️ Variables Disponibles

### **Configuración Principal**

- `ENVIRONMENT`: `development`, `qa`, `staging`, `production`
- `API_BASE_URL`: URL base para llamadas API
- `DEBUG_MODE`: `true`/`false` - Modo debug
- `MIXPANEL_TOKEN`: Token de Mixpanel

### **Configuración de Cache**

- `CACHE_TTL`: Tiempo de vida del cache (segundos)
- `SYNC_INTERVAL`: Intervalo de sincronización (segundos)

### **Configuración de Session Replay**

- `SESSION_REPLAY_ENABLED`: `true`/`false`
- `SESSION_REPLAY_SAMPLING_RATE`: Porcentaje de sampling (0-100)

## 🔄 Prioridad de Configuración

1. **Build-time defines** (máxima prioridad)
2. **Variables en `.env`**
3. **Variables específicas por ambiente** (ej: `QA_API_URL`)
4. **Valores por defecto** (mínima prioridad)

## 📁 Estructura de Archivos

```
miniature_paint_finder/
├── .env                    # Configuración activa (generado automáticamente)
├── env.template           # Plantilla de configuración
├── config/
│   ├── development.env    # Configuración de desarrollo
│   ├── qa.env            # Configuración de QA
│   ├── staging.env       # Configuración de staging
│   └── production.env    # Configuración de producción
└── scripts/
    ├── setup_env.sh      # Script de configuración automática
    └── switch_to_qa.sh   # Script de cambio rápido a QA
```

## 🎯 Casos de Uso Comunes

### **Trabajando en Feature Branch**

```bash
# Tu rama: feature/new-feature
./scripts/setup_env.sh
# → Configura automáticamente como 'development'
# → Usa QA API para testing
```

### **Testing en QA**

```bash
# Cambiar a QA
./scripts/switch_to_qa.sh
# → Cambia a rama 'qa' (o la crea)
# → Configura automáticamente QA environment
# → Usa QA API
```

### **Deploy a Producción**

```bash
# En rama main/master
./scripts/setup_env.sh
# → Configura automáticamente como 'production'
# → Usa Production API
```

## ✅ **Estado Actual**

- ✅ **Sistema implementado y funcionando**
- ✅ **Detección automática por rama Git**
- ✅ **Todos los servicios actualizados**
- ✅ **Scripts de automatización creados**
- ✅ **Documentación completa**

## 🔧 **Próximos Pasos**

1. **Usar `./scripts/setup_env.sh`** cada vez que cambies de rama
2. **Verificar logs de inicio** para confirmar configuración
3. **Crear rama QA** cuando sea necesario con `./scripts/switch_to_qa.sh`

¡El sistema está listo para uso en producción! 🚀
