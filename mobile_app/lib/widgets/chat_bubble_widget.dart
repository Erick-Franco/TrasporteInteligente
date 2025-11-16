// lib/widgets/chat_bubble_widget.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/models/mensaje_model.dart';

class ChatBubbleWidget extends StatelessWidget {
  final MensajeModel mensaje;
  final bool esMio;

  const ChatBubbleWidget({
    Key? key,
    required this.mensaje,
    required this.esMio,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hora = DateFormat('HH:mm').format(mensaje.fechaEnvio);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            esMio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Nombre del usuario (solo si no es mío)
          if (!esMio)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Text(
                mensaje.username,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.indigo.shade700,
                ),
              ),
            ),

          // Burbuja del mensaje
          Row(
            mainAxisAlignment:
                esMio ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: esMio ? Colors.indigo.shade700 : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(esMio ? 16 : 4),
                      bottomRight: Radius.circular(esMio ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mensaje.mensaje,
                        style: TextStyle(
                          fontSize: 15,
                          color: esMio ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hora,
                        style: TextStyle(
                          fontSize: 11,
                          color: esMio
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
