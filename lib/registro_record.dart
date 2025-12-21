// lib/registro_record.dart

class RegistroRecord {
  final String? id;
  final String date;
  final String ut;
  final String point;
  final String description;
  final String priority;
  final String status; // <-- NUEVO CAMPO

  RegistroRecord({
    this.id,
    required this.date,
    required this.ut,
    required this.point,
    required this.description,
    this.priority = 'Medio',
    this.status = 'Abierto', // <-- Valor por defecto
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RegistroRecord) return false;
    if (id != null && other.id != null) return id == other.id;
    return date == other.date &&
        ut == other.ut &&
        point == other.point &&
        description == other.description &&
        priority == other.priority &&
        status == other.status; // <-- Incluir en comparación
  }

  @override
  int get hashCode => id?.hashCode ?? Object.hash(date, ut, point, description, priority, status);
}