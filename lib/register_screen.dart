import 'package:flutter/material.dart';
// --- CAMBIOS DE IMPORTACIÓN ---
import 'file_manager_locator.dart'; // Importamos el "selector"
import 'file_manager_interface.dart'; // Importamos la interfaz
import 'equipment_record.dart'; // (Ya no se necesita aquí, pero lo dejamos por si acaso)
// --- FIN DE CAMBIOS ---

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // --- CAMBIO DE INICIALIZACIÓN ---
  // Ahora le pedimos al "selector" que nos dé la implementación correcta
  final FileManagerInterface fileManager = getFileManager();
  // --- FIN DEL CAMBIO ---

  final TextEditingController _utController = TextEditingController();
  final TextEditingController _pointController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final String _currentDate =
      "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";

  final List<String> validPrefixes = [
    "PFM6", "PFM4", "PCM1", "PCM3", "PP30", "PP40",
    "PP50", "PP90", "PP95", "PP20", "PR"
  ];

  final List<String> pointOptions = [
    "Vib/soporte", "Vib/reductor", "Roce",
    "Holgura", "Golpeteo", "Ruido/bandas",
    "Alta/temp", "Vib/estructural",
    "Soltura/sop", "Ruido/acop",
    "Engranamiento", "Falta/lub", "NA - None"
  ];

  @override
  void dispose() {
    _utController.dispose();
    _pointController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // (El resto del archivo, _handleSave, build, etc., no cambia en absoluto)
  // ...
  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();

    final String ut = _utController.text;
    final String point = _pointController.text;
    final String description = _descriptionController.text;

    if (ut.isEmpty || point.isEmpty) {
      _showAlertDialog('Error', 'Los campos UT y Punto no pueden estar vacíos.');
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
      point,
      description,
    );

    if (success) {
      _showSnackBar('¡Registro guardado exitosamente!');
      _utController.clear();
      _pointController.clear();
      _descriptionController.clear();
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

  void _showPointDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccione el punto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: pointOptions.map((option) {
                return ListTile(
                  title: Text(option),
                  onTap: () {
                    _pointController.text = option;
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
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

          const Text('Punto', style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(
            controller: _pointController,
            decoration: const InputDecoration(
              hintText: 'Seleccione punto',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.arrow_drop_down),
            ),
            readOnly: true,
            onTap: _showPointDialog,
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

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
                child: const Text('Salir', style: TextStyle(color: Colors.white)),
              ),
              ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700]),
                child: const Text('Guardar', style: TextStyle(color: Colors.white)),
              ),
              ElevatedButton(
                onPressed: () {
                  _utController.clear();
                  _pointController.clear();
                  _descriptionController.clear();
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