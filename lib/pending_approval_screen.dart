// lib/pending_approval_screen.dart

import 'package:flutter/material.dart';
import 'auth_service.dart'; // Importamos el servicio para poder cerrar sesión

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuenta Pendiente'),
        backgroundColor: Colors.orange[800], // Un color de advertencia
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hourglass_empty,
                size: 80,
                color: Colors.orange[800],
              ),
              const SizedBox(height: 24),
              const Text(
                'Gracias por registrarte',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Tu cuenta ha sido creada, pero está pendiente de aprobación por un administrador. Serás notificado cuando tu acceso sea concedido.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Al presionar, cerramos la sesión del usuario
                  // para que vuelva a la pantalla de Login.
                  AuthService().signOut();
                },
                child: const Text('Volver al Inicio de Sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}