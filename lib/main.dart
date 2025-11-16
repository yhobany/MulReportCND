import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

// --- 1. IMPORTA EL ARCHIVO GENERADO ---
import 'firebase_options.dart';

// (Importaciones de las pantallas)
import 'register_screen.dart';
import 'report_screen.dart';
import 'equipos_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- 2. USA LAS OPCIONES DEL ARCHIVO ---
  // Le decimos a Firebase que se inicialice usando las "llaves"
  // que 'flutterfire configure' acaba de crear.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
      body: TabBarView(
        children: [
          RegisterScreen(),
          ReportScreen(),
          EquiposScreen(),
        ],
      ),
    );
  }
}