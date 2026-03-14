import 'package:flutter/material.dart';
import '../../equipment_record.dart';

class EditEquipmentDialog extends StatefulWidget {
  final EquipmentRecord item;
  final Function(EquipmentRecord, String, String) onSave;

  const EditEquipmentDialog({super.key, required this.item, required this.onSave});

  @override
  State<EditEquipmentDialog> createState() => _EditEquipmentDialogState();
}

class _EditEquipmentDialogState extends State<EditEquipmentDialog> {
  late TextEditingController _utEditController;
  late TextEditingController _equipEditController;

  @override
  void initState() {
    super.initState();
    _utEditController = TextEditingController(text: widget.item.ut);
    _equipEditController = TextEditingController(text: widget.item.equipment);
  }

  @override
  void dispose() {
    _utEditController.dispose();
    _equipEditController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Equipo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Corrija los datos necesarios:"),
            const SizedBox(height: 16),
            TextField(
              controller: _utEditController,
              decoration: const InputDecoration(labelText: 'UT', border: OutlineInputBorder()),
              onChanged: (text) {
                _utEditController.value = _utEditController.value.copyWith(
                  text: text.toUpperCase(),
                  selection: TextSelection.collapsed(offset: text.length),
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _equipEditController,
              decoration: const InputDecoration(labelText: 'Equipo / Imagen', border: OutlineInputBorder()),
              onChanged: (text) {
                _equipEditController.value = _equipEditController.value.copyWith(
                  text: text.toUpperCase(),
                  selection: TextSelection.collapsed(offset: text.length),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final newUt = _utEditController.text.trim();
            final newEquip = _equipEditController.text.trim();

            if (newUt.isEmpty || newEquip.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Los campos no pueden estar vacíos'))
              );
              return;
            }

            Navigator.pop(context);
            widget.onSave(widget.item, newUt, newEquip);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
