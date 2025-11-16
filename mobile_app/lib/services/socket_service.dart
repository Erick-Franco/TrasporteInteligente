// ════════════════════════════════════════════════════════
// 🔌 SERVICIO WEBSOCKET - TRANSPORTE INTELIGENTE
// lib/services/socket_service.dart
// ════════════════════════════════════════════════════════

import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/constants.dart';

class SocketService {
  // Singleton pattern
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  final Map<String, List<Function>> _listeners = {};
  bool _isConnecting = false;
  Timer? _reconnectTimer;

  // ════════════════════════════════════════════════════════
  // 🔌 CONEXIÓN Y DESCONEXIÓN
  // ════════════════════════════════════════════════════════

  /// Conectar al WebSocket
  Future<void> conectar() async {
    if (_socket?.connected ?? false) {
      print('✅ Socket ya está conectado');
      return;
    }

    if (_isConnecting) {
      print('⏳ Conexión en progreso...');
      return;
    }

    try {
      _isConnecting = true;

      print('🔌 Conectando a WebSocket: ${AppConstants.wsUrl}');

      _socket = IO.io(
        AppConstants.wsUrl,
        IO.OptionBuilder()
            .setTransports(['websocket']) // Solo WebSocket, no polling
            .enableAutoConnect() // Auto conectar
            .enableReconnection() // Auto reconectar
            .setReconnectionAttempts(5) // 5 intentos
            .setReconnectionDelay(2000) // 2 segundos entre intentos
            .build(),
      );

      _configurarEventosConexion();
      _configurarEventosApp();

      _socket!.connect();
    } catch (e) {
      print('❌ Error al conectar WebSocket: $e');
      _isConnecting = false;
      _programarReconexion();
    }
  }

  /// Configurar eventos de conexión
  void _configurarEventosConexion() {
    _socket!.onConnect((_) {
      print('✅ WebSocket conectado exitosamente');
      _isConnecting = false;
      _reconnectTimer?.cancel();
    });

    _socket!.onDisconnect((_) {
      print('❌ WebSocket desconectado');
      _isConnecting = false;
      _programarReconexion();
    });

    _socket!.onConnectError((error) {
      print('❌ Error de conexión WebSocket: $error');
      _isConnecting = false;
      _programarReconexion();
    });

    _socket!.onError((error) {
      print('❌ Error en WebSocket: $error');
    });

    _socket!.onReconnect((attempt) {
      print('🔄 Reconectando... Intento #$attempt');
    });

    _socket!.onReconnectError((error) {
      print('❌ Error al reconectar: $error');
    });

    _socket!.onReconnectFailed((_) {
      print('❌ Reconexión fallida después de múltiples intentos');
      _programarReconexion();
    });
  }

  /// Configurar eventos de la aplicación
  void _configurarEventosApp() {
    // ════════════════════════════════════════════════════════
    // 📍 EVENTOS DE UBICACIÓN GPS (BUSES)
    // ════════════════════════════════════════════════════════

    // Ubicación actualizada de un bus
    _socket!.on('bus-location-update', (data) {
      if (AppConstants.enableLogs) {
        print('📍 Bus location update: ${data['conductor_id']}');
      }
      _notificarListeners('bus-location-update', data);
    });

    // Bus llegó a un paradero
    _socket!.on('bus-arrived-stop', (data) {
      print('🛑 Bus llegó a paradero: ${data['punto_control_id']}');
      _notificarListeners('bus-arrived-stop', data);
    });

    // Bus completó ruta
    _socket!.on('bus-route-completed', (data) {
      print('✅ Bus completó ruta: ${data['viaje_id']}');
      _notificarListeners('bus-route-completed', data);
    });

    // ════════════════════════════════════════════════════════
    // 💬 EVENTOS DE CHAT GLOBAL
    // ════════════════════════════════════════════════════════

    // Nuevo mensaje en el chat
    _socket!.on('chat-message', (data) {
      if (AppConstants.enableLogs) {
        print(
            '💬 Nuevo mensaje: ${data['usuario_nombre']}: ${data['mensaje']}');
      }
      _notificarListeners('chat-message', data);
    });

    // Usuario se unió al chat
    _socket!.on('user-joined', (data) {
      print('👋 ${data['nombre']} se unió al chat');
      _notificarListeners('user-joined', data);
    });

    // Usuario salió del chat
    _socket!.on('user-left', (data) {
      print('👋 ${data['nombre']} salió del chat');
      _notificarListeners('user-left', data);
    });

    // ════════════════════════════════════════════════════════
    // 🔔 EVENTOS DE NOTIFICACIONES
    // ════════════════════════════════════════════════════════

    // Notificación general
    _socket!.on('notification', (data) {
      print('🔔 Notificación: ${data['mensaje']}');
      _notificarListeners('notification', data);
    });
  }

