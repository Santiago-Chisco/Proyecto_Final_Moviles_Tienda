import 'package:flutter/foundation.dart';

/// URL de la API cuando se pasa con --dart-define=API_URL=...
const String _definedUrl = String.fromEnvironment('API_URL');

/// ⚠️ CAMBIA ESTA URL por la de tu servicio en Render (sin "/" al final).
const String kRenderUrl = 'https://tienda-app.onrender.com';

/// URL base de la API REST:
///  1. --dart-define=API_URL=... (p. ej. http://10.0.2.2:3000 para backend local)
///  2. En web (Render): el mismo origen que sirve la app.
///  3. En Android/iOS: la URL de Render definida arriba.
String get apiBaseUrl {
  if (_definedUrl.isNotEmpty) return _definedUrl;
  if (kIsWeb) return Uri.base.origin;
  return kRenderUrl;
}

String resolveUrl(String path) => path.startsWith('http') ? path : '$apiBaseUrl$path';
