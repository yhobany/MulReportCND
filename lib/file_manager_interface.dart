// lib/file_manager_interface.dart

import 'equipment_record.dart';
import 'registro_record.dart'; // <-- IMPORTANTE

abstract class FileManagerInterface {

  // --- Funciones de Registro ---
  Future<bool> saveDataToFile(
      String date, String ut, String point, String description);

  // CAMBIO: Devuelve List<RegistroRecord> en lugar de List<String>
  Future<List<RegistroRecord>> searchInFile(
      String startDateStr, String endDateStr, String ut, String plant);

  // NUEVO: Función para borrar registros seleccionados
  Future<bool> deleteRegistros(List<RegistroRecord> recordsToDelete);

  // --- Funciones de Equipos ---
  Future<bool> saveEquipmentToCsv(
      String date, String ut, String equipment);

  Future<List<EquipmentRecord>> readEquipmentRecords();

  Future<bool> deleteEquipmentRecords(List<EquipmentRecord> recordsToDelete);

  Future<String> getNextImageName(String ut);

  // CAMBIO: Devuelve List<EquipmentRecord> en lugar de List<String>
  Future<List<EquipmentRecord>> searchInEquiposFile(
      String startDateStr, String endDateStr, String ut, String plant);

  Future<String?> exportRecords(List<EquipmentRecord> records);
}