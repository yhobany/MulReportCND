# Report CND vFlutter

App de reportes CND (versión Flutter).

Esta es una migración del proyecto original de Kotlin (ReportCND13) a Flutter, con el objetivo de crear una aplicación multiplataforma (Android, iOS y Web) para la gestión y el registro de reportes de mantenimiento industrial.

## Características Principales (Móvil)

La aplicación replica la funcionalidad de la versión nativa de Kotlin, almacenando datos localmente en el dispositivo en archivos `.csv` y `.txt`.

### 1. Register (Registro)
* Formulario de entrada para **UT**, **Punto** (con selector de diálogo) y **Descripción**.
* La fecha se establece automáticamente como la fecha actual del sistema (no editable).
* Validación de prefijos de UT (ej. "PFM6", "PP20", etc.).
* Guarda los datos en `registro.txt`.

### 2. Report (Reporte)
* Consulta y filtra los registros históricos de `registro.txt`.
* Filtra por **Rango de Fechas** (con selector de calendario), **Planta** (con selector de diálogo) o **UT**.
* Muestra los resultados en una lista de tarjetas.

### 3. Equipos
* Permite la entrada de un **Equipo Principal** y **Equipos Adicionales** dinámicos.
* **Integración con Cámara:** Usa `image_picker` y `permission_handler` para abrir la cámara, pedir permisos y nombrar la foto con un contador único (ej. `PFM6-001.JPG`).
* Guarda los datos en `equipos.csv`.
* **Eliminación:** Permite la selección múltiple (con `Checkbox`) y la eliminación de registros de `equipos.csv` con un diálogo de confirmación.
* **Exportación:** Filtra `equipos.csv` por la fecha actual y usa `share_plus` para compartir el archivo `.csv` resultante.

## Tecnologías Utilizadas

* **Lenguaje:** Dart
* **Framework:** Flutter
* **Gestión de Estado:** `StatefulWidget` (para la gestión de estado local de cada pantalla).
* **Almacenamiento de Archivos:** `path_provider` (para encontrar las carpetas) y `dart:io` (para leer/escribir).
* **Almacenamiento Clave-Valor:** `shared_preferences` (para el contador de imágenes).
* **Hardware:** `image_picker` (cámara) y `permission_handler` (permisos).
* **Compartir:** `share_plus` (para la exportación).
* **Formateo:** `intl` (para el manejo de fechas).