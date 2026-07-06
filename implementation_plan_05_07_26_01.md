# Plan de Corrección: Registro de Usuario y Recuperación de Contraseña

Este plan aborda dos problemas identificados en el flujo de autenticación:
1. **Fallo en el Registro (Creación de Cuenta):** Al registrar una cuenta mediante `AuthProvider`, no se está creando el documento correspondiente en la colección `users` de Cloud Firestore. Esto hace que `AuthGate` redirija al usuario al Login en un bucle infinito, sin mostrar la pantalla de aprobación pendiente.
2. **Mensaje de Éxito en Recuperación:** El texto `"Se ha enviado un correo a \$email."` escapa el símbolo `$`, mostrando literalmente la palabra `$email` en lugar de la dirección de correo ingresada.

## Cambios Propuestos

### Componente de Autenticación y Proveedor de Estado

#### [MODIFY] [auth_provider.dart](file:///C:/Users/angel/report_cnd/lib/providers/auth_provider.dart)
* Importar `cloud_firestore` para crear el documento de usuario al registrarse.
* Actualizar el método `createUserWithEmailAndPassword` para guardar la información del usuario en Firestore con `status: 'pending'` y la fecha de creación, igual que hacía el método original de `AuthService`.

```dart
  Future<void> createUserWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      // Crear el documento del usuario en Firestore para que AuthGate lo reconozca
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      rethrow;
    }
  }
```

---

### Componente de Interfaz de Usuario

#### [MODIFY] [login_screen.dart](file:///C:/Users/angel/report_cnd/lib/login_screen.dart)
* Corregir el string de éxito en `_handlePasswordReset` quitando el escape en el símbolo `$` (`"Se ha enviado un correo a $email."`).

## Plan de Verificación

### Verificación Manual
1. Intentar registrar una cuenta nueva desde la pantalla de registro y comprobar que redirija a la pantalla de "Cuenta Pendiente de Aprobación" (`PendingApprovalScreen`).
2. Verificar en la consola de Firebase Firestore que el documento de usuario se haya creado correctamente en la colección `users` con el estado `pending`.
3. Probar la recuperación de contraseña y confirmar que el mensaje de éxito muestre correctamente la dirección de correo ingresada en lugar del texto literal `$email`.
