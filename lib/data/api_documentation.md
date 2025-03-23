# Documentación de API para Miniature Paint Finder

Esta documentación proporciona detalles sobre los endpoints de API requeridos para el funcionamiento correcto de la aplicación Miniature Paint Finder.

## Base URL

```
https://api.miniature-paint-finder.com/v1
```

## Autenticación

Todos los endpoints requieren autenticación mediante un token JWT en el encabezado de la solicitud:

```
Authorization: Bearer <token>
```

## Endpoints de Pinturas

### Obtener todas las pinturas

```
GET /paints
```

**Parámetros de consulta opcionales:**
- `brand` - Filtrar por marca (ej. "Citadel", "Vallejo")
- `category` - Filtrar por categoría (ej. "Base", "Layer")
- `query` - Buscar por texto en nombre y marca
- `limit` - Número máximo de resultados (predeterminado: 50)
- `offset` - Desplazamiento para paginación (predeterminado: 0)

**Ejemplo de respuesta:**
```json
{
  "total": 1500,
  "limit": 50,
  "offset": 0,
  "paints": [
    {
      "id": "cit-base-001",
      "name": "Abaddon Black",
      "brand": "Citadel",
      "colorHex": "#231F20",
      "category": "Base",
      "isMetallic": false,
      "isTransparent": false
    },
    // Más pinturas...
  ]
}
```

### Obtener una pintura por ID

```
GET /paints/{id}
```

**Ejemplo de respuesta:**
```json
{
  "id": "cit-base-001",
  "name": "Abaddon Black",
  "brand": "Citadel",
  "colorHex": "#231F20",
  "category": "Base",
  "isMetallic": false,
  "isTransparent": false,
  "description": "Una pintura negra base con excelente cobertura.",
  "equivalentPaints": [
    {
      "id": "val-model-002",
      "name": "German Grey",
      "brand": "Vallejo",
      "colorHex": "#2A3439",
      "similarity": 92
    }
  ]
}
```

### Buscar pinturas por color

```
GET /paints/by-color
```

**Parámetros de consulta:**
- `hex` - Código de color hexadecimal (ej. "#FF0000")
- `threshold` - Umbral de similitud de 0 a 1 (predeterminado: 0.1)
- `limit` - Número máximo de resultados (predeterminado: 20)

**Ejemplo de respuesta:**
```json
{
  "matches": [
    {
      "id": "cit-layer-023",
      "name": "Troll Slayer Orange",
      "brand": "Citadel",
      "colorHex": "#FF5D2A",
      "category": "Layer",
      "similarity": 0.95
    },
    // Más coincidencias...
  ]
}
```

### Buscar pinturas por marca

```
GET /paints/by-brand
```

**Parámetros de consulta:**
- `brand` - Nombre de la marca (ej. "Citadel")
- `limit` - Número máximo de resultados (predeterminado: 50)
- `offset` - Desplazamiento para paginación (predeterminado: 0)

**Ejemplo de respuesta:**
```json
{
  "total": 120,
  "limit": 50,
  "offset": 0,
  "paints": [
    // Lista de pinturas de la marca especificada
  ]
}
```

### Buscar pinturas por categoría

```
GET /paints/by-category
```

**Parámetros de consulta:**
- `category` - Nombre de la categoría (ej. "Base", "Layer")
- `limit` - Número máximo de resultados (predeterminado: 50)
- `offset` - Desplazamiento para paginación (predeterminado: 0)

**Ejemplo de respuesta:**
```json
{
  "total": 45,
  "limit": 50,
  "offset": 0,
  "paints": [
    // Lista de pinturas de la categoría especificada
  ]
}
```

### Buscar pinturas por código de barras

```
GET /paints/by-barcode
```

**Parámetros de consulta:**
- `code` - Código de barras escaneado

**Ejemplo de respuesta:**
```json
{
  "id": "cit-base-001",
  "name": "Abaddon Black",
  "brand": "Citadel",
  "colorHex": "#231F20",
  "category": "Base",
  "isMetallic": false,
  "isTransparent": false
}
```

### Búsqueda de texto

```
GET /paints/search
```

