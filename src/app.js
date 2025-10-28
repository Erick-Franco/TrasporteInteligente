// src/app.js
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const http = require('http');
const socketIo = require('socket.io');
const db = require('./config/database');

// Importar rutas
const busRoutes = require('./routes/busRoutes');
const busesActivosRoutes = require('./routes/busesActivosRoutes');
const rutaRoutes = require('./routes/rutaRoutes');
const conductoresRoutes = require('./routes/conductoresRoutes');
const asignacionesRoutes = require('./routes/asignacionesRoutes');
const ubicacionesRoutes = require('./routes/ubicacionesRoutes');
const paradasRoutes = require('./routes/paradasRoutes');

// Crear app Express
const app = express();
const server = http.createServer(app);

// Configurar Socket.IO
const io = socketIo(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

// ============ MIDDLEWARES ============
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Middleware para logging
app.use((req, res, next) => {
  console.log(`📡 ${req.method} ${req.path}`);
  next();
});

// Middleware para pasar io a los controladores
app.use((req, res, next) => {
  req.io = io;
  next();
});

// ============ RUTAS ============
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'API de Transporte Inteligente',
    version: '1.1.0', // Versión actualizada
    endpoints: {
      buses: '/api/buses',
      rutas: '/api/rutas',
      conductores: '/api/conductores',
      asignaciones: '/api/asignaciones',
      ubicaciones: '/api/ubicaciones',
    }
  });
});

// Rutas de la API
// Mapear rutas de buses y alias para compatibilidad con el frontend
app.use('/api/buses', busRoutes);
app.use('/api/buses-activos', busesActivosRoutes);
app.use('/api/rutas', rutaRoutes);
app.use('/api/conductores', conductoresRoutes);
app.use('/api/asignaciones', asignacionesRoutes);
app.use('/api/ubicaciones', ubicacionesRoutes);
app.use('/api/paradas', paradasRoutes);

// Ruta de salud
app.get('/health', (req, res) => {
  res.json({
    success: true,
    status: 'OK',
    timestamp: new Date()
  });
});

// Rutas públicas usadas por el frontend (no bajo /api)
// GET /rutas-coordenadas -> devuelve rutas con arreglo de coordenadas (GeoJSON-like simple)
app.get('/rutas-coordenadas', async (req, res) => {
  try {
    const rows = await db.query(
      `SELECT r.id as ruta_id, r.nombre, cr.latitud, cr.longitud, cr.orden
       FROM rutas r
       JOIN coordenadas_ruta cr ON cr.ruta_id = r.id
       WHERE r.activa = true
       ORDER BY r.id, cr.orden ASC`
    );

    const data = (rows.rows || []).reduce((acc, row) => {
      const rid = row.ruta_id;
      if (!acc[rid]) acc[rid] = { ruta_id: rid, nombre: row.nombre, coordenadas: [] };
      acc[rid].coordenadas.push({ lat: parseFloat(row.latitud), lon: parseFloat(row.longitud), orden: row.orden });
      return acc;
    }, {});

    res.json({ success: true, data: Object.values(data) });
  } catch (error) {
    console.error('Error en /rutas-coordenadas:', error.message);
    res.status(500).json({ success: false, message: 'Error al obtener rutas con coordenadas' });
  }
});

// ============ WEBSOCKET (NUEVA LÓGICA) ============
let clientesConectados = 0;

io.on('connection', (socket) => {
  clientesConectados++;
  console.log(`✅ Cliente conectado: ${socket.id} (Total: ${clientesConectados})`);

  // Enviar buses activos al conectarse usando la vista `vista_buses_activos`
  db.query('SELECT * FROM vista_buses_activos ORDER BY bus_id')
    .then(result => socket.emit('buses-init', result.rows))
    .catch(err => console.error('Error al enviar buses iniciales:', err));

  // Evento: Cliente se suscribe a una ruta específica
  socket.on('suscribir-ruta', (rutaId) => {
    socket.join(`ruta-${rutaId}`);
    console.log(`📍 Cliente ${socket.id} suscrito a ruta ${rutaId}`);
  });

  // Evento: Cliente se desuscribe de una ruta
  socket.on('desuscribir-ruta', (rutaId) => {
    socket.leave(`ruta-${rutaId}`);
    console.log(`🔌 Cliente ${socket.id} desuscrito de ruta ${rutaId}`);
  });

  // Evento: Desconexión
  socket.on('disconnect', () => {
    clientesConectados--;
    console.log(`❌ Cliente desconectado: ${socket.id} (Total: ${clientesConectados})`);
  });
});

