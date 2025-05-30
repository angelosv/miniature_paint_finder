# Sistema de Cache Offline para Inventario

## 🎯 Objetivo

Implementar un sistema de cache inteligente offline-first para el inventario que permita:
- **Funcionalidad sin internet**: El inventario funciona completamente offline
- **Sincronización automática**: Los cambios se sincronizan cuando hay conexión
- **Actualizaciones optimistas**: Los cambios se ven inmediatamente en la UI
- **Resolución de conflictos**: Manejo básico de conflictos con "last-write-wins"

## 📁 Archivos Implementados

### 1. `lib/services/inventory_cache_service.dart`
**Servicio principal de cache offline-first**

#### Características principales:
- **Cache persistente local** con TTL de 30 minutos
- **Queue de operaciones pendientes** para cambios offline
- **Detección de conectividad** automática
- **Sincronización en background** cada 5 minutos
- **Optimistic updates** para respuesta inmediata de la UI

#### Métodos públicos:
```dart
// Obtener inventario (cache-first)
Future<List<PaintInventoryItem>> getInventory({
  bool forceRefresh = false,
  int limit = 10,
  int page = 1,
  String? searchQuery,
  bool? onlyInStock,
  String? brand,
  String? category,
})

// Operaciones CRUD con optimistic updates
Future<bool> addInventoryItem(String brandId, String paintId, int quantity, {String? notes})
Future<bool> updateInventoryItem(String inventoryId, int quantity, {String? notes})
Future<bool> deleteInventoryItem(String inventoryId)

// Gestión manual
Future<void> forcSync()
Future<void> clearCache()
```

#### Estados expuestos:
```dart
bool get isInitialized
bool get isSyncing
bool get hasConnection
bool get hasPendingOperations
int get pendingOperationsCount
```

### 2. `lib/main.dart` (Actualizado)
**Inicialización y providers**

- Agregado `InventoryCacheService` como provider
- Inicialización en background para no bloquear startup
- Integración con `InventoryService` existente

### 3. `lib/screens/inventory_screen.dart` (Actualizado)
**Integración transparente con la UI**

#### Características añadidas:
- **Indicador de estado de conexión** en tiempo real
- **Fallback automático** al API directo si el cache no está listo
- **Actualizaciones optimistas** para stock y notas
- **Botón de sincronización manual** cuando hay operaciones pendientes

#### Indicadores visuales:
- 🟢 **Online**: Conectado y sincronizado
- 🟠 **Offline**: Sin conexión, usando cache local
- 🔵 **Syncing**: Sincronizando en progreso
- 🟡 **Sync pending**: Operaciones pendientes (con contador)

## 🔄 Flujo de Funcionamiento

### 1. Carga de Datos
```
1. InventoryScreen solicita datos
2. InventoryCacheService verifica:
   - ¿Cache válido? → Retorna cache
   - ¿Sin conexión? → Retorna cache expirado
   - ¿Necesita refresh? → Carga del API y actualiza cache
3. UI se actualiza inmediatamente
```

### 2. Modificaciones (Optimistic Updates)
```
1. Usuario modifica inventario (stock/notas/eliminación)
2. InventoryCacheService:
   - Actualiza cache local inmediatamente
   - Agrega operación a queue pendientes
   - Notifica cambios a la UI
3. UI se actualiza al instante
4. En background: sincroniza con API cuando hay conexión
```

### 3. Sincronización Automática
```
1. Timer cada 5 minutos verifica operaciones pendientes
2. Listener de conectividad detecta reconexión
3. Procesa queue de operaciones en orden
4. Actualiza cache con datos del servidor
5. Remueve operaciones completadas
```

## 📊 Métricas y Monitoreo

### Analytics Integrados
El sistema trackea automáticamente:
- **Tiempo de carga** con/sin cache
- **Uso de cache vs API directo**
- **Estado de conectividad**
- **Número de operaciones pendientes**
- **Errores de sincronización**

### Estados de Debug
```dart
// Información disponible para debugging
cacheService.isInitialized
cacheService.isSyncing  
cacheService.hasConnection
cacheService.pendingOperationsCount
cacheService.cachedInventory?.length
```

## 🔧 Configuración

### TTL y Intervals
```dart
// En InventoryCacheService
static const int _inventoryCacheTTL = 30; // 30 minutos
static const int _syncRetryInterval = 5;  // 5 minutos
```

