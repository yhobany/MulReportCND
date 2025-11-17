# Report CND vFlutter (con Backend de Firebase)

Esta es una aplicación multiplataforma (Android, iOS y Web) construida con Flutter para la gestión y el registro de reportes de mantenimiento industrial.

La aplicación utiliza **Firebase** como backend para consolidar todos los datos en la nube, requiriendo que los usuarios estén autenticados y aprobados por un administrador para acceder.

## Características Principales

### 1. Autenticación y Seguridad
* **Servicio:** Utiliza **Firebase Authentication**.
* **Flujo de Registro:** Los usuarios pueden crear una cuenta (Email/Contraseña).
* **Flujo de Aprobación:** Al registrarse, un nuevo documento de usuario se crea en la colección `users` con un `status: "pending"`. El `AuthGate` de la app bloquea a estos usuarios en una pantalla de "Cuenta Pendiente".
* **Acceso de Administrador:** Un administrador debe ir a la Consola de Firebase y cambiar manualmente el `status` a `"approved"` para conceder acceso al usuario.
* **Seguridad de Datos:** Las Reglas de Seguridad de Firestore (`firestore.rules`) garantizan que solo los usuarios con `status == "approved"` puedan leer o escribir en las bases de datos de `registros` y `equipos`.
* **Recuperación:** Incluye un flujo de "Olvidé mi contraseña" que utiliza el servicio de Firebase para enviar un correo de restablecimiento.

### 2. Módulos de la App (Base de Datos Firestore)
La aplicación utiliza **Cloud Firestore** para almacenar datos en tiempo real.

* **Register (Registro):**
    * Guarda nuevos hallazgos en la colección `registros`.
    * Guarda la fecha como un `Timestamp` (para búsquedas) y un `date_string` (para mostrar).
* **Report (Reporte):**
    * Consulta la colección `registros` de Firestore.
    * Filtra los datos *directamente en la nube* usando consultas de `Timestamp` para los rangos de fecha y consultas `where` para la planta.
* **Equipos:**
    * Guarda nuevos equipos en la colección `equipos`.
    * Permite la selección múltiple y la eliminación de documentos directamente desde Firestore.
    * Permite la exportación de registros filtrados por la fecha actual.

### 3. Manejo de Imágenes (Opción A)
* **Optimización:** Utiliza `image_picker` con compresión (`imageQuality: 80`, `maxWidth: 1024`) para reducir el tamaño de las fotos en móvil y web.
* **Almacenamiento (Importante):** Para evitar costos (Plan Spark), la aplicación **NO** sube el archivo de imagen a Firebase Storage. Solo guarda el **nombre** del archivo generado (ej. `PFM6-001.JPG`) en la base de datos de Firestore.

### 4. Arquitectura Multiplataforma
* La app utiliza una Interfaz (`FileManagerInterface`) con un "selector" (`file_manager_locator.dart`).
* Actualmente, el selector está "bloqueado" para usar **`file_manager_firebase.dart`** en todas las plataformas (móvil y web) para asegurar que todos los datos estén centralizados.
