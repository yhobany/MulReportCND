// lib/report_screen.dart

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'services/database_service.dart';
import 'theme/app_theme.dart';
import 'equipment_record.dart';
import 'registro_record.dart';
import 'widgets/dialogs/edit_status_dialog.dart';
import 'widgets/dialogs/edit_equipment_dialog.dart';
import 'widgets/items/registro_list_item.dart';
import 'widgets/items/equipment_list_item.dart';
import 'html_stub.dart' if (dart.library.html) 'dart:html' as html_stub;

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late DatabaseService fileManager;

  @override
  void initState() {
    super.initState();
    fileManager = Provider.of<DatabaseService>(context, listen: false);
  }

  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _plantController = TextEditingController();
  final TextEditingController _utController = TextEditingController();

  List<dynamic> _results = [];
  Set<dynamic> _selectedItems = {};

  String _searchType = 'Registros';
  final List<String> _searchOptions = ['Registros', 'Equipos'];

  String _searchPriority = 'Todas';
  final List<String> _priorityOptions = ['Todas', 'Alto', 'Medio', 'Bajo'];

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

  void _showEditStatusDialog(RegistroRecord item) {
    showDialog(
      context: context,
      builder: (context) {
        return EditStatusDialog(
          item: item,
          onSave: (RegistroRecord recordToUpdate, String newStatus, String noteText) async {
            bool success = await fileManager.updateRegistroStatus(recordToUpdate, newStatus, noteText);

            if (success) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Estatus actualizado a: $newStatus')));
              }

              setState(() {
                int index = _results.indexOf(recordToUpdate);
                if (index != -1) {
                  final newItem = RegistroRecord(
                    id: recordToUpdate.id,
                    date: recordToUpdate.date,
                    ut: recordToUpdate.ut,
                    point: recordToUpdate.point,
                    description: recordToUpdate.description,
                    priority: recordToUpdate.priority,
                    status: newStatus,
                    actionNote: noteText,
                  );
                  _results[index] = newItem;
                }
              });
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error al actualizar estatus')));
              }
            }
          },
        );
      },
    );
  }

  void _showEditEquipmentDialog(EquipmentRecord item) {
    showDialog(
      context: context,
      builder: (context) {
        return EditEquipmentDialog(
          item: item,
          onSave: (EquipmentRecord recordToUpdate, String newUt, String newEquip) async {
            final String newDate = "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";
            bool success = await fileManager.updateEquipment(recordToUpdate, newUt, newEquip, newDate);

            if (success) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Equipo actualizado correctamente')));
              }

              setState(() {
                int index = _results.indexOf(recordToUpdate);
                if (index != -1) {
                  final newItem = EquipmentRecord(
                    id: recordToUpdate.id,
                    date: newDate,
                    ut: newUt,
                    equipment: newEquip,
                  );
                  _results[index] = newItem;
                }
              });
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error al actualizar el equipo')));
              }
            }
          },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // --- SECCIÓN SUPERIOR ESTÁTICA/FILTROS ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _searchType,
                              isExpanded: true, // PREVIENE OVERFLOW DE TEXTO LARGO
                              decoration: InputDecoration(
                                labelText: 'Tipo', // Texto más corto
                                prefixIcon: const Icon(Icons.search),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: _searchOptions.map((v) => DropdownMenuItem(
                                value: v, 
                                child: Text(v, overflow: TextOverflow.ellipsis) // Previene overflow en el item
                              )).toList(),
                              onChanged: (v) => setState(() { _searchType = v!; _results = []; _selectedItems.clear(); }),
                            ),
                          ),
                          if (_searchType == 'Registros') ...[
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                value: _searchPriority,
                                isExpanded: true, // PREVIENE OVERFLOW DE TEXTO LARGO
                                decoration: InputDecoration(
                                  labelText: 'Prioridad',
                                  prefixIcon: const Icon(Icons.flag_outlined),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                items: _priorityOptions.map((v) => DropdownMenuItem(
                                  value: v, 
                                  child: Text(v, overflow: TextOverflow.ellipsis) // Previene overflow
                                )).toList(),
                                onChanged: (v) => setState(() { _searchPriority = v!; }),
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: _areFiltersVisible ? Colors.indigo.shade50 : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: Icon(_areFiltersVisible ? Icons.expand_less : Icons.tune),
                              color: _areFiltersVisible ? Colors.indigo.shade700 : Colors.grey.shade600,
                              tooltip: _areFiltersVisible ? "Ocultar Filtros Avanzados" : "Mostrar Filtros Avanzados",
                              onPressed: () => setState(() => _areFiltersVisible = !_areFiltersVisible),
                            ),
                          ),
                        ],
                      ),

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
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _performSearch,
                            icon: const Icon(Icons.search),
                            label: const Text('Ejecutar Búsqueda'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 54),
                              elevation: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (_results.isNotEmpty || _selectedItems.isNotEmpty)
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: ElevatedButton(
                            onPressed: _toggleSelectAll,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(_selectedItems.length == _results.length ? 'Deseleccionar Todo' : 'Seleccionar Todo'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_selectedItems.isNotEmpty)
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusOpen),
                              onPressed: _handleDelete,
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('Borrar', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ),
                        if (_searchType == 'Equipos' && _results.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _handleExport,
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('Exportar'),
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),

                  const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // --- SECCIÓN INFERIOR: RESULTADOS (LISTA DESLIZABLE) ---
          if (_results.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('No hay resultados.')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final item = _results[index];
                    final isSelected = _selectedItems.contains(item);
                    if (item is RegistroRecord) {
                      return RegistroListItem(
                        item: item,
                        isSelected: isSelected,
                        onToggleSelection: () => _toggleSelection(item),
                        onEdit: () => _showEditStatusDialog(item),
                      );
                    } else if (item is EquipmentRecord) {
                        return EquipmentListItem(
                          item: item,
                          isSelected: isSelected,
                          onToggleSelection: () => _toggleSelection(item),
                          onEdit: () => _showEditEquipmentDialog(item),
                        );
                    }
                    return const SizedBox.shrink();
                  },
                  childCount: _results.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}