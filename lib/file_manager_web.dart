import 'dart:html' as html;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'equipment_record.dart';
import 'registro_record.dart';
import 'file_manager_interface.dart';

const String _registroKey = 'registro_txt_data';
const String _equiposKey = 'equipos_csv_data';

class FileManager implements FileManagerInterface {

  // CAMBIO: Añadido 'priority'
  @override
  Future<bool> saveDataToFile(
      String date, String ut, String point, String description, String priority) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> records = prefs.getStringList(_registroKey) ?? [];
      // Guardamos la prioridad al final
      records.add("$date,$ut,$point,$description,$priority");
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

  // CAMBIO: Añadido filtro 'priority'
  @override
  Future<List<RegistroRecord>> searchInFile(
      String startDateStr, String endDateStr, String ut, String plant, String priority) async {
    final results = <RegistroRecord>[];
    final prefs = await SharedPreferences.getInstance();
    final List<String> lines = prefs.getStringList(_registroKey) ?? [];
    final DateTime? startDate = _parseDate(startDateStr);
    final DateTime? endDate = _parseDate(endDateStr);

    try {
      for (final line in lines) {
        if (line.isEmpty) continue;
        final parts = line.split(',');
        if (parts.length >= 4) {
          final String recordDateStr = parts[0];
          final String recordUt = parts[1];
          // Compatibilidad
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
          final bool matchesPriority = priority.isEmpty || priority == 'Todas' || recordPriority == priority;

          if (matchesDate && matchesUt && matchesPlant && matchesPriority) {
            results.add(RegistroRecord(
              id: null,
              date: recordDateStr,
              ut: recordUt,
              point: parts[2],
              description: parts[3],
              priority: recordPriority,
            ));
          }
        }
      }
    } catch (e) {
      print("Error al buscar en SharedPreferences (web): $e");
    }
    return results;
  }

  @override
  Future<bool> deleteRegistros(List<RegistroRecord> recordsToDelete) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> lines = prefs.getStringList(_registroKey) ?? [];
    final recordsToDeleteSet = recordsToDelete.toSet();

    try {
      final linesToKeep = <String>[];
      for (final line in lines) {
        if (line.isEmpty) continue;
        final parts = line.split(',');
        if (parts.length >= 4) {
          final p = parts.length >= 5 ? parts[4] : 'Medio';
          final rec = RegistroRecord(id: null, date: parts[0], ut: parts[1], point: parts[2], description: parts[3], priority: p);
          if (!recordsToDeleteSet.contains(rec)) {
            linesToKeep.add(line);
          }
        }
      }
      await prefs.setStringList(_registroKey, linesToKeep);
      return true;
    } catch (e) { return false; }
  }

  // --- EL RESTO DEL ARCHIVO (Equipos) SE COPIA EXACTAMENTE IGUAL ---
  // (Copia las funciones de equipos searchInEquiposFile, saveEquipmentToCsv,
  // readEquipmentRecords, deleteEquipmentRecords, getNextImageName, exportRecords
  // tal como estaban en tu archivo anterior).

  @override
  Future<List<EquipmentRecord>> searchInEquiposFile(String startDateStr, String endDateStr, String ut, String plant) async {
    // ... (Misma implementación)
    final results = <EquipmentRecord>[];
    final prefs = await SharedPreferences.getInstance();
    final List<String> lines = prefs.getStringList(_equiposKey) ?? [];
    final DateTime? startDate = _parseDate(startDateStr);
    final DateTime? endDate = _parseDate(endDateStr);

    try {
      for (final line in lines) {
        if (line.isEmpty) continue;
        final parts = line.split(',');
        if (parts.length < 3) continue;
        final String recordDateStr = parts[0];
        final String recordUt = parts[1];
        bool matchesDate = true;
        final DateTime? recordDate = _parseDate(recordDateStr);
        if (recordDate != null) {
          if (startDate != null && recordDate.isBefore(startDate)) matchesDate = false;
          if (endDate != null && recordDate.isAfter(endDate)) matchesDate = false;
        } else if (startDate != null || endDate != null) { matchesDate = false; }
        final bool matchesUt = ut.isEmpty || recordUt.toLowerCase().contains(ut.toLowerCase());
        final bool matchesPlant = plant.isEmpty || recordUt.toLowerCase().startsWith(plant.toLowerCase());
        if (matchesDate && matchesUt && matchesPlant) {
          results.add(EquipmentRecord(id: null, date: recordDateStr, ut: recordUt, equipment: parts[2]));
        }
      }
    } catch (e) { }
    return results;
  }

  @override
  Future<bool> saveEquipmentToCsv(String date, String ut, String equipment) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> records = prefs.getStringList(_equiposKey) ?? [];
      records.add("$date,$ut,$equipment");
      await prefs.setStringList(_equiposKey, records);
      return true;
    } catch (e) { return false; }
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
          results.add(EquipmentRecord(id: null, date: parts[0], ut: parts[1], equipment: parts[2]));
        }
      }
    } catch (e) { }
    results.sort((a, b) => b.date.compareTo(a.date));
    return results;
  }

  @override
  Future<bool> deleteEquipmentRecords(List<EquipmentRecord> recordsToDelete) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> lines = prefs.getStringList(_equiposKey) ?? [];
    final recordsToDeleteSet = recordsToDelete.map((r) => "${r.date},${r.ut},${r.equipment}").toSet();
    try {
      final linesToKeep = <String>[];
      for (final line in lines) {
        if (line.isNotEmpty && !recordsToDeleteSet.contains(line)) {
          linesToKeep.add(line);
        }
      }
      await prefs.setStringList(_equiposKey, linesToKeep);
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
    final csvContent = records.map((r) => "${r.date},${r.ut},${r.equipment}").join('\n');
    return csvContent;
  }
}