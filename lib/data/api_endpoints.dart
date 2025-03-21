/// This file contains documentation for the recommended API endpoints
/// to be implemented by the backend service for the Miniature Paint Finder app.
/// 
/// NOTE: This is not actual code, but a specification document for backend developers.

/*
========================================================================
                          API ENDPOINTS DOCUMENTATION
========================================================================

BASE URL: https://api.miniature-paint-finder.com/v1

AUTHENTICATION:
- All endpoints require an API key sent in the header:
  "X-API-Key": "your_api_key_here"
- User-specific endpoints require a JWT token:
  "Authorization": "Bearer your_jwt_token_here"

========================================================================
                          PAINT RELATED ENDPOINTS
========================================================================

1. GET /paints
   Description: Get a list of all paints, with optional filtering
   Query Parameters:
     - brand: Filter by brand name (e.g., "Citadel", "Vallejo")
     - category: Filter by category (e.g., "Base", "Layer", "Model Color")
     - search: Search term for paint names
     - limit: Maximum number of results (default: 50)
     - offset: Pagination offset (default: 0)
   Response Example:
   {
     "total": 1500,
     "offset": 0,
     "limit": 50,
     "paints": [
       {
         "id": "cit-base-001",
         "name": "Abaddon Black",
         "brand": "Citadel",
         "colorHex": "#231F20",
         "category": "Base",
         "isMetallic": false,
         "isTransparent": false,
         "colorCode": "001", 
         "barcode": "5011921026340",
         "imageUrl": "https://cdn.miniature-paint-finder.com/paints/cit-base-001.jpg"
       },
       // More paints...
     ]
   }

2. GET /paints/{paintId}
   Description: Get detailed information about a specific paint
   Response Example:
   {
     "id": "cit-base-001",
     "name": "Abaddon Black",
     "brand": "Citadel",
     "colorHex": "#231F20",
     "category": "Base",
     "isMetallic": false,
     "isTransparent": false,
     "colorCode": "001",
     "barcode": "5011921026340",
     "imageUrl": "https://cdn.miniature-paint-finder.com/paints/cit-base-001.jpg",
     "description": "A solid black basecoat paint with excellent coverage.",
     "relatedPaints": [
       {
         "id": "val-model-002",
         "name": "German Grey",
         "brand": "Vallejo",
         "colorHex": "#2A3439",
         "similarity": 92
       },
       // More related paints...
     ]
   }

3. GET /brands
   Description: Get a list of all paint brands
   Response Example:
   {
     "brands": [
       {
         "id": "citadel",
         "name": "Citadel",
         "logo": "https://cdn.miniature-paint-finder.com/brands/citadel.png"
       },
       {
         "id": "vallejo",
         "name": "Vallejo",
         "logo": "https://cdn.miniature-paint-finder.com/brands/vallejo.png"
       },
       // More brands...
     ]
   }

4. POST /match-color
   Description: Find paints that match a given color
   Request Body:
   {
     "color": "#FF5733",  // Hex color to match
     "brands": ["Citadel", "Vallejo"],  // Optional: brands to search within
     "threshold": 75  // Optional: minimum match percentage (0-100)
   }
   Response Example:
   {
     "matches": [
       {
         "id": "cit-layer-023",
         "name": "Troll Slayer Orange",
         "brand": "Citadel",
         "colorHex": "#FF5D2A",
         "category": "Layer",
         "match": 95,
         "colorCode": "023",
         "barcode": "5011921027255",
         "imageUrl": "https://cdn.miniature-paint-finder.com/paints/cit-layer-023.jpg"
       },
       // More matching paints...
     ]
   }

5. POST /extract-colors
   Description: Extract dominant colors from an uploaded image
   Request Body:
     - Multipart form with an "image" field containing the image file
     - Optional "maxColors" field (default: 5) for maximum number of colors to extract
   Response Example:
   {
     "colors": [
       {
         "hex": "#FF5733",
         "rgb": {"r": 255, "g": 87, "b": 51},
         "proportion": 0.35
       },
       // More colors...
     ]
   }

========================================================================
                          USER RELATED ENDPOINTS
========================================================================

1. POST /auth/register
   Description: Register a new user
   Request Body:
   {
     "email": "user@example.com",
     "password": "securepassword",
     "name": "John Doe"
   }
   Response Example:
   {
     "userId": "user-123",
     "token": "jwt_token_here",
     "name": "John Doe",
     "email": "user@example.com"
   }

2. POST /auth/login
   Description: Log in an existing user
   Request Body:
   {
     "email": "user@example.com",
     "password": "securepassword"
   }
   Response Example:
   {
     "userId": "user-123",
     "token": "jwt_token_here",
     "name": "John Doe"
   }

3. GET /user/palettes
   Description: Get a user's saved palettes (authenticated)
   Query Parameters:
     - limit: Maximum number of results (default: 20)
     - offset: Pagination offset (default: 0)
   Response Example:
   {
     "total": 42,
     "offset": 0,
     "limit": 20,
     "palettes": [
       {
         "id": "palette-001",
         "name": "Space Marine Ultramarines",
         "imageUrl": "https://cdn.miniature-paint-finder.com/user-palettes/user-123/palette-001.jpg",
         "colors": [
           "#0D407F",
           "#231F20",
           "#C0C0C0"
         ],
         "paintSelections": [
           {
             "colorHex": "#0D407F",
             "paintId": "cit-base-003",
             "paintName": "Macragge Blue"
           },
           // More paint selections...
         ],
         "createdAt": "2023-03-15T10:30:00Z"
       },
       // More palettes...
     ]
   }

4. POST /user/palettes
   Description: Save a new palette (authenticated)
   Request Body:
   {
     "name": "My Blood Angels",
     "colors": [
       "#9A1115",
       "#231F20",
       "#85714D"
     ],
     "paintSelections": [
       {
         "colorHex": "#9A1115",
         "paintId": "cit-base-002",
         "paintName": "Mephiston Red"
       },
       // More paint selections (optional)...
     ],
     "image": "base64_encoded_image" // Optional
   }
   Response Example:
   {
     "id": "palette-042",
     "name": "My Blood Angels",
     "imageUrl": "https://cdn.miniature-paint-finder.com/user-palettes/user-123/palette-042.jpg",
     "createdAt": "2023-03-21T14:22:00Z"
   }

5. DELETE /user/palettes/{paletteId}
   Description: Delete a palette (authenticated)
   Response Example:
   {
     "success": true
   }

========================================================================
                          INVENTORY RELATED ENDPOINTS
========================================================================

1. GET /user/inventory
   Description: Get a user's paint inventory (authenticated)
   Query Parameters:
     - brand: Filter by brand name
     - category: Filter by category
     - search: Search term for paint names
   Response Example:
   {
     "inventory": [
       {
         "paintId": "cit-base-001",
         "name": "Abaddon Black",
         "brand": "Citadel",
         "colorHex": "#231F20",
         "addedAt": "2023-01-15T10:30:00Z",
         "quantity": 1,
         "status": "owned"
       },
       {
         "paintId": "val-model-003",
         "name": "Silver",
         "brand": "Vallejo",
         "colorHex": "#C0C0C0",
         "addedAt": "2023-02-20T08:15:00Z",
         "quantity": 2,
         "status": "wishlist"
       },
       // More inventory items...
     ]
   }

2. POST /user/inventory
   Description: Add a paint to inventory (authenticated)
   Request Body:
   {
     "paintId": "cit-base-001",
     "quantity": 1,
     "status": "owned"  // "owned" or "wishlist"
   }
   Response Example:
   {
     "success": true,
     "inventoryItem": {
       "paintId": "cit-base-001",
       "name": "Abaddon Black",
       "brand": "Citadel",
       "colorHex": "#231F20",
       "addedAt": "2023-03-21T14:30:00Z",
       "quantity": 1,
       "status": "owned"
     }
   }

3. PUT /user/inventory/{paintId}
   Description: Update a paint in inventory (authenticated)
   Request Body:
   {
     "quantity": 2,
     "status": "owned"
   }
   Response Example:
   {
     "success": true
   }

4. DELETE /user/inventory/{paintId}
   Description: Remove a paint from inventory (authenticated)
   Response Example:
   {
     "success": true
   }

*/ 