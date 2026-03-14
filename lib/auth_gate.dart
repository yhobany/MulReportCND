import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'providers/auth_provider.dart';
import 'login_screen.dart';
import 'main.dart';
import 'pending_approval_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (authProvider.user == null) {
          return const LoginScreen();
        }

        // Si el usuario está autenticado, escuchamos su documento de Firestore
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(authProvider.user!.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const LoginScreen();
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            final String status = userData['status'] ?? 'pending';

            if (status == 'approved' || status == 'admin') {
              return const DefaultTabController(
                length: 3,
                child: MainScreen(),
              );
            } else {
              return const PendingApprovalScreen();
            }
          },
        );
      },
    );
  }
}