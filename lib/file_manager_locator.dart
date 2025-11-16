// lib/file_manager_locator.dart

import 'file_manager_interface.dart';

// --- CAMBIO CLAVE ---
// 1. Comentamos (o borramos) todas las importaciones condicionales antiguas
// import 'file_manager_mobile.dart'
//     if (dart.library.html) 'file_manager_web.dart'
//     if (dart.library.io) 'file_manager_mobile.dart';

// 2. Importamos DIRECTAMENTE nuestra nueva implementación de Firebase
import 'file_manager_firebase.dart';
// --- FIN DEL CAMBIO ---


// Esta función es la que usa nuestra app.
// Ahora siempre devolverá la versión de Firebase.
FileManagerInterface getFileManager() => FileManager();