# Plan de Refactorización de MulReportCND

Dado que buscas un enfoque paso a paso y sencillo, utilizaremos **Provider** para la gestión del estado (es el estándar recomendado por Flutter y más intuitivo al principio). Nos enfocaremos en ir separando las cosas poco a poco para que puedas seguir cada cambio sin que la app deje de funcionar.

Dejaremos el manejo de imágenes tal cual está por ahora.

## Fases del Plan

### Fase 1: Configuración Inicial e Inyección de Dependencias
* **Objetivo:** Preparar la aplicación para manejar el estado de forma global sin pasar datos por cada widget.
* **Pasos:**
  1. Añadir el paquete `provider` a [pubspec.yaml](file:///c:/Users/angel/Laboratorio/MulReportCND/pubspec.yaml).
  2. Envolver la aplicación principal ([main.dart](file:///c:/Users/angel/Laboratorio/MulReportCND/lib/main.dart)) con un `MultiProvider`.

### Fase 2: Gestión de Autenticación (Auth)
* **Objetivo:** Separar la lógica de si el usuario está conectado o no, de la interfaz visual.
* **Pasos:**
  1. Crear un [AuthProvider](file:///c:/Users/angel/Laboratorio/MulReportCND/lib/providers/auth_provider.dart#4-40) que escuche los cambios de Firebase Auth.
  2. Refactorizar [AuthGate](file:///c:/Users/angel/Laboratorio/MulReportCND/lib/auth_gate.dart#9-56) y [LoginScreen](file:///c:/Users/angel/Laboratorio/MulReportCND/lib/login_screen.dart#10-16) para que utilicen este nuevo proveedor en lugar de manejar el estado localmente.

### Fase 3: Tematización Centralizada (Opcional pero Recomendado)
* **Objetivo:** Quitar los colores definidos directamente en la interfaz.
* **Pasos:**
  1. Crear un archivo [lib/theme/app_theme.dart](file:///c:/Users/angel/Laboratorio/MulReportCND/lib/theme/app_theme.dart).
  2. Actualizar [main.dart](file:///c:/Users/angel/Laboratorio/MulReportCND/lib/main.dart) para aplicar el tema en toda la app de forma consistente.

### Fase 4: Refactorización de Servicios de Base de Datos
* **Objetivo:** Sacar las consultas de Firebase (`FirebaseFirestore.instance...`) de las pantallas.
* **Pasos:**
  1. Crear un servicio [DatabaseService](file:///c:/Users/angel/Laboratorio/MulReportCND/lib/services/database_service.dart#10-247) genérico.
  2. Implementar métodos limpios (ej. `getRegistros()`, `addEquipo()`).

### Fase 5: Separación de la Interfaz (UI)
* **Objetivo:** Dividir archivos gigantes (como [report_screen.dart](file:///c:/Users/angel/Laboratorio/MulReportCND/lib/report_screen.dart) que tiene ~700 líneas) en componentes más pequeños.
* **Pasos:**
  1. Extraer los diálogos a sus propios archivos (`lib/widgets/dialogs/...`).
  2. Extraer los elementos de las listas a `lib/widgets/list_items/...`.

### Fase 6: Diseño de Experiencia Profesional (UX/UI)
* **Objetivo:** Darle estética de producto final, moderno y premium.
* **Pasos:**
  1. Instalar `google_fonts` y definir tipografía e íconos modernos.
  2. Rehacer [AppTheme](file:///c:/Users/angel/Laboratorio/MulReportCND/lib/theme/app_theme.dart#4-127) para estandarizar el nuevo esquema de colores premium y formas redondeadas (bordes, inputs, botones).
  3. Rediseñar por completo la pantalla de `login_screen`.
  4. Rediseñar la pantalla de reportes para maximizar visibilidad y mejorar las *Cards*.

### Fase 7: Validación de Equipos Duplicados y Gestión de Ramas (Branching)
* **Objetivo:** Prevenir la creación accidental de equipos duplicados y permitir al usuario decidir si desea sobrescribir los datos. Aislar este desarrollo en una rama de Git para proteger la versión estable.
* **Pasos:**
  1. Crear una nueva rama en Git (`feature/validacion-equipos`).
  2. Implementar un método `checkEquipmentExists(String ut, String equipment)` en `DatabaseService.dart`.
  3. Modificar [_handleSave](file:///c:/Users/angel/Laboratorio/MulReportCND/lib/register_screen.dart#125-164) en [equipos_screen.dart](file:///c:/Users/angel/Laboratorio/MulReportCND/lib/equipos_screen.dart) para verificar la existencia antes de guardar.
  4. Mostrar un [AlertDialog](file:///c:/Users/angel/Laboratorio/MulReportCND/lib/register_screen.dart#174-193) si existe un duplicado, permitiendo al usuario cancelar o sobrescribir (actualizar el registro existente).

### Fase 8: Refinamiento de UX (Gestión de Síntomas y Auto-Focus)
* **Objetivo:** Renombrar la terminología y mejorar la agilidad en la captura de datos basada en el feedback del usuario.
* **Pasos:**
  1. (Register/Report) Renombrar visualmente el concepto "Punto" a "Síntoma".
  2. Implementar `SharedPreferences` para cargar y guardar la lista de `symptomOptions` dinámicamente, permitiendo añadir nuevos elementos personalizados a través de la interfaz.
  3. En [equipos_screen.dart](file:///c:/Users/angel/Laboratorio/MulReportCND/lib/equipos_screen.dart), implementar una lista de `FocusNode` sincronizada con los controladores de texto. Al añadir un "Equipo Adicional", se solicitará el foco automático (`requestFocus()`) sobre la nueva caja de texto.

### Fase 9: Sincronización Global de Síntomas
* **Objetivo:** Permitir que los nuevos síntomas creados por cualquier usuario estén disponibles inmediatamente para todos los demás dispositivos instalados.
* **Pasos:**
  1. Crear lógica en `DatabaseService.dart` para gestionar una nueva colección en Firebase llamada `sintomas_globales`.
  2. Modificar [_loadSymptoms()](file:///c:/Users/angel/Laboratorio/MulReportCND/lib/register_screen.dart#55-78) en [register_screen.dart](file:///c:/Users/angel/Laboratorio/MulReportCND/lib/register_screen.dart) para que descargue la lista directamente desde Firebase en lugar de `SharedPreferences`.
  3. Modificar [_saveSymptom(String newSymptom)](file:///c:/Users/angel/Laboratorio/MulReportCND/lib/register_screen.dart#79-116) para que, al presionar el botón de agregar (+), el nuevo síntoma se suba a la nube (`sintomas_globales`) como un documento único, permitiendo que cualquier dispositivo lo lea la próxima vez que abra la pantalla.

### Fase 10: Bug Fixes e Integridad de Exportación
* **Objetivo:** Asegurar que los datos exportados a formato CSV sean legibles y estén correctamente procesados.
* **Pasos:**
  1. Identificar escapes literales incorrectos (`\$`) en las cadenas de interpolación dentro del servicio de datos.
  2. Refactorizar la función [exportRecords](file:///c:/Users/angel/Laboratorio/MulReportCND/lib/services/database_service.dart#238-246) para garantizar que Dart procese las variables dinámicas de fecha y equipo.
  3. Realizar limpieza de imports y advertencias linter para optimizar el rendimiento.

---
## User Review Required
> [!NOTE]
> Revisa la nueva Fase 9 en el plan de implementación. Implica crear una nueva colección `sintomas_globales` en tu base de datos de Firebase. Si estás de acuerdo con que los síntomas viajen a la nube para ser compartidos entre todos tus usuarios, dame tu autorización.