  /// Programar reconexión automática
  void _programarReconexion() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      Duration(seconds: AppConstants.reconnectInterval),
      () {
        print('🔄 Intentando reconectar...');
        conectar();
      },
    );
  }

  /// Desconectar
  void desconectar() {
    _reconnectTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _listeners.clear();
    _isConnecting = false;
    print('🔌 Socket desconectado y limpiado');
  }

  // ════════════════════════════════════════════════════════
  // 📡 EMISIÓN DE EVENTOS
  // ════════════════════════════════════════════════════════

  /// Emitir evento genérico
  void emit(String evento, dynamic data) {
    if (_socket?.connected ?? false) {
      _socket!.emit(evento, data);
      if (AppConstants.enableLogs) {
        print('📤 Evento emitido: $evento');
      }
    } else {
      print('❌ No se puede emitir $evento: Socket desconectado');
    }
  }

  // ════════════════════════════════════════════════════════
  // 💬 MÉTODOS DE CHAT
  // ════════════════════════════════════════════════════════

  /// Unirse al chat
  void unirseAlChat({
    required String nombre,
    required String id,
  }) {
    emit('user-join', {
      'nombre': nombre,
      'id': id,
    });
    print('👋 Uniéndose al chat como: $nombre');
  }

  /// Enviar mensaje al chat
  void enviarMensajeChat({
    required String usuarioNombre,
    required String usuarioId,
    required String mensaje,
  }) {
    emit('chat-message', {
      'usuario_nombre': usuarioNombre,
      'usuario_id': usuarioId,
      'mensaje': mensaje,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Salir del chat
  void salirDelChat({
    required String nombre,
    required String id,
  }) {
    emit('user-leave', {
      'nombre': nombre,
      'id': id,
    });
    print('👋 Saliendo del chat: $nombre');
  }

  // ════════════════════════════════════════════════════════
  // 📍 MÉTODOS DE UBICACIÓN GPS (PARA CONDUCTOR)
  // ════════════════════════════════════════════════════════

  /// Enviar ubicación GPS del conductor (en tiempo real)
  void enviarUbicacionConductor({
    required int conductorId,
    required int vehiculoId,
    required int rutaId,
    required double latitud,
    required double longitud,
    required double velocidad,
    required double direccion,
  }) {
    emit('conductor-location', {
      'conductor_id': conductorId,
      'vehiculo_id': vehiculoId,
      'ruta_id': rutaId,
      'latitud': latitud,
      'longitud': longitud,
      'velocidad': velocidad,
      'direccion': direccion,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Registrar llegada a paradero
  void registrarLlegadaParadero({
    required int viajeId,
    required int puntoControlId,
    required double latitud,
    required double longitud,
  }) {
    emit('bus-arrived-stop', {
      'viaje_id': viajeId,
      'punto_control_id': puntoControlId,
      'latitud': latitud,
      'longitud': longitud,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Notificar finalización de ruta
  void notificarFinRuta({
    required int viajeId,
  }) {
    emit('bus-route-completed', {
      'viaje_id': viajeId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // ════════════════════════════════════════════════════════
  // 🎯 SUSCRIPCIONES A RUTAS
  // ════════════════════════════════════════════════════════

  /// Suscribirse a actualizaciones de una ruta específica
  void suscribirseARuta(int rutaId) {
    emit('subscribe-route', {'ruta_id': rutaId});
    print('📍 Suscrito a actualizaciones de ruta $rutaId');
  }

  /// Desuscribirse de una ruta
  void desuscribirseDeRuta(int rutaId) {
    emit('unsubscribe-route', {'ruta_id': rutaId});
    print('🔌 Desuscrito de ruta $rutaId');
  }

  // ════════════════════════════════════════════════════════
  // 🎧 MANEJO DE LISTENERS
  // ════════════════════════════════════════════════════════

  /// Agregar listener para un evento
  void on(String evento, Function callback) {
    if (!_listeners.containsKey(evento)) {
      _listeners[evento] = [];
    }
    _listeners[evento]!.add(callback);

    if (AppConstants.enableLogs) {
      print('🎧 Listener agregado para evento: $evento');
    }
  }

  /// Remover listener específico
  void off(String evento, Function callback) {
    _listeners[evento]?.remove(callback);
    if (AppConstants.enableLogs) {
      print('🔇 Listener removido de evento: $evento');
    }
  }

  /// Remover todos los listeners de un evento
  void offAll(String evento) {
    _listeners.remove(evento);
    if (AppConstants.enableLogs) {
      print('🔇 Todos los listeners removidos de: $evento');
    }
  }

  /// Notificar a todos los listeners de un evento
  void _notificarListeners(String evento, dynamic data) {
    if (_listeners.containsKey(evento)) {
      for (var listener in _listeners[evento]!) {
        try {
          listener(data);
        } catch (e) {
          print('❌ Error en listener de $evento: $e');
        }
      }
    }
  }

  // ════════════════════════════════════════════════════════
  // 🔍 GETTERS
  // ════════════════════════════════════════════════════════

  /// Verificar si está conectado
  bool get conectado => _socket?.connected ?? false;

  /// Obtener ID del socket
  String? get socketId => _socket?.id;

  /// Verificar si está conectando
  bool get conectando => _isConnecting;
}
