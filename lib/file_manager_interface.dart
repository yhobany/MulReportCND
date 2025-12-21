// lib/file_manager_interface.dart

import 'equipment_record.dart';
import 'registro_record.dart';

abstract class FileManagerInterface {

  // --- Funciones de Registro ---

  // CAMBIO: Añadido parámetro 'status'
  Future<bool> saveDataToFile(
      String date, String ut, String point, String description, String priority, String status);

  // CAMBIO: Añadido parámetro 'status' (filtro)
  Future<List<RegistroRecord>> searchInFile(
      String startDateStr, String endDateStr, String ut, String plant, String priority, String status);

  Future<bool> deleteRegistros(List<RegistroRecord> recordsToDelete);

  // NUEVO: Función para actualizar solo el estatus
  Future<bool> updateRegistroStatus(RegistroRecord record, String newStatus);

  // --- Funciones de Equipos (Sin cambios) ---

  Future<bool> saveEquipmentToCsv(
      String date, String ut, String equipment);

  Future<List<EquipmentRecord>> readEquipmentRecords();

  Future<bool> deleteEquipmentRecords(List<EquipmentRecord> recordsToDelete);

  Future<String> getNextImageName(String ut);

  Future<List<EquipmentRecord>> searchInEquiposFile(
      String startDateStr, String endDateStr, String ut, String plant);

  Future<String?> exportRecords(List<EquipmentRecord> records);
}