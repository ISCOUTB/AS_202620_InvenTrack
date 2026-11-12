import 'package:flutter/material.dart';

import 'package:inventrack/models/producto.dart';

class CrearProductoDialog extends StatefulWidget {
  const CrearProductoDialog({super.key});

  @override
  State<CrearProductoDialog> createState() => _CrearProductoDialogState();
}

class _CrearProductoDialogState extends State<CrearProductoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nombreController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    _nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.add_box_outlined),
      title: const Text('Nuevo Producto'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: 'ID del Producto',
                hintText: 'ej: PROD-001',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El ID es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Producto',
                hintText: 'ej: Tornillo M8',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es obligatorio';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _crear,
          child: const Text('Crear'),
        ),
      ],
    );
  }

  void _crear() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      CrearProductoRequest(
        id: _idController.text.trim(),
        nombre: _nombreController.text.trim(),
      ),
    );
  }
}