**Parámetros de consulta:**
- `q` - Texto de búsqueda
- `limit` - Número máximo de resultados (predeterminado: 20)

**Ejemplo de respuesta:**
```json
{
  "total": 12,
  "paints": [
    // Lista de pinturas que coinciden con la búsqueda
  ]
}
```

## Endpoints de Usuario

### Registrar nuevo usuario

```
POST /auth/register
```

**Cuerpo de la solicitud:**
```json
{
  "email": "usuario@ejemplo.com",
  "password": "contraseñaSegura",
  "name": "Nombre Usuario"
}
```

**Ejemplo de respuesta:**
```json
{
  "userId": "user-123",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "name": "Nombre Usuario",
  "email": "usuario@ejemplo.com"
}
```

### Iniciar sesión

```
POST /auth/login
```

**Cuerpo de la solicitud:**
```json
{
  "email": "usuario@ejemplo.com",
  "password": "contraseñaSegura"
}
```

**Ejemplo de respuesta:**
```json
{
  "userId": "user-123",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "name": "Nombre Usuario"
}
```

## Endpoints de Paletas

### Obtener paletas del usuario

```
GET /user/palettes
```

**Parámetros de consulta opcionales:**
- `limit` - Número máximo de resultados (predeterminado: 20)
- `offset` - Desplazamiento para paginación (predeterminado: 0)

**Ejemplo de respuesta:**
```json
{
  "total": 8,
  "limit": 20,
  "offset": 0,
  "palettes": [
    {
      "id": "palette-001",
      "name": "Space Marine Ultramarines",
      "imageUrl": "https://cdn.example.com/palettes/user-123/palette-001.jpg",
      "colors": ["#0D407F", "#231F20", "#C0C0C0"],
      "paintSelections": [
        {
          "colorHex": "#0D407F",
          "paintId": "cit-base-003",
          "paintName": "Macragge Blue",
          "paintBrand": "Citadel"
        }
      ],
      "createdAt": "2023-03-15T10:30:00Z"
    },
    // Más paletas...
  ]
}
```

### Crear nueva paleta

```
POST /user/palettes
```

**Cuerpo de la solicitud:**
```json
{
  "name": "Mi Blood Angels",
  "colors": ["#9A1115", "#231F20", "#85714D"],
  "paintSelections": [
    {
      "colorHex": "#9A1115",
      "paintId": "cit-base-002"
    }
  ],
  "image": "base64_encoded_image" // Opcional
}
```

**Ejemplo de respuesta:**
```json
{
  "id": "palette-123",
  "name": "Mi Blood Angels",
  "imageUrl": "https://cdn.example.com/palettes/user-123/palette-123.jpg",
  "createdAt": "2023-03-21T14:22:00Z"
}
```

### Actualizar paleta

```
PUT /user/palettes/{id}
```

**Cuerpo de la solicitud:**
```json
{
  "name": "Mi Blood Angels V2",
  "colors": ["#9A1115", "#231F20", "#85714D", "#D6D5C3"],
  "paintSelections": [
    {
      "colorHex": "#9A1115",
      "paintId": "cit-base-002"
    },
    {
      "colorHex": "#D6D5C3",
      "paintId": "cit-layer-001"
    }
  ]
}
```

**Ejemplo de respuesta:**
```json
{
  "id": "palette-123",
  "name": "Mi Blood Angels V2",
  "imageUrl": "https://cdn.example.com/palettes/user-123/palette-123.jpg",
  "updatedAt": "2023-03-22T10:15:00Z"
}
```

### Eliminar paleta

```
DELETE /user/palettes/{id}
```

**Ejemplo de respuesta:**
```json
{
  "success": true
}
```

### Agregar pintura a paleta

```
POST /user/palettes/{paletteId}/paints
```

**Cuerpo de la solicitud:**
```json
{
  "paintId": "cit-layer-001",
  "colorHex": "#D6D5C3"
}
```

**Ejemplo de respuesta:**
```json
{
  "success": true,
  "paletteId": "palette-123",
  "paintId": "cit-layer-001"
}
```

### Eliminar pintura de paleta

```
DELETE /user/palettes/{paletteId}/paints/{paintId}
```

