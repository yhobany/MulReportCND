// lib/file_manager_interface.dart

import 'equipment_record.dart';
import 'registro_record.dart';

abstract class FileManagerInterface {

  // --- Funciones de Registro ---
  Future<bool> saveDataToFile(
      String date, String ut, String point, String description, String priority, String status);

  Future<List<RegistroRecord>> searchInFile(
      String startDateStr, String endDateStr, String ut, String plant, String priority, String status);

  Future<bool> deleteRegistros(List<RegistroRecord> recordsToDelete);

  Future<bool> updateRegistroStatus(RegistroRecord record, String newStatus, String actionNote);

  // --- Funciones de Equipos ---

  Future<bool> saveEquipmentToCsv(
      String date, String ut, String equipment);

  Future<List<EquipmentRecord>> readEquipmentRecords();

  Future<bool> deleteEquipmentRecords(List<EquipmentRecord> recordsToDelete);

  Future<bool> updateEquipment(EquipmentRecord oldRecord, String newUt, String newEquipment, String newDate);

  Future<String> getNextImageName(String ut);

  Future<List<EquipmentRecord>> searchInEquiposFile(
      String startDateStr, String endDateStr, String ut, String plant);

  Future<String?> exportRecords(List<EquipmentRecord> records);
}