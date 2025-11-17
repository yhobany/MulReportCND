// lib/login_screen.dart

import 'package:flutter/material.dart';
import 'auth_service.dart';

// 1. DEFINIMOS LOS TRES ESTADOS POSIBLES
enum AuthMode { login, register, passwordReset }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 2. USAMOS EL NUEVO 'enum' PARA EL ESTADO
  AuthMode _authMode = AuthMode.login;
  String? _errorMessage;
  String? _successMessage;

  // Función para limpiar mensajes y cambiar el estado
  void _setAuthMode(AuthMode newMode) {
    setState(() {
      _authMode = newMode;
      _errorMessage = null;
      _successMessage = null;
      // Limpiamos la contraseña si volvemos a "Reset"
      if (newMode == AuthMode.passwordReset) {
        _passwordController.clear();
      }
    });
  }

  // Función unificada para Login y Registro
  Future<void> _handleSubmit() async {
    setState(() { _errorMessage = null; _successMessage = null; });

    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() { _errorMessage = "Email y contraseña no pueden estar vacíos."; });
      return;
    }

    if (_authMode == AuthMode.login) {
      // Estamos en modo Login
      final result = await _authService.signInWithEmail(email, password);
      if (result == null) {
        setState(() { _errorMessage = "Error al iniciar sesión. Verifica tus datos."; });
      }
    } else {
      // Estamos en modo Registro
      final result = await _authService.registerWithEmail(email, password);
      if (result == null) {
        setState(() { _errorMessage = "Error al registrar. El email ya podría estar en uso."; });
      }
    }
  }

  Future<void> _handlePasswordReset() async {
    setState(() { _errorMessage = null; _successMessage = null; });

    final email = _emailController.text;
    if (email.isEmpty) {
      setState(() { _errorMessage = "Por favor, ingresa tu correo en el campo de arriba para restablecer la contraseña."; });
      return;
    }

    final result = await _authService.sendPasswordResetEmail(email);

    if (result == "success") {
      setState(() {
        _successMessage = "Se ha enviado un correo a $email. Revisa tu bandeja de entrada (y spam).";
      });
    } else {
      setState(() { _errorMessage = result; });
    }
  }

  // 3. FUNCIÓN PARA OBTENER EL TÍTULO CORRECTO
  String _getTitle() {
    switch (_authMode) {
      case AuthMode.login:
        return 'Iniciar Sesión';
      case AuthMode.register:
        return 'Registrar Usuario';
      case AuthMode.passwordReset:
        return 'Restablecer Contraseña';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()), // Título dinámico
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- CAMPO EMAIL (Siempre visible) ---
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // --- 4. CAMPO CONTRASEÑA (Ahora es condicional) ---
              // Solo se muestra si NO estamos en modo 'passwordReset'
              if (_authMode != AuthMode.passwordReset)
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
              const SizedBox(height: 24),

              // --- MOSTRAR ERROR (si existe) ---
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),

              // --- MOSTRAR ÉXITO (si existe) ---
              if (_successMessage != null)
                Text(
                  _successMessage!,
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 16),

              // --- 5. BOTÓN PRINCIPAL (AHORA DINÁMICO) ---
              ElevatedButton(
                // La acción del botón depende del modo
                onPressed: _authMode == AuthMode.passwordReset
                    ? _handlePasswordReset
                    : _handleSubmit,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    // Color dinámico (verde para login/registro, azul para reset)
                    backgroundColor: _authMode == AuthMode.passwordReset
                        ? Colors.blue[700]
                        : Colors.green[700],
                    foregroundColor: Colors.white
                ),
                // Texto dinámico
                child: Text(
                    _authMode == AuthMode.login ? 'Iniciar Sesión' :
                    _authMode == AuthMode.register ? 'Registrar' :
                    'Enviar correo de restablecimiento'
                ),
              ),
              const SizedBox(height: 16),

              // --- 6. BOTONES SECUNDARIOS (AHORA DINÁMICOS) ---
              if (_authMode == AuthMode.login)
              // Si estamos en Login, mostramos "Registrarse" y "Olvidé"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => _setAuthMode(AuthMode.register),
                      child: const Text('¿No tienes cuenta? Regístrate'),
                    ),
                    TextButton(
                      onPressed: () => _setAuthMode(AuthMode.passwordReset),
                      child: const Text('¿Olvidaste tu contraseña?'),
                    ),
                  ],
                )
              else
              // Si estamos en Registro o Reset, solo mostramos "Volver a Login"
                TextButton(
                  onPressed: () => _setAuthMode(AuthMode.login),
                  child: const Text('¿Ya tienes cuenta? Inicia sesión'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}