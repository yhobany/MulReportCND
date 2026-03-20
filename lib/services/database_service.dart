import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../equipment_record.dart';
import '../registro_record.dart';

class DatabaseService {
  final _firestore = FirebaseFirestore.instance;

  DateTime? _parseDate(String dateStr) {
    try { return DateFormat('d/M/yyyy').parseStrict(dateStr); } catch (e) { return null; }
  }

  Future<bool> saveDataToFile(
      String date, String ut, String point, String description, String priority, String status) async {
    try {
      await _firestore.collection('registros').add({
        'date_string': date, 'timestamp': Timestamp.now(), 'ut': ut, 'point': point,
        'description': description, 'priority': priority, 'status': status, 'actionNote': ''
      });
      return true;
    } catch (e) { return false; }
  }

  // --- SÍNTOMAS GLOBALES ---

  Future<List<String>> getGlobalSymptoms() async {
    final results = <String>[];
    try {
      final snapshot = await _firestore.collection('sintomas_globales').orderBy('name').get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['name'] != null && data['name'].toString().trim().isNotEmpty) {
          results.add(data['name']);
        }
      }
    } catch (e) {
      print("Error obteniendo síntomas globales en Firestore: $e");
    }
    return results;
  }

  Future<String> saveGlobalSymptom(String newSymptom) async {
    try {
      final trimmed = newSymptom.trim();
      if (trimmed.isEmpty) return 'error: empty string';
      
      // Formato: Inicial mayúscula, resto minúsculas (Ej: "vIbRaCioN" -> "Vibracion")
      final formattedSymptom = trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
      
      // Validar duplicados exactos en la nube primero
      final existing = await _firestore.collection('sintomas_globales')
          .where('name', isEqualTo: formattedSymptom)
          .limit(1)
          .get();
          
      if (existing.docs.isEmpty) {
        await _firestore.collection('sintomas_globales').add({
          'name': formattedSymptom, // Guardamos con formato capitalizado
          'timestamp': Timestamp.now(),
        });
        return 'success';
      }
      return 'duplicate'; // Ya existía
    } catch (e) {
      print("Error guardando síntoma global en Firestore: $e");
      return 'error: $e';
    }
  }

  Future<List<RegistroRecord>> searchInFile(String startDateStr, String endDateStr, String ut, String plant, String priority, String status) async {
    final results = <RegistroRecord>[];
    try {
      Query query = _firestore.collection('registros');
      final DateTime? startDate = _parseDate(startDateStr);
      final DateTime? endDate = _parseDate(endDateStr);
      if (startDate != null) query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      if (endDate != null) {
        final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
      }
      query = query.orderBy('timestamp', descending: true);
      final snapshot = await query.get();
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String recordUt = data['ut'] ?? '';
        final String recordPriority = data['priority'] ?? 'Medio';
        final String recordStatus = data['status'] ?? 'Abierto';
        final String recordNote = data['actionNote'] ?? '';

        final bool matchesUt = ut.isEmpty || recordUt.toLowerCase().contains(ut.toLowerCase());
        final bool matchesPlant = plant.isEmpty || recordUt.toLowerCase().startsWith(plant.toLowerCase());
        final bool matchesPriority = priority.isEmpty || priority == 'Todas' || recordPriority == priority;
        final bool matchesStatus = status.isEmpty || status == 'Todos' || recordStatus == status;
        if (matchesUt && matchesPlant && matchesPriority && matchesStatus) {
          results.add(RegistroRecord(
            id: doc.id, date: data['date_string'] ?? '', ut: recordUt, point: data['point'] ?? '',
            description: data['description'] ?? '', priority: recordPriority, status: recordStatus, actionNote: recordNote,
          ));
        }
      }
    } catch (e) { }
    return results;
  }

  Future<bool> updateRegistroStatus(RegistroRecord record, String newStatus, String actionNote) async {
    try {
      if (record.id == null) return false;
      await _firestore.collection('registros').doc(record.id).update({
        'status': newStatus,
        'actionNote': actionNote,
      });
      return true;
    } catch (e) { return false; }
  }

  Future<bool> deleteRegistros(List<RegistroRecord> recordsToDelete) async {
    try {
      final collection = _firestore.collection('registros');
      final batch = _firestore.batch();
      for (var record in recordsToDelete) { if (record.id != null) batch.delete(collection.doc(record.id)); }
      await batch.commit();
      return true;
    } catch (e) { return false; }
  }

  // --- EQUIPOS ---

  Future<bool> updateEquipment(EquipmentRecord record, String newUt, String newEquipment, String newDate) async {
    try {
      if (record.id == null) return false;
      await _firestore.collection('equipos').doc(record.id).update({
        'ut': newUt,
        'equipment': newEquipment,
        'date_string': newDate,
        'timestamp': Timestamp.now(), // Actualiza la posición en la lista
      });
      return true;
    } catch (e) {
      print("Error al actualizar equipo en Firestore: \$e");
      return false;
    }
  }

  Future<List<EquipmentRecord>> searchInEquiposFile(String startDateStr, String endDateStr, String ut, String plant) async {
    final results = <EquipmentRecord>[];
    try {
      Query query = _firestore.collection('equipos');
      final DateTime? startDate = _parseDate(startDateStr);
      final DateTime? endDate = _parseDate(endDateStr);
      if (startDate != null) query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
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
          results.add(EquipmentRecord(id: doc.id, date: data['date_string'] ?? '', ut: recordUt, equipment: data['equipment'] ?? ''));
        }
      }
    } catch (e) { }
    return results;
  }

  Future<bool> saveEquipmentToCsv(String date, String ut, String equipment) async {
    try {
      await _firestore.collection('equipos').add({
        'date_string': date, 'timestamp': Timestamp.now(), 'ut': ut, 'equipment': equipment,
      });
      return true;
    } catch (e) { return false; }
  }

  /// Obtiene todos los equipos registrados para una UT en específico.
  Future<List<EquipmentRecord>> getEquipmentByUt(String ut) async {
    final results = <EquipmentRecord>[];
    try {
      final snapshot = await _firestore.collection('equipos')
          .where('ut', isEqualTo: ut.toUpperCase())
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        results.add(EquipmentRecord(
          id: doc.id,
          date: data['date_string'] ?? '',
          ut: data['ut'] ?? '',
          equipment: data['equipment'] ?? ''
        ));
      }
    } catch (e) {
      print("Error obteniendo equipos para UT en Firestore: \$e");
    }
    return results;
  }

  Future<List<EquipmentRecord>> readEquipmentRecords() async {
    final results = <EquipmentRecord>[];
    try {
      final snapshot = await _firestore.collection('equipos').orderBy('timestamp', descending: true).get();
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        results.add(EquipmentRecord(id: doc.id, date: data['date_string'] ?? '', ut: data['ut'] ?? '', equipment: data['equipment'] ?? ''));
      }
    } catch (e) { }
    return results;
  }

  Future<bool> deleteEquipmentRecords(List<EquipmentRecord> recordsToDelete) async {
    try {
      final collection = _firestore.collection('equipos');
      final batch = _firestore.batch();
      for (var record in recordsToDelete) { if (record.id != null) batch.delete(collection.doc(record.id)); }
      await batch.commit();
      return true;
    } catch (e) { return false; }
  }

  Future<String> getNextImageName(String ut) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = ut.length >= 4 ? ut.substring(0, 4).toUpperCase() : ut.toUpperCase();
    final key = "image_counter_\$prefix";
    final int counter = prefs.getInt(key) ?? 1;
    final String fileName = "\$prefix-\${counter.toString().padLeft(3, '0')}.jpg";
    await prefs.setInt(key, counter + 1);
    return fileName;
  }

  Future<String?> exportRecords(List<EquipmentRecord> records) async {
    if (records.isEmpty) return null;
    final csvRows = records.map((r) {
      final String line = "${r.date},${r.ut},${r.equipment}";
      return line;
    }).toList();
    return csvRows.join('\n');
  }
}