### Claves de Cache
```dart
static const String _keyInventoryItems = 'inventory_cache_items';
static const String _keyPendingOperations = 'inventory_cache_pending_ops';
static const String _keyLastSyncTimestamp = 'inventory_cache_last_sync';
static const String _keyInventoryTimestamp = 'inventory_cache_timestamp';
```

## 🚀 Beneficios Obtenidos

### 1. Experiencia de Usuario
- ✅ **Funciona sin internet**: Inventario completamente funcional offline
- ✅ **Respuesta inmediata**: Cambios visibles al instante
- ✅ **Transparencia**: Indicadores claros del estado de sincronización
- ✅ **Recuperación automática**: Sincroniza automáticamente al reconectar

### 2. Performance
- ✅ **Carga instantánea**: Cache local elimina latencia de red
- ✅ **Reducción de llamadas API**: Solo actualiza cuando es necesario
- ✅ **Batching**: Agrupa operaciones para eficiencia

### 3. Robustez
- ✅ **Tolerancia a fallos**: Continúa funcionando sin conexión
- ✅ **Consistencia eventual**: Los datos se sincronizan automáticamente
- ✅ **Recuperación**: Reintenta operaciones fallidas automáticamente

## 🔄 Casos de Uso Típicos

### Escenario 1: Usuario Offline
```
1. Usuario abre app sin internet
2. Ve su inventario desde cache local
3. Modifica cantidades y notas
4. Cambios se guardan localmente
5. Al reconectar, todo se sincroniza automáticamente
```

### Escenario 2: Conexión Intermitente
```
1. Usuario trabaja con conexión inestable
2. Modificaciones se hacen optimísticamente
3. Sistema reintenta sincronización automáticamente
4. Indicador muestra operaciones pendientes
5. Usuario puede forzar sync manualmente
```

### Escenario 3: Múltiples Dispositivos
```
1. Usuario modifica en dispositivo A
2. Cambios se sincronizan al servidor
3. Usuario abre dispositivo B
4. Cache se actualiza con cambios del servidor
5. Ambos dispositivos quedan sincronizados
```

## 📱 Consideraciones Técnicas

### Dependencias Añadidas
```yaml
dependencies:
  connectivity_plus: ^6.1.0  # Detección de conectividad
```

### Limitaciones Actuales
- **Resolución de conflictos**: Usa "last-write-wins" simple
- **Operación UPDATE**: Requiere implementación completa en API
- **Sincronización masiva**: No optimizada para inventarios muy grandes

### Próximas Mejoras
- [ ] Resolución de conflictos más sofisticada
- [ ] Compresión de cache para inventarios grandes
- [ ] Sincronización incremental (delta sync)
- [ ] Backup automático de operaciones pendientes
- [ ] Métricas de uso de cache más detalladas

## 🧪 Testing

### Pruebas Recomendadas
1. **Offline complete**: Usar app completamente sin internet
2. **Reconnection**: Desconectar y reconectar durante uso
3. **Background sync**: Dejar app en background y verificar sincronización
4. **Data corruption**: Limpiar cache y verificar recarga
5. **Concurrent changes**: Modificar desde múltiples dispositivos

### Monitoreo en Producción
- Trackear ratio cache-hit vs API calls
- Monitorear errores de sincronización
- Medir tiempo de recuperación post-conexión
- Analizar patrones de uso offline

### ✅ **Operaciones Soportadas**:
- **Agregar items**: `addInventoryItem()` - ✅ Implementado
- **Actualizar stock/notas**: `updateInventoryItem()` - ✅ Implementado  
- **Eliminar items**: `deleteInventoryItem()` - ✅ Implementado
- **Obtener inventario**: `getInventory()` - ✅ Implementado

### 📱 **Flujo de Eliminación Optimista**:
1. **Usuario desliza para eliminar** item del inventario
2. **Confirmación**: Dialog de confirmación estándar
3. **Update optimista**: Item se remueve inmediatamente de la UI
4. **Background sync**: Operación se envía al servidor por detrás
5. **Error handling**: Si falla, recarga inventario para restaurar UI

### 🔧 **Integración Completa**:
- **InventoryScreen**: Dismissible widgets con eliminación optimista
- **LibraryScreen**: Agregar pinturas desde library
- **BarcodeScannerScreen**: Agregar pinturas desde scanner  
- **WishlistScreen**: Mover de wishlist a inventario
- **PaintCard**: Acciones rápidas de inventario

---

**Estado**: ✅ Implementado y funcional
**Versión**: 1.0
**Última actualización**: Diciembre 2024 