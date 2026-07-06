# Resumen de Cambios: Flujo de Registro, Recuperación de Contraseña y Selección de Imágenes

Se han aplicado las correcciones necesarias en autenticación y en la extracción del nombre original de los archivos `.jpg` al seleccionar imágenes en la pestaña de Equipos.

## Cambios Realizados

### 1. Creación de Documento en Firestore para Nuevos Usuarios
#### [MODIFY] [auth_provider.dart](file:///C:/Users/angel/report_cnd/lib/providers/auth_provider.dart)
* Se importó el paquete `package:cloud_firestore/cloud_firestore.dart`.
* Se modificó el método `createUserWithEmailAndPassword`: al crear una nueva cuenta en Firebase Auth, ahora se genera automáticamente su documento en la colección `users` de Cloud Firestore con la estructura:
  ```json
  {
    "uid": "<id_usuario>",
    "email": "correo@ejemplo.com",
    "status": "pending",
    "createdAt": "<Timestamp>"
  }
  ```
* **Garantía para usuarios existentes:** Como este código sólo se ejecuta dentro del método de creación de cuenta (`createUserWithEmailAndPassword`), los usuarios ya registrados (que usan `signInWithEmailAndPassword`) nunca ejecutan esta parte del código. Por tanto, su información, rol (`admin`, `approved`, etc.) y registros permanecen totalmente inalterados.

---

### 2. Corrección en Mensaje de Recuperación de Contraseña
#### [MODIFY] [login_screen.dart](file:///C:/Users/angel/report_cnd/lib/login_screen.dart)
* Se corrigió la interpolación en el mensaje de éxito del método `_handlePasswordReset`.
* Antes: `"Se ha enviado un correo a \$email."` (mostraba el texto literal `$email`).
* Ahora: `"Se ha enviado un correo a $email."` (muestra la dirección de correo ingresada por el usuario).

---

### 3. Preservación del Nombre Original del Archivo (.jpg) en Equipos
#### [MODIFY] [equipos_screen.dart](file:///C:/Users/angel/report_cnd/lib/equipos_screen.dart#L295-L300)
* Se eliminó el parámetro `imageQuality: 80` en la llamada a `_picker.pickImage` dentro de la función `_handleCamera`.
* **Motivo:** Al solicitar compresión o calidad reducida, el plugin creaba una copia temporal re-codificada en la caché con un nombre aleatorio generado por el sistema (ej. `scaled_image_picker_...jpg`). Al quitar este parámetro, se accede directamente a la referencia original del archivo en el dispositivo, asegurando que `photo.name` extraiga el nombre exacto de la imagen (ej. `PFM6-001.JPG`).

---

## Resultados de Verificación
* **Análisis de Código (`flutter analyze`):** No se encontraron errores de sintaxis ni de compilación en los archivos modificados (`auth_provider.dart`, `login_screen.dart` y `equipos_screen.dart`).
