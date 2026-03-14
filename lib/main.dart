import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'auth_gate.dart';
import 'auth_service.dart';
import 'providers/auth_provider.dart';
import 'services/database_service.dart';
import 'theme/app_theme.dart';

import 'register_screen.dart';
import 'report_screen.dart';
import 'equipos_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        Provider<DatabaseService>(create: (_) => DatabaseService()),
      ],
      child: MaterialApp(
        title: 'Report CND',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthGate(),
      ),
    ),
  );
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
        // Colores omitidos para usar el app_theme.dart
        // --- AÑADIMOS UN BOTÓN DE "CERRAR SESIÓN" ---
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).signOut();
            },
          )
        ],
        // --- FIN DEL CAMBIO ---
        bottom: const TabBar(
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