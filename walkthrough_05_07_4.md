# Plan de Implementación: Reemplazar image_picker por file_picker

Este plan propone reemplazar el plugin `image_picker` por `file_picker` en la pestaña "Equipos" para poder capturar el nombre de archivo original exacto (ej: `IMG_20260703_152951.jpg`) en lugar de nombres temporales generados por el sistema (ej: `1000317694.jpg`).

## Diagnóstico Técnico
En versiones recientes de Android, cuando se utiliza `image_picker`, el sistema copia la imagen seleccionada a la caché temporal de la app con un nombre autogenerado basado en su ID de MediaStore. La librería `file_picker` está diseñada para acceder a los metadatos reales del archivo (`OpenableColumns.DISPLAY_NAME`) a través de un Content Resolver, lo que garantiza que retorne el nombre original del archivo físico seleccionado.

## Cambios Propuestos

### 1. Dependencias del Proyecto
#### [MODIFY] [pubspec.yaml](file:///C:/Users/angel/report_cnd/pubspec.yaml)
* Agregar la dependencia `file_picker: ^8.0.3` (compatible con el SDK de Dart 3.9.2 actual del entorno).

---

### 2. Pestaña de Equipos
#### [MODIFY] [equipos_screen.dart](file:///C:/Users/angel/report_cnd/lib/equipos_screen.dart)
* Reemplazar la importación de `image_picker` por `file_picker`.
* Eliminar la instancia de `ImagePicker _picker`.
* Refactorizar el método `_handleCamera` para utilizar `FilePicker.platform.pickFiles` filtrando por imágenes y recuperar el nombre original a través de `result.files.first.name`.

---

## Plan de Verificación

### Pruebas Automatizadas
* Ejecutar `flutter pub get` para descargar el nuevo paquete.
* Ejecutar `flutter analyze` para verificar la compilación libre de errores y advertencias.

### Pruebas Manuales
* El usuario podrá compilar la versión en su dispositivo y verificar que al presionar el botón de la cámara y seleccionar una imagen, el campo de texto se autocomplete con el nombre original (ej: `IMG_20260703_152951.jpg`) y no con el ID temporal de caché.
