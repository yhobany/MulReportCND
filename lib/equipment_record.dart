// lib/equipment_record.dart

class EquipmentRecord {
  final String date;
  final String ut;
  final String equipment;

  EquipmentRecord({required this.date, required this.ut, required this.equipment});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is EquipmentRecord &&
              runtimeType == other.runtimeType &&
              date == other.date &&
              ut == other.ut &&
              equipment == other.equipment;

  @override
  int get hashCode => date.hashCode ^ ut.hashCode ^ equipment.hashCode;
}