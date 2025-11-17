// lib/auth_gate.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// 1. IMPORTACIONES NECESARIAS
import 'package:cloud_firestore/cloud_firestore.dart'; // Para leer la base de datos
import 'login_screen.dart'; // Pantalla de Login
import 'main.dart'; // App principal (MainScreen)
import 'pending_approval_screen.dart'; // La nueva pantalla de "pendiente"

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // --- REVISIÓN 1: ¿EL USUARIO INICIÓ SESIÓN? ---
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {

        // Si está esperando la conexión de Auth, muestra un cargador
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
        }

        // Si NO tiene datos de Auth, el usuario no ha iniciado sesión
        if (!authSnapshot.hasData) {
          // Muestra la pantalla de Login
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: LoginScreen(),
          );
        }

        // --- REVISIÓN 2: SI INICIÓ SESIÓN, ¿CUÁL ES SU ESTADO? ---
        // Si llegamos aquí, 'authSnapshot.hasData' es true.
        // Ahora revisamos su documento en la colección 'users'.
        return StreamBuilder<DocumentSnapshot>(
          // Escuchamos los cambios en el documento del usuario actual
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(authSnapshot.data!.uid) // Usamos el UID del usuario logueado
              .snapshots(),
          builder: (context, userSnapshot) {

            // Si está esperando la lectura de la base de datos, muestra un cargador
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
            }

            // Si el documento del usuario NO existe (esto no debería pasar si el registro funcionó)
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              // (Podríamos mostrar un error, pero por ahora lo mandamos a Login)
              return const MaterialApp(
                debugShowCheckedModeBanner: false,
                home: LoginScreen(),
              );
            }

            // ¡Tenemos los datos del usuario! Leemos su estado.
            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            final String status = userData['status'] ?? 'pending';

            // --- LA DECISIÓN FINAL ---
            if (status == 'approved' || status == 'admin') {
              // 1. APROBADO: Muestra la app principal
              return const MaterialApp(
                debugShowCheckedModeBanner: false,
                home: DefaultTabController(
                  length: 3,
                  child: MainScreen(),
                ),
              );
            } else {
              // 2. PENDIENTE (o cualquier otro estado): Muestra la pantalla de espera
              return const MaterialApp(
                debugShowCheckedModeBanner: false,
                home: PendingApprovalScreen(),
              );
            }
          },
        );
      },
    );
  }
}