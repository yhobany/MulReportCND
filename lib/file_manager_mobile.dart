// lib/file_manager_mobile.dart

import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'equipment_record.dart';
import 'registro_record.dart';
import 'file_manager_interface.dart';

class FileManager implements FileManagerInterface {

  Future<String> _getStorageDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _getEquiposFile() async {
    final path = await _getStorageDirectory();
    return File('$path/equipos.csv');
  }

  Future<File> _getRegistroFile() async {
    final path = await _getStorageDirectory();
    return File('$path/registro.txt');
  }

  DateTime? _parseDate(String dateStr) {
    try { return DateFormat('d/M/yyyy').parseStrict(dateStr); } catch (e) { return null; }
  }

  @override
  Future<bool> saveDataToFile(String date, String ut, String point, String description, String priority, String status) async {
    try {
      final file = await _getRegistroFile();
      await file.writeAsString("$date,$ut,$point,$description,$priority,$status,\n", mode: FileMode.append);
      return true;
    } catch (e) { return false; }
  }

  @override
  Future<List<RegistroRecord>> searchInFile(String startDateStr, String endDateStr, String ut, String plant, String priority, String status) async {
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
          final String recordPriority = parts.length >= 5 ? parts[4] : 'Medio';
          final String recordStatus = parts.length >= 6 ? parts[5] : 'Abierto';
          final String recordNote = parts.length >= 7 ? parts[6] : '';

          bool matchesDate = true;
          final DateTime? recordDate = _parseDate(recordDateStr);
          if (recordDate != null) {
            if (startDate != null && recordDate.isBefore(startDate)) matchesDate = false;
            if (endDate != null && recordDate.isAfter(endDate)) matchesDate = false;
          } else if (startDate != null || endDate != null) { matchesDate = false; }

          final bool matchesUt = ut.isEmpty || recordUt.toLowerCase().contains(ut.toLowerCase());
          final bool matchesPlant = plant.isEmpty || recordUt.toLowerCase().startsWith(plant.toLowerCase());
          final bool matchesPriority = priority.isEmpty || priority == 'Todas' || recordPriority == priority;
          final bool matchesStatus = status.isEmpty || status == 'Todos' || recordStatus == status;

          if (matchesDate && matchesUt && matchesPlant && matchesPriority && matchesStatus) {
            results.add(RegistroRecord(id: null, date: recordDateStr, ut: recordUt, point: parts[2], description: parts[3], priority: recordPriority, status: recordStatus, actionNote: recordNote));
          }
        }
      }
      results.sort((a, b) {
        final dateA = _parseDate(a.date) ?? DateTime(1900);
        final dateB = _parseDate(b.date) ?? DateTime(1900);
        return dateB.compareTo(dateA);
      });
    } catch (e) {}
    return results;
  }

  @override
  Future<bool> deleteRegistros(List<RegistroRecord> recordsToDelete) async {
    final file = await _getRegistroFile();
    if (!await file.exists()) return false;
    final recordsToDeleteSet = recordsToDelete.toSet();
    try {
      final lines = await file.readAsLines();
      final linesToKeep = <String>[];
      for (final line in lines) {
        if (line.isEmpty) continue;
        final parts = line.split(',');
        if (parts.length >= 4) {
          final p = parts.length >= 5 ? parts[4] : 'Medio';
          final s = parts.length >= 6 ? parts[5] : 'Abierto';
          final n = parts.length >= 7 ? parts[6] : '';
          final rec = RegistroRecord(id: null, date: parts[0], ut: parts[1], point: parts[2], description: parts[3], priority: p, status: s, actionNote: n);
          if (!recordsToDeleteSet.contains(rec)) linesToKeep.add(line);
        }
      }
      await file.writeAsString(linesToKeep.join('\n'));
      if (linesToKeep.isNotEmpty) await file.writeAsString('\n', mode: FileMode.append);
      return true;
    } catch (e) { return false; }
  }

  @override
  Future<bool> updateRegistroStatus(RegistroRecord record, String newStatus, String actionNote) async {
    final file = await _getRegistroFile();
    if (!await file.exists()) return false;
    try {
      final lines = await file.readAsLines();
      final newLines = <String>[];
      bool found = false;
      for (final line in lines) {
        if (line.isEmpty) continue;
        final parts = line.split(',');
        if (parts.length >= 4) {
          final p = parts.length >= 5 ? parts[4] : 'Medio';
          final s = parts.length >= 6 ? parts[5] : 'Abierto';
          final n = parts.length >= 7 ? parts[6] : '';
          final currentRecord = RegistroRecord(id: null, date: parts[0], ut: parts[1], point: parts[2], description: parts[3], priority: p, status: s, actionNote: n);

          if (currentRecord == record) {
            String safeNote = actionNote.replaceAll(',', ';');
            final newLine = "${record.date},${record.ut},${record.point},${record.description},${record.priority},$newStatus,$safeNote";
            newLines.add(newLine);
            found = true;
          } else { newLines.add(line); }
        }
      }
      if (found) {
        await file.writeAsString(newLines.join('\n'));
        if (newLines.isNotEmpty) await file.writeAsString('\n', mode: FileMode.append);
        return true;
      }
      return false;
    } catch (e) { return false; }
  }

  // --- EQUIPOS ---

  @override
  Future<bool> updateEquipment(EquipmentRecord oldRecord, String newUt, String newEquipment, String newDate) async {
    final file = await _getEquiposFile();
    if (!await file.exists()) return false;

    try {
      final lines = await file.readAsLines();
      final newLines = <String>[];
      bool found = false;

      final searchString = "${oldRecord.date},${oldRecord.ut},${oldRecord.equipment}";

      for (final line in lines) {
        if (line.trim() == searchString.trim() && !found) {
          newLines.add("$newDate,$newUt,$newEquipment");
          found = true;
        } else {
          newLines.add(line);
        }
      }

      if (found) {
        await file.writeAsString(newLines.join('\n'));
        if (newLines.isNotEmpty) await file.writeAsString('\n', mode: FileMode.append);
        return true;
      }
      return false;
    } catch (e) {
      print("Error al actualizar equipo local: $e");
      return false;
    }
  }

  @override
  Future<List<EquipmentRecord>> searchInEquiposFile(String startDateStr, String endDateStr, String ut, String plant) async {
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
      results.sort((a, b) {
        final dateA = _parseDate(a.date) ?? DateTime(1900);
        final dateB = _parseDate(b.date) ?? DateTime(1900);
        return dateB.compareTo(dateA);
      });
    } catch (e) {}
    return results;
  }

  @override
  Future<bool> saveEquipmentToCsv(String date, String ut, String equipment) async {
    try {
      final file = await _getEquiposFile();
      await file.writeAsString("$date,$ut,$equipment\n", mode: FileMode.append);
      return true;
    } catch (e) { return false; }
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
        if (parts.length >= 3) results.add(EquipmentRecord(id: null, date: parts[0], ut: parts[1], equipment: parts[2]));
      }
    } catch (e) {}
    results.sort((a, b) {
      final dateA = _parseDate(a.date) ?? DateTime(1900);
      final dateB = _parseDate(b.date) ?? DateTime(1900);
      return dateB.compareTo(dateA);
    });
    return results;
  }

  @override
  Future<bool> deleteEquipmentRecords(List<EquipmentRecord> recordsToDelete) async {
    final file = await _getEquiposFile();
    if (!await file.exists()) return false;
    final recordsToDeleteSet = recordsToDelete.map((r) => "${r.date},${r.ut},${r.equipment}").toSet();
    try {
      final lines = await file.readAsLines();
      final linesToKeep = <String>[];
      for (final line in lines) {
        if (line.isNotEmpty && !recordsToDeleteSet.contains(line)) linesToKeep.add(line);
      }
      await file.writeAsString(linesToKeep.join('\n'));
      if (linesToKeep.isNotEmpty) await file.writeAsString('\n', mode: FileMode.append);
      return true;
    } catch (e) { return false; }
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
    return records.map((r) => "${r.date},${r.ut},${r.equipment}").join('\n');
  }
}