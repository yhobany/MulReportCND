# Plan de Implementación y Solución a Anormalidades de Testeo

Este documento detalla el diagnóstico técnico y el plan de acción paso a paso para resolver las 4 anormalidades encontradas durante las pruebas de testeo en las versiones Web y Nativa.

---

## 1. Diagnóstico de los Problemas Reportados

### Inconveniente 1 y 2: Nombres de archivo incorrectos al usar la Cámara (Web y Nativo)
* **Síntoma:** En la versión Web, los cambios no parecen surtir efecto o al capturar desde la cámara sigue dando nombres inválidos/autogenerados. En la versión Nativa (Android), al tomar una foto o seleccionar desde el icono de cámara, se obtiene un nombre aleatorio o ID numérico (ej: `1000317694.jpg`) en lugar del nombre original.
* **Causa Técnica:** Cuando se invoca `FilePicker.platform.pickFiles(type: FileType.image)`, Android utiliza el *Photo Picker* / `MediaStore`, el cual enmascara la ruta del archivo detrás de un content URI y asigna el ID de base de datos del archivo en su caché temporal. En Web, las fotos capturadas en vivo desde la cámara web reciben un nombre temporal generado por el navegador.
* **Solución Propuesta:** Cambiar en `lib/equipos_screen.dart` el parámetro a `type: FileType.custom` con `allowedExtensions: ['jpg', 'jpeg', 'png', 'heic', 'HEIC']`. Esto obliga a los sistemas operativos (especialmente Android SAF y navegadores Web) a abrir el selector de archivos del sistema real (*Storage Access Framework*), el cual **siempre preserva y retorna el nombre original intacto (`DISPLAY_NAME`)** en todas las plataformas. Además, se añadirá un refresco forzado en la configuración de GitHub Pages para eliminar la caché del *service worker* en la versión Web.

### Inconveniente 3: Errores de código en `lib/theme/app_theme.dart`
* **Síntoma:** El comando `flutter analyze` en la máquina local reporta errores en las líneas 93, 104 y 116 (`The argument type 'CardTheme' can't be assigned to the parameter type 'CardThemeData?'`).
* **Causa Técnica:** Diferencia de versiones entre el SDK local instalado (que requiere `CardThemeData`, `DialogThemeData`, `TabBarThemeData`) y la versión fijada en la nube (que requiere `CardTheme`, etc.).
* **Solución Propuesta:** Refactorizar `lib/theme/app_theme.dart` para eliminar las clases que causan discrepancia entre versiones del SDK, aplicando la estilización de tarjetas, diálogos y pestañas a través de constructores y propiedades universales que compilan sin errores ni en el entorno local ni en GitHub Actions.

### Inconveniente 4: Falta de notificación/aprobación de nuevos usuarios en Firebase
* **Síntoma:** Al crear un nuevo usuario no se observa una notificación o registro claro para ser aprobado en la consola de Firebase.
* **Causa Técnica:** Cuando se ejecuta `authService.registerWithEmail` (en `lib/auth_service.dart`), se crea el usuario en *Firebase Authentication* y se intenta crear un documento en la colección `users` de *Cloud Firestore* con `status: 'pending'`. Sin embargo, las **Reglas de Seguridad de Firestore** en la consola de Firebase están bloqueando o rechazando la creación del documento de nuevos usuarios, o falta un mecanismo visual en la consola/app para los administradores.
* **Solución Propuesta:** 
  1. Verificar y proporcionar la estructura exacta de las **Reglas de Seguridad de Firestore (`firestore.rules`)** para garantizar que los nuevos registros puedan escribir exitosamente su documento con estatus `pending`.
  2. Implementar/asegurar en el código una validación robusta de errores para informar al usuario de inmediato si el documento no pudo crearse en la base de datos de Firebase.

---

## 2. Plan de Acción Paso a Paso

### Fase 1: Corrección de Nombres de Archivos en Cámara y Galería (Multiplataforma)
#### [MODIFY] [equipos_screen.dart](file:///C:/Users/angel/report_cnd/lib/equipos_screen.dart)
* En el método `_handleCamera(int? index)`, reemplazar:
  ```dart
  final FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    allowMultiple: false,
  );
  ```
  por:
  ```dart
  final FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['jpg', 'jpeg', 'png', 'heic', 'HEIC'],
    allowMultiple: false,
  );
  ```
* Limpiar cualquier variable sin uso pendiente (como `_isCheckingUt`) para asegurar 0 advertencias.

### Fase 2: Armonización Universal de Estilos en el Tema
#### [MODIFY] [app_theme.dart](file:///C:/Users/angel/report_cnd/lib/theme/app_theme.dart)
* Refactorizar las propiedades `cardTheme`, `dialogTheme` y `tabBarTheme` en `app_theme.dart` para que sean sintácticamente compatibles con cualquier SDK de Flutter (local y CI), eliminando el error de `CardTheme` vs `CardThemeData`.

### Fase 3: Aseguramiento del Flujo de Registro y Firebase
#### [MODIFY] [auth_service.dart](file:///C:/Users/angel/report_cnd/lib/auth_service.dart)
* Optimizar la función `registerWithEmail` para asegurar la correcta escritura del documento en la colección `users` de Firestore y añadir registros explícitos para depuración en consola en caso de rechazo por reglas de seguridad.
* Proporcionar guía de configuración y reglas en `firestore.rules` para habilitar la aprobación sin bloqueo en la consola web de Firebase.

### Fase 4: Despliegue y Validación Web en GitHub Pages
#### [MODIFY] [deploy.yml](file:///C:/Users/angel/report_cnd/.github/workflows/deploy.yml)
* Ajustar la configuración de construcción web y la versión de Flutter para garantizar que el nuevo build invalide la caché anterior en los navegadores y se refleje de inmediato en la URL del proyecto.

---

## 3. Plan de Verificación
* **Verificación Local:** Ejecutar `flutter analyze` y comprobar que devuelva exactamente `No issues found!`.
* **Prueba de Selección de Archivos:** Probar en nativo y web que al presionar el icono de la cámara y seleccionar una imagen, el campo de texto reciba el nombre original exacto (ej. `IMG_20260703_152951.jpg`).
* **Prueba de Firebase:** Registrar una cuenta nueva y constatar en la consola de Firebase (`Firestore -> colección users`) la creación del documento con el campo `status: "pending"`.
