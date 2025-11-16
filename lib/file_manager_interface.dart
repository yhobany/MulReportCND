// lib/file_manager_interface.dart

// 1. Importar nuestro nuevo modelo de datos
import 'equipment_record.dart';

// 2. Quitamos las importaciones incorrectas (dart.dart y file_manager_mobile.dart)

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

  // 3. CAMBIO CLAVE:
  // En lugar de devolver un 'File' (específico de móvil),
  // devolvemos un 'String?' (la RUTA al archivo, que es neutral).
  Future<String?> generateDatedCsvFileWithFilter();
}