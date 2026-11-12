import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MovimientoDialog extends StatefulWidget {
  const MovimientoDialog({super.key, required this.titulo});

  /// Dialog title, e.g. "Registrar Entrada" or "Registrar Salida".
  final String titulo;

  @override
  State<MovimientoDialog> createState() => _MovimientoDialogState();
}

class _MovimientoDialogState extends State<MovimientoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController();

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esEntrada = widget.titulo.toLowerCase().contains('entrada');

    return AlertDialog(
      icon: Icon(
        esEntrada ? Icons.add_circle_outline : Icons.remove_circle_outline,
        color: esEntrada ? Colors.green : Colors.orange,
      ),
      title: Text(widget.titulo),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _cantidadController,
          decoration: const InputDecoration(
            labelText: 'Cantidad',
            hintText: 'Ingresa la cantidad',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.numbers),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          autofocus: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La cantidad es obligatoria';
            }
            final cantidad = int.tryParse(value.trim());
            if (cantidad == null || cantidad <= 0) {
              return 'La cantidad debe ser mayor a 0';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _confirmar,
          child: const Text('Confirmar'),
        ),
      ],
    );
  }

  void _confirmar() {
    if (!_formKey.currentState!.validate()) return;

    final cantidad = int.parse(_cantidadController.text.trim());
    Navigator.of(context).pop(cantidad);
  }
}
