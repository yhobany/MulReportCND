import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'auth_service.dart';
import 'theme/app_theme.dart';

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

  AuthMode _authMode = AuthMode.login;
  String? _errorMessage;
  String? _successMessage;

  void _setAuthMode(AuthMode newMode) {
    setState(() {
      _authMode = newMode;
      _errorMessage = null;
      _successMessage = null;
      if (newMode == AuthMode.passwordReset) {
        _passwordController.clear();
      }
    });
  }

  Future<void> _handleSubmit() async {
    setState(() { _errorMessage = null; _successMessage = null; });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() { _errorMessage = "Email y contraseña son obligatorios."; });
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      if (_authMode == AuthMode.login) {
        await authProvider.signInWithEmailAndPassword(email, password);
      } else {
        await authProvider.createUserWithEmailAndPassword(email, password);
      }
    } catch (e) {
      setState(() {
         if (_authMode == AuthMode.login) {
            _errorMessage = "Credenciales inválidas. Verifica tus datos.";
         } else {
            _errorMessage = "Algo falló. Quizá el correo ya está registrado.";
         }
      });
    }
  }

  Future<void> _handlePasswordReset() async {
    setState(() { _errorMessage = null; _successMessage = null; });

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() { _errorMessage = "Ingresa tu correo para restablecer la contraseña."; });
      return;
    }

    final result = await _authService.sendPasswordResetEmail(email);

    if (result == "success") {
      setState(() {
        _successMessage = "Se ha enviado un correo a \$email.";
      });
    } else {
      setState(() { _errorMessage = result; });
    }
  }

  String _getTitle() {
    switch (_authMode) {
      case AuthMode.login: return 'Bienvenido de nuevo';
      case AuthMode.register: return 'Crear nueva cuenta';
      case AuthMode.passwordReset: return 'Recuperar acceso';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos los colores primarios del AppTheme
    final primaryColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      // Evitar appbar estricto para un look más moderno
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450), // Limitar ancho en tablets/web
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- HEADER VISUAL ---
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _authMode == AuthMode.login ? Icons.lock_person :
                      _authMode == AuthMode.register ? Icons.person_add :
                      Icons.mark_email_read,
                      size: 40,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _getTitle(),
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "MulReport CND Management",
                    style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 16),
                  ),
                  const SizedBox(height: 40),

                  // --- FORMULARIO EN TARJETA FLOTANTE ---
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        // Campo Email
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Correo Electrónico',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        
                        // Campo Contraseña (Condicional animado)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: _authMode == AuthMode.passwordReset ? 0 : 80,
                          curve: Curves.easeInOut,
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: Column(
                              children: [
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _passwordController,
                                  decoration: const InputDecoration(
                                    labelText: 'Contraseña',
                                    prefixIcon: Icon(Icons.lock_outline),
                                  ),
                                  obscureText: true,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Mensajes de Alerta
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade900, fontSize: 13))),
                              ],
                            ),
                          )
                        ],

                        if (_successMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 20),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_successMessage!, style: TextStyle(color: Colors.green.shade900, fontSize: 13))),
                              ],
                            ),
                          )
                        ],

                        const SizedBox(height: 24),

                        // Botón Principal
                        ElevatedButton(
                          onPressed: _authMode == AuthMode.passwordReset
                              ? _handlePasswordReset
                              : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 54),
                              shadowColor: primaryColor.withOpacity(0.4),
                              elevation: 4,
                          ),
                          child: Text(
                              _authMode == AuthMode.login ? 'Comenzar' :
                              _authMode == AuthMode.register ? 'Unirse Ahora' :
                              'Enviar Enlace'
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --- BOTONES SECUNDARIOS ---
                  if (_authMode == AuthMode.login)
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        TextButton(
                          onPressed: () => _setAuthMode(AuthMode.register),
                          child: const Text('Crear una cuenta nueva'),
                        ),
                        TextButton(
                          onPressed: () => _setAuthMode(AuthMode.passwordReset),
                          child: const Text('Recuperar contraseña'),
                        ),
                      ],
                    )
                  else
                    TextButton.icon(
                      onPressed: () => _setAuthMode(AuthMode.login),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Volver al inicio de sesión'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}