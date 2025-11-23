// ════════════════════════════════════════════════════════
// 💬 BOTÓN FLOTANTE DE CHAT - CORREGIDO
// lib/widgets/chat_floating_button.dart
// ════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../presentation/providers/chat_provider.dart';
import '../presentation/screens/chat_screen.dart';

class ChatFloatingButton extends StatelessWidget {
  final String username;
  final String? userId; // ✅ AGREGADO: Opcional user ID

  const ChatFloatingButton({
    Key? key,
    required this.username,
    this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final tieneNoLeidos = chatProvider.mensajesNoLeidos > 0;

        return Stack(
          children: [
            // ✅ BOTÓN PRINCIPAL
            FloatingActionButton(
              onPressed: () {
                print('💬 Abriendo ChatScreen para usuario: $username');

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      username: username,
                      userId: userId ?? username, // ✅ Pasar userId
                    ),
                  ),
                );
              },
              backgroundColor: Colors.indigo.shade700,
              child: const Icon(
                Icons.chat_bubble_rounded,
                color: Colors.white,
              ),
            ),

            // ✅ BADGE DE NOTIFICACIONES
            if (tieneNoLeidos)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  child: Center(
                    child: Text(
                      chatProvider.mensajesNoLeidos > 99
                          ? '99+'
                          : '${chatProvider.mensajesNoLeidos}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

            // ✅ INDICADOR DE ESTADO DE CONEXIÓN
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: chatProvider.conectado
                      ? Colors.green.shade500
                      : Colors.grey.shade400,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
