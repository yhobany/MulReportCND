# Plan de Implementación: Bugs Críticos de Autenticación

Diagnóstico y plan para resolver los 2 bugs reportados en la fase de testeo de autenticación, e iniciar la nueva rama de trabajo.

---

## Diagnóstico

### Bug 1: Los nuevos usuarios NO llegan a Firebase ni reciben confirmación

**Causa raíz encontrada en `lib/providers/auth_provider.dart`:**

El flujo actual hace `createUserWithEmailAndPassword()` en Firebase Auth y luego, si la cuenta se crea, intenta escribir el documento en Firestore. Esto tiene **2 problemas críticos:**

1. **Inmediatamente tras crear la cuenta en Auth, el estado `authStateChanges` se dispara** (línea 11-15 del `auth_provider.dart`), lo que hace que `AuthGate` detecte al usuario como autenticado y muestre la pantalla `PendingApprovalScreen` **antes de que el documento en Firestore termine de escribirse**. Esta condición de carrera puede causar que si la escritura en Firestore falla, el usuario quede en un estado inconsistente.
2. **Las reglas en `firestore.rules` solo existen en el archivo local** — nunca fueron desplegadas a la consola de Firebase, por lo que los permisos reales de la colección `users` en la nube pueden estar rechazando la escritura silenciosamente.
3. **No existe ningún mensaje de confirmación** en la pantalla de registro cuando el proceso termina exitosamente.

### Bug 2: Recuperación de contraseña sin validar registro previo

**Causa raíz encontrada en `lib/login_screen.dart` línea 76:**

La función `_handlePasswordReset` llama directamente a `_authService.sendPasswordResetEmail(email)` **sin verificar primero si ese correo electrónico existe en la colección `users` de Firestore**. Firebase Auth envía el correo de recuperación a cualquier dirección que exista en su base de datos de autenticación, independientemente de si ese usuario completó el registro completo o fue aprobado.

### Punto 4: Nueva rama de trabajo

El usuario solicita que todos los nuevos cambios se realicen en una nueva rama Git.

---

## User Review Required

> [!IMPORTANT]
> Las reglas de Firestore (`firestore.rules`) deben desplegarse manualmente en la consola web de Firebase (`Firestore Database → Rules`). El archivo local solo es una referencia. Sin este paso, los nuevos usuarios no podrán escribir su documento `pending` en la colección `users`.

> [!WARNING]
> El Bug 1 también puede tener componente de **reglas de Firestore en producción**. Deberás confirmar en tu consola de Firebase si la colección `users` tiene reglas que permitan escritura a nuevos usuarios autenticados.

---

## Open Questions

> [!IMPORTANT]
> **¿Qué comportamiento deseas cuando un usuario se registra y su documento en Firestore falla?**
> - Opción A: Mostrar error y permitir que reintenten (más seguro).
> - Opción B: Mantener la cuenta en Firebase Auth pero informar el error (flujo actual pero con mensaje).

---

## Proposed Changes

### Nueva Rama Git

Se creará la rama `fix/auth-registration-and-reset` antes de iniciar cualquier cambio.

---

### Componente 1: Flujo de Registro

#### [MODIFY] [auth_provider.dart](file:///C:/Users/angel/report_cnd/lib/providers/auth_provider.dart)
- Refactorizar `createUserWithEmailAndPassword` para que retorne un resultado explícito (éxito/error) en lugar de lanzar excepciones silenciosas.
- Separar la creación en Auth y la escritura en Firestore con manejo de errores granular para detectar si la escritura en Firestore falla específicamente.

#### [MODIFY] [login_screen.dart](file:///C:/Users/angel/report_cnd/lib/login_screen.dart)
- En el modo `AuthMode.register`, después del registro exitoso, mostrar un **mensaje de confirmación claro y visible** al usuario (ej: *"¡Registro enviado! Tu cuenta está pendiente de aprobación por el administrador. Serás notificado."*) antes de hacer `signOut()` automáticamente para que el usuario no entre en un estado de espera indefinido.
- Agregar un `signOut()` inmediato post-registro para que el usuario regrese a la pantalla de login con el mensaje de confirmación, en lugar de quedar atrapado en `PendingApprovalScreen`.

---

### Componente 2: Validación en Recuperación de Contraseña

#### [MODIFY] [auth_service.dart](file:///C:/Users/angel/report_cnd/lib/auth_service.dart)
- Agregar nueva función `checkUserExistsInFirestore(String email)` que consulte la colección `users` en Firestore buscando el documento por el campo `email`.

#### [MODIFY] [login_screen.dart](file:///C:/Users/angel/report_cnd/lib/login_screen.dart)
- Antes de llamar a `sendPasswordResetEmail`, ejecutar `checkUserExistsInFirestore(email)`.
- Si el usuario **no existe en Firestore**: mostrar mensaje de error *"No se encontró ninguna cuenta registrada con este correo electrónico."* y no enviar el correo.
- Si el usuario **existe en Firestore**: proceder normalmente con el envío del enlace de recuperación.

---

### Componente 3: Reglas de Firestore

#### [MODIFY] [firestore.rules](file:///C:/Users/angel/report_cnd/firestore.rules)
- Revisar y ajustar para incluir explícitamente que usuarios en proceso de registro (`request.auth != null`) puedan escribir su propio documento.
- Proporcionar las reglas exactas para copiar y pegar en la consola web de Firebase.

---

## Verification Plan

### Automated Tests
- `flutter analyze` — verificar 0 errores de compilación.

### Manual Verification
1. **Registro:** Crear una cuenta nueva → confirmar que aparece el mensaje de confirmación → confirmar que el documento `pending` aparece en `Firestore → users` en la consola de Firebase.
2. **Recuperación sin cuenta:** Ingresar un correo que NO existe en Firestore → confirmar que el sistema muestra error en lugar de enviar el correo.
3. **Recuperación con cuenta:** Ingresar un correo que SÍ existe y está en estado `pending` → confirmar que recibe el correo de recuperación.
