import 'package:flutter/material.dart';
// 1. IMPORTA el file_manager
import 'file_manager.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  // 2. CREA UNA INSTANCIA de FileManager
  final FileManager fileManager = FileManager();

  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _plantController = TextEditingController();
  final TextEditingController _utController = TextEditingController();

  // La lista de resultados AHORA SÍ CAMBIARÁ
  List<String> _results = [];

  // Lista de prefijos para el filtro de Planta
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

  // 3. LÓGICA DE BÚSQUEDA (AHORA COMPLETA)
  Future<void> _performSearch() async {
    // Ocultar el teclado
    FocusScope.of(context).unfocus();

    // Llama al fileManager con los valores de los campos
    final searchResults = await fileManager.searchInFile(
      _startDateController.text,
      _endDateController.text,
      _utController.text,
      _plantController.text,
    );

    // Actualiza la UI con los resultados
    setState(() {
      _results = searchResults;
    });
  }

  // 4. LÓGICA PARA MOSTRAR EL SELECTOR DE FECHA
  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // Fecha inicial
      firstDate: DateTime(2020), // Límite inferior
      lastDate: DateTime(2101),  // Límite superior
    );

    if (picked != null) {
      // Formatea la fecha como DD/MM/YYYY y la pone en el campo
      controller.text = "${picked.day}/${picked.month}/${picked.year}";
    }
  }

  // 5. LÓGICA PARA MOSTRAR EL SELECTOR DE PLANTA
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
                // Opción para limpiar el filtro
                ListTile(
                  title: const Text('TODAS (limpiar filtro)'),
                  onTap: () {
                    _plantController.clear();
                    Navigator.of(context).pop();
                  },
                ),
                // Lista de plantas
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- FILTROS DE BÚSQUEDA ---
            Row(
              children: [
                // 6. CAMPO FECHA DE INICIO (MODIFICADO)
                Expanded(
                  child: TextField(
                    controller: _startDateController,
                    decoration: const InputDecoration(
                      labelText: 'Fecha de inicio',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.date_range),
                    ),
                    readOnly: true, // No se puede escribir
                    onTap: () => _selectDate(context, _startDateController), // Llama al selector
                  ),
                ),
                const SizedBox(width: 16),
                // 7. CAMPO FECHA DE FIN (MODIFICADO)
                Expanded(
                  child: TextField(
                    controller: _endDateController,
                    decoration: const InputDecoration(
                      labelText: 'Fecha de fin',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.date_range),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context, _endDateController), // Llama al selector
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // 8. CAMPO PLANTA (MODIFICADO)
                Expanded(
                  child: TextField(
                    controller: _plantController,
                    decoration: const InputDecoration(
                      labelText: 'Planta',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    readOnly: true, // No se puede escribir
                    onTap: _showPlantDialog, // Llama al selector
                  ),
                ),
                const SizedBox(width: 16),
                // Campo UT (sin cambios)
                Expanded(
                  child: TextField(
                    controller: _utController,
                    decoration: const InputDecoration(
                      labelText: 'UT',
                      border: OutlineInputBorder(),
                    ),
                    // Convierte a mayúsculas
                    onChanged: (text) {
                      _utController.value = _utController.value.copyWith(
                        text: text.toUpperCase(),
                        selection: TextSelection.collapsed(offset: text.length),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- BOTÓN DE BÚSQUEDA (CONECTADO) ---
            ElevatedButton(
              onPressed: _performSearch, // Llama a la lógica de búsqueda
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Buscar'),
            ),
            const SizedBox(height: 16),

            // --- ÁREA DE RESULTADOS (SIN CAMBIOS) ---
            const Text('Resultados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(),

            // 9. LÓGICA DE VISUALIZACIÓN DE RESULTADOS
            if (_results.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No hay resultados para mostrar.'),
                ),
              )
            else
            // Muestra los resultados en una lista
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(_results[index]), // Muestra la línea del archivo
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