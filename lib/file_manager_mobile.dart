import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'equipment_record.dart';
import 'registro_record.dart';
import 'file_manager_interface.dart';

class FileManager implements FileManagerInterface {

  // ... (Funciones auxiliares de ruta no cambian)
  Future<String> _getStorageDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _getRegistroFile() async {
    final path = await _getStorageDirectory();
    return File('$path/registro.txt');
  }

  // CAMBIO: Añadido 'priority'
  @override
  Future<bool> saveDataToFile(
      String date, String ut, String point, String description, String priority) async {
    try {
      final file = await _getRegistroFile();
      // Guardamos la prioridad al final (índice 4)
      final data = "$date,$ut,$point,$description,$priority\n";
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
    } catch (e) { return null; }
  }

  // CAMBIO: Añadido 'priority' al filtro
  @override
  Future<List<RegistroRecord>> searchInFile(
      String startDateStr, String endDateStr, String ut, String plant, String priority) async {
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
          // Si el registro es antiguo y no tiene prioridad, usamos "Medio"
          final String recordPriority = parts.length >= 5 ? parts[4] : 'Medio';

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
          // Filtro de prioridad
          final bool matchesPriority = priority.isEmpty || priority == 'Todas' || recordPriority == priority;

          if (matchesDate && matchesUt && matchesPlant && matchesPriority) {
            results.add(RegistroRecord(
              id: null,
              date: recordDateStr,
              ut: recordUt,
              point: point,
              description: description,
              priority: recordPriority, // <-- Asignamos
            ));
          }
        }
      }
    } catch (e) {
      print("Error al leer/buscar en registro.txt: $e");
    }
    return results;
  }

  // --- EL RESTO DEL ARCHIVO (Equipos) SE COPIA EXACTAMENTE IGUAL ---
  // (deleteRegistros, searchInEquiposFile, saveEquipmentToCsv, readEquipmentRecords,
  // deleteEquipmentRecords, getNextImageName, exportRecords)

  @override
  Future<bool> deleteRegistros(List<RegistroRecord> recordsToDelete) async {
    final file = await _getRegistroFile();
    if (!await file.exists()) return false;
    // Comparación robusta incluyendo prioridad
    final recordsToDeleteSet = recordsToDelete.toSet();

    try {
      final lines = await file.readAsLines();
      final linesToKeep = <String>[];

      for (final line in lines) {
        if (line.isEmpty) continue;
        final parts = line.split(',');
        if (parts.length >= 4) {
          final p = parts.length >= 5 ? parts[4] : 'Medio';
          final rec = RegistroRecord(
              id: null, date: parts[0], ut: parts[1], point: parts[2], description: parts[3], priority: p
          );
          if (!recordsToDeleteSet.contains(rec)) {
            linesToKeep.add(line);
          }
        }
      }
      await file.writeAsString(linesToKeep.join('\n'));
      if (linesToKeep.isNotEmpty) await file.writeAsString('\n', mode: FileMode.append);
      return true;
    } catch (e) { return false; }
  }

  // (Copia el resto de funciones idénticas a tu versión anterior para no hacer el mensaje muy largo)
  // ...
  Future<File> _getEquiposFile() async {
    final path = await _getStorageDirectory();
    return File('$path/equipos.csv');
  }

  @override
  Future<List<EquipmentRecord>> searchInEquiposFile(
      String startDateStr, String endDateStr, String ut, String plant) async {
    // ... (Misma implementación)
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
        } else if (startDate != null || endDate != null) { matchesDate = false; }
        final bool matchesUt = ut.isEmpty || recordUt.toLowerCase().contains(ut.toLowerCase());
        final bool matchesPlant = plant.isEmpty || recordUt.toLowerCase().startsWith(plant.toLowerCase());
        if (matchesDate && matchesUt && matchesPlant) {
          results.add(EquipmentRecord(id: null, date: recordDateStr, ut: recordUt, equipment: recordEquip));
        }
      }
    } catch (e) {}
    return results;
  }

  @override
  Future<bool> saveEquipmentToCsv(String date, String ut, String equipment) async {
    // ... (Misma implementación)
    try {
      final file = await _getEquiposFile();
      final data = "$date,$ut,$equipment\n";
      await file.writeAsString(data, mode: FileMode.append);
      return true;
    } catch (e) { return false; }
  }

  @override
  Future<List<EquipmentRecord>> readEquipmentRecords() async {
    // ... (Misma implementación)
    final results = <EquipmentRecord>[];
    final file = await _getEquiposFile();
    if (!await file.exists()) return results;
    try {
      final lines = await file.readAsLines();
      for (final line in lines) {
        if (line.isEmpty) continue;
        final parts = line.split(',');
        if (parts.length >= 3) {
          results.add(EquipmentRecord(id: null, date: parts[0], ut: parts[1], equipment: parts[2]));
        }
      }
    } catch (e) {}
    results.sort((a, b) => b.date.compareTo(a.date));
    return results;
  }

  @override
  Future<bool> deleteEquipmentRecords(List<EquipmentRecord> recordsToDelete) async {
    // ... (Misma implementación)
    final file = await _getEquiposFile();
    if (!await file.exists()) return false;
    final recordsToDeleteSet = recordsToDelete.map((r) => "${r.date},${r.ut},${r.equipment}").toSet();
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
    } catch (e) { return false; }
  }

  @override
  Future<String> getNextImageName(String ut) async {
    // ... (Misma implementación)
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
    // ... (Misma implementación)
    if (records.isEmpty) return null;
    final csvContent = records.map((r) => "${r.date},${r.ut},${r.equipment}").join('\n');
    return csvContent;
  }
}