// lib/report_screen.dart

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

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

  List<dynamic> _results = [];
  Set<dynamic> _selectedItems = {};

  String _searchType = 'Registros';
  final List<String> _searchOptions = ['Registros', 'Equipos'];

  // Filtro de Prioridad
  String _searchPriority = 'Todas';
  final List<String> _priorityOptions = ['Todas', 'Alto', 'Medio', 'Bajo'];

  // Filtro de Estatus
  String _searchStatus = 'Todos';
  final List<String> _statusFilterOptions = ['Todos', 'Abierto', 'En Proceso', 'Culminado'];
  final List<String> _statusEditOptions = ['Abierto', 'En Proceso', 'Culminado'];

  bool _areFiltersVisible = true;

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
    // No limpiamos selección para mejor UX al editar

    if (_searchType == 'Registros') {
      final results = await fileManager.searchInFile(
        _startDateController.text,
        _endDateController.text,
        _utController.text,
        _plantController.text,
        _searchPriority,
        _searchStatus,
      );
      setState(() {
        _results = results;
        if (_results.isNotEmpty) _areFiltersVisible = false;
      });
    } else {
      final results = await fileManager.searchInEquiposFile(
        _startDateController.text,
        _endDateController.text,
        _utController.text,
        _plantController.text,
      );
      setState(() {
        _results = results;
        if (_results.isNotEmpty) _areFiltersVisible = false;
      });
    }
  }

  // --- Función para cambiar Estatus (con actualización local) ---
  void _showEditStatusDialog(RegistroRecord item) {
    String newStatus = item.status;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Actualizar Estatus'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("UT: ${item.ut}", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Seleccione el nuevo estatus:"),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: newStatus,
                items: _statusEditOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) {
                  if (val != null) newStatus = val;
                },
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Cerrar diálogo

                // 1. Actualizar en Backend
                bool success = await fileManager.updateRegistroStatus(item, newStatus);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Estatus actualizado a: $newStatus'))
                  );

                  // 2. Actualización Local Inmediata
                  setState(() {
                    int index = _results.indexOf(item);
                    if (index != -1) {
                      final oldItem = _results[index] as RegistroRecord;
                      final newItem = RegistroRecord(
                        id: oldItem.id,
                        date: oldItem.date,
                        ut: oldItem.ut,
                        point: oldItem.point,
                        description: oldItem.description,
                        priority: oldItem.priority,
                        status: newStatus,
                      );
                      _results[index] = newItem;
                    }
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error al actualizar estatus'))
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

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
        final list = _selectedItems.cast<RegistroRecord>().toList();
        success = await fileManager.deleteRegistros(list);
      } else {
        final list = _selectedItems.cast<EquipmentRecord>().toList();
        success = await fileManager.deleteEquipmentRecords(list);
      }
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Eliminados correctamente')));
        _selectedItems.clear();
        _performSearch();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al eliminar')));
      }
    }
  }

  Future<void> _handleExport() async {
    if (_searchType != 'Equipos') return;
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Abierto': return Colors.red.shade700;
      case 'En Proceso': return Colors.orange.shade800;
      case 'Culminado': return Colors.green.shade700;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- CABECERA ---
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _searchType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _searchOptions.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                    onChanged: (v) => setState(() { _searchType = v!; _results = []; _selectedItems.clear(); }),
                  ),
                ),

                if (_searchType == 'Registros') ...[
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _searchPriority,
                      decoration: const InputDecoration(
                        labelText: 'Prioridad',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _priorityOptions.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                      onChanged: (v) => setState(() { _searchPriority = v!; }),
                    ),
                  ),
                ],

                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: Icon(_areFiltersVisible ? Icons.expand_less : Icons.filter_list),
                  tooltip: _areFiltersVisible ? "Ocultar Filtros" : "Mostrar Filtros",
                  onPressed: () => setState(() => _areFiltersVisible = !_areFiltersVisible),
                ),
              ],
            ),

            // --- ÁREA COLAPSABLE DE FILTROS ---
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: Container(
                height: _areFiltersVisible ? null : 0,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
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

                    if (_searchType == 'Registros') ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _searchStatus,
                              decoration: const InputDecoration(
                                labelText: 'Estatus del Registro',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: _statusFilterOptions.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                              onChanged: (v) => setState(() { _searchStatus = v!; }),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: _performSearch,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      child: const Text('Buscar'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Botones de Acción
            if (_results.isNotEmpty || _selectedItems.isNotEmpty)
              Row(
                children: [
                  Expanded(child: ElevatedButton(onPressed: _toggleSelectAll, child: Text(_selectedItems.length == _results.length ? 'Deseleccionar Todo' : 'Seleccionar Todo'))),
                  const SizedBox(width: 8),
                  if (_selectedItems.isNotEmpty)
                    Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: _handleDelete, child: const Text('Borrar', style: TextStyle(color: Colors.white)))),
                  if (_searchType == 'Equipos' && _results.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green), onPressed: _handleExport, child: const Text('Exportar', style: TextStyle(color: Colors.white)))),
                  ]
                ],
              ),

            const SizedBox(height: 8),
            const Divider(),

            // Lista de Resultados
            if (_results.isEmpty)
              const Expanded(child: Center(child: Text('No hay resultados.')))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final item = _results[index];
                    final isSelected = _selectedItems.contains(item);

                    String title = "";
                    Widget? subtitleWidget;
                    Widget? trailingWidget;

                    if (item is RegistroRecord) {
                      title = "${item.ut} (${item.date})";
                      subtitleWidget = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: Text("Prioridad: ${item.priority}", style: const TextStyle(fontSize: 12)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(item.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: _getStatusColor(item.status)),
                                ),
                                child: Text(
                                    item.status.toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _getStatusColor(item.status)
                                    )
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text("${item.point}\n${item.description}"),
                        ],
                      );
                      trailingWidget = IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditStatusDialog(item),
                        tooltip: "Editar Estatus",
                      );
                    } else if (item is EquipmentRecord) {
                      title = "${item.ut} (${item.date})";
                      subtitleWidget = Text(item.equipment);
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
                        subtitle: subtitleWidget,
                        trailing: trailingWidget,
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