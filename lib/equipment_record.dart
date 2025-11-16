// lib/equipment_record.dart

class EquipmentRecord {
  final String? id; // <-- 1. AÑADIDO: El ID único de la base de datos
  final String date;
  final String ut;
  final String equipment;

  EquipmentRecord({
    this.id, // <-- 2. AÑADIDO: al constructor
    required this.date,
    required this.ut,
    required this.equipment,
  });

  // --- 3. LÓGICA DE COMPARACIÓN ACTUALIZADA ---
  // Esto es crucial para que la app sepa si dos registros son "iguales"
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EquipmentRecord) return false;

    // Si los IDs están disponibles (vienen de Firebase),
    // son la única fuente de verdad.
    if (id != null && other.id != null) {
      return id == other.id;
    }

    // Si no hay IDs (vienen de archivos locales/web),
    // comparamos el contenido.
    return date == other.date &&
        ut == other.ut &&
        equipment == other.equipment;
  }

  @override
  int get hashCode {
    // Usar el ID para el 'hashCode' si existe
    if (id != null) {
      return id.hashCode;
    }
    // Usar el contenido si no hay ID
    return date.hashCode ^ ut.hashCode ^ equipment.hashCode;
  }
}