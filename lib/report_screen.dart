import 'package:flutter/material.dart';
// --- CAMBIOS DE IMPORTACIÓN ---
import 'file_manager_locator.dart'; // Importamos el "selector"
import 'file_manager_interface.dart'; // Importamos la interfaz
// --- FIN DE CAMBIOS ---

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  // --- CAMBIO DE INICIALIZACIÓN ---
  final FileManagerInterface fileManager = getFileManager();
  // --- FIN DEL CAMBIO ---

  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _plantController = TextEditingController();
  final TextEditingController _utController = TextEditingController();

  List<String> _results = [];

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

  // (El resto del archivo, _performSearch, build, etc., no cambia en absoluto)
  // ...

  Future<void> _performSearch() async {
    FocusScope.of(context).unfocus();

    final searchResults = await fileManager.searchInFile(
      _startDateController.text,
      _endDateController.text,
      _utController.text,
      _plantController.text,
    );

    setState(() {
      _results = searchResults;
    });
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _startDateController,
                    decoration: const InputDecoration(
                      labelText: 'Fecha de inicio',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.date_range),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context, _startDateController),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _endDateController,
                    decoration: const InputDecoration(
                      labelText: 'Fecha de fin',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.date_range),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context, _endDateController),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _plantController,
                    decoration: const InputDecoration(
                      labelText: 'Planta',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    readOnly: true,
                    onTap: _showPlantDialog,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _utController,
                    decoration: const InputDecoration(
                      labelText: 'UT',
                      border: OutlineInputBorder(),
                    ),
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

            ElevatedButton(
              onPressed: _performSearch,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Buscar'),
            ),
            const SizedBox(height: 16),

            const Text('Resultados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(),

            if (_results.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No hay resultados para mostrar.'),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(_results[index]),
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