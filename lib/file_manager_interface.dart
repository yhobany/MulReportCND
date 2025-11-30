// lib/file_manager_interface.dart

import 'equipment_record.dart';

abstract class FileManagerInterface {

  // --- Funciones de Registro ---
  Future<bool> saveDataToFile(
      String date, String ut, String point, String description);

  Future<List<String>> searchInFile(
      String startDateStr, String endDateStr, String ut, String plant);

  // --- Funciones de Equipos ---
  Future<bool> saveEquipmentToCsv(
      String date, String ut, String equipment);

  Future<List<EquipmentRecord>> readEquipmentRecords();

  Future<bool> deleteEquipmentRecords(List<EquipmentRecord> recordsToDelete);

  Future<String> getNextImageName(String ut);

  // --- CAMBIO AQUÍ ---
  // Ahora recibe la lista de registros a exportar
  // Ya no filtra por fecha internamente.
  Future<String?> exportRecords(List<EquipmentRecord> records);
}