// ============ SIMULADOR GPS (REESCRITO PARA IDA/VUELTA) ============
if (process.env.NODE_ENV === 'development') {

  const estadoBuses = new Map();

  const inicializarSimulador = async () => {
    try {
      // Obtener buses activos desde la vista
      const { rows: buses } = await db.query('SELECT * FROM vista_buses_activos');

      for (const bus of buses) {
        // Obtener coordenadas de la ruta desde la tabla `coordenadas_ruta` (si existe)
        const coordsRes = await db.query('SELECT * FROM coordenadas_ruta WHERE ruta_id = $1 ORDER BY orden', [bus.ruta_id]);
        const coords = coordsRes.rows || [];

        if (!coords || coords.length === 0) {
          console.warn(`⚠️ Bus ${bus.placa} (ruta ${bus.ruta_id}) no tiene coordenadas. Saltando.`);
          continue;
        }

        const lastLocationRes = await db.query('SELECT latitud, longitud FROM ubicaciones_tiempo_real WHERE bus_id = $1 ORDER BY fecha_registro DESC LIMIT 1', [bus.bus_id]);
        const lastLocation = (lastLocationRes.rows && lastLocationRes.rows[0]) || null;

        const latitudInicial = lastLocation ? parseFloat(lastLocation.latitud) : parseFloat(coords[0].latitud);
        const longitudInicial = lastLocation ? parseFloat(lastLocation.longitud) : parseFloat(coords[0].longitud);

        estadoBuses.set(bus.bus_id, {
          id: bus.bus_id,
          placa: bus.placa,
          ruta_id: bus.ruta_id,
          ruta_nombre: bus.ruta_nombre || null,
          sentido: bus.sentido || 'ida',
          rutaCoords: coords,
          puntoActual: 0,
          siguientePunto: 1,
          progreso: 0,
          velocidad: 0,
          detenido: true,
          tiempoDetenido: 0,
          latitud: latitudInicial,
          longitud: longitudInicial,
        });
      }

      console.log(`🎮 Simulador GPS inicializado con ${estadoBuses.size} buses`);
    } catch (error) {
      console.error('❌ Error al inicializar simulador:', error.message);
    }
  };

  const calcularDistancia = (lat1, lon1, lat2, lon2) => {
    const R = 6371;
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a = Math.sin(dLat/2) * Math.sin(dLat/2) + Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * Math.sin(dLon/2) * Math.sin(dLon/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return R * c;
  };

  const interpolar = (lat1, lon1, lat2, lon2, progreso) => ({
    lat: lat1 + (lat2 - lat1) * progreso,
    lon: lon1 + (lon2 - lon1) * progreso
  });

  const calcularDireccion = (lat1, lon1, lat2, lon2) => {
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const y = Math.sin(dLon) * Math.cos(lat2 * Math.PI / 180);
    const x = Math.cos(lat1 * Math.PI / 180) * Math.sin(lat2 * Math.PI / 180) - Math.sin(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * Math.cos(dLon);
    return (Math.atan2(y, x) * 180 / Math.PI + 360) % 360;
  };

  const actualizarPosiciones = async () => {
    if (estadoBuses.size === 0) return;

    try {
      for (const [busId, estado] of estadoBuses) {
        const rutaActual = estado.rutaCoords;

        if (estado.puntoActual >= rutaActual.length - 1) {
          // Cambio de sentido en memoria (no actualizamos DB aquí para evitar errores si no existe columna)
          estado.sentido = estado.sentido === 'ida' ? 'vuelta' : 'ida';
          estado.puntoActual = 0;
          estado.siguientePunto = 1;
          estado.progreso = 0;
          estado.detenido = true;
          console.log(`🔄 Bus ${estado.placa} cambió de sentido a ${estado.sentido}`);
          continue;
        }

        const puntoActual = rutaActual[estado.puntoActual];
        const siguientePunto = rutaActual[Math.min(estado.siguientePunto, rutaActual.length - 1)];

        if (estado.detenido) {
          estado.tiempoDetenido += 2;
          const tiempoParada = 0; // No hay indicador en coordenadas_ruta

          if (estado.tiempoDetenido >= tiempoParada) {
            estado.detenido = false;
            estado.tiempoDetenido = 0;
            estado.velocidad = 15 + Math.random() * 10;
          }
          continue;
        }

        const velocidadBase = 25;
        const variacion = (Math.random() - 0.5) * 10;
        estado.velocidad = Math.max(10, Math.min(40, velocidadBase + variacion));

        const distancia = calcularDistancia(
          parseFloat(puntoActual.latitud), parseFloat(puntoActual.longitud),
          parseFloat(siguientePunto.latitud), parseFloat(siguientePunto.longitud)
        );

        if (distancia > 0) {
          const incrementoProgreso = (estado.velocidad / distancia / 3600) * 2;
          estado.progreso += incrementoProgreso;
        } else {
          estado.progreso = 1;
        }

        if (estado.progreso >= 1) {
          estado.progreso = 0;
          estado.puntoActual = estado.siguientePunto;
          estado.siguientePunto = estado.puntoActual + 1;
        }

        const posActual = rutaActual[estado.puntoActual];
        const posSiguiente = rutaActual[Math.min(estado.siguientePunto, rutaActual.length - 1)];

        const nuevaPosicion = interpolar(
          parseFloat(posActual.latitud), parseFloat(posActual.longitud),
          parseFloat(posSiguiente.latitud), parseFloat(posSiguiente.longitud),
          estado.progreso
        );

        estado.latitud = nuevaPosicion.lat;
        estado.longitud = nuevaPosicion.lon;

        const direccion = calcularDireccion(
          parseFloat(posActual.latitud), parseFloat(posActual.longitud),
          parseFloat(posSiguiente.latitud), parseFloat(posSiguiente.longitud)
        );

        await db.query(
          'INSERT INTO ubicaciones_tiempo_real (bus_id, latitud, longitud, velocidad, direccion) VALUES ($1, $2, $3, $4, $5)',
          [busId, estado.latitud, estado.longitud, estado.velocidad, Math.round(direccion)]
        );

        io.emit('bus-update', {
          bus_id: busId,
          placa: estado.placa,
          ruta_id: estado.ruta_id,
          ruta_nombre: estado.ruta_nombre,
          sentido: estado.sentido,
          latitud: estado.latitud,
          longitud: estado.longitud,
          velocidad: estado.velocidad,
          direccion: direccion,
          timestamp: new Date()
        });
      }
    } catch (error) {
      console.error('❌ Error en el ciclo del simulador:', error.message);
    }
  };

  inicializarSimulador().then(() => {
    setInterval(actualizarPosiciones, 2000);
    console.log('✅ Simulador GPS en ejecución (actualización cada 2 segundos)');
  });
}
// ============ MANEJO DE ERRORES ============
app.use((err, req, res, next) => {
  console.error('❌ Error:', err);
  res.status(500).json({
    success: false,
    message: 'Error interno del servidor',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// Ruta 404
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Ruta no encontrada'
  });
});



// Si se ejecuta directamente (node src/app.js), levantar servidor para pruebas locales
if (require.main === module) {
  const PORT = process.env.PORT || 3000;
  server.listen(PORT, () => console.log(`🚀 Server escuchando en http://localhost:${PORT}`));
}

module.exports = app;