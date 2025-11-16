// ════════════════════════════════════════════════════════
// 💬 SERVICIO DE CHAT GLOBAL - TRANSPORTE INTELIGENTE
// lib/services/chat_service.dart
// ════════════════════════════════════════════════════════

import '../data/models/mensaje_model.dart';
import 'api_service.dart';
import 'socket_service.dart';

class ChatService {
  // Singleton pattern
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  // Usar servicios existentes para evitar duplicación
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();

  // Listeners para nuevos mensajes
  final List<Function(MensajeModel)> _listeners = [];

  // Info del usuario actual
  String? _usuarioNombre;
  String? _usuarioId;

  // ✅ NUEVO: Flag para evitar múltiples registros
  bool _listenerRegistrado = false;

  // ════════════════════════════════════════════════════════
  // 🔌 CONEXIÓN
  // ════════════════════════════════════════════════════════

  /// Conectar al chat (WebSocket)
  Future<void> conectar({
    required String usuarioNombre,
    required String usuarioId,
  }) async {
    _usuarioNombre = usuarioNombre;
    _usuarioId = usuarioId;

    // Conectar WebSocket si no está conectado
    if (!_socketService.conectado) {
      await _socketService.conectar();
    }

    // Unirse al chat
    _socketService.unirseAlChat(
      nombre: usuarioNombre,
      id: usuarioId,
    );

    // ✅ ARREGLO: Solo registrar listener UNA VEZ
    if (!_listenerRegistrado) {
      _registrarListeners();
      _listenerRegistrado = true;
      print('🎧 Listeners del WebSocket registrados');
    }

    print('✅ Chat conectado como: $usuarioNombre');
  }

  /// ✅ NUEVO: Registrar listeners una sola vez
  void _registrarListeners() {
    // Escuchar nuevos mensajes
    _socketService.on('chat-message', (data) {
      try {
        print(
            '💬 Nuevo mensaje recibido: ${data['usuario_nombre']}: ${data['mensaje']}');
        final mensaje = MensajeModel.fromJson(data);
        _notificarListeners(mensaje);
      } catch (e) {
        print('❌ Error al procesar mensaje: $e');
      }
    });

    // Escuchar nuevo-mensaje (backend emite con este nombre)
    _socketService.on('nuevo-mensaje', (data) {
      try {
        print(
            '💬 Nuevo mensaje recibido (nuevo-mensaje): ${data['usuario_nombre']}: ${data['mensaje']}');
        final mensaje = MensajeModel.fromJson(data);
        _notificarListeners(mensaje);
      } catch (e) {
        print('❌ Error al procesar mensaje: $e');
      }
    });

    // Escuchar usuarios que se unen
    _socketService.on('user-joined', (data) {
      print('👋 ${data['nombre']} se unió al chat');
    });

    // Escuchar usuarios que salen
    _socketService.on('user-left', (data) {
      print('👋 ${data['nombre']} salió del chat');
    });
  }

  /// Desconectar del chat
  void desconectar() {
    if (_usuarioNombre != null && _usuarioId != null) {
      _socketService.salirDelChat(
        nombre: _usuarioNombre!,
        id: _usuarioId!,
      );
    }

    // ✅ ARREGLO: Limpiar listeners del WebSocket
    _socketService.offAll('chat-message');
    _socketService.offAll('nuevo-mensaje');
    _socketService.offAll('user-joined');
    _socketService.offAll('user-left');

    _listenerRegistrado = false;
    _listeners.clear();

    _usuarioNombre = null;
    _usuarioId = null;

    print('🔌 Chat desconectado');
  }

  // ════════════════════════════════════════════════════════
  // 💬 MENSAJES
  // ════════════════════════════════════════════════════════

  /// Obtener historial de mensajes
  Future<List<MensajeModel>> obtenerMensajes({
    int limite = 50,
  }) async {
    try {
      final data = await _apiService.getMensajesChat(limit: limite);
      return data.map((json) => MensajeModel.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error al obtener mensajes: $e');
      return [];
    }
  }

  /// Enviar mensaje (via HTTP + WebSocket)
  Future<bool> enviarMensaje({
    required String mensaje,
    String? usuarioNombre,
    String? usuarioId,
  }) async {
    try {
      final nombre = usuarioNombre ?? _usuarioNombre;
      final id = usuarioId ?? _usuarioId;

      if (nombre == null || id == null) {
        print('❌ Usuario no identificado. Llama a conectar() primero.');
        return false;
      }

      // Validar mensaje
      if (mensaje.trim().isEmpty) {
        print('❌ Mensaje vacío');
        return false;
      }

      // ✅ SOLO enviar via HTTP REST (el backend ya emite via WebSocket)
      final success = await _apiService.enviarMensajeChat(
        usuarioNombre: nombre,
        usuarioId: id,
        mensaje: mensaje.trim(),
      );

      if (!success) {
        print('❌ Error al guardar mensaje en DB');
        return false;
      }

      print('✅ Mensaje enviado: $mensaje');
      return true;
    } catch (e) {
      print('❌ Error al enviar mensaje: $e');
      return false;
    }
  }

  /// Enviar mensaje con modelo MensajeModel
  Future<bool> enviarMensajeModel(MensajeModel mensaje) async {
    return await enviarMensaje(
      mensaje: mensaje.mensaje,
      usuarioNombre: mensaje.usuarioNombre,
      usuarioId: mensaje.usuarioId,
    );
  }

  // ════════════════════════════════════════════════════════
  // 🎧 LISTENERS
  // ════════════════════════════════════════════════════════

  /// Agregar listener para nuevos mensajes
  void agregarListener(Function(MensajeModel) callback) {
    if (!_listeners.contains(callback)) {
      _listeners.add(callback);
      print('🎧 Listener agregado al chat (Total: ${_listeners.length})');
    }
  }

  /// Remover listener
  void removerListener(Function(MensajeModel) callback) {
    _listeners.remove(callback);
    print('🔇 Listener removido del chat (Total: ${_listeners.length})');
  }

  /// Limpiar todos los listeners
  void limpiarListeners() {
    _listeners.clear();
    print('🔇 Todos los listeners del chat limpiados');
  }

  /// Notificar a todos los listeners
  void _notificarListeners(MensajeModel mensaje) {
    print('📢 Notificando a ${_listeners.length} listeners');
    for (var listener in _listeners) {
      try {
        listener(mensaje);
      } catch (e) {
        print('❌ Error en listener del chat: $e');
      }
    }
  }

  // ════════════════════════════════════════════════════════
  // 🔧 GETTERS
  // ════════════════════════════════════════════════════════

  /// Verificar si está conectado
  bool get conectado => _socketService.conectado;

  /// Obtener nombre del usuario actual
  String? get usuarioActual => _usuarioNombre;

  /// Obtener ID del usuario actual
  String? get usuarioActualId => _usuarioId;

  /// Verificar si hay un usuario identificado
  bool get tieneUsuario => _usuarioNombre != null && _usuarioId != null;
}
