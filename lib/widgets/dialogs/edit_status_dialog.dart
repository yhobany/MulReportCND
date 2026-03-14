import 'package:flutter/material.dart';
import '../../registro_record.dart';

class EditStatusDialog extends StatefulWidget {
  final RegistroRecord item;
  final Function(RegistroRecord, String, String) onSave;

  const EditStatusDialog({super.key, required this.item, required this.onSave});

  @override
  State<EditStatusDialog> createState() => _EditStatusDialogState();
}

class _EditStatusDialogState extends State<EditStatusDialog> {
  late String _newStatus;
  late TextEditingController _noteController;

  final List<String> _statusEditOptions = ['Abierto', 'En Proceso', 'Culminado'];

  @override
  void initState() {
    super.initState();
    _newStatus = widget.item.status;
    _noteController = TextEditingController(text: widget.item.actionNote);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Actualizar Estatus'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("UT: ${widget.item.ut}", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Seleccione el nuevo estatus:"),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _newStatus,
            items: _statusEditOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (val) {
              setState(() {
                if (val != null) _newStatus = val;
              });
            },
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),

          if (_newStatus == 'En Proceso' || _newStatus == 'Culminado')
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Nota de la acción (Opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onSave(widget.item, _newStatus, _noteController.text.trim());
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
