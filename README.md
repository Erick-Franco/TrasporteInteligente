# API de Transporte Inteligente - Backend

Este backend proporciona endpoints REST para acceder a la información de rutas de transporte, incluyendo sus coordenadas y paradas.

## Endpoints Disponibles

### Rutas

#### GET `/api/rutas`
Obtiene todas las rutas activas con información básica.

```json
{
  "success": true,
  "count": 2,
  "data": [
    {
      "id": 1,
      "nombre": "L31_SPEEDY_V_DE_COPACABANA",
      "descripcion": "Ruta Speedy V de Copacabana",
      "color": "#009688",
      "total_buses": 3,
      "total_paradas": 12
    }
  ]
}
```

#### GET `/api/rutas/:rutaId`
Obtiene detalles de una ruta específica incluyendo sus paradas.

```json
{
  "success": true,
  "data": {
    "id": 1,
    "nombre": "L31_SPEEDY_V_DE_COPACABANA",
    "descripcion": "Ruta Speedy V de Copacabana",
    "color": "#009688",
    "paradas": [
      {
        "id": 1,
        "nombre": "Terminal Central",
        "latitud": -16.123456,
        "longitud": -68.123456,
        "orden": 1,
        "tiempo_estimado": 0
      }
    ]
  }
}
```

#### GET `/api/rutas/:rutaId/coordenadas`
Obtiene las coordenadas de una ruta específica en formato GeoJSON.

```json
{
  "success": true,
  "data": {
    "type": "Feature",
    "properties": {
      "id": 1,
      "nombre": "L31_SPEEDY_V_DE_COPACABANA",
      "total_coordenadas": 146
    },
    "geometry": {
      "type": "LineString",
      "coordinates": [
        [-68.123456, -16.123456],
        [-68.123457, -16.123457]
      ]
    }
  }
}
```

#### GET `/api/rutas/geojson`
Obtiene todas las rutas activas en formato GeoJSON, útil para visualización en mapas.

```json
{
  "success": true,
  "data": {
    "type": "FeatureCollection",
    "features": [
      {
        "type": "Feature",
        "properties": {
          "id": 1,
          "nombre": "L31_SPEEDY_V_DE_COPACABANA",
          "color": "#009688",
          "total_coordenadas": 146
        },
        "geometry": {
          "type": "LineString",
          "coordinates": [...]
        }
      }
    ]
  }
}
```

## Configuración del Proyecto

1. Clona el repositorio
2. Instala dependencias:
   ```bash
   cd backend
   npm install
   ```
3. Crea archivo `.env` basado en `.env.example` y configura:
   ```
   DATABASE_URL=postgresql://<usuario>:<contraseña>@<host>:5432/<basedatos>
   ```

## Importación de Datos GeoJSON

Para importar rutas desde archivos GeoJSON:

1. Coloca los archivos .geojson en `backend/src/scripts/`
2. Ejecuta:
   ```bash
   cd backend
   npm run import:geojson
   ```

## Uso en el Frontend

Ejemplo de cómo consumir las rutas en formato GeoJSON con Leaflet:

```javascript
// Ejemplo con fetch
fetch('http://tu-api/api/rutas/geojson')
  .then(response => response.json())
  .then(data => {
    if (data.success) {
      L.geoJSON(data.data, {
        style: (feature) => ({
          color: feature.properties.color,
          weight: 3
        })
      }).addTo(map);
    }
  });
```