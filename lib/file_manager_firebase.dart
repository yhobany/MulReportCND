import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'equipment_record.dart';
import 'registro_record.dart'; // <-- IMPORTANTE
import 'file_manager_interface.dart';

class FileManager implements FileManagerInterface {
  final _firestore = FirebaseFirestore.instance;

  // --- REGISTROS ---

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
    } catch (e) { return null; }
  }

  // ACTUALIZADO: Devuelve objetos RegistroRecord
  @override
  Future<List<RegistroRecord>> searchInFile(
      String startDateStr, String endDateStr, String ut, String plant) async {
    final results = <RegistroRecord>[];
    try {
      Query query = _firestore.collection('registros');
      // (Lógica de filtros de fecha igual que antes...)
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
        // Filtro local de UT (contains)
        final bool matchesUt = ut.isEmpty || recordUt.toLowerCase().contains(ut.toLowerCase());

        if (matchesUt) {
          // CREAMOS EL OBJETO CON EL ID
          results.add(RegistroRecord(
            id: doc.id,
            date: data['date_string'] ?? '',
            ut: recordUt,
            point: data['point'] ?? '',
            description: data['description'] ?? '',
          ));
        }
      }
    } catch (e) {
      print("Error al buscar en Firestore (registros): $e");
    }
    return results;
  }

  // NUEVO: Borrar Registros
  @override
  Future<bool> deleteRegistros(List<RegistroRecord> recordsToDelete) async {
    try {
      final collection = _firestore.collection('registros');
      final batch = _firestore.batch();
      for (var record in recordsToDelete) {
        if (record.id != null) {
          batch.delete(collection.doc(record.id));
        }
      }
      await batch.commit();
      return true;
    } catch (e) {
      print("Error al eliminar de Firestore (registros): $e");
      return false;
    }
  }

  // --- EQUIPOS ---

  // ACTUALIZADO: Devuelve objetos EquipmentRecord
  @override
  Future<List<EquipmentRecord>> searchInEquiposFile(
      String startDateStr, String endDateStr, String ut, String plant) async {
    final results = <EquipmentRecord>[];
    try {
      Query query = _firestore.collection('equipos');
      // (Mismos filtros de fecha...)
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
          // CREAMOS EL OBJETO CON EL ID
          results.add(EquipmentRecord(
            id: doc.id,
            date: data['date_string'] ?? '',
            ut: recordUt,
            equipment: data['equipment'] ?? '',
          ));
        }
      }
    } catch (e) {
      print("Error al buscar en Firestore (equipos): $e");
    }
    return results;
  }

  // (El resto de funciones save, read, deleteEquipment, getNext, export NO CAMBIAN)
  // Copia el resto de las funciones de tu archivo anterior tal cual estaban.
  // (saveEquipmentToCsv, readEquipmentRecords, deleteEquipmentRecords, getNextImageName, exportRecords)

  @override
  Future<bool> saveEquipmentToCsv(String date, String ut, String equipment) async {
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

  @override
  Future<String?> exportRecords(List<EquipmentRecord> records) async {
    if (records.isEmpty) return null;
    final csvContent = records
        .map((r) => "${r.date},${r.ut},${r.equipment}")
        .join('\n');
    return csvContent;
  }
}