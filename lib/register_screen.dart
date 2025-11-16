import 'package:flutter/material.dart';
// 1. IMPORTA el file_manager que acabamos de modificar
import 'file_manager.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // 2. CREA UNA INSTANCIA de FileManager para usarla
  final FileManager fileManager = FileManager();

  final TextEditingController _utController = TextEditingController();
  final TextEditingController _pointController = TextEditingController(); // Este lo haremos 'readonly'
  final TextEditingController _descriptionController = TextEditingController();

  final String _currentDate =
      "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";

  // 3. (OPCIONAL PERO RECOMENDADO) Lista de prefijos válidos
  final List<String> validPrefixes = [
    "PFM6", "PFM4", "PCM1", "PCM3", "PP30", "PP40",
    "PP50", "PP90", "PP95", "PP20", "PR"
  ];

  // --- AÑADIDO: LISTA DE OPCIONES (copiada de tu app de Kotlin) ---
  final List<String> pointOptions = [
    "Vib/soporte", "Vib/reductor", "Roce",
    "Holgura", "Golpeteo", "Ruido/bandas",
    "Alta/temp", "Vib/estructural",
    "Soltura/sop", "Ruido/acop",
    "Engranamiento", "Falta/lub", "NA - None"
  ];
  // --- FIN DE LA LISTA ---

  @override
  void dispose() {
    _utController.dispose();
    _pointController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // 4. MUEVE LA LÓGICA DE GUARDADO a su propia función
  Future<void> _handleSave() async {
    // Ocultar el teclado
    FocusScope.of(context).unfocus();

    // Obtenemos los valores
    final String ut = _utController.text;
    final String point = _pointController.text;
    final String description = _descriptionController.text;

    // --- VALIDACIONES (Igual que en la app de Kotlin) ---

    // Validar campos vacíos
    if (ut.isEmpty || point.isEmpty) {
      _showAlertDialog('Error', 'Los campos UT y Punto no pueden estar vacíos.');
      return;
    }

    // Validar prefijo
    final bool isValidPrefix = validPrefixes.any((prefix) => ut.startsWith(prefix));
    if (!isValidPrefix) {
      _showAlertDialog('Prefijo de planta inválido',
          'El campo UT debe comenzar con uno de los prefijos siguientes: ${validPrefixes.join(", ")}');
      return;
    }

    // --- FIN VALIDACIONES ---

    // Si todo está bien, procedemos a guardar
    bool success = await fileManager.saveDataToFile(
      _currentDate,
      ut,
      point,
      description,
    );

    if (success) {
      // Mostramos un mensaje de éxito
      _showSnackBar('¡Registro guardado exitosamente!');
      _utController.clear();
      _pointController.clear();
      _descriptionController.clear();
    } else {
      // Mostramos un error
      _showAlertDialog('Error', 'No se pudo guardar el registro.');
    }
  }

  // Función de ayuda para mostrar un SnackBar (mensaje rápido)
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Función de ayuda para mostrar un Diálogo de Alerta (como en Kotlin)
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

  // --- AÑADIDO: FUNCIÓN PARA MOSTRAR EL DIÁLOGO DE SELECCIÓN ---
  void _showPointDialog() {
    // 'showDialog' es la función de Flutter para mostrar pop-ups
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccione el punto'),
          // Usamos un 'SingleChildScrollView' para que la lista
          // pueda "scrollear" si es muy larga.
          content: SingleChildScrollView(
            child: Column(
              // Usamos 'shrinkWrap' para que la columna
              // no ocupe más espacio del necesario
              mainAxisSize: MainAxisSize.min,
              children: pointOptions.map((option) {
                // Hacemos que cada opción sea 'tappable'
                return ListTile(
                  title: Text(option),
                  onTap: () {
                    // Al tocar una opción:
                    // 1. Actualizamos el texto del controlador
                    _pointController.text = option;
                    // 2. Cerramos el diálogo
                    Navigator.of(context).pop();
                  },
                );
              }).toList(), // Convertimos el 'map' en una lista de Widgets
            ),
          ),
          actions: [
            // Botón para cerrar el diálogo si no se selecciona nada
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
  // --- FIN DE LA FUNCIÓN DE DIÁLOGO ---


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // ... (Los campos de texto de Fecha y UT no cambian) ...

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

          // --- MODIFICADO: CAMPO PUNTO ---
          const Text('Punto', style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(
            controller: _pointController,
            decoration: const InputDecoration(
              hintText: 'Seleccione punto',
              border: OutlineInputBorder(),
              // Añadimos un ícono para indicar que es seleccionable
              suffixIcon: Icon(Icons.arrow_drop_down),
            ),
            readOnly: true,  // Hacemos que no se pueda escribir en él
            onTap: _showPointDialog, // Llamamos al diálogo al tocar
          ),
          // --- FIN DE LA MODIFICACIÓN ---

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
                  // (Lógica para salir - Aún no implementada)
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
                child: const Text('Salir', style: TextStyle(color: Colors.white)),
              ),

              // 5. CONECTA EL BOTÓN a la nueva función de guardado
              ElevatedButton(
                onPressed: _handleSave, // <-- CAMBIO AQUÍ
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