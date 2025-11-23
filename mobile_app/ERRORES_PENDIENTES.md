# 🔧 Correcciones Pendientes para Firebase

## Errores de Compilación Encontrados

### 1. **BusModel** - Cambiar IDs de `int` a `String`
- `busId`: `int?` → `String?`
- `conductorId`: `int?` → `String?`
- `vehiculoId`: `int?` → `String?`
- `viajeId`: `int?` → `String?`
- `rutaId`: `int?` → `String?`

### 2. **RutaModel** - Cambiar ID y agregar campo `numero`
- `id`: `int` → `String`
- Agregar campo `numero` (opcional)

### 3. **BusProvider** - Actualizar métodos
- Eliminar `id: 0` en línea 75 (BusModel no tiene parámetro `id`)
- Cambiar `conductorId` de String a String (ya correcto)
- Cambiar tipo de `rutaId` en `busesPorRuta` de `int` a `String`

### 4. **RutaProvider** - Corregir creación de RutaModel
- Eliminar parámetro `numero` en línea 107 (no existe en el constructor)

### 5. **FirebaseService** - Conflicto de imports
- Resolver conflicto entre `Query` de Firestore y Realtime Database
- Usar alias para uno de los imports

### 6. **Screens** - Actualizar llamadas a métodos
- `home_screen.dart`: Cambiar `conectarWebSocket()` → `conectarRealtimeDatabase()`
- `home_screen.dart`: Cambiar `cargarBusesPorRuta()` → `filtrarPorRuta()`
- `home_screen.dart`: Eliminar `cargarBusesActivos()` (no existe)
- `mapa_tiempo_real_screen.dart`: Similar a home_screen
- `modo_conductor_screen.dart`: Cambiar tipos de `conductorId` y `rutaId` a `String`

## Orden de Corrección

1. ✅ Conductor model (ya corregido)
2. ⏳ BusModel
3. ⏳ RutaModel  
4. ⏳ FirebaseService (resolver conflicto de imports)
5. ⏳ BusProvider
6. ⏳ RutaProvider
7. ⏳ Screens (home, mapa, modo_conductor)
