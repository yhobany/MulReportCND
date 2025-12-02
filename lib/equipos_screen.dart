import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart'; // Para la fecha

// Importaciones de nuestra arquitectura
import 'file_manager_locator.dart';
import 'file_manager_interface.dart';

class EquiposScreen extends StatefulWidget {
  const EquiposScreen({super.key});

  @override
  State<EquiposScreen> createState() => _EquiposScreenState();
}

class _EquiposScreenState extends State<EquiposScreen> {
  final FileManagerInterface fileManager = getFileManager();

  // Controladores
  final TextEditingController _utController = TextEditingController();
  final TextEditingController _equipoPrincipalController = TextEditingController();
  List<TextEditingController> _additionalEquipControllers = [];

  // Fecha actual
  final String _currentDate =
      "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";

  // Prefijos válidos
  final List<String> validPrefixes = [
    "PFM6", "PFM4", "PCM1", "PCM3", "PP30", "PP40",
    "PP50", "PP90", "PP95", "PP20", "PR"
  ];

  final ImagePicker _picker = ImagePicker();

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
    bool allSuccess = true;
    for (String equipment in allEquipments) {
      bool success = await fileManager.saveEquipmentToCsv(_currentDate, ut, equipment);
      if (!success) allSuccess = false;
    }

    if (allSuccess) {
      _showSnackBar('¡Equipos guardados exitosamente!');
      // Limpiar formulario
      _utController.clear();
      _equipoPrincipalController.clear();
      for (var controller in _additionalEquipControllers) controller.dispose();
      setState(() { _additionalEquipControllers = []; });
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
    // En web usamos galería, en móvil usamos cámara
    final ImageSource source = kIsWeb ? ImageSource.gallery : ImageSource.camera;

    if (kIsWeb) {
      try {
        photo = await _picker.pickImage(
            source: source,
            imageQuality: 80,
            maxWidth: 1024
        );
      } catch (e) {
        _showAlertDialog('Error al seleccionar archivo', 'No se pudo cargar la imagen: $e');
      }
    } else {
      var status = await Permission.camera.request();
      if (status.isGranted) {
        try {
          photo = await _picker.pickImage(
              source: source,
              imageQuality: 80,
              maxWidth: 1024
          );
        } catch (e) {
          _showAlertDialog('Error de Cámara', 'No se pudo iniciar la cámara: $e');
        }
      } else if (status.isDenied || status.isPermanentlyDenied) {
        _showAlertDialog('Permiso Denegado',
            'No se puede usar la cámara sin permisos. Vaya a la configuración de la app para habilitarlos.');
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
        padding: const EdgeInsets.all(24.0), // Más espacio alrededor
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título o Encabezado opcional
            const Text(
              "Registro de Equipos",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const SizedBox(height: 20),

            // --- FILA 1: Fecha y UT ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fecha (Solo lectura)
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
                // UT (Entrada)
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
                      hintText: 'Nombre o deja vacío para foto',
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
                  tooltip: "Tomar foto / Subir imagen",
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
                          decoration: InputDecoration(
                            hintText: 'Equipo adicional ${index + 1}',
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

            // Botón para añadir más
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

            // --- BOTÓN GUARDAR (Grande y destacado) ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
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