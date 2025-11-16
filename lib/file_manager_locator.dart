// lib/file_manager_locator.dart

import 'file_manager_interface.dart';
// 1. Importación "stub" (ficticia) que será reemplazada
import 'file_manager_mobile.dart'
// 2. Condición: Si el compilador sabe qué es 'dart:html', usa 'file_manager_web.dart'
if (dart.library.html) 'file_manager_web.dart'
// 3. Condición: Si el compilador sabe qué es 'dart:io', usa 'file_manager_mobile.dart'
if (dart.library.io) 'file_manager_mobile.dart';

// Esta función es la que usará nuestra app.
// Devuelve la implementación correcta según la plataforma.
FileManagerInterface getFileManager() => FileManager();