import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'equipment_record.dart';
import 'file_manager_interface.dart';

class FileManager implements FileManagerInterface {

  // (Todas las funciones de REGISTRO no cambian)

  Future<String> _getStorageDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _getRegistroFile() async {
    final path = await _getStorageDirectory();
    return File('$path/registro.txt');
  }

  @override
  Future<bool> saveDataToFile(
      String date, String ut, String point, String description) async {
    try {
      final file = await _getRegistroFile();
      final data = "$date,$ut,$point,$description\n";
      await file.writeAsString(data, mode: FileMode.append);
      return true;
    } catch (e) {
      print("Error al guardar en registro.txt: $e");
      return false;
    }
  }

  DateTime? _parseDate(String dateStr) {
    try {
      return DateFormat('d/M/yyyy').parseStrict(dateStr);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<String>> searchInFile(
      String startDateStr, String endDateStr, String ut, String plant) async {
    final results = <String>[];
    final file = await _getRegistroFile();
    if (!await file.exists()) return results;
    final DateTime? startDate = _parseDate(startDateStr);
    final DateTime? endDate = _parseDate(endDateStr);
    try {
      final lines = await file.readAsLines();
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
        if (matchesDate && matchesUt && matchesPlant) results.add(line);
      }
    } catch (e) {
      print("Error al leer/buscar en registro.txt: $e");
    }
    return results;
  }

  // --- EQUIPOS (equipos.csv) ---

  Future<File> _getEquiposFile() async {
    final path = await _getStorageDirectory();
    return File('$path/equipos.csv');
  }

  @override
  Future<bool> saveEquipmentToCsv(
      String date, String ut, String equipment) async {
    try {
      final file = await _getEquiposFile();
      final data = "$date,$ut,$equipment\n";
      await file.writeAsString(data, mode: FileMode.append);
      return true;
    } catch (e) {
      print("Error al guardar en equipos.csv: $e");
      return false;
    }
  }

  @override
  Future<List<EquipmentRecord>> readEquipmentRecords() async {
    final results = <EquipmentRecord>[];
    final file = await _getEquiposFile();
    if (!await file.exists()) return results;
    try {
      final lines = await file.readAsLines();
      for (final line in lines) {
        if (line.isEmpty) continue;
        final parts = line.split(',');
        if (parts.length >= 3) {
          // --- CAMBIO AQUÍ ---
          // Le pasamos 'id: null' porque este registro viene de un archivo,
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
      print("Error al leer equipos.csv: $e");
    }
    results.sort((a, b) => b.date.compareTo(a.date));
    return results;
  }

  @override
  Future<bool> deleteEquipmentRecords(List<EquipmentRecord> recordsToDelete) async {
    // (Esta función no necesita cambios, ya que nuestro '=='
    // actualizado en EquipmentRecord sabe cómo manejar 'id: null')
    final file = await _getEquiposFile();
    if (!await file.exists()) return false;
    final recordsToDeleteSet = recordsToDelete
        .map((r) => "${r.date},${r.ut},${r.equipment}")
        .toSet();
    if (recordsToDeleteSet.isEmpty) return true;
    try {
      final lines = await file.readAsLines();
      final linesToKeep = <String>[];
      for (final line in lines) {
        if (line.isNotEmpty && !recordsToDeleteSet.contains(line)) {
          linesToKeep.add(line);
        }
      }
      await file.writeAsString(linesToKeep.join('\n'));
      if (linesToKeep.isNotEmpty) {
        await file.writeAsString('\n', mode: FileMode.append);
      }
      return true;
    } catch (e) {
      print("Error al eliminar de equipos.csv: $e");
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
    final masterFile = await _getEquiposFile();
    if (!await masterFile.exists()) return null;
    final String currentDate = "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";
    final allRecords = await readEquipmentRecords();
    final filteredRecords = allRecords.where((record) => record.date == currentDate).toList();
    if (filteredRecords.isEmpty) {
      print("No hay registros de hoy para exportar.");
      return null;
    }
    final csvContent = filteredRecords
        .map((r) => "${r.date},${r.ut},${r.equipment}")
        .join('\n');
    try {
      final String dateSuffix = DateFormat('dd_MM_yy').format(DateTime.now());
      final String fileName = "equipos_$dateSuffix.csv";
      final tempDir = await getTemporaryDirectory();
      final File tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsString(csvContent);
      return tempFile.path;
    } catch (e) {
      print("Error al crear archivo CSV temporal: $e");
      return null;
    }
  }
}