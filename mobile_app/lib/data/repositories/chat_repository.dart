// ════════════════════════════════════════════════════════
// 💬 REPOSITORIO DE CHAT - CORREGIDO
// lib/data/repositories/chat_repository.dart
// ════════════════════════════════════════════════════════

import '../models/mensaje_model.dart';
import '../../services/chat_service.dart';

class ChatRepository {
  final ChatService _chatService = ChatService();

  // ════════════════════════════════════════════════════════
  // 🔌 CONEXIÓN
  // ════════════════════════════════════════════════════════

  /// Conectar al chat con datos del usuario
  Future<void> conectar({
    required String usuarioNombre,
    required String usuarioId,
  }) async {
    print('🔗 ChatRepository: Conectando...');
    await _chatService.conectar(
      usuarioNombre: usuarioNombre,
      usuarioId: usuarioId,
    );
    print('✅ ChatRepository: Conectado');
  }

  /// Desconectar del chat
  void desconectar() {
    print('🔌 ChatRepository: Desconectando...');
    _chatService.desconectar();
  }

  // ════════════════════════════════════════════════════════
  // 💬 MENSAJES
  // ════════════════════════════════════════════════════════

  /// Obtener historial de mensajes con DEBUG
  Future<List<MensajeModel>> obtenerMensajes({
    int limite = 50,
  }) async {
    print('🔍 ChatRepository: Obteniendo mensajes (límite: $limite)');

    final mensajes = await _chatService.obtenerMensajes(limite: limite);

    print('✅ ChatRepository: ${mensajes.length} mensajes obtenidos');

    // ✅ DEBUG: Mostrar detalles de los primeros mensajes
    if (mensajes.isNotEmpty) {
      print('📋 Primeros mensajes:');
      for (int i = 0; i < (mensajes.length > 3 ? 3 : mensajes.length); i++) {
        final m = mensajes[i];
        print(
            '  [$i] ID:${m.id} | ${m.usuarioNombre}: ${m.mensaje.substring(0, m.mensaje.length > 30 ? 30 : m.mensaje.length)}');
      }
    } else {
      print('⚠️ ChatRepository: Lista de mensajes vacía');
    }

    return mensajes;
  }

  /// Enviar mensaje (usando MensajeModel)
  Future<bool> enviarMensaje(MensajeModel mensaje) async {
    print('📤 ChatRepository: Enviando mensaje de ${mensaje.usuarioNombre}');

    final resultado = await _chatService.enviarMensajeModel(mensaje);

    if (resultado) {
      print('✅ ChatRepository: Mensaje enviado exitosamente');
    } else {
      print('❌ ChatRepository: Falló el envío del mensaje');
    }

    return resultado;
  }

  /// Enviar mensaje (usando strings directamente)
  Future<bool> enviarMensajeTexto({
    required String mensaje,
    String? usuarioNombre,
    String? usuarioId,
  }) async {
    return await _chatService.enviarMensaje(
      mensaje: mensaje,
      usuarioNombre: usuarioNombre,
      usuarioId: usuarioId,
    );
  }

  // ════════════════════════════════════════════════════════
  // 🎧 LISTENERS
  // ════════════════════════════════════════════════════════

  /// Escuchar nuevos mensajes
  void escucharNuevosMensajes(Function(MensajeModel) callback) {
    print('🎧 ChatRepository: Registrando listener para nuevos mensajes');
    _chatService.agregarListener(callback);
  }

  /// Dejar de escuchar
  void dejarDeEscuchar(Function(MensajeModel) callback) {
    _chatService.removerListener(callback);
  }

  /// Limpiar todos los listeners
  void limpiarListeners() {
    _chatService.limpiarListeners();
  }

  // ════════════════════════════════════════════════════════
  // 🔧 GETTERS
  // ════════════════════════════════════════════════════════

  /// Verificar si está conectado
  bool get conectado => _chatService.conectado;

  /// Obtener usuario actual
  String? get usuarioActual => _chatService.usuarioActual;

  /// Verificar si hay un usuario identificado
  bool get tieneUsuario => _chatService.tieneUsuario;
}
