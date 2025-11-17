// lib/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // (signInWithEmail no cambia)
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print("Error al iniciar sesión: ${e.message}");
      return null;
    }
  }

  // (registerWithEmail no cambia)
  Future<UserCredential?> registerWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print("Error al registrar: ${e.message}");
      return null;
    } catch (e) {
      print("Error al crear documento de usuario: $e");
      return null;
    }
  }

  // (signOut no cambia)
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // (authStateChanges no cambia)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // --- FUNCIÓN AÑADIDA ---
  Future<String> sendPasswordResetEmail(String email) async {
    try {
      // Le dice a Firebase que envíe el correo de restablecimiento
      await _auth.sendPasswordResetEmail(email: email);
      return "success"; // Devolvemos un string de éxito
    } on FirebaseAuthException catch (e) {
      // Manejamos errores comunes
      if (e.code == 'user-not-found') {
        return "No se encontró ningún usuario con ese correo.";
      }
      return "Error: ${e.message}"; // Otro error
    } catch (e) {
      return "Ocurrió un error inesperado.";
    }
  }
// --- FIN DE LA FUNCIÓN AÑADIDA ---
}