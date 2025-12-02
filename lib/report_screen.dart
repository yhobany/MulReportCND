import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart'; // Para el nombre del archivo exportado

import 'file_manager_locator.dart';
import 'file_manager_interface.dart';
import 'equipment_record.dart';
import 'registro_record.dart';
import 'html_stub.dart' if (dart.library.html) 'dart:html' as html_stub;

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final FileManagerInterface fileManager = getFileManager();

  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _plantController = TextEditingController();
  final TextEditingController _utController = TextEditingController();

  // Usamos una lista dinámica para poder guardar ambos tipos de registros
  List<dynamic> _results = [];
  // Sets para guardar la selección
  Set<dynamic> _selectedItems = {};

  String _searchType = 'Registros';
  final List<String> _searchOptions = ['Registros', 'Equipos'];

  final List<String> plantOptions = [
    "PFM6", "PFM4", "PCM1", "PCM3", "PP30", "PP40",
    "PP50", "PP90", "PP95", "PP20", "PR"
  ];

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _plantController.dispose();
    _utController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    FocusScope.of(context).unfocus();
    _selectedItems.clear(); // Limpiar selección al buscar de nuevo

    if (_searchType == 'Registros') {
      final results = await fileManager.searchInFile(
        _startDateController.text,
        _endDateController.text,
        _utController.text,
        _plantController.text,
      );
      setState(() { _results = results; });
    } else {
      final results = await fileManager.searchInEquiposFile(
        _startDateController.text,
        _endDateController.text,
        _utController.text,
        _plantController.text,
      );
      setState(() { _results = results; });
    }
  }

  // --- FUNCIÓN DE BORRAR ---
  Future<void> _handleDelete() async {
    if (_selectedItems.isEmpty) return;

    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Desea eliminar ${_selectedItems.length} elemento(s)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    ) ?? false;

    if (confirm) {
      bool success = false;
      if (_searchType == 'Registros') {
        // Convertimos la selección al tipo correcto
        final list = _selectedItems.cast<RegistroRecord>().toList();
        success = await fileManager.deleteRegistros(list);
      } else {
        final list = _selectedItems.cast<EquipmentRecord>().toList();
        success = await fileManager.deleteEquipmentRecords(list);
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Eliminados correctamente')));
        _performSearch(); // Refrescar la lista
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al eliminar')));
      }
    }
  }

  // --- FUNCIÓN DE EXPORTAR ---
  Future<void> _handleExport() async {
    // Solo permitimos exportar si estamos en modo 'Equipos'
    if (_searchType != 'Equipos') return;

    // Si hay selección, exportamos solo eso. Si no, exportamos TODO lo que se ve en pantalla.
    final listToExport = _selectedItems.isNotEmpty
        ? _selectedItems.cast<EquipmentRecord>().toList()
        : _results.cast<EquipmentRecord>().toList();

    if (listToExport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay datos para exportar')));
      return;
    }

    final String? csvContent = await fileManager.exportRecords(listToExport);
    if (csvContent == null) return;

    final String dateSuffix = DateFormat('dd_MM_yy').format(DateTime.now());
    final String fileName = "reporte_equipos_$dateSuffix.csv";

    if (kIsWeb) {
      try {
        final bytes = utf8.encode(csvContent);
        final blob = html_stub.Blob([bytes], 'text/csv');
        final url = html_stub.Url.createObjectUrlFromBlob(blob);
        html_stub.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html_stub.Url.revokeObjectUrl(url);
      } catch (e) { print(e); }
    } else {
      try {
        final tempDir = await getTemporaryDirectory();
        final File tempFile = File('${tempDir.path}/$fileName');
        await tempFile.writeAsString(csvContent);
        await Share.shareXFiles([XFile(tempFile.path)], text: 'Exportación de Equipos');
      } catch (e) { print(e); }
    }
  }

  // (Funciones auxiliares de UI)
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      controller.text = "${picked.day}/${picked.month}/${picked.year}";
    }
  }

  void _showPlantDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccione la planta'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('TODAS (limpiar filtro)'),
                  onTap: () {
                    _plantController.clear();
                    Navigator.of(context).pop();
                  },
                ),
                ...plantOptions.map((option) {
                  return ListTile(
                    title: Text(option),
                    onTap: () {
                      _plantController.text = option;
                      Navigator.of(context).pop();
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleSelection(dynamic item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        _selectedItems.add(item);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedItems.length == _results.length) {
        _selectedItems.clear();
      } else {
        _selectedItems.addAll(_results);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _searchType,
              decoration: const InputDecoration(labelText: 'Tipo de Búsqueda', border: OutlineInputBorder()),
              items: _searchOptions.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() { _searchType = v!; _results = []; _selectedItems.clear(); }),
            ),
            const SizedBox(height: 16),
            // (Filas de filtros de fecha y planta - igual que antes)
            Row(
              children: [
                Expanded(child: TextField(controller: _startDateController, readOnly: true, onTap: () => _selectDate(context, _startDateController), decoration: const InputDecoration(labelText: 'Fecha inicio', border: OutlineInputBorder(), suffixIcon: Icon(Icons.date_range)))),
                const SizedBox(width: 16),
                Expanded(child: TextField(controller: _endDateController, readOnly: true, onTap: () => _selectDate(context, _endDateController), decoration: const InputDecoration(labelText: 'Fecha fin', border: OutlineInputBorder(), suffixIcon: Icon(Icons.date_range)))),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextField(controller: _plantController, readOnly: true, onTap: _showPlantDialog, decoration: const InputDecoration(labelText: 'Planta', border: OutlineInputBorder(), suffixIcon: Icon(Icons.arrow_drop_down)))),
                const SizedBox(width: 16),
                Expanded(child: TextField(controller: _utController, decoration: const InputDecoration(labelText: 'UT', border: OutlineInputBorder()), onChanged: (t) => _utController.value = _utController.value.copyWith(text: t.toUpperCase(), selection: TextSelection.collapsed(offset: t.length)))),
              ],
            ),
            const SizedBox(height: 16),

            ElevatedButton(onPressed: _performSearch, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)), child: const Text('Buscar')),

            const SizedBox(height: 16),

            // --- BOTONES DE ACCIÓN (BORRAR / EXPORTAR) ---
            Row(
              children: [
                if (_results.isNotEmpty)
                  Expanded(child: ElevatedButton(onPressed: _toggleSelectAll, child: Text(_selectedItems.length == _results.length ? 'Deseleccionar Todo' : 'Seleccionar Todo'))),

                if (_results.isNotEmpty) const SizedBox(width: 8),

                if (_selectedItems.isNotEmpty)
                  Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: _handleDelete, child: const Text('Borrar', style: TextStyle(color: Colors.white)))),

                if (_searchType == 'Equipos' && _results.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green), onPressed: _handleExport, child: const Text('Exportar', style: TextStyle(color: Colors.white)))),
                ]
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),

            if (_results.isEmpty)
              const Expanded(child: Center(child: Text('No hay resultados.')))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final item = _results[index];
                    final isSelected = _selectedItems.contains(item);

                    // Renderizado condicional según el tipo de objeto
                    String title = "";
                    String subtitle = "";

                    if (item is RegistroRecord) {
                      title = "${item.ut} (${item.date})";
                      subtitle = "${item.point}\n${item.description}";
                    } else if (item is EquipmentRecord) {
                      title = "${item.ut} (${item.date})";
                      subtitle = item.equipment;
                    }

                    return Card(
                      color: isSelected ? Colors.blue[50] : null,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Checkbox(
                          value: isSelected,
                          onChanged: (bool? value) => _toggleSelection(item),
                        ),
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(subtitle),
                        onTap: () => _toggleSelection(item),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}