// ════════════════════════════════════════════════════════
// 💬 PROVIDER DE CHAT - TRANSPORTE INTELIGENTE
// lib/presentation/providers/chat_provider.dart
// MIGRADO A FIREBASE
// ════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../../data/models/mensaje_model.dart';
import '../../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();

  // Listener interno registrado en ChatService (para poder removerlo)
  Function(MensajeModel)? _internalListener;

  // IDs ya conocidos (pre-cargados) para evitar duplicados
  final Set<String> _knownIds = {};
  // Timestamp del último mensaje cargado durante la inicialización
  DateTime? _lastLoadedTimestamp;
  List<MensajeModel> _mensajes = [];
  bool _cargando = false;
  String? _error;
  int _mensajesNoLeidos = 0;
  bool _chatAbierto = false;
  String? _usuarioNombre;
  String? _usuarioId;
  String? _usuarioTipo;

  // Getters
  List<MensajeModel> get mensajes => _mensajes;
  bool get cargando => _cargando;
  String? get error => _error;
  int get mensajesNoLeidos => _mensajesNoLeidos;
  bool get chatAbierto => _chatAbierto;
  bool get conectado => _chatService.conectado;

  ChatProvider() {
    print('🏗️ ChatProvider inicializado');
  }

  // ════════════════════════════════════════════════════════
  // 🚀 INICIALIZACIÓN
  // ════════════════════════════════════════════════════════

  /// Inicializar chat con datos del usuario
  Future<void> inicializar({
    required String usuarioNombre,
    required String usuarioId,
    String usuarioTipo = 'conductor',
  }) async {
    print('🚀 Inicializando ChatProvider...');
    print('👤 Usuario: $usuarioNombre (ID: $usuarioId, Tipo: $usuarioTipo)');

    _usuarioNombre = usuarioNombre;
    _usuarioId = usuarioId;
    _usuarioTipo = usuarioTipo;

    // 1️⃣ Conectar a Firestore
    await conectar();

    // 2️⃣ Cargar mensajes históricos
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
      print('🔌 Conectando al chat Firestore...');
      await _chatService.conectar(
        usuarioNombre: _usuarioNombre!,
        usuarioId: _usuarioId!,
        usuarioTipo: _usuarioTipo ?? 'conductor',
      );
      print('✅ Conectado al chat');
      // notify after frame to avoid locked-tree issues
      SchedulerBinding.instance.addPostFrameCallback((_) {
        try {
          notifyListeners();
        } catch (e) {
          print('⚠️ notifyListeners fallo en conectar: $e');
        }
      });
    } catch (e) {
      print('❌ Error al conectar: $e');
      _error = 'Error al conectar al chat: $e';
      SchedulerBinding.instance.addPostFrameCallback((_) {
        try {
          notifyListeners();
        } catch (e) {
          print('⚠️ notifyListeners fallo en conectar(error): $e');
        }
      });
    }
  }

  void desconectar() {
    print('🔌 Desconectando chat...');
    // Remover listener si fue registrado
    if (_internalListener != null) {
      try {
        _chatService.removerListener(_internalListener!);
      } catch (e) {
        print('⚠️ Error removiendo listener interno: $e');
      }
      _internalListener = null;
    }

    _chatService.desconectar();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      try {
        notifyListeners();
      } catch (e) {
        print('⚠️ notifyListeners fallo en desconectar: $e');
      }
    });
  }

  // ════════════════════════════════════════════════════════
  // 💬 MENSAJES
  // ════════════════════════════════════════════════════════

  /// Cargar mensajes históricos
  Future<void> cargarMensajes() async {
    _cargando = true;
    _error = null;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      try {
        notifyListeners();
      } catch (e) {
        print('⚠️ notifyListeners fallo en cargarMensajes inicio: $e');
      }
    });

    try {
      print('📥 Cargando mensajes del chat desde Firestore...');
      _mensajes = await _chatService.obtenerMensajes();

      // Registrar IDs conocidos y calcular el último timestamp
      _knownIds.clear();
      if (_mensajes.isNotEmpty) {
        for (final m in _mensajes) {
          if (m.docId != null) _knownIds.add(m.docId!);
        }
        // El último mensaje (más reciente) estará al final de la lista
        _lastLoadedTimestamp = _mensajes.last.fechaEnvio;
      } else {
        _lastLoadedTimestamp = null;
      }

      print('✅ Mensajes cargados: ${_mensajes.length}');

      if (_mensajes.isNotEmpty) {
        for (int i = 0;
            i < (_mensajes.length > 3 ? 3 : _mensajes.length);
            i++) {
          final m = _mensajes[i];
          print(
              '  📝 [$i] ${m.usuarioNombre}: ${m.mensaje.substring(0, m.mensaje.length > 30 ? 30 : m.mensaje.length)}...');
        }
      } else {
        print('  ⚠️ No hay mensajes en Firestore');
      }

      _cargando = false;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        try {
          notifyListeners();
        } catch (e) {
          print('⚠️ notifyListeners fallo en cargarMensajes success: $e');
        }
      });
    } catch (e) {
      print('❌ Error al cargar mensajes: $e');
      _error = 'Error al cargar mensajes: $e';
      _cargando = false;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        try {
          notifyListeners();
        } catch (e) {
          print('⚠️ notifyListeners fallo en cargarMensajes error: $e');
        }
      });
    }
  }

  /// Enviar mensaje
  Future<bool> enviarMensaje(String username, String texto) async {
    if (texto.trim().isEmpty) {
      print('⚠️ Mensaje vacío, ignorado');
      return false;
    }

    try {
      final nombreUsuario = _usuarioNombre ?? username;
      final idUsuario = _usuarioId ?? username;
      final tipoUsuario = _usuarioTipo ?? 'conductor';

      print(
          '📤 Enviando mensaje de $nombreUsuario: ${texto.substring(0, texto.length > 50 ? 50 : texto.length)}...');

      final enviado = await _chatService.enviarMensaje(
        mensaje: texto.trim(),
        usuarioNombre: nombreUsuario,
        usuarioId: idUsuario,
        usuarioTipo: tipoUsuario,
      );

      if (!enviado) {
        print('❌ No se pudo enviar el mensaje');
        _error = 'No se pudo enviar el mensaje';
        SchedulerBinding.instance.addPostFrameCallback((_) {
          try {
            notifyListeners();
          } catch (e) {
            print('⚠️ notifyListeners fallo en enviarMensaje(no enviado): $e');
          }
        });
      } else {
        print('✅ Mensaje enviado correctamente');
        // El mensaje se agregará automáticamente vía listener de Firestore
      }

      return enviado;
    } catch (e) {
      print('❌ Error al enviar mensaje: $e');
      _error = 'Error al enviar mensaje: $e';
      SchedulerBinding.instance.addPostFrameCallback((_) {
        try {
          notifyListeners();
        } catch (e) {
          print('⚠️ notifyListeners fallo en enviarMensaje(catch): $e');
        }
      });
      return false;
    }
  }

  // ════════════════════════════════════════════════════════
  // 🎧 TIEMPO REAL
  // ════════════════════════════════════════════════════════

  /// Escuchar nuevos mensajes vía Firestore
  void _escucharNuevosMensajes() {
    print('🎧 Configurando listener para nuevos mensajes...');
    // Si ya hay un listener registrado, removerlo antes de registrar otro
    if (_internalListener != null) {
      try {
        _chatService.removerListener(_internalListener!);
      } catch (e) {
        print(
            '⚠️ Error removiendo listener previo antes de registrar uno nuevo: $e');
      }
      _internalListener = null;
    }

    // Crear listener y guardarlo para poder removerlo
    _internalListener = (MensajeModel nuevoMensaje) {
      print('💬 Nuevo mensaje recibido vía Firestore:');
      print('   Usuario: ${nuevoMensaje.usuarioNombre}');
      print(
          '   Mensaje: ${nuevoMensaje.mensaje.substring(0, nuevoMensaje.mensaje.length > 50 ? 50 : nuevoMensaje.mensaje.length)}...');

      // Si el mensaje es anterior o igual al último cargado, ignorarlo
      if (_lastLoadedTimestamp != null &&
          !nuevoMensaje.fechaEnvio.isAfter(_lastLoadedTimestamp!)) {
        print(
            '⚠️ Mensaje con timestamp ${nuevoMensaje.fechaEnvio} anterior/al último cargado, ignorado');
        return;
      }

      // Verificar que no exista duplicado
      final existe = _mensajes.any((m) =>
          // Coincidencia por docId cuando esté disponible
          ((m.docId != null && nuevoMensaje.docId != null) &&
              m.docId == nuevoMensaje.docId) ||
          // Fallback por contenido y proximidad temporal
          (m.mensaje == nuevoMensaje.mensaje &&
              m.usuarioNombre == nuevoMensaje.usuarioNombre &&
              m.fechaEnvio.difference(nuevoMensaje.fechaEnvio).inSeconds.abs() <
                  2));

      if (!existe) {
        _mensajes.add(nuevoMensaje);

        // Añadir a knownIds si viene con docId
        if (nuevoMensaje.docId != null) _knownIds.add(nuevoMensaje.docId!);

        // Incrementar contador si el chat está cerrado
        if (!_chatAbierto) {
          _mensajesNoLeidos++;
        }

        print('✅ Mensaje agregado a la lista (Total: ${_mensajes.length})');

        // Asegurarse de notificar después del frame activo
        SchedulerBinding.instance.addPostFrameCallback((_) {
          try {
            notifyListeners();
          } catch (e) {
            print('⚠️ notifyListeners fallo en listener: $e');
          }
        });
      } else {
        print('⚠️ Mensaje duplicado detectado, ignorado');
      }
    };

    _chatService.agregarListener(_internalListener!);

    print('✅ Listener configurado correctamente');
  }

  // ════════════════════════════════════════════════════════
  // 🎯 ESTADO DEL CHAT
  // ════════════════════════════════════════════════════════

  void abrirChat() {
    print('📖 Chat abierto por usuario');
    _chatAbierto = true;
    _mensajesNoLeidos = 0;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      try {
        notifyListeners();
      } catch (e) {
        print('⚠️ notifyListeners fallo en abrirChat: $e');
      }
    });
    // Asegurar que el listener esté registrado cuando el chat está abierto
    if (_internalListener == null) {
      try {
        _escucharNuevosMensajes();
      } catch (e) {
        print('⚠️ Error registrando listener al abrir chat: $e');
      }
    }
  }

  void cerrarChat() {
    print('📕 Chat cerrado por usuario');
    _chatAbierto = false;
    // Remover listener cuando el chat se cierra para evitar callbacks innecesarios
    if (_internalListener != null) {
      try {
        _chatService.removerListener(_internalListener!);
      } catch (e) {
        print('⚠️ Error removiendo listener al cerrar chat: $e');
      }
      _internalListener = null;
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      try {
        notifyListeners();
      } catch (e) {
        print('⚠️ notifyListeners fallo en cerrarChat: $e');
      }
    });
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
