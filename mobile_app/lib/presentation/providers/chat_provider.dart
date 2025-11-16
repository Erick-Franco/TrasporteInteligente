// ════════════════════════════════════════════════════════
// 💬 PROVIDER DE CHAT - CORREGIDO
// lib/presentation/providers/chat_provider.dart
// ════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import '../../data/models/mensaje_model.dart';
import '../../data/repositories/chat_repository.dart';

class ChatProvider with ChangeNotifier {
  final ChatRepository _repository = ChatRepository();

  List<MensajeModel> _mensajes = [];
  bool _cargando = false;
  String? _error;
  int _mensajesNoLeidos = 0;
  bool _chatAbierto = false;
  String? _usuarioNombre;
  String? _usuarioId;

  // Getters
  List<MensajeModel> get mensajes => _mensajes;
  bool get cargando => _cargando;
  String? get error => _error;
  int get mensajesNoLeidos => _mensajesNoLeidos;
  bool get chatAbierto => _chatAbierto;
  bool get conectado => _repository.conectado;

  ChatProvider() {
    print('🏗️ ChatProvider inicializado');
  }

  // ════════════════════════════════════════════════════════
  // 🚀 INICIALIZACIÓN
  // ════════════════════════════════════════════════════════

  /// ✅ Inicializar chat con datos del usuario
  Future<void> inicializar({
    required String usuarioNombre,
    required String usuarioId,
  }) async {
    print('🚀 Inicializando ChatProvider...');
    print('👤 Usuario: $usuarioNombre (ID: $usuarioId)');

    _usuarioNombre = usuarioNombre;
    _usuarioId = usuarioId;

    // 1️⃣ Conectar WebSocket
    await conectar();

    // 2️⃣ Cargar mensajes históricos de la DB
    await cargarMensajes();

    // 3️⃣ Escuchar nuevos mensajes en tiempo real
    _escucharNuevosMensajes();

    print('✅ ChatProvider inicializado correctamente');
  }

  // ════════════════════════════════════════════════════════
  // 🔌 CONEXIÓN
  // ════════════════════════════════════════════════════════

  Future<void> conectar() async {
    if (_usuarioNombre == null || _usuarioId == null) {
      _error = 'Debes llamar a inicializar() primero';
      notifyListeners();
      return;
    }

    try {
      print('🔌 Conectando al chat WebSocket...');
      await _repository.conectar(
        usuarioNombre: _usuarioNombre!,
        usuarioId: _usuarioId!,
      );
      print('✅ Conectado al chat');
      notifyListeners();
    } catch (e) {
      print('❌ Error al conectar: $e');
      _error = 'Error al conectar al chat: $e';
      notifyListeners();
    }
  }

  void desconectar() {
    print('🔌 Desconectando chat...');
    _repository.desconectar();
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════
  // 💬 MENSAJES
  // ════════════════════════════════════════════════════════

  /// ✅ Cargar mensajes históricos con DEBUG
  Future<void> cargarMensajes() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      print('📥 Cargando mensajes del chat desde la DB...');
      _mensajes = await _repository.obtenerMensajes();

      print('✅ Mensajes cargados: ${_mensajes.length}');

      // ✅ DEBUG: Mostrar los primeros 3 mensajes
      if (_mensajes.isNotEmpty) {
        for (int i = 0;
            i < (_mensajes.length > 3 ? 3 : _mensajes.length);
            i++) {
          final m = _mensajes[i];
          print(
              '  📝 [$i] ${m.usuarioNombre}: ${m.mensaje.substring(0, m.mensaje.length > 30 ? 30 : m.mensaje.length)}...');
        }
      } else {
        print('  ⚠️ No hay mensajes en la DB');
      }

      _cargando = false;
      notifyListeners();
    } catch (e) {
      print('❌ Error al cargar mensajes: $e');
      _error = 'Error al cargar mensajes: $e';
      _cargando = false;
      notifyListeners();
    }
  }

  /// ✅ Enviar mensaje
  Future<bool> enviarMensaje(String username, String texto) async {
    if (texto.trim().isEmpty) {
      print('⚠️ Mensaje vacío, ignorado');
      return false;
    }

    try {
      final nombreUsuario = _usuarioNombre ?? username;
      final idUsuario = _usuarioId ?? username;

      print(
          '📤 Enviando mensaje de $nombreUsuario: ${texto.substring(0, texto.length > 50 ? 50 : texto.length)}...');

      final mensaje = MensajeModel(
        usuarioNombre: nombreUsuario,
        usuarioId: idUsuario,
        mensaje: texto.trim(),
        tipo: 'texto',
      );

      final enviado = await _repository.enviarMensaje(mensaje);

      if (!enviado) {
        print('❌ No se pudo enviar el mensaje');
        _error = 'No se pudo enviar el mensaje';
        notifyListeners();
      } else {
        print('✅ Mensaje enviado correctamente');
      }

      return enviado;
    } catch (e) {
      print('❌ Error al enviar mensaje: $e');
      _error = 'Error al enviar mensaje: $e';
      notifyListeners();
      return false;
    }
  }

  // ════════════════════════════════════════════════════════
  // 🎧 TIEMPO REAL
  // ════════════════════════════════════════════════════════

  /// ✅ Escuchar nuevos mensajes vía WebSocket
  void _escucharNuevosMensajes() {
    print('🎧 Configurando listener para nuevos mensajes...');

    _repository.escucharNuevosMensajes((nuevoMensaje) {
      print('💬 Nuevo mensaje recibido vía WebSocket:');
      print('   Usuario: ${nuevoMensaje.usuarioNombre}');
      print(
          '   Mensaje: ${nuevoMensaje.mensaje.substring(0, nuevoMensaje.mensaje.length > 50 ? 50 : nuevoMensaje.mensaje.length)}...');
      print('   Timestamp: ${nuevoMensaje.fechaEnvio}');

      // ✅ Verificar que no exista duplicado
      final existe = _mensajes.any((m) =>
          m.id == nuevoMensaje.id ||
          (m.mensaje == nuevoMensaje.mensaje &&
              m.usuarioNombre == nuevoMensaje.usuarioNombre &&
              m.fechaEnvio.difference(nuevoMensaje.fechaEnvio).inSeconds.abs() <
                  2));

      if (!existe) {
        _mensajes.add(nuevoMensaje);

        // Incrementar contador si el chat está cerrado
        if (!_chatAbierto) {
          _mensajesNoLeidos++;
        }

        print('✅ Mensaje agregado a la lista (Total: ${_mensajes.length})');
        notifyListeners();
      } else {
        print('⚠️ Mensaje duplicado detectado, ignorado');
      }
    });

    print('✅ Listener configurado correctamente');
  }

  // ════════════════════════════════════════════════════════
  // 🎯 ESTADO DEL CHAT
  // ════════════════════════════════════════════════════════

  void abrirChat() {
    print('📖 Chat abierto por usuario');
    _chatAbierto = true;
    _mensajesNoLeidos = 0;
    notifyListeners();
  }

  void cerrarChat() {
    print('📕 Chat cerrado por usuario');
    _chatAbierto = false;
    notifyListeners();
  }

  void limpiarError() {
    _error = null;
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════
  // 🗑️ CLEANUP
  // ════════════════════════════════════════════════════════

  @override
  void dispose() {
    print('🗑️ Disposing ChatProvider');
    desconectar();
    super.dispose();
  }
}
