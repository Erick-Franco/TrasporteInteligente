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
    message: '🚍 API de Transporte Inteligente',
    version: '1.0.0',
    endpoints: {
      buses: '/api/buses',
      rutas: '/api/rutas',
      websocket: `ws://localhost:${PORT}`
    }
  });
});

// Rutas de la API
app.use('/api/buses', busRoutes);
app.use('/api/rutas', rutaRoutes);

// Ruta de salud
app.get('/health', (req, res) => {
  res.json({
    success: true,
    status: 'OK',
    timestamp: new Date()
  });
});

// ============ WEBSOCKET ============
let clientesConectados = 0;

io.on('connection', (socket) => {
  clientesConectados++;
  console.log(`✅ Cliente conectado: ${socket.id} (Total: ${clientesConectados})`);

  // Enviar buses activos al conectarse
  db.query('SELECT * FROM vista_buses_activos')
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

// ============ SIMULADOR GPS MEJORADO ============
if (process.env.NODE_ENV === 'development') {
  
  // Estado del simulador para cada bus
  const estadoBuses = new Map();

  // Inicializar estado de los buses
  const inicializarSimulador = async () => {
    try {
      const { rows: buses } = await db.query('SELECT * FROM vista_buses_activos');
      
      for (const bus of buses) {
        // Obtener la ruta completa de paradas
        const { rows: paradas } = await db.query(`
          SELECT 
            p.id,
            p.nombre,
            p.latitud,
            p.longitud,
            rp.orden,
            rp.es_parada_principal
          FROM ruta_paradas rp
          JOIN paradas p ON rp.parada_id = p.id
          WHERE rp.ruta_id = $1
          ORDER BY rp.orden
        `, [bus.ruta_id]);

        // Encontrar parada más cercana a la posición actual
        let paradaMasCercana = 0;
        let menorDistancia = Infinity;
        
        for (let i = 0; i < paradas.length; i++) {
          const distancia = calcularDistancia(
            parseFloat(bus.latitud),
            parseFloat(bus.longitud),
            parseFloat(paradas[i].latitud),
            parseFloat(paradas[i].longitud)
          );
          
          if (distancia < menorDistancia) {
            menorDistancia = distancia;
            paradaMasCercana = i;
          }
        }

        // Guardar estado inicial del bus
        estadoBuses.set(bus.bus_id, {
          id: bus.bus_id,
          placa: bus.placa,
          ruta_id: bus.ruta_id,
          ruta_nombre: bus.ruta_nombre,
          paradas: paradas,
          paradaActual: paradaMasCercana,
          siguienteParada: (paradaMasCercana + 1) % paradas.length,
          progreso: 0, // 0 a 1 entre dos paradas
          velocidad: 0,
          detenido: false,
          tiempoDetenido: 0,
          direccion: 'ida', // ida o vuelta
          latitud: parseFloat(bus.latitud),
          longitud: parseFloat(bus.longitud)
        });
      }

      console.log(`🎮 Simulador inicializado con ${estadoBuses.size} buses`);
    } catch (error) {
      console.error('❌ Error al inicializar simulador:', error.message);
    }
  };

  // Calcular distancia entre dos puntos (Haversine simplificado)
  const calcularDistancia = (lat1, lon1, lat2, lon2) => {
    const R = 6371; // Radio de la Tierra en km
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    
    const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
              Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
              Math.sin(dLon/2) * Math.sin(dLon/2);
    
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return R * c;
  };

  // Interpolar entre dos puntos
  const interpolar = (lat1, lon1, lat2, lon2, progreso) => {
    return {
      lat: lat1 + (lat2 - lat1) * progreso,
      lon: lon1 + (lon2 - lon1) * progreso
    };
  };

  // Calcular ángulo de dirección entre dos puntos
  const calcularDireccion = (lat1, lon1, lat2, lon2) => {
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const y = Math.sin(dLon) * Math.cos(lat2 * Math.PI / 180);
    const x = Math.cos(lat1 * Math.PI / 180) * Math.sin(lat2 * Math.PI / 180) -
              Math.sin(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * Math.cos(dLon);
    let direccion = Math.atan2(y, x) * 180 / Math.PI;
    return (direccion + 360) % 360; // Normalizar a 0-360
  };

  // Actualizar posición de los buses cada 2 segundos
  const actualizarPosiciones = async () => {
    try {
      for (const [busId, estado] of estadoBuses) {
        const paradaActual = estado.paradas[estado.paradaActual];
        const siguienteParada = estado.paradas[estado.siguienteParada];

        // Si está detenido en una parada
        if (estado.detenido) {
          estado.tiempoDetenido += 2; // 2 segundos
          
          // Detenerse 10 segundos en paradas principales, 5 en normales
          const tiempoParada = paradaActual.es_parada_principal ? 10 : 5;
          
          if (estado.tiempoDetenido >= tiempoParada) {
            estado.detenido = false;
            estado.tiempoDetenido = 0;
            estado.velocidad = 15 + Math.random() * 10; // 15-25 km/h inicial
          }
          continue;
        }

        // Velocidad variable (simulando tráfico)
        const velocidadBase = 25; // km/h promedio
        const variacion = (Math.random() - 0.5) * 10; // ±5 km/h
        estado.velocidad = Math.max(10, Math.min(40, velocidadBase + variacion));

        // Incrementar progreso según velocidad
        // progreso por segundo = velocidad(km/h) / distancia(km) / 3600
        const distancia = calcularDistancia(
          paradaActual.latitud,
          paradaActual.longitud,
          siguienteParada.latitud,
          siguienteParada.longitud
        );
        
        const incrementoProgreso = (estado.velocidad / distancia / 3600) * 2; // * 2 segundos
        estado.progreso += incrementoProgreso;

        // Si llegó a la siguiente parada
        if (estado.progreso >= 1) {
          estado.progreso = 0;
          estado.paradaActual = estado.siguienteParada;
          
          // Calcular siguiente parada
          if (estado.direccion === 'ida') {
            if (estado.siguienteParada === estado.paradas.length - 1) {
              // Llegó al final, dar vuelta
              estado.direccion = 'vuelta';
              estado.siguienteParada = estado.paradaActual - 1;
            } else {
              estado.siguienteParada++;
            }
          } else {
            if (estado.siguienteParada === 0) {
              // Llegó al inicio, dar vuelta
              estado.direccion = 'ida';
              estado.siguienteParada = estado.paradaActual + 1;
            } else {
              estado.siguienteParada--;
            }
          }

          // Detenerse en la parada
          estado.detenido = true;
          estado.velocidad = 0;
          
          console.log(`🚏 Bus ${estado.placa} llegó a: ${paradaActual.nombre}`);
        }

        // Calcular nueva posición
        const nuevaPosicion = interpolar(
          paradaActual.latitud,
          paradaActual.longitud,
          siguienteParada.latitud,
          siguienteParada.longitud,
          estado.progreso
        );

        estado.latitud = nuevaPosicion.lat;
        estado.longitud = nuevaPosicion.lon;

        // Calcular dirección (ángulo)
        const direccion = calcularDireccion(
          paradaActual.latitud,
          paradaActual.longitud,
          siguienteParada.latitud,
          siguienteParada.longitud
        );

        await db.query(`
        INSERT INTO ubicaciones_tiempo_real 
        (bus_id, latitud, longitud, velocidad, direccion, altitud)
        VALUES ($1, $2, $3, $4, $5, 3825)
        `, [
        busId,
        parseFloat(estado.latitud),
        parseFloat(estado.longitud),
        parseFloat(estado.velocidad),
        Math.round(direccion)
        ]);
// Emitir por WebSocket a todos los clientes
        io.emit('bus-update', {
          bus_id: busId,
          placa: estado.placa,
          ruta_id: estado.ruta_id,
          ruta_nombre: estado.ruta_nombre,
          latitud: estado.latitud,
          longitud: estado.longitud,
          velocidad: estado.velocidad,
          direccion: direccion,
          parada_actual: paradaActual.nombre,
          siguiente_parada: siguienteParada.nombre,
          en_parada: estado.detenido,
          timestamp: new Date()
        });

        // Emitir solo a clientes suscritos a esta ruta
        io.to(`ruta-${estado.ruta_id}`).emit('bus-ruta-update', {
          bus_id: busId,
          latitud: estado.latitud,
          longitud: estado.longitud,
          velocidad: estado.velocidad
        });
      }
    } catch (error) {
      console.error('❌ Error en simulador:', error.message);
    }
  };

  // Iniciar simulador
  inicializarSimulador().then(() => {
    // Actualizar cada 2 segundos
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

// ============ INICIAR SERVIDOR ============
const PORT = process.env.PORT || 3000;

const startServer = async () => {
  try {
    // Verificar conexión a la base de datos
    const dbConnected = await db.testConnection();
    
    if (!dbConnected) {
      console.error('❌ No se pudo conectar a la base de datos');
      process.exit(1);
    }

    // Iniciar servidor
    server.listen(PORT, () => {
      console.log('\n🚀 ================================');
      console.log(`🚍 Servidor corriendo en http://localhost:${PORT}`);
      console.log(`📡 WebSocket listo en ws://localhost:${PORT}`);
      console.log(`🗄️  Base de datos: ${process.env.DB_NAME}`);
      console.log(`🌍 Entorno: ${process.env.NODE_ENV || 'development'}`);
      console.log('🚀 ================================\n');
    });
  } catch (error) {
    console.error('❌ Error al iniciar servidor:', error);
    process.exit(1);
  }
};

startServer();

// Manejo de señales de terminación
process.on('SIGTERM', () => {
  console.log('⚠️ SIGTERM recibido, cerrando servidor...');
  server.close(() => {
    console.log('✅ Servidor cerrado');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('\n⚠️ SIGINT recibido, cerrando servidor...');
  server.close(() => {
    console.log('✅ Servidor cerrado');
    process.exit(0);
  });
});

module.exports = { app, io };