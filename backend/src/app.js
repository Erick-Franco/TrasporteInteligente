// ============================================
// SERVIDOR PRINCIPAL - TRANSPORTE INTELIGENTE
// CON WEBSOCKET PARA CHAT, GPS Y GERENTES
// backend/src/app.js
// ============================================

const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
require('dotenv').config();

const { testConnection } = require('./config/database');
const { guardarMensaje } = require('./controllers/chatController');

// Importar rutas
const rutaRoutes = require('./routes/rutaRoutes');
const busRoutes = require('./routes/busRoutes');
const conductorRoutes = require('./routes/conductorRoutes');
const ubicacionRoutes = require('./routes/ubicacionRoutes');
const chatRoutes = require('./routes/chatRoutes');
const viajesRoutes = require('./routes/viajesRoutes');
const gerenteRoutes = require('./routes/gerenteRoutes'); // ✅ NUEVO

// Crear app y servidor HTTP
const app = express();
const server = http.createServer(app);
const io = new Server(server, {
    cors: {
        origin: process.env.CORS_ORIGIN || '*',
        methods: ['GET', 'POST']
    }
});

const PORT = process.env.PORT || 3000;

// ============================================
// MIDDLEWARES
// ============================================
app.use(cors({
    origin: process.env.CORS_ORIGIN || '*'
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Logging de requests
app.use((req, res, next) => {
    console.log(`${req.method} ${req.path}`, req.query);
    next();
});

// ✅ MIDDLEWARE: Hacer io accesible en los controllers
app.use((req, res, next) => {
    req.io = io;
    next();
});

// ============================================
// RUTAS DE LA API
// ============================================
app.use('/api/rutas', rutaRoutes);
app.use('/api/buses', busRoutes);
app.use('/api/conductores', conductorRoutes);
app.use('/api/ubicaciones', ubicacionRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/viajes', viajesRoutes);
app.use('/api/gerente', gerenteRoutes); // ✅ NUEVO

// Ruta de prueba
app.get('/', (req, res) => {
    res.json({
        success: true,
        message: '🚌 API Transporte Inteligente',
        version: '1.0.0',
        endpoints: {
            rutas: '/api/rutas',
            buses: '/api/buses/activos',
            conductores: '/api/conductores/login',
            ubicaciones: '/api/ubicaciones',
            chat: '/api/chat/mensajes',
            viajes: '/api/viajes',
            gerente: '/api/gerente/login' // ✅ NUEVO
        },
        websocket: {
            url: `ws://localhost:${PORT}`,
            eventos: [
                'chat-message', 
                'bus-location-update', 
                'viaje-iniciado', 
                'viaje-finalizado', 
                'user-joined', 
                'user-left',
                'conductor-movimiento' // ✅ NUEVO (para gerentes)
            ]
        }
    });
});

// Health check
app.get('/api/health', async (req, res) => {
    const dbStatus = await testConnection();
    res.json({
        success: true,
        status: 'OK',
        database: dbStatus ? 'Conectada' : 'Desconectada',
        websocket: io.engine.clientsCount + ' clientes conectados',
        timestamp: new Date()
    });
});

// ============================================
// WEBSOCKET - EVENTOS EN TIEMPO REAL
// ============================================
let usuariosConectados = new Map(); // Map<socketId, {nombre, id, tipo}>

io.on('connection', (socket) => {
    console.log(`📱 Cliente conectado: ${socket.id}`);
    
    // ════════════════════════════════════════════════════════
    // 💬 CHAT GLOBAL
    // ════════════════════════════════════════════════════════
    
    // Usuario se une al chat
    socket.on('user-join', async (userData) => {
        const { nombre, id, tipo } = userData; // tipo: 'conductor' o 'gerente'
        usuariosConectados.set(socket.id, { nombre, id, tipo: tipo || 'conductor' });
        
        console.log(`👤 ${nombre} (${tipo || 'conductor'}) se unió al chat`);
        
        // Notificar a todos (excepto al que se unió)
        socket.broadcast.emit('user-joined', {
            nombre,
            id,
            tipo: tipo || 'conductor',
            timestamp: new Date(),
            usuariosConectados: Array.from(usuariosConectados.values())
        });
    });
    
    // Usuario sale del chat
    socket.on('user-leave', async (userData) => {
        const { nombre, id } = userData;
        console.log(`👋 ${nombre} salió del chat`);
        
        usuariosConectados.delete(socket.id);
        
        // Notificar a todos
        io.emit('user-left', {
            nombre,
            id,
            timestamp: new Date(),
            usuariosConectados: Array.from(usuariosConectados.values())
        });
    });
    
    // ════════════════════════════════════════════════════════
    // 📍 UBICACIÓN GPS (BUSES)
    // ════════════════════════════════════════════════════════
    
    // Actualización de ubicación de conductor
    socket.on('conductor-location', (data) => {
        console.log(`📍 GPS Conductor ${data.conductor_id}:`, 
                    `${data.latitud}, ${data.longitud}`);
        
        // Emitir a todos los clientes (incluyendo gerentes)
        io.emit('bus-location-update', {
            conductor_id: data.conductor_id,
            vehiculo_id: data.vehiculo_id,
            ruta_id: data.ruta_id,
            latitud: data.latitud,
            longitud: data.longitud,
            velocidad: data.velocidad,
            direccion: data.direccion,
            timestamp: new Date()
        });

        // ✅ NUEVO: Emitir específicamente a gerentes de esa ruta
        io.to(`ruta_${data.ruta_id}`).emit('conductor-movimiento', {
            conductor_id: data.conductor_id,
            vehiculo_id: data.vehiculo_id,
            ruta_id: data.ruta_id,
            latitud: data.latitud,
            longitud: data.longitud,
            velocidad: data.velocidad,
            direccion: data.direccion,
            timestamp: new Date()
        });
    });
    
    // Bus llegó a paradero
    socket.on('bus-arrived-stop', (data) => {
        console.log(`🛑 Bus llegó a paradero ${data.punto_control_id}`);
        
        io.emit('bus-arrived-stop', {
            viaje_id: data.viaje_id,
            punto_control_id: data.punto_control_id,
            latitud: data.latitud,
            longitud: data.longitud,
            timestamp: new Date()
        });

        // Emitir a gerentes de la ruta
        if (data.ruta_id) {
            io.to(`ruta_${data.ruta_id}`).emit('bus-arrived-stop', {
                viaje_id: data.viaje_id,
                punto_control_id: data.punto_control_id,
                latitud: data.latitud,
                longitud: data.longitud,
                timestamp: new Date()
            });
        }
    });
    
    // Bus completó ruta
    socket.on('bus-route-completed', (data) => {
        console.log(`✅ Bus completó ruta: viaje ${data.viaje_id}`);
        
        io.emit('bus-route-completed', {
            viaje_id: data.viaje_id,
            timestamp: new Date()
        });
    });
    
    // ════════════════════════════════════════════════════════
    // 🎯 SUSCRIPCIONES A RUTAS (PARA GERENTES)
    // ════════════════════════════════════════════════════════
    
    socket.on('subscribe-route', (data) => {
        const { ruta_id } = data;
        socket.join(`ruta_${ruta_id}`);
        console.log(`📍 Socket ${socket.id} suscrito a ruta ${ruta_id}`);
    });
    
    socket.on('unsubscribe-route', (data) => {
        const { ruta_id } = data;
        socket.leave(`ruta_${ruta_id}`);
        console.log(`🔌 Socket ${socket.id} desuscrito de ruta ${ruta_id}`);
    });
    
    // ════════════════════════════════════════════════════════
    // 🔌 DESCONEXIÓN
    // ════════════════════════════════════════════════════════
    
    socket.on('disconnect', () => {
        const usuario = usuariosConectados.get(socket.id);
        
        if (usuario) {
            console.log(`👋 ${usuario.nombre} se desconectó`);
            
            usuariosConectados.delete(socket.id);
            
            // Notificar a todos
            io.emit('user-left', {
                nombre: usuario.nombre,
                id: usuario.id,
                timestamp: new Date(),
                usuariosConectados: Array.from(usuariosConectados.values())
            });
        } else {
            console.log(`📱 Cliente desconectado: ${socket.id}`);
        }
    });
});

// ============================================
// MANEJO DE ERRORES
// ============================================
app.use((req, res) => {
    res.status(404).json({
        success: false,
        error: 'Endpoint no encontrado',
        path: req.path
    });
});

app.use((err, req, res, next) => {
    console.error('Error no manejado:', err);
    res.status(500).json({
        success: false,
        error: 'Error interno del servidor',
        message: process.env.NODE_ENV === 'development' ? err.message : undefined
    });
});

// ============================================
// INICIAR SERVIDOR
// ============================================
const startServer = async () => {
    try {
        // Verificar conexión a la base de datos
        console.log('🔍 Verificando conexión a base de datos...');
        const connected = await testConnection();
        
        if (!connected) {
            console.error('❌ No se pudo conectar a la base de datos');
            process.exit(1);
        }
        
        // Iniciar servidor
        server.listen(PORT, () => {
            console.log('═'.repeat(60));
            console.log('🚀 SERVIDOR INICIADO CORRECTAMENTE');
            console.log('═'.repeat(60));
            console.log(`📡 Puerto: ${PORT}`);
            console.log(`🌐 HTTP: http://localhost:${PORT}`);
            console.log(`🔌 WebSocket: ws://localhost:${PORT}`);
            console.log(`📊 Base de datos: ${process.env.DB_NAME}@${process.env.DB_HOST}:${process.env.DB_PORT}`);
            console.log('═'.repeat(60));
            console.log('\n📋 ENDPOINTS REST:');
            console.log('   RUTAS:');
            console.log('   GET  /api/rutas');
            console.log('   GET  /api/rutas/:id/puntos?tipo=ida');
            console.log('   BUSES:');
            console.log('   GET  /api/buses/activos');
            console.log('   CONDUCTORES:');
            console.log('   POST /api/conductores/login');
            console.log('   GET  /api/conductores/:id/viaje-actual');
            console.log('   UBICACIONES:');
            console.log('   POST /api/ubicaciones');
            console.log('   CHAT:');
            console.log('   GET  /api/chat/mensajes?limit=50');
            console.log('   POST /api/chat/enviar');
            console.log('   VIAJES:');
            console.log('   POST /api/viajes/iniciar');
            console.log('   PUT  /api/viajes/:id/finalizar');
            console.log('   GET  /api/viajes/activos');
            console.log('   GET  /api/viajes/historial');
            console.log('   GERENTES:                             ✅ NUEVO');
            console.log('   POST /api/gerente/login');
            console.log('   GET  /api/gerente/:ruta_id/conductores-activos');
            console.log('   GET  /api/gerente/:ruta_id/ruta-completa');
            console.log('   GET  /api/gerente/:ruta_id/estadisticas');
            console.log('\n🔌 EVENTOS WEBSOCKET:');
            console.log('   CHAT:');
            console.log('   → user-join              (unirse al chat)');
            console.log('   → user-leave             (salir del chat)');
            console.log('   ← user-joined            (usuario se unió)');
            console.log('   ← user-left              (usuario salió)');
            console.log('   ← chat-message           (nuevo mensaje)');
            console.log('   GPS:');
            console.log('   → conductor-location     (enviar GPS)');
            console.log('   ← bus-location-update    (GPS actualizado)');
            console.log('   ← bus-arrived-stop       (llegó a paradero)');
            console.log('   ← bus-route-completed    (completó ruta)');
            console.log('   VIAJES:');
            console.log('   ← viaje-iniciado         (viaje iniciado)');
            console.log('   ← viaje-finalizado       (viaje finalizado)');
            console.log('   GERENTES:                             ✅ NUEVO');
            console.log('   → subscribe-route        (suscribirse a ruta)');
            console.log('   → unsubscribe-route      (desuscribirse)');
            console.log('   ← conductor-movimiento   (actualización GPS)');
            console.log('═'.repeat(60));
            console.log('');
        });
    } catch (error) {
        console.error('❌ Error al iniciar servidor:', error);
        process.exit(1);
    }
};

// Iniciar
startServer();

// Manejo de cierre graceful
process.on('SIGTERM', () => {
    console.log('🔴 SIGTERM recibido, cerrando servidor...');
    io.close();
    server.close();
    process.exit(0);
});

process.on('SIGINT', () => {
    console.log('🔴 SIGINT recibido, cerrando servidor...');
    io.close();
    server.close();
    process.exit(0);
});

module.exports = { app, server, io };