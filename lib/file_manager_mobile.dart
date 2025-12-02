import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'equipment_record.dart';
import 'registro_record.dart'; // <-- IMPORTANTE
import 'file_manager_interface.dart';

class FileManager implements FileManagerInterface {

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

  // --- ACTUALIZADO: Devuelve objetos RegistroRecord ---
  @override
  Future<List<RegistroRecord>> searchInFile(
      String startDateStr, String endDateStr, String ut, String plant) async {
    final results = <RegistroRecord>[];
    final file = await _getRegistroFile();
    if (!await file.exists()) return results;

    final DateTime? startDate = _parseDate(startDateStr);
    final DateTime? endDate = _parseDate(endDateStr);

    try {
      final lines = await file.readAsLines();
      for (final line in lines) {
        if (line.isEmpty) continue;
        final parts = line.split(',');
        if (parts.length >= 4) {
          final String recordDateStr = parts[0];
          final String recordUt = parts[1];
          final String point = parts[2];
          final String description = parts[3];

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
            // Devolvemos un objeto con ID nulo (porque es un archivo local)
            results.add(RegistroRecord(
                id: null,
                date: recordDateStr,
                ut: recordUt,
                point: point,
                description: description
            ));
          }
        }
      }
    } catch (e) {
      print("Error al leer/buscar en registro.txt: $e");
    }
    return results;
  }

  // --- NUEVO: Implementación de borrar registros ---
  @override
  Future<bool> deleteRegistros(List<RegistroRecord> recordsToDelete) async {
    final file = await _getRegistroFile();
    if (!await file.exists()) return false;

    // Creamos un set de las líneas a borrar para comparar
    final recordsToDeleteSet = recordsToDelete
        .map((r) => "${r.date},${r.ut},${r.point},${r.description}")
        .toSet();

    try {
      final lines = await file.readAsLines();
      final linesToKeep = <String>[];

      for (final line in lines) {
        if (line.isNotEmpty && !recordsToDeleteSet.contains(line)) {
          linesToKeep.add(line);
        }
      }

      await file.writeAsString(linesToKeep.join('\n'));
      if (linesToKeep.isNotEmpty) await file.writeAsString('\n', mode: FileMode.append);

      return true;
    } catch (e) {
      print("Error al eliminar de registro.txt: $e");
      return false;
    }
  }

  Future<File> _getEquiposFile() async {
    final path = await _getStorageDirectory();
    return File('$path/equipos.csv');
  }

  // --- ACTUALIZADO: Devuelve objetos EquipmentRecord ---
  @override
  Future<List<EquipmentRecord>> searchInEquiposFile(
      String startDateStr, String endDateStr, String ut, String plant) async {
    final results = <EquipmentRecord>[];
    final file = await _getEquiposFile();
    if (!await file.exists()) return results;

    final DateTime? startDate = _parseDate(startDateStr);
    final DateTime? endDate = _parseDate(endDateStr);

    try {
      final lines = await file.readAsLines();
      for (final line in lines) {
        if (line.isEmpty) continue;
        final parts = line.split(',');
        if (parts.length < 3) continue;

        final String recordDateStr = parts[0];
        final String recordUt = parts[1];
        final String recordEquip = parts[2];

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
          results.add(EquipmentRecord(
              id: null,
              date: recordDateStr,
              ut: recordUt,
              equipment: recordEquip
          ));
        }
      }
    } catch (e) {
      print("Error al buscar en equipos.csv: $e");
    }
    return results;
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
          results.add(EquipmentRecord(
              id: null,
              date: parts[0],
              ut: parts[1],
              equipment: parts[2]
          ));
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
    final file = await _getEquiposFile();
    if (!await file.exists()) return false;
    final recordsToDeleteSet = recordsToDelete
        .map((r) => "${r.date},${r.ut},${r.equipment}")
        .toSet();
    try {
      final lines = await file.readAsLines();
      final linesToKeep = <String>[];
      for (final line in lines) {
        if (line.isNotEmpty && !recordsToDeleteSet.contains(line)) {
          linesToKeep.add(line);
        }
      }
      await file.writeAsString(linesToKeep.join('\n'));
      if (linesToKeep.isNotEmpty) await file.writeAsString('\n', mode: FileMode.append);
      return true;
    } catch (e) {
      print("Error al eliminar de equipos.csv: $e");
      return false;
    }
  }

  @override
  Future<String> getNextImageName(String ut) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = ut.length >= 4 ? ut.substring(0, 4).toUpperCase() : ut.toUpperCase();
    final key = "image_counter_$prefix";
    final int counter = prefs.getInt(key) ?? 1;
    final String fileName = "$prefix-${counter.toString().padLeft(3, '0')}.jpg";
    await prefs.setInt(key, counter + 1);
    return fileName;
  }

  @override
  Future<String?> exportRecords(List<EquipmentRecord> records) async {
    if (records.isEmpty) return null;
    final csvContent = records
        .map((r) => "${r.date},${r.ut},${r.equipment}")
        .join('\n');
    return csvContent;
  }
}