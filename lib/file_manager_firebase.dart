// lib/file_manager_firebase.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'equipment_record.dart';
import 'file_manager_interface.dart';

class FileManager implements FileManagerInterface {
  final _firestore = FirebaseFirestore.instance;

  // ... (saveDataToFile, _parseDate, searchInFile, saveEquipmentToCsv, readEquipmentRecords, deleteEquipmentRecords, getNextImageName NO CAMBIAN)

  @override
  Future<bool> saveDataToFile(
      String date, String ut, String point, String description) async {
    try {
      final collection = _firestore.collection('registros');
      await collection.add({
        'date_string': date,
        'timestamp': Timestamp.now(),
        'ut': ut,
        'point': point,
        'description': description,
      });
      return true;
    } catch (e) {
      print("Error al guardar en Firestore (registros): $e");
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
    try {
      Query query = _firestore.collection('registros');
      final DateTime? startDate = _parseDate(startDateStr);
      final DateTime? endDate = _parseDate(endDateStr);
      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
      }
      if (plant.isNotEmpty) {
        query = query.where('ut', isGreaterThanOrEqualTo: plant)
            .where('ut', isLessThan: '$plant\uf8ff');
      }
      final snapshot = await query.get();
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String recordUt = data['ut'] ?? '';
        final bool matchesUt = ut.isEmpty || recordUt.toLowerCase().contains(ut.toLowerCase());
        if (matchesUt) {
          results.add("${data['date_string']},${recordUt},${data['point']},${data['description']}");
        }
      }
    } catch (e) {
      print("Error al buscar en Firestore (registros): $e");
    }
    return results;
  }

  @override
  Future<bool> saveEquipmentToCsv(
      String date, String ut, String equipment) async {
    try {
      final collection = _firestore.collection('equipos');
      await collection.add({
        'date_string': date,
        'timestamp': Timestamp.now(),
        'ut': ut,
        'equipment': equipment,
      });
      return true;
    } catch (e) {
      print("Error al guardar en Firestore (equipos): $e");
      return false;
    }
  }

  @override
  Future<List<EquipmentRecord>> readEquipmentRecords() async {
    final results = <EquipmentRecord>[];
    try {
      final snapshot = await _firestore.collection('equipos')
          .orderBy('timestamp', descending: true)
          .get();
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        results.add(EquipmentRecord(
          id: doc.id,
          date: data['date_string'] ?? '',
          ut: data['ut'] ?? '',
          equipment: data['equipment'] ?? '',
        ));
      }
    } catch (e) {
      print("Error al leer Firestore (equipos): $e");
    }
    return results;
  }

  @override
  Future<bool> deleteEquipmentRecords(List<EquipmentRecord> recordsToDelete) async {
    try {
      final collection = _firestore.collection('equipos');
      final batch = _firestore.batch();
      for (var record in recordsToDelete) {
        if (record.id != null) {
          batch.delete(collection.doc(record.id));
        }
      }
      await batch.commit();
      return true;
    } catch (e) {
      print("Error al eliminar de Firestore (equipos): $e");
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

  // --- FUNCIÓN DE EXPORTAR ACTUALIZADA ---
  @override
  Future<String?> exportRecords(List<EquipmentRecord> records) async {
    if (records.isEmpty) {
      return null;
    }

    // Convertimos la lista recibida a CSV directamente
    final csvContent = records
        .map((r) => "${r.date},${r.ut},${r.equipment}")
        .join('\n');

    return csvContent; // Devolvemos el contenido para que la UI lo maneje
  }
}