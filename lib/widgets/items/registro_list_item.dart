import 'package:flutter/material.dart';
import '../../registro_record.dart';

class RegistroListItem extends StatelessWidget {
  final RegistroRecord item;
  final bool isSelected;
  final VoidCallback onToggleSelection;
  final VoidCallback onEdit;

  const RegistroListItem({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onToggleSelection,
    required this.onEdit,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'abierto': return const Color(0xFFEF4444); // Red 500
      case 'en proceso': return const Color(0xFFF59E0B); // Amber 500
      case 'culminado': return const Color(0xFF10B981); // Emerald 500
      default: return Colors.grey.shade600;
    }
  }

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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                // Prioridad Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flag_outlined, size: 14, color: Colors.grey.shade700),
                      const SizedBox(width: 4),
                      Text("Prioridad: ${item.priority}", style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(item.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getStatusColor(item.status).withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 10, color: _getStatusColor(item.status)),
                      const SizedBox(width: 6),
                      Text(
                          item.status.toUpperCase(),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: _getStatusColor(item.status)
                          )
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text("${item.point}\n${item.description}"),

            if (item.actionNote.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notes, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Nota: ${item.actionNote}",
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.blue.shade900, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )
            ],
            ],
          ),
          trailing: IconButton(
            icon: Icon(Icons.edit_note, color: Colors.grey.shade600),
            onPressed: onEdit,
            tooltip: "Editar Estatus",
          ),
          onTap: onToggleSelection,
        ),
      ),
    );
  }
}
