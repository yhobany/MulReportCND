import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:permission_handler/permission_handler.dart'; // Ya no es estrictamente necesario para galería simple
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'services/database_service.dart';
import 'theme/app_theme.dart';
import 'equipment_record.dart';

class EquiposScreen extends StatefulWidget {
  const EquiposScreen({super.key});

  @override
  State<EquiposScreen> createState() => _EquiposScreenState();
}

class _EquiposScreenState extends State<EquiposScreen> {
  late DatabaseService fileManager;

  @override
  void initState() {
    super.initState();
    fileManager = Provider.of<DatabaseService>(context, listen: false);
  }

  // Controladores
  final TextEditingController _utController = TextEditingController();
  final TextEditingController _equipoPrincipalController = TextEditingController();
  List<TextEditingController> _additionalEquipControllers = [];
  List<FocusNode> _additionalEquipFocusNodes = [];

  // Fecha actual
  final String _currentDate =
      "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";

  // Prefijos válidos
  final List<String> validPrefixes = [
    "PFM6", "PFM4", "PCM1", "PCM3", "PP30", "PP40",
    "PP50", "PP90", "PP95", "PP20", "PR"
  ];

  final ImagePicker _picker = ImagePicker();

  // Variables para validación predictiva
  Timer? _debounce;
  List<EquipmentRecord> _existingEquipments = [];
  bool _isCheckingUt = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _utController.dispose();
    _equipoPrincipalController.dispose();
    for (var controller in _additionalEquipControllers) controller.dispose();
    for (var node in _additionalEquipFocusNodes) node.dispose();
    super.dispose();
  }

  void _addEquipmentField() {
    setState(() {
      final newFocusNode = FocusNode();
      _additionalEquipControllers.add(TextEditingController());
      _additionalEquipFocusNodes.add(newFocusNode);
      
      // Request focus after the frame builds
      WidgetsBinding.instance.addPostFrameCallback((_) {
        newFocusNode.requestFocus();
      });
    });
  }

  void _removeEquipmentField(int index) {
    setState(() {
      _additionalEquipControllers[index].dispose();
      _additionalEquipControllers.removeAt(index);
      
      _additionalEquipFocusNodes[index].dispose();
      _additionalEquipFocusNodes.removeAt(index);
    });
  }

  void _onUtChanged(String text) {
    // Convertir a mayúsculas y mantener cursor
    _utController.value = _utController.value.copyWith(
      text: text.toUpperCase(),
      selection: TextSelection.collapsed(offset: text.length),
    );

    final ut = text.toUpperCase();

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    // Si borró la UT, reseteamos la lista
    if (ut.isEmpty) {
      setState(() {
        _existingEquipments.clear();
        _isCheckingUt = false;
      });
      return;
    }

    // Esperar 800ms de inactividad
    _debounce = Timer(const Duration(milliseconds: 800), () async {
      // Validar si el prefijo es válido antes de consultar la BD
      final bool isValidPrefix = validPrefixes.any((prefix) => ut.startsWith(prefix));
      if (!isValidPrefix) return;

      setState(() { _isCheckingUt = true; });
      final equipments = await fileManager.getEquipmentByUt(ut);
      if (mounted) {
        setState(() {
          _existingEquipments = equipments;
          _isCheckingUt = false;
        });
      }
    });
  }

  Future<List<EquipmentRecord>?> _showMultiDuplicateWarning(List<EquipmentRecord> conflicts, String ut) {
    List<EquipmentRecord> selectedToOverwrite = List.from(conflicts);

    return showDialog<List<EquipmentRecord>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Equipos Duplicados'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Se encontraron equipos ya registrados para la UT "$ut".\n\nSelecciona cuáles deseas actualizar a la fecha de hoy:'),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: conflicts.length,
                        itemBuilder: (context, index) {
                          final record = conflicts[index];
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(record.equipment, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Original: ${record.date}'),
                            value: selectedToOverwrite.contains(record),
                            activeColor: AppTheme.accentColor,
                            onChanged: (bool? value) {
                              setDialogState(() {
                                if (value == true) {
                                  selectedToOverwrite.add(record);
                                } else {
                                  selectedToOverwrite.remove(record);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Cancelar Guardado'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, selectedToOverwrite),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor),
                  child: const Text('Continuar', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();

    // 1. Validaciones
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

    // 2. Recolectar equipos
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

    // 3. Guardar
    int savedCount = 0;
    bool hadErrors = false;
    
    // Identificar conflictos cruzando contra la lista asíncrona pre-cargada
    List<EquipmentRecord> conflicts = [];
    List<String> newEquipments = [];
    
    for (String eq in allEquipments) {
      try {
        final existing = _existingEquipments.firstWhere(
          (e) => e.equipment.toUpperCase() == eq.toUpperCase()
        );
        conflicts.add(existing);
      } catch (e) {
        newEquipments.add(eq);
      }
    }

    List<EquipmentRecord> recordsToOverwrite = [];
    
    if (conflicts.isNotEmpty) {
      final result = await _showMultiDuplicateWarning(conflicts, ut);
      if (result == null) {
        // El usuario presionó Cancelar Guardado
        return;
      }
      recordsToOverwrite = result;
    }

    // 4. Guardar los que no tienen conflicto (nuevos)
    for (String newEq in newEquipments) {
      bool success = await fileManager.saveEquipmentToCsv(_currentDate, ut, newEq);
      if (success) savedCount++; else hadErrors = true;
    }
    
    // 5. Sobreescribir solo los seleccionados
    for (var record in recordsToOverwrite) {
      bool success = await fileManager.updateEquipment(record, ut, record.equipment, _currentDate);
      if (success) savedCount++; else hadErrors = true;
    }

    if (hadErrors) {
      _showAlertDialog('Error', 'Hubo problemas al guardar algunos equipos.');
    } else if (savedCount > 0) {
      _showSnackBar('¡$savedCount equipo(s) procesado(s) exitosamente!');
      
      // Actualizar la lista en memoria para que no haya falsos nuevos
      _existingEquipments = await fileManager.getEquipmentByUt(ut);
      
      // Limpiar formulario
      _utController.clear();
      _equipoPrincipalController.clear();
      for (var controller in _additionalEquipControllers) controller.dispose();
      for (var node in _additionalEquipFocusNodes) node.dispose();
      setState(() { 
        _additionalEquipControllers = []; 
        _additionalEquipFocusNodes = [];
        _existingEquipments.clear();
      });
    }
  }

  // --- MODIFICADO: Seleccionar imagen de Galería y usar nombre de archivo ---
  Future<void> _handleCamera(int? index) async {
    // Aunque no generamos consecutivo, es buena práctica validar que haya contexto
    // Pero para solo leer el nombre del archivo, no es estrictamente obligatorio validar la UT.
    // Sin embargo, mantenemos la consistencia.
    /*
    if (_utController.text.isEmpty) {
      _showAlertDialog('Error', 'Debe ingresar la UT antes de seleccionar una imagen.');
      return;
    }
    */

    try {
      // Forzamos uso de Galería en todos los casos (Web y Móvil)
      // Esto simplifica la lógica y evita problemas de permisos de cámara en web
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Opcional, ya que no subimos la imagen, pero reduce uso de RAM al procesar
      );

      if (photo != null) {
        // Obtenemos solo el nombre del archivo (ej: imagen.jpg)
        final String fileName = photo.name;

        setState(() {
          if (index == null) {
            _equipoPrincipalController.text = fileName;
          } else {
            _additionalEquipControllers[index].text = fileName;
          }
        });
      }
    } catch (e) {
      _showAlertDialog('Error', 'No se pudo seleccionar la imagen: $e');
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
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Registro de Equipos",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const SizedBox(height: 20),

            // --- FILA 1: Fecha y UT ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.grey.shade100,
                        ),
                        child: Text(
                          _currentDate,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('UT', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _utController,
                        decoration: const InputDecoration(
                          hintText: 'Ej: PFM6-123',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        onChanged: _onUtChanged,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- FILA 2: Equipo Principal ---
            const Text('Equipo Principal', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _equipoPrincipalController,
                    decoration: const InputDecoration(
                      hintText: 'Nombre o seleccione imagen',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (text) {
                      _equipoPrincipalController.value = _equipoPrincipalController.value.copyWith(
                        text: text.toUpperCase(),
                        selection: TextSelection.collapsed(offset: text.length),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.camera_alt, size: 24),
                  onPressed: () => _handleCamera(null),
                  tooltip: "Seleccionar imagen", // Tooltip actualizado
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- EQUIPOS ADICIONALES ---
            if (_additionalEquipControllers.isNotEmpty) ...[
              const Text('Equipos Adicionales', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
            ],

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _additionalEquipControllers.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _additionalEquipControllers[index],
                          focusNode: _additionalEquipFocusNodes[index],
                          decoration: InputDecoration(
                            hintText: 'Ej: Foto-0${index + 2}.jpg',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          onChanged: (text) {
                            _additionalEquipControllers[index].value = _additionalEquipControllers[index].value.copyWith(
                              text: text.toUpperCase(),
                              selection: TextSelection.collapsed(offset: text.length),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.camera_alt),
                        onPressed: () => _handleCamera(index),
                        tooltip: "Seleccionar imagen",
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: AppTheme.statusOpen),
                        onPressed: () => _removeEquipmentField(index),
                      ),
                    ],
                  ),
                );
              },
            ),

            Center(
              child: TextButton.icon(
                onPressed: _addEquipmentField,
                icon: const Icon(Icons.add),
                label: const Text('Agregar otro equipo'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                ),
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  elevation: 2,
                ),
                child: const Text(
                  'GUARDAR EQUIPOS',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}