// src/app.js
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const http = require('http');
const socketIo = require('socket.io');
const db = require('./config/database');

// Importar rutas
const busRoutes = require('./routes/busRoutes');
const rutaRoutes = require('./routes/rutaRoutes');
const conductoresRoutes = require('./routes/conductoresRoutes');
const asignacionesRoutes = require('./routes/asignacionesRoutes');
const ubicacionesRoutes = require('./routes/ubicacionesRoutes');

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
      ubicaciones: '/api/ubicaciones'
    }
  });
});

// Rutas de la API
app.use('/api/buses', busRoutes);
app.use('/api/rutas', rutaRoutes);
app.use('/api/conductores', conductoresRoutes);
app.use('/api/asignaciones', asignacionesRoutes);
app.use('/api/ubicaciones', ubicacionesRoutes);

// Ruta de salud
app.get('/health', (req, res) => {
  res.json({
    success: true,
    status: 'OK',
    timestamp: new Date()
  });
});

// ============ WEBSOCKET (NUEVA LÓGICA) ============
let clientesConectados = 0;

io.on('connection', (socket) => {
  clientesConectados++;
  console.log(`✅ Cliente conectado: ${socket.id} (Total: ${clientesConectados})`);

  // Enviar buses activos al conectarse (nueva consulta)
  db.query(`
    SELECT 
        b.bus_id,
        b.placa,
        b.sentido,
        r.ruta_id,
        r.nombre AS ruta_nombre,
        r.color AS ruta_color,
        u.latitud,
        u.longitud,
        u.velocidad,
        u.direccion,
        u.fecha_registro
    FROM buses b
    JOIN rutas r ON b.ruta_id = r.ruta_id
    JOIN LATERAL (
        SELECT latitud, longitud, velocidad, direccion, fecha_registro
        FROM ubicaciones_tiempo_real
        WHERE bus_id = b.bus_id
        ORDER BY fecha_registro DESC
        LIMIT 1
    ) u ON true
    WHERE b.estado = 'activo' AND r.activa = true;
  `)
    .then(result => {
      socket.emit('buses-init', result.rows);
    })
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
      const { rows: buses } = await db.query(`
        SELECT b.*, r.nombre as ruta_nombre 
        FROM buses b
        JOIN rutas r ON b.ruta_id = r.ruta_id
        WHERE b.estado = 'activo'
      `);
      
      for (const bus of buses) {
        const { rows: coords } = await db.query(
          'SELECT * FROM ruta_coordenadas WHERE ruta_id = $1 ORDER BY direccion, orden',
          [bus.ruta_id]
        );

        const rutaIda = coords.filter(c => c.direccion === 'ida');
        const rutaVuelta = coords.filter(c => c.direccion === 'vuelta');

        if (rutaIda.length === 0 || rutaVuelta.length === 0) {
          console.warn(`⚠️ Bus ${bus.placa} no tiene coordenadas de ida y/o vuelta. Saltando.`);
          continue;
        }

        const { rows: [lastLocation] } = await db.query(
          'SELECT latitud, longitud FROM ubicaciones_tiempo_real WHERE bus_id = $1 ORDER BY fecha_registro DESC LIMIT 1',
          [bus.bus_id]
        );

        const latitudInicial = lastLocation ? parseFloat(lastLocation.latitud) : parseFloat(rutaIda[0].latitud);
        const longitudInicial = lastLocation ? parseFloat(lastLocation.longitud) : parseFloat(rutaIda[0].longitud);

        estadoBuses.set(bus.bus_id, {
          id: bus.bus_id,
          placa: bus.placa,
          ruta_id: bus.ruta_id,
          ruta_nombre: bus.ruta_nombre,
          sentido: bus.sentido, // 'ida' o 'vuelta'
          rutaIda,
          rutaVuelta,
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
        const rutaActual = estado.sentido === 'ida' ? estado.rutaIda : estado.rutaVuelta;
        
        if (estado.puntoActual >= rutaActual.length - 1) {
            // Lógica de cambio de sentido
            const nuevoSentido = estado.sentido === 'ida' ? 'vuelta' : 'ida';
            estado.sentido = nuevoSentido;
            estado.puntoActual = 0;
            estado.siguientePunto = 1;
            estado.progreso = 0;
            estado.detenido = true; // Forzar parada al cambiar de sentido
            console.log(`🔄 Bus ${estado.placa} cambió de sentido a ${nuevoSentido}`);
            await db.query('UPDATE buses SET sentido = $1 WHERE bus_id = $2', [nuevoSentido, busId]);
            continue;
        }

        const puntoActual = rutaActual[estado.puntoActual];
        const siguientePunto = rutaActual[estado.siguientePunto];

        if (estado.detenido) {
          estado.tiempoDetenido += 2;
          const tiempoParada = puntoActual.es_parada ? 10 : 0;
          
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
            estado.progreso = 1; // Si la distancia es 0, saltar al siguiente punto
        }

        if (estado.progreso >= 1) {
          estado.progreso = 0;
          estado.puntoActual = estado.siguientePunto;
          estado.siguientePunto = estado.puntoActual + 1;

          const puntoAlcanzado = rutaActual[estado.puntoActual];
          if (puntoAlcanzado.es_parada) {
            estado.detenido = true;
            estado.velocidad = 0;
            console.log(`🚏 Bus ${estado.placa} llegó a la parada: ${puntoAlcanzado.nombre_referencia}`);
          }
        }

        const posActual = rutaActual[estado.puntoActual];
        const posSiguiente = rutaActual[estado.siguientePunto];

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
          es_parada: puntoActual.es_parada,
          siguiente_parada: siguientePunto.nombre_referencia,
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



module.exports = app;