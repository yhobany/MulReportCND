import 'package:flutter/material.dart';

// 1. IMPORTA las tres pantallas
import 'register_screen.dart';
import 'report_screen.dart';
import 'equipos_screen.dart'; // <-- NUEVA IMPORTACIÓN

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DefaultTabController(
        length: 3,
        child: MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report CND vFlutter'),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        bottom: const TabBar(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Register', icon: Icon(Icons.app_registration)),
            Tab(text: 'Report', icon: Icon(Icons.search)),
            Tab(text: 'Equipos', icon: Icon(Icons.camera_alt)),
          ],
        ),
      ),
      // --- CAMBIO AQUÍ: 'const' ELIMINADO ---
      body: TabBarView(
        children: [
          // Pantalla 1
          RegisterScreen(),

          // Pantalla 2
          ReportScreen(),

          // Pantalla 3
          EquiposScreen(),
        ],
      ),
    );
  }
}