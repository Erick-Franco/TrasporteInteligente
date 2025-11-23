# Plan de Corrección Completa

## Archivos a Corregir (en orden de prioridad)

### 1. Providers (CRÍTICO)
- ✅ `bus_provider.dart` - Ya usa String, solo quitar método `id: 0`
- ⏳ `ruta_provider.dart` - Quitar parámetro `numero`

### 2. Services
- ⏳ `firebase_service.dart` - Resolver conflicto de imports Query

### 3. Screens (ALTO IMPACTO)
- ⏳ `home_screen.dart` - Cambiar métodos WebSocket → Realtime, tipos int → String
- ⏳ `mapa_tiempo_real_screen.dart` - Similar a home_screen
- ⏳ `modo_conductor_screen.dart` - Cambiar tipos de conductorId y rutaId

### 4. Data Files (BAJO IMPACTO - pueden comentarse temporalmente)
- ⏳ `dummy_data.dart` - Cambiar todos los IDs de int a String
- ⏳ `detalle_bus_screen.dart` - Quitar referencias a busId
- ⏳ Repositories - Actualizar firmas de métodos

## Estrategia
1. Corregir providers primero (son la base)
2. Corregir screens principales (home, mapa, modo_conductor)
3. Comentar/deshabilitar archivos de datos dummy si es necesario
4. Verificar compilación
5. Probar app

## Tiempo Estimado
- Providers: 5 min
- Screens: 15 min
- Data files: 10 min
- **Total: ~30 minutos**
