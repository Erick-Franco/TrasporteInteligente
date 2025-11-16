// lib/widgets/buscador_destino_widget.dart

import 'package:flutter/material.dart';

class BuscadorDestinoWidget extends StatefulWidget {
  final Function(String) onBuscar;
  final VoidCallback? onLimpiar;
  final bool cargando;

  const BuscadorDestinoWidget({
    Key? key,
    required this.onBuscar,
    this.onLimpiar,
    this.cargando = false,
  }) : super(key: key);

  @override
  State<BuscadorDestinoWidget> createState() => _BuscadorDestinoWidgetState();
}

class _BuscadorDestinoWidgetState extends State<BuscadorDestinoWidget> {
  final TextEditingController _controller = TextEditingController();
  bool _mostrarLimpiar = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _mostrarLimpiar = _controller.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: Colors.grey.shade600,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: '¿A dónde quieres ir?',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 15),
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  widget.onBuscar(value.trim());
                }
              },
            ),
          ),
          if (widget.cargando)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.indigo.shade700,
              ),
            )
          else if (_mostrarLimpiar)
            InkWell(
              onTap: () {
                _controller.clear();
                if (widget.onLimpiar != null) {
                  widget.onLimpiar!();
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
