// ... (Importaciones sin cambios)
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'file_manager_locator.dart';
import 'file_manager_interface.dart';
import 'equipment_record.dart';
import 'html_stub.dart' if (dart.library.html) 'dart:html' as html_stub;

class EquiposScreen extends StatefulWidget {
  const EquiposScreen({super.key});

  @override
  State<EquiposScreen> createState() => _EquiposScreenState();
}

class _EquiposScreenState extends State<EquiposScreen> {
  // (Variables y métodos init/dispose/camera/delete/save sin cambios)
  // ...
  final FileManagerInterface fileManager = getFileManager();
  final TextEditingController _utController = TextEditingController();
  final TextEditingController _equipoPrincipalController = TextEditingController();
  List<TextEditingController> _additionalEquipControllers = [];
  List<EquipmentRecord> _savedRecords = [];
  bool _isCollapsed = false;
  Set<EquipmentRecord> _selectedRecords = {};
  final String _currentDate = "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";
  final List<String> validPrefixes = ["PFM6", "PFM4", "PCM1", "PCM3", "PP30", "PP40", "PP50", "PP90", "PP95", "PP20", "PR"];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = await fileManager.readEquipmentRecords();
    setState(() {
      _savedRecords = records;
      _selectedRecords.clear();
    });
  }

  @override
  void dispose() {
    _utController.dispose();
    _equipoPrincipalController.dispose();
    for (var controller in _additionalEquipControllers) controller.dispose();
    super.dispose();
  }

  void _addEquipmentField() {
    setState(() {
      _additionalEquipControllers.add(TextEditingController());
    });
  }

  void _removeEquipmentField(int index) {
    setState(() {
      _additionalEquipControllers[index].dispose();
      _additionalEquipControllers.removeAt(index);
    });
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    final String ut = _utController.text;
    if (ut.isEmpty) {
      _showAlertDialog('Error', 'El campo UT es obligatorio.');
      return;
    }
    final bool isValidPrefix = validPrefixes.any((prefix) => ut.startsWith(prefix));
    if (!isValidPrefix) {
      _showAlertDialog('Prefijo de planta inválido',
          'El campo UT debe comenzar con uno de los prefijos siguientes: ${validPrefixes.join(", ")}');
      return;
    }
    final List<String> allEquipments = [];
    if (_equipoPrincipalController.text.isNotEmpty) {
      allEquipments.add(_equipoPrincipalController.text);
    }
    for (var controller in _additionalEquipControllers) {
      if (controller.text.isNotEmpty) {
        allEquipments.add(controller.text);
      }
    }
    if (allEquipments.isEmpty) {
      _showAlertDialog('Error', 'Debe ingresar al menos un equipo.');
      return;
    }
    bool allSuccess = true;
    for (String equipment in allEquipments) {
      bool success = await fileManager.saveEquipmentToCsv(_currentDate, ut, equipment);
      if (!success) allSuccess = false;
    }
    if (allSuccess) {
      _showSnackBar('¡Equipos guardados exitosamente!');
      _utController.clear();
      _equipoPrincipalController.clear();
      for (var controller in _additionalEquipControllers) controller.dispose();
      setState(() { _additionalEquipControllers = []; });
      _loadRecords();
    } else {
      _showAlertDialog('Error', 'No se pudieron guardar uno o más equipos.');
    }
  }

  Future<void> _handleCamera(int? index) async {
    if (_utController.text.isEmpty) {
      _showAlertDialog('Error', 'Debe ingresar la UT antes de tomar una foto.');
      return;
    }
    XFile? photo;
    final ImageSource source = kIsWeb ? ImageSource.gallery : ImageSource.camera;
    if (kIsWeb) {
      try {
        photo = await _picker.pickImage(source: source, imageQuality: 80, maxWidth: 1024);
      } catch (e) {
        _showAlertDialog('Error al seleccionar archivo', 'No se pudo cargar la imagen: $e');
      }
    } else {
      var status = await Permission.camera.request();
      if (status.isGranted) {
        try {
          photo = await _picker.pickImage(source: source, imageQuality: 80, maxWidth: 1024);
        } catch (e) {
          _showAlertDialog('Error de Cámara', 'No se pudo iniciar la cámara: $e');
        }
      } else if (status.isDenied || status.isPermanentlyDenied) {
        _showAlertDialog('Permiso Denegado', 'No se puede usar la cámara sin permisos.');
      }
    }
    if (photo != null) {
      final String newFileName = await fileManager.getNextImageName(_utController.text);
      setState(() {
        if (index == null) {
          _equipoPrincipalController.text = newFileName;
        } else {
          _additionalEquipControllers[index].text = newFileName;
        }
      });
    }
  }

  Future<void> _handleDelete() async {
    if (_selectedRecords.isEmpty) {
      _showAlertDialog('Error', 'No se han seleccionado registros para eliminar.');
      return;
    }
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Desea eliminar ${_selectedRecords.length} registro(s) seleccionado(s)?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirmar')),
        ],
      ),
    ) ?? false;
    if (confirm) {
      bool success = await fileManager.deleteEquipmentRecords(_selectedRecords.toList());
      if (success) {
        _showSnackBar('Registros eliminados exitosamente.');
        _loadRecords();
      } else {
        _showAlertDialog('Error', 'No se pudieron eliminar los registros.');
      }
    }
  }

  // --- FUNCIÓN DE EXPORTACIÓN (ACTUALIZADA) ---
  Future<void> _handleExport() async {
    // 1. DECIDIR QUÉ EXPORTAR
    // Si hay seleccionados -> exportar seleccionados
    // Si no hay seleccionados -> exportar TODO (_savedRecords)
    final List<EquipmentRecord> recordsToExport =
    _selectedRecords.isNotEmpty ? _selectedRecords.toList() : _savedRecords;

    if (recordsToExport.isEmpty) {
      _showAlertDialog('No hay datos', 'No hay registros para exportar.');
      return;
    }

    // 2. Obtener el CONTENIDO CSV
    final String? csvContent = await fileManager.exportRecords(recordsToExport);

    if (csvContent == null) {
      _showAlertDialog('Error', 'Error al generar el archivo CSV.');
      return;
    }

    final String dateSuffix = DateFormat('dd_MM_yy').format(DateTime.now());
    final String fileName = "equipos_export_$dateSuffix.csv"; // Nombre genérico

    if (kIsWeb) {
      try {
        final bytes = utf8.encode(csvContent);
        final blob = html_stub.Blob([bytes], 'text/csv');
        final url = html_stub.Url.createObjectUrlFromBlob(blob);
        html_stub.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html_stub.Url.revokeObjectUrl(url);
        _showSnackBar('Descargando archivo...');
      } catch (e) {
        _showAlertDialog('Error de Exportación Web', 'No se pudo descargar el archivo: $e');
      }
    } else {
      try {
        final tempDir = await getTemporaryDirectory();
        final File tempFile = File('${tempDir.path}/$fileName');
        await tempFile.writeAsString(csvContent);

        await Share.shareXFiles(
          [XFile(tempFile.path)],
          text: 'Exportación de Equipos',
          subject: 'Reporte CND - Equipos',
        );
      } catch (e) {
        _showAlertDialog('Error de Exportación Móvil', 'No se pudo compartir el archivo: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _showAlertDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // (El build() no cambia)
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: Container(
              height: _isCollapsed ? 0 : null,
              child: Opacity(
                opacity: _isCollapsed ? 0 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: Text(_currentDate, style: const TextStyle(fontSize: 16)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('UT', style: TextStyle(fontWeight: FontWeight.bold)),
                              TextField(
                                controller: _utController,
                                decoration: const InputDecoration(
                                  hintText: 'Ej: PFM6-123',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (text) {
                                  _utController.value = _utController.value.copyWith(
                                    text: text.toUpperCase(),
                                    selection: TextSelection.collapsed(offset: text.length),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Equipo Principal', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _equipoPrincipalController,
                            decoration: const InputDecoration(
                              hintText: 'Nombre o deja vacío para foto',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (text) {
                              _equipoPrincipalController.value = _equipoPrincipalController.value.copyWith(
                                text: text.toUpperCase(),
                                selection: TextSelection.collapsed(offset: text.length),
                              );
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.camera_alt, size: 30),
                          onPressed: () => _handleCamera(null),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _additionalEquipControllers.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _additionalEquipControllers[index],
                                  decoration: const InputDecoration(
                                    hintText: 'Equipo adicional',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (text) {
                                    _additionalEquipControllers[index].value = _additionalEquipControllers[index].value.copyWith(
                                      text: text.toUpperCase(),
                                      selection: TextSelection.collapsed(offset: text.length),
                                    );
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.camera_alt),
                                onPressed: () => _handleCamera(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () => _removeEquipmentField(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    TextButton(
                      onPressed: _addEquipmentField,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add),
                          Text('Agregar equipo'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _handleSave,
                  child: const Text('Guardar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _handleExport,
                  child: const Text('Exportar'),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => setState(() => _isCollapsed = !_isCollapsed),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_isCollapsed ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up),
                      Text(_isCollapsed ? 'Expandir' : 'Colapsar'),
                    ],

                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton(
                  onPressed: _handleDelete,
                  child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),
          const Text('Registros Guardados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          if (_savedRecords.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No hay equipos guardados.'),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _savedRecords.length,
              itemBuilder: (context, index) {
                final record = _savedRecords[index];
                final bool isSelected = _selectedRecords.contains(record);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text("${record.ut} - ${record.equipment}"),
                    subtitle: Text(record.date),
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedRecords.add(record);
                          } else {
                            _selectedRecords.remove(record);
                          }
                        });
                      },
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}