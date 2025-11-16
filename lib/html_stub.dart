// lib/html_stub.dart
// Un archivo "stub" (falso) para que el compilador móvil no falle.
// Estas clases no hacen nada.

class Blob {
  Blob(List<dynamic> parts, String type);
}

class Url {
  static String createObjectUrlFromBlob(Blob blob) => '';
  static void revokeObjectUrl(String url) {}
}

class AnchorElement {
  String? href;
  AnchorElement({this.href});

  void setAttribute(String name, String value) {}
  void click() {}
}