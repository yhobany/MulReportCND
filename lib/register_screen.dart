// lib/register_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late DatabaseService fileManager;



  final TextEditingController _utController = TextEditingController();
  final TextEditingController _symptomController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final String _currentDate =
      "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";

  String _selectedPriority = 'Medio';
  final List<String> _priorities = ['Alto', 'Medio', 'Bajo'];

  final List<String> validPrefixes = [
    "PFM6", "PFM4", "PCM1", "PCM3", "PP30", "PP40",
    "PP50", "PP90", "PP95", "PP20", "PR"
  ];

  // Lista dinámica de síntomas. Empezamos con los predeterminados.
  List<String> symptomOptions = [];

  // Lista base original para fallback si no hay guardados
  final List<String> defaultSymptomOptions = [
    "Vib/soporte", "Vib/reductor", "Roce",
    "Holgura", "Golpeteo", "Ruido/bandas",
    "Alta/temp", "Vib/estructural",
    "Soltura/sop", "Ruido/acop",
    "Engranamiento", "Falta/lub", "NA - None"
  ];

  @override
  void initState() {
    super.initState();
    fileManager = Provider.of<DatabaseService>(context, listen: false);
    _loadSymptoms();
  }

  Future<void> _loadSymptoms() async {
    // 1. Cargamos la lista base
    List<String> combinedList = List.from(defaultSymptomOptions);
    
    // 2. Traemos todos los síntomas creados por la comunidad en Firebase
    final globalSymptoms = await fileManager.getGlobalSymptoms();
    
    // 3. Unimos ambas listas y evitamos duplicados
    for (String symp in globalSymptoms) {
      if (!combinedList.contains(symp)) {
        combinedList.add(symp);
      }
    }
    
    // 4. Ordenamos alfabéticamente para facilidad de lectura
    combinedList.sort((a, b) => a.compareTo(b));

    if (mounted) {
      setState(() {
        symptomOptions = combinedList;
      });
    }
  }

  Future<void> _saveSymptom(String newSymptom) async {
    final newSympTrim = newSymptom.trim();
    if (newSympTrim.isEmpty) return;
    
    // 1. Validar localmente ignorando mayúsculas/minúsculas
    bool existsLocally = symptomOptions.any((sym) => sym.toUpperCase() == newSympTrim.toUpperCase());
    if (existsLocally) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ese síntoma ya está en tu lista.')),
        );
      }
      return;
    }
    
    // 2. Guardar en la nube para todos los dispositivos
    String result = await fileManager.saveGlobalSymptom(newSympTrim);
    
    if (mounted) {
      if (result == 'success') {
        await _loadSymptoms(); // Recargar la lista completa desde Firebase
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Síntoma "$newSympTrim" añadido globalmente')),
        );
      } else if (result == 'duplicate') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Este síntoma ya fue añadido por otro usuario.')),
        );
      } else {
        // Hubo un error de Firebase (probablemente Reglas de Seguridad)
        _showAlertDialog(
          'Error de Sincronización', 
          'No se pudo conectar a "sintomas_globales" en Firebase. Verifica tus reglas de seguridad en la consola web.\n\nDetalle: $result'
        );
      }
    }
  }

  @override
  void dispose() {
    _utController.dispose();
    _symptomController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();

    final String ut = _utController.text;
    final String symptom = _symptomController.text;
    final String description = _descriptionController.text;

    if (ut.isEmpty || symptom.isEmpty || description.isEmpty) {
      _showAlertDialog('Error', 'Todos los campos son obligatorios.');
      return;
    }

    final bool isValidPrefix = validPrefixes.any((prefix) => ut.startsWith(prefix));
    if (!isValidPrefix) {
      _showAlertDialog('Prefijo de planta inválido',
          'El campo UT debe comenzar con uno de los prefijos siguientes: ${validPrefixes.join(", ")}');
      return;
    }

    bool success = await fileManager.saveDataToFile(
      _currentDate,
      ut,
      symptom, // Pasando sintoma donde esperaba el point
      description,
      _selectedPriority,
      'Abierto',
    );

    if (success) {
      _showSnackBar('¡Registro guardado exitosamente!');
      // Limpiar formulario excepto fecha
      _utController.clear();
      _symptomController.clear();
      _descriptionController.clear();
      setState(() { _selectedPriority = 'Medio'; });
    } else {
      _showAlertDialog('Error', 'No se pudo guardar el registro.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
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
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showSymptomDialog() {
    final TextEditingController newSymptomController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Seleccione o agregue Síntoma'),
              contentPadding: const EdgeInsets.only(top: 16.0),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Buscador / Añadir nuevo
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: newSymptomController,
                              decoration: const InputDecoration(
                                hintText: 'Nuevo síntoma...',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              final txt = newSymptomController.text.trim();
                              if (txt.isNotEmpty) {
                                _saveSymptom(txt).then((_) {
                                  // Recargar dialogo
                                  setDialogState((){});
                                  newSymptomController.clear();
                                });
                              }
                            },
                            tooltip: "Añadir a lista permanente",
                          )
                        ],
                      ),
                    ),
                    const Divider(),
                    // Lista existente
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: symptomOptions.length,
                        itemBuilder: (context, index) {
                          final option = symptomOptions[index];
                          return ListTile(
                            title: Text(option),
                            onTap: () {
                              _symptomController.text = option;
                              Navigator.of(context).pop();
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
                  child: const Text('Cancelar'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [

          const Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold)),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              _currentDate,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 16),

          const Text('UT', style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(
            controller: _utController,
            decoration: const InputDecoration(
              hintText: 'Ingrese UT',
              border: OutlineInputBorder(),
            ),
            onChanged: (text) {
              _utController.value = _utController.value.copyWith(
                text: text.toUpperCase(),
                selection: TextSelection.collapsed(offset: text.length),
              );
            },
          ),
          const SizedBox(height: 16),

          // CORREGIDO OVERFLOW AQUÍ: Ajuste de flex para la fila Punto/Prioridad
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3, // Más espacio al punto
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Síntoma', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextField(
                      controller: _symptomController,
                      decoration: const InputDecoration(
                        hintText: 'Seleccione síntoma',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                      readOnly: true,
                      onTap: _showSymptomDialog,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8), // Reducido espaciado central
              Expanded(
                flex: 2, // Menos espacio a prioridad
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Prioridad', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField<String>(
                      value: _selectedPriority,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 16), // Padding interno reducido
                      ),
                      isExpanded: true, // Esto ayuda a evitar overflow interno en el dropdown
                      items: _priorities.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedPriority = newValue!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Text('Descripción',
              style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              hintText: 'Ingrese descripción',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 24),

          // CORREGIDO OVERFLOW AQUÍ: Uso de Wrap para los botones inferiores
          Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              ElevatedButton(
                onPressed: _handleSave,
                child: const Text('Guardar'),
              ),
              ElevatedButton(
                onPressed: () {
                  _utController.clear();
                  _symptomController.clear();
                  _descriptionController.clear();
                  setState(() { _selectedPriority = 'Medio'; });
                },
                child: const Text('Limpiar'),
              ),
            ],
          )
        ],
      ),
    );
  }
}