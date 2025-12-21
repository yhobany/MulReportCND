import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'equipment_record.dart';
import 'registro_record.dart';
import 'file_manager_interface.dart';

class FileManager implements FileManagerInterface {
  final _firestore = FirebaseFirestore.instance;

  // --- REGISTROS ---

  @override
  Future<bool> saveDataToFile(
      String date, String ut, String point, String description, String priority, String status) async { // <-- Param 'status'
    try {
      final collection = _firestore.collection('registros');
      await collection.add({
        'date_string': date,
        'timestamp': Timestamp.now(),
        'ut': ut,
        'point': point,
        'description': description,
        'priority': priority,
        'status': status, // <-- Guardamos el estatus
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

  @override
  Future<List<RegistroRecord>> searchInFile(
      String startDateStr, String endDateStr, String ut, String plant, String priority, String status) async { // <-- Param 'status'
    final results = <RegistroRecord>[];
    try {
      Query query = _firestore.collection('registros');

      // 1. Filtro Fecha
      final DateTime? startDate = _parseDate(startDateStr);
      final DateTime? endDate = _parseDate(endDateStr);
      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
      }

      // 2. Ordenamiento
      query = query.orderBy('timestamp', descending: true);

      final snapshot = await query.get();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String recordUt = data['ut'] ?? '';
        final String recordPriority = data['priority'] ?? 'Medio';
        final String recordStatus = data['status'] ?? 'Abierto'; // <-- Valor por defecto

        // 3. Filtros en Memoria
        final bool matchesUt = ut.isEmpty || recordUt.toLowerCase().contains(ut.toLowerCase());
        final bool matchesPlant = plant.isEmpty || recordUt.toLowerCase().startsWith(plant.toLowerCase());
        final bool matchesPriority = priority.isEmpty || priority == 'Todas' || recordPriority == priority;

        // Nuevo Filtro de Estatus
        final bool matchesStatus = status.isEmpty || status == 'Todos' || recordStatus == status;

        if (matchesUt && matchesPlant && matchesPriority && matchesStatus) {
          results.add(RegistroRecord(
            id: doc.id,
            date: data['date_string'] ?? '',
            ut: recordUt,
            point: data['point'] ?? '',
            description: data['description'] ?? '',
            priority: recordPriority,
            status: recordStatus, // <-- Leemos estatus
          ));
        }
      }
    } catch (e) {
      print("Error al buscar en Firestore (registros): $e");
    }
    return results;
  }

  // --- NUEVA FUNCIÓN: Actualizar Estatus ---
  @override
  Future<bool> updateRegistroStatus(RegistroRecord record, String newStatus) async {
    try {
      if (record.id == null) return false;
      await _firestore.collection('registros').doc(record.id).update({
        'status': newStatus,
      });
      return true;
    } catch (e) {
      print("Error al actualizar estatus en Firestore: $e");
      return false;
    }
  }

  // --- RESTO DE FUNCIONES (Sin cambios) ---
  // Copia el resto de funciones (Equipos, deleteRegistros, etc.) tal cual estaban.
  // ...

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
    } catch (e) { return false; }
  }

  @override
  Future<List<EquipmentRecord>> searchInEquiposFile(
      String startDateStr, String endDateStr, String ut, String plant) async {
    final results = <EquipmentRecord>[];
    try {
      Query query = _firestore.collection('equipos');
      final DateTime? startDate = _parseDate(startDateStr);
      final DateTime? endDate = _parseDate(endDateStr);
      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
      }
      query = query.orderBy('timestamp', descending: true);
      final snapshot = await query.get();
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String recordUt = data['ut'] ?? '';
        final bool matchesUt = ut.isEmpty || recordUt.toLowerCase().contains(ut.toLowerCase());
        final bool matchesPlant = plant.isEmpty || recordUt.toLowerCase().startsWith(plant.toLowerCase());
        if (matchesUt && matchesPlant) {
          results.add(EquipmentRecord(
            id: doc.id,
            date: data['date_string'] ?? '',
            ut: recordUt,
            equipment: data['equipment'] ?? '',
          ));
        }
      }
    } catch (e) { print("Error al buscar equipos: $e"); }
    return results;
  }

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
    } catch (e) { return false; }
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
    } catch (e) { }
    return results;
  }

  @override
  Future<bool> deleteEquipmentRecords(List<EquipmentRecord> recordsToDelete) async {
    try {
      final collection = _firestore.collection('equipos');
      final batch = _firestore.batch();
      for (var record in recordsToDelete) {
        if (record.id != null) batch.delete(collection.doc(record.id));
      }
      await batch.commit();
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
    final csvContent = records
        .map((r) => "${r.date},${r.ut},${r.equipment}")
        .join('\n');
    return csvContent;
  }
}