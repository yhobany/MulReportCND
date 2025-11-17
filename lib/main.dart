import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth_gate.dart'; // <-- 1. IMPORTAMOS EL 'AuthGate'

// --- IMPORTACIÓN AÑADIDA QUE FALTABA ---
import 'auth_service.dart';
// --- FIN DE LA IMPORTACIÓN ---

// Importamos las pantallas que 'AuthGate' necesita conocer
import 'register_screen.dart';
import 'report_screen.dart';
import 'equipos_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- 2. CAMBIO CLAVE ---
  // Ya no usamos 'MyApp', ahora usamos 'AuthGate'
  runApp(const AuthGate());
  // --- FIN DEL CAMBIO ---
}

// --- 3. 'MyApp' YA NO SE USA, PERO 'MainScreen' SÍ ---
// (AuthGate necesita 'MainScreen', así que la dejamos aquí)

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report CND vFlutter'),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        // --- AÑADIMOS UN BOTÓN DE "CERRAR SESIÓN" ---
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              // Ahora 'AuthService' sí está definido
              AuthService().signOut();
            },
          )
        ],
        // --- FIN DEL CAMBIO ---
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