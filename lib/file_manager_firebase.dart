// lib/file_manager_firebase.dart

import 'dart:io'; // Necesario para la exportación MÓVIL
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart'; // Necesario para la exportación MÓVIL
import 'package:shared_preferences/shared_preferences.dart';

import 'equipment_record.dart';
import 'file_manager_interface.dart';

class FileManager implements FileManagerInterface {
  final _firestore = FirebaseFirestore.instance;

  // (Todas las funciones de REGISTRO no cambian)
  // ...
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

  // (Funciones de EQUIPOS 'save', 'read', 'delete' no cambian)
  // ...
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
    // (Esta función no cambia)
    final prefs = await SharedPreferences.getInstance();
    final prefix = ut.length >= 4 ? ut.substring(0, 4).toUpperCase() : ut.toUpperCase();
    final key = "image_counter_$prefix";
    final int counter = prefs.getInt(key) ?? 1;
    final String fileName = "$prefix-${counter.toString().padLeft(3, '0')}.jpg";
    await prefs.setInt(key, counter + 1);
    return fileName;
  }

  // --- FUNCIÓN DE EXPORTAR (ACTUALIZADA) ---
  @override
  Future<String?> generateDatedCsvFileWithFilter() async {

    // 1. Obtener el rango de hoy
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day); // Hoy a las 00:00
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59); // Hoy a las 23:59

    final filteredRecords = <EquipmentRecord>[];

    try {
      // 2. Pedir a Firebase solo los registros de hoy
      final snapshot = await _firestore.collection('equipos')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfToday))
          .get();

      // Convertir los documentos a EquipmentRecord
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        filteredRecords.add(EquipmentRecord(
          id: doc.id,
          date: data['date_string'] ?? '',
          ut: data['ut'] ?? '',
          equipment: data['equipment'] ?? '',
        ));
      }

    } catch (e) {
      print("Error al filtrar por fecha en Firestore: $e");
      return null; // Hubo un error
    }

    if (filteredRecords.isEmpty) {
      print("No hay registros de hoy para exportar.");
      return null; // No hay datos
    }

    // 3. Crear el contenido del CSV (esto es igual que antes)
    final csvContent = filteredRecords
        .map((r) => "${r.date},${r.ut},${r.equipment}")
        .join('\n');

    // 4. Devolver el contenido o la ruta del archivo
    // (Tu 'equipos_screen.dart' ya sabe cómo manejar esto
    // gracias a nuestra lógica kIsWeb)
    try {
      final String dateSuffix = DateFormat('dd_MM_yy').format(DateTime.now());
      final String fileName = "equipos_$dateSuffix.csv";

      // getTemporaryDirectory() solo funciona en móvil
      // así que aquí solo devolvemos el contenido si es web,
      // o creamos el archivo si es móvil.
      // ¡Espera! 'dart:io' no puede estar en el mismo archivo que 'dart:html'
      // Nuestra implementación de exportación debe estar en la UI.

      // --- Corrección: Devolvemos el contenido CSV a la UI ---
      // (La UI ('equipos_screen.dart') se encargará de guardarlo
      // en un archivo temporal si es móvil, o descargarlo si es web)
      return csvContent;

    } catch (e) {
      print("Error al crear el string CSV: $e");
      return null;
    }
  }
}