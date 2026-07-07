# Resumen de Cambios: Selección de Archivos con Nombre de Archivo Original

Se reemplazó el plugin `image_picker` por `file_picker` en la pestaña de Equipos para corregir de forma definitiva la pérdida de los nombres originales de los archivos seleccionados en Android, iOS y la Web.

## Cambios Realizados

### 1. Actualización de dependencias
#### [MODIFY] [pubspec.yaml](file:///C:/Users/angel/report_cnd/pubspec.yaml)
* Se agregó la dependencia `file_picker: ^8.0.3` para dar soporte multiplataforma a la selección de archivos conservando sus metadatos de nombre original.

---

### 2. Refactorización de la pestaña de Equipos
#### [MODIFY] [equipos_screen.dart](file:///C:/Users/angel/report_cnd/lib/equipos_screen.dart)
* Se eliminó el paquete `image_picker` e importó `file_picker`.
* Se borró la instancia de `ImagePicker _picker`.
* Se refactorizó la función `_handleCamera` para utilizar el selector nativo de archivos:
  ```dart
  final FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    allowMultiple: false,
  );
  ```
* Se implementó una extracción de nombre segura y compatible con cualquier tipo de dispositivo/sistema operativo para aislar el nombre del archivo de rutas físicas:
  ```dart
  final String fileName = result.files.first.name.split('/').last.split('\\').last;
  ```
  Esto asegura que el campo se autocomplete exactamente con el nombre de la imagen (ej: `IMG_20260703_152951.jpg`) independientemente de la plataforma.

---

## Resultados de Verificación
* **Análisis de Código (`flutter analyze`):** Exitoso. Se eliminaron variables sin uso (`_isCheckingUt`, `_statusEditOptions`) logrando 0 errores en la estructura.
* **Compilación Web Multiplataforma:** Se verificó y ejecutó localmente `flutter build web --release`, construyendo el paquete web en verde sin errores.
* **Despliegue Continuo en Nube (GitHub Actions):** Se solucionó la incompatibilidad multiplataforma en CI/CD añadiendo `--no-tree-shake-icons` en el workflow de construcción y alineando la versión del motor (`3.24.4`) y las clases de estilo (`CardTheme`, `DialogTheme`, `TabBarTheme`) en [app_theme.dart](file:///C:/Users/angel/report_cnd/lib/theme/app_theme.dart), logrando que el flujo de GitHub Pages finalice con todos los botones en verde (**✔**).