**Ejemplo de respuesta:**
```json
{
  "success": true
}
```

## Endpoints de Inventario

### Obtener inventario del usuario

```
GET /user/inventory
```

**Parámetros de consulta opcionales:**
- `limit` - Número máximo de resultados (predeterminado: 50)
- `offset` - Desplazamiento para paginación (predeterminado: 0)

**Ejemplo de respuesta:**
```json
{
  "total": 42,
  "limit": 50,
  "offset": 0,
  "items": [
    {
      "paintId": "cit-base-001",
      "quantity": 1,
      "notes": "Casi vacío, comprar nuevo",
      "updatedAt": "2023-03-10T15:20:00Z",
      "paint": {
        "id": "cit-base-001",
        "name": "Abaddon Black",
        "brand": "Citadel",
        "colorHex": "#231F20",
        "category": "Base"
      }
    },
    // Más items...
  ]
}
```

### Agregar pintura al inventario

```
POST /user/inventory
```

**Cuerpo de la solicitud:**
```json
{
  "paintId": "cit-layer-001",
  "quantity": 1,
  "notes": "Nuevo, comprado el 15/03"
}
```

**Ejemplo de respuesta:**
```json
{
  "paintId": "cit-layer-001",
  "quantity": 1,
  "notes": "Nuevo, comprado el 15/03",
  "updatedAt": "2023-03-21T14:22:00Z"
}
```

### Actualizar cantidad o notas de inventario

```
PUT /user/inventory/{paintId}
```

**Cuerpo de la solicitud:**
```json
{
  "quantity": 2,
  "notes": "Compré otro"
}
```

**Ejemplo de respuesta:**
```json
{
  "paintId": "cit-layer-001",
  "quantity": 2,
  "notes": "Compré otro",
  "updatedAt": "2023-03-22T10:15:00Z"
}
```

### Eliminar pintura del inventario

```
DELETE /user/inventory/{paintId}
```

**Ejemplo de respuesta:**
```json
{
  "success": true
}
```

## Endpoints de Wishlist

### Obtener wishlist del usuario

```
GET /user/wishlist
```

**Parámetros de consulta opcionales:**
- `limit` - Número máximo de resultados (predeterminado: 50)
- `offset` - Desplazamiento para paginación (predeterminado: 0)

**Ejemplo de respuesta:**
```json
{
  "total": 15,
  "limit": 50,
  "offset": 0,
  "items": [
    {
      "paintId": "cit-base-005",
      "addedAt": "2023-03-10T15:20:00Z",
      "paint": {
        "id": "cit-base-005",
        "name": "Retributor Armour",
        "brand": "Citadel",
        "colorHex": "#85714D",
        "category": "Base"
      }
    },
    // Más items...
  ]
}
```

### Agregar pintura a la wishlist

```
POST /user/wishlist
```

**Cuerpo de la solicitud:**
```json
{
  "paintId": "cit-shade-001"
}
```

**Ejemplo de respuesta:**
```json
{
  "paintId": "cit-shade-001",
  "addedAt": "2023-03-21T14:22:00Z"
}
```

### Eliminar pintura de la wishlist

```
DELETE /user/wishlist/{paintId}
```

**Ejemplo de respuesta:**
```json
{
  "success": true
}
```

## Códigos de estado

- 200 OK - La solicitud se completó con éxito
- 201 Created - El recurso se creó correctamente
- 400 Bad Request - La solicitud contiene parámetros inválidos
- 401 Unauthorized - Autenticación requerida o inválida
- 403 Forbidden - El usuario no tiene permiso para acceder al recurso
- 404 Not Found - El recurso solicitado no existe
- 500 Internal Server Error - Error del servidor

## Límites de tarifa

Para evitar el abuso de la API, se aplican límites de tarifa:

- 60 solicitudes por minuto por usuario autenticado
- 10 solicitudes por minuto para solicitudes no autenticadas

Las respuestas incluirán los siguientes encabezados:
- `X-RateLimit-Limit`: Número máximo de solicitudes permitidas
- `X-RateLimit-Remaining`: Número de solicitudes restantes
- `X-RateLimit-Reset`: Tiempo (en segundos) hasta que se restablezca el límite 