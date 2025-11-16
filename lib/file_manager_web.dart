import 'dart.html' as html;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'equipment_record.dart';
import 'file_manager_interface.dart';

const String _registroKey = 'registro_txt_data';
const String _equiposKey = 'equipos_csv_data';

class FileManager implements FileManagerInterface {

  // (saveDataToFile y searchInFile no cambian)
  @override
  Future<bool> saveDataToFile(
      String date, String ut, String point, String description) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> records = prefs.getStringList(_registroKey) ?? [];
      records.add("$date,$ut,$point,$description");
      await prefs.setStringList(_registroKey, records);
      return true;
    } catch (e) {
      print("Error al guardar en SharedPreferences (web): $e");
      return false;
    }
  }

  DateTime? _parseDate(String dateStr) {
    try {
      return DateFormat('d/M/yyyy').parseStrict(dateStr);
    } catch (e) { return null; }
  }

  @override
  Future<List<String>> searchInFile(
      String startDateStr, String endDateStr, String ut, String plant) async {
    final results = <String>[];
    final prefs = await SharedPreferences.getInstance();
    final List<String> lines = prefs.getStringList(_registroKey) ?? [];
    final DateTime? startDate = _parseDate(startDateStr);
    final DateTime? endDate = _parseDate(endDateStr);
    try {
      for (final line in lines) {
        if (line.isEmpty) continue;
        final parts = line.split(',');
        if (parts.length < 4) continue;
        final String recordDateStr = parts[0];
        final String recordUt = parts[1];
        bool matchesDate = true;
        final DateTime? recordDate = _parseDate(recordDateStr);
        if (recordDate != null) {
          if (startDate != null && recordDate.isBefore(startDate)) matchesDate = false;
          if (endDate != null && recordDate.isAfter(endDate)) matchesDate = false;
        } else if (startDate != null || endDate != null) {
          matchesDate = false;
        }
        final bool matchesUt = ut.isEmpty || recordUt.toLowerCase().contains(ut.toLowerCase());
        final bool matchesPlant = plant.isEmpty || recordUt.toLowerCase().startsWith(plant.toLowerCase());
        if (matchesDate && matchesUt && matchesPlant) {
          results.add(line);
        }
      }
    } catch (e) {
      print("Error al buscar en SharedPreferences (web): $e");
    }
    return results;
  }

  // --- Funciones de EQUIPOS (Versión Web) ---

  @override
  Future<bool> saveEquipmentToCsv(
      String date, String ut, String equipment) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> records = prefs.getStringList(_equiposKey) ?? [];
      records.add("$date,$ut,$equipment");
      await prefs.setStringList(_equiposKey, records);
      return true;
    } catch (e) {
      print("Error al guardar en SharedPreferences (web): $e");
      return false;
    }
  }

  @override
  Future<List<EquipmentRecord>> readEquipmentRecords() async {
    final results = <EquipmentRecord>[];
    final prefs = await SharedPreferences.getInstance();
    final List<String> lines = prefs.getStringList(_equiposKey) ?? [];
    try {
      for (final line in lines) {
        if (line.isEmpty) continue;
        final parts = line.split(',');
        if (parts.length >= 3) {
          // --- CAMBIO AQUÍ ---
          // Le pasamos 'id: null' porque este registro viene de localStorage,
          // no de Firebase.
          results.add(EquipmentRecord(
              id: null, // <-- AÑADIDO
              date: parts[0],
              ut: parts[1],
              equipment: parts[2]
          ));
          // --- FIN DEL CAMBIO ---
        }
      }
    } catch (e) {
      print("Error al leer SharedPreferences (web): $e");
    }
    results.sort((a, b) => b.date.compareTo(a.date));
    return results;
  }

  @override
  Future<bool> deleteEquipmentRecords(List<EquipmentRecord> recordsToDelete) async {
    // (Esta función no necesita cambios, ya que nuestro '=='
    // actualizado en EquipmentRecord sabe cómo manejar 'id: null')
    final prefs = await SharedPreferences.getInstance();
    final List<String> lines = prefs.getStringList(_equiposKey) ?? [];
    final recordsToDeleteSet = recordsToDelete
        .map((r) => "${r.date},${r.ut},${r.equipment}")
        .toSet();
    if (recordsToDeleteSet.isEmpty) return true;
    try {
      final linesToKeep = <String>[];
      for (final line in lines) {
        if (line.isNotEmpty && !recordsToDeleteSet.contains(line)) {
          linesToKeep.add(line);
        }
      }
      await prefs.setStringList(_equiposKey, linesToKeep);
      return true;
    } catch (e) {
      print("Error al eliminar de SharedPreferences (web): $e");
      return false;
    }
  }

  @override
  Future<String> getNextImageName(String ut) async {
    // (Esta función no cambia)
    final prefs = await SharedPreferences.getInstance();
    final prefix = ut.length >= 4 ? ut.substring(0, 4).toUpperCase() : ut.toUpperCase();
    final key = "image_counter_$prefix";
    final int counter = prefs.getInt(key) ?? 1;
    final String fileName = "$prefix-${counter.toString().padLeft(3, '0')}.jpg";
    await prefs.setInt(key, counter + 1);
    return fileName;
  }

  @override
  Future<String?> generateDatedCsvFileWithFilter() async {
    // (Esta función no cambia)
    print("Generando CSV... (lógica de descarga se manejará en la UI)");
    final String currentDate = "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";
    final allRecords = await readEquipmentRecords();
    final filteredRecords = allRecords.where((record) => record.date == currentDate).toList();
    if (filteredRecords.isEmpty) {
      return null;
    }
    final csvContent = filteredRecords
        .map((r) => "${r.date},${r.ut},${r.equipment}")
        .join('\n');
    return csvContent;
  }
}