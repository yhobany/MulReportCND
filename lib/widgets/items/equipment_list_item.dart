import 'package:flutter/material.dart';
import '../../equipment_record.dart';

class EquipmentListItem extends StatelessWidget {
  final EquipmentRecord item;
  final bool isSelected;
  final VoidCallback onToggleSelection;
  final VoidCallback onEdit;

  const EquipmentListItem({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onToggleSelection,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected ? Colors.indigo.shade50 : null,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: Checkbox(
            value: isSelected,
            activeColor: Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: (bool? value) => onToggleSelection(),
          ),
          title: Text(
            "${item.ut} (${item.date})",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(item.equipment),
          trailing: IconButton(
            icon: Icon(Icons.edit_note, color: Colors.grey.shade600),
            onPressed: onEdit,
            tooltip: "Editar Equipo",
          ),
          onTap: onToggleSelection,
        ),
      ),
    );
  }
}
