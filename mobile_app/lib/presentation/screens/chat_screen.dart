// ════════════════════════════════════════════════════════
// 💬 PANTALLA DE CHAT - CORREGIDO
// lib/presentation/screens/chat_screen.dart
// ════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../../widgets/chat_bubble_widget.dart';

class ChatScreen extends StatefulWidget {
  final String username;
  final String? userId;

  const ChatScreen({
    Key? key,
    required this.username,
    this.userId,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isComposing = false;
  bool _initialized = false;
  ChatProvider? _chatProvider; // Store provider reference

  @override
  void initState() {
    super.initState();
    // Ejecutar la inicialización después del primer frame para evitar
    // llamar a notifyListeners() mientras el árbol de widgets está bloqueado.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initializeChat();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Save provider reference safely
    _chatProvider = context.read<ChatProvider>();
  }

  // ✅ NUEVO: Inicializar el chat correctamente
  Future<void> _initializeChat() async {
    try {
      print('🚀 Inicializando chat...');

      final chatProvider = context.read<ChatProvider>();

      // Inicializar con nombre y ID del usuario
      await chatProvider.inicializar(
        usuarioNombre: widget.username,
        usuarioId: widget.userId ?? widget.username,
      );

      print('✅ Chat inicializado correctamente');
      print('📊 Mensajes cargados: ${chatProvider.mensajes.length}');

      setState(() {
        _initialized = true;
      });

      // Abrir el chat
      chatProvider.abrirChat();

      // Scroll al final después de un delay
      Future.delayed(const Duration(milliseconds: 500), () {
        _scrollToBottom();
      });
    } catch (e) {
      print('❌ Error al inicializar chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al conectar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // Use stored provider reference instead of context
    _chatProvider?.cerrarChat();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients && mounted) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients && mounted) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _enviarMensaje() async {
    final mensaje = _messageController.text.trim();

    if (mensaje.isEmpty) return;

    final chatProvider = context.read<ChatProvider>();

    setState(() {
      _isComposing = false;
      _messageController.clear();
    });

    print('📤 Enviando mensaje: $mensaje');

    final enviado = await chatProvider.enviarMensaje(widget.username, mensaje);

    if (!enviado && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No se pudo enviar el mensaje'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Reintentar',
            textColor: Colors.white,
            onPressed: () {
              _messageController.text = mensaje;
              _enviarMensaje();
            },
          ),
        ),
      );
    } else {
      print('✅ Mensaje enviado correctamente');
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Chat de la comunidad'),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: chatProvider.conectado
                          ? Colors.green.shade400
                          : Colors.red.shade400,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          chatProvider.conectado ? 'En línea' : 'Desconectado',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ BANNER DE ESTADO
          if (!_initialized)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.orange.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation(Colors.orange.shade700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Conectando al chat...',
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // ✅ LISTA DE MENSAJES
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                // Loading
                if (!_initialized ||
                    (chatProvider.cargando && chatProvider.mensajes.isEmpty)) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Cargando mensajes...'),
                      ],
                    ),
                  );
                }

                // Error
                if (chatProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar mensajes',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            chatProvider.error!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () async {
                            chatProvider.limpiarError();
                            await chatProvider.cargarMensajes();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Sin mensajes
                if (chatProvider.mensajes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay mensajes aún',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '¡Sé el primero en escribir!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // ✅ LISTA DE MENSAJES
                print('📱 Mostrando ${chatProvider.mensajes.length} mensajes');

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: chatProvider.mensajes.length,
                  itemBuilder: (context, index) {
                    final mensaje = chatProvider.mensajes[index];

                    // ✅ CORREGIDO: Usar usuarioNombre
                    final esMio = mensaje.usuarioNombre == widget.username;

                    return ChatBubbleWidget(
                      mensaje: mensaje,
                      esMio: esMio,
                    );
                  },
                );
              },
            ),
          ),

          // ✅ CAMPO DE TEXTO
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        enabled: _initialized,
                        decoration: InputDecoration(
                          hintText: _initialized
                              ? 'Escribe un mensaje...'
                              : 'Conectando...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (text) {
                          setState(() {
                            _isComposing = text.trim().isNotEmpty;
                          });
                        },
                        onSubmitted: (_) => _enviarMensaje(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: (_isComposing && _initialized)
                          ? Colors.indigo.shade700
                          : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded),
                      color: Colors.white,
                      onPressed: (_isComposing && _initialized)
                          ? _enviarMensaje
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
