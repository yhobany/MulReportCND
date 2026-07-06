# Plan de Implementación: Refactorización y Buenas Prácticas QA

Este plan detalla los cambios para resolver los 3 puntos del plan de acción propuesto en la auditoría de calidad, además de corregir un error crítico detectado en la generación del nombre de las imágenes debido a caracteres de escape incorrectos.

## Cambios Propuestos

### 1. Dependencias del Proyecto
#### [MODIFY] [pubspec.yaml](file:///C:/Users/angel/report_cnd/pubspec.yaml)
* Remover la dependencia `firebase_storage: ^11.7.5` para eliminar código no utilizado (bloat) y optimizar el tamaño de la aplicación web y móvil.

---

### 2. Capa de Servicios y Base de Datos
#### [MODIFY] [database_service.dart](file:///C:/Users/angel/report_cnd/lib/services/database_service.dart)
* **Importaciones:** Limpiar importaciones no utilizadas (`dart:io`, `package:path_provider/path_provider.dart`).
* **Seguridad en Logs:** Reemplazar el uso de `print` por `debugPrint` (importando `package:flutter/foundation.dart`) para evitar fugas de información en producción.
* **Manejo de Errores:** Completar los bloques `catch` vacíos con logs de error controlados en modo depuración (`debugPrint`).
* **Corrección de Bug de Interpolación:** Corregir el método `getNextImageName` que escapaba erróneamente los símbolos `$` en `"image_counter_\$prefix"` y `"\$prefix-\${counter...}"`, haciendo que la variable `prefix` se detectara como no utilizada y generara nombres de archivo e identificadores incorrectos.

---

## Plan de Verificación

### Pruebas Automatizadas
* Ejecutar `flutter pub get` para sincronizar las dependencias.
* Ejecutar `flutter analyze` para verificar la ausencia de errores o advertencias en el código refactorizado.
