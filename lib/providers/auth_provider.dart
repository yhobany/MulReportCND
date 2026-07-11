import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _isLoading = true;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      _isLoading = false;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isLoading => _isLoading;

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createUserWithEmailAndPassword(String email, String password) async {
    UserCredential? userCredential;
    try {
      userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      // Solo se ejecuta si la cuenta nueva se creó exitosamente en Firebase Auth.
      // Los usuarios existentes nunca llegarán aquí, preservando su información intacta.
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      // Si la cuenta se creó en Auth pero falló el registro en la base de datos (Firestore),
      // eliminamos el usuario en Auth para evitar cuentas huérfanas e inconsistencias.
      if (userCredential != null && userCredential.user != null) {
        try {
          await userCredential.user!.delete();
        } catch (deleteError) {
          // Ignorar error de eliminación
        }
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
