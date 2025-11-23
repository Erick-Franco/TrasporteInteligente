// ════════════════════════════════════════════════════════
// 💬 SERVICIO DE CHAT GLOBAL - TRANSPORTE INTELIGENTE
// lib/services/chat_service.dart
// MIGRADO A FIREBASE FIRESTORE
// ════════════════════════════════════════════════════════

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/mensaje_model.dart';

class ChatService {
  // Singleton pattern
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream de mensajes
  StreamSubscription<QuerySnapshot>? _mensajesSubscription;

  // Listeners para nuevos mensajes
  final List<Function(MensajeModel)> _listeners = [];

  // Info del usuario actual
  String? _usuarioNombre;
  String? _usuarioId;
  String? _usuarioTipo; // 'conductor' o 'gerente'

  // ════════════════════════════════════════════════════════
  // 🔌 CONEXIÓN
  // ════════════════════════════════════════════════════════

  /// Conectar al chat (Firestore listeners)
  Future<void> conectar({
    required String usuarioNombre,
    required String usuarioId,
    String usuarioTipo = 'conductor',
  }) async {
    _usuarioNombre = usuarioNombre;
    _usuarioId = usuarioId;
    _usuarioTipo = usuarioTipo;

    // Iniciar escucha de mensajes en tiempo real
    _escucharMensajes();

    print('✅ Chat conectado como: $usuarioNombre ($usuarioTipo)');
  }

  /// Escuchar mensajes en tiempo real desde Firestore
  void _escucharMensajes() {
    // Cancelar suscripción anterior si existe
    _mensajesSubscription?.cancel();

    // Escuchar nuevos mensajes ordenados por timestamp
    _mensajesSubscription = _firestore
        .collection('mensajes_chat')
        .orderBy('timestamp', descending: false)
        .limit(100)
        .snapshots()
        .listen(
      (snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            try {
              final data = change.doc.data()!;
              data['id'] = change.doc.id;

              // Convertir Timestamp a DateTime
              if (data['timestamp'] is Timestamp) {
                data['timestamp'] =
                    (data['timestamp'] as Timestamp).toDate().toIso8601String();
              }

              final mensaje = MensajeModel.fromJson(data);

              // Notificar TODOS los mensajes (propios y de otros)
              print(
                  '💬 Nuevo mensaje recibido: ${mensaje.usuarioNombre}: ${mensaje.mensaje}');
              _notificarListeners(mensaje);
            } catch (e) {
              print('❌ Error al procesar mensaje: $e');
            }
          }
        }
      },
      onError: (error) {
        print('❌ Error en stream de mensajes: $error');
      },
    );

    print('🎧 Escuchando mensajes en tiempo real');
  }

  /// Desconectar del chat
  void desconectar() {
    _mensajesSubscription?.cancel();
    _mensajesSubscription = null;
    _listeners.clear();

    _usuarioNombre = null;
    _usuarioId = null;
    _usuarioTipo = null;

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
      final snapshot = await _firestore
          .collection('mensajes_chat')
          .orderBy('timestamp', descending: true)
          .limit(limite)
          .get();

      final mensajes = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;

        // Convertir Timestamp a DateTime
        if (data['timestamp'] is Timestamp) {
          data['timestamp'] =
              (data['timestamp'] as Timestamp).toDate().toIso8601String();
        }

        return MensajeModel.fromJson(data);
      }).toList();

      // Invertir para que los más antiguos estén primero
      return mensajes.reversed.toList();
    } catch (e) {
      print('❌ Error al obtener mensajes: $e');
      return [];
    }
  }

  /// Enviar mensaje a Firestore
  Future<bool> enviarMensaje({
    required String mensaje,
    String? usuarioNombre,
    String? usuarioId,
    String? usuarioTipo,
  }) async {
    try {
      final nombre = usuarioNombre ?? _usuarioNombre;
      final id = usuarioId ?? _usuarioId;
      final tipo = usuarioTipo ?? _usuarioTipo ?? 'conductor';

      if (nombre == null || id == null) {
        print('❌ Usuario no identificado. Llama a conectar() primero.');
        return false;
      }

      // Validar mensaje
      if (mensaje.trim().isEmpty) {
        print('❌ Mensaje vacío');
        return false;
      }

      // Guardar mensaje en Firestore
      await _firestore.collection('mensajes_chat').add({
        'usuario_id': id,
        'usuario_nombre': nombre,
        'usuario_tipo': tipo,
        'mensaje': mensaje.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'leido': false,
      });

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
      usuarioTipo: mensaje.usuarioTipo,
    );
  }

  /// Obtener stream de mensajes en tiempo real
  Stream<List<MensajeModel>> getMensajesStream({int limite = 50}) {
    return _firestore
        .collection('mensajes_chat')
        .orderBy('timestamp', descending: true)
        .limit(limite)
        .snapshots()
        .map((snapshot) {
      final mensajes = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;

        // Convertir Timestamp a DateTime
        if (data['timestamp'] is Timestamp) {
          data['timestamp'] =
              (data['timestamp'] as Timestamp).toDate().toIso8601String();
        }

        return MensajeModel.fromJson(data);
      }).toList();

      // Invertir para que los más antiguos estén primero
      return mensajes.reversed.toList();
    });
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
  bool get conectado => _mensajesSubscription != null;

  /// Obtener nombre del usuario actual
  String? get usuarioActual => _usuarioNombre;

  /// Obtener ID del usuario actual
  String? get usuarioActualId => _usuarioId;

  /// Verificar si hay un usuario identificado
  bool get tieneUsuario => _usuarioNombre != null && _usuarioId != null;

  /// Obtener tipo de usuario
  String? get tipoUsuario => _usuarioTipo;

  // ════════════════════════════════════════════════════════
  // 🧹 CLEANUP
  // ════════════════════════════════════════════════════════

  /// Limpiar recursos
  Future<void> dispose() async {
    await _mensajesSubscription?.cancel();
    _listeners.clear();
  }
}
