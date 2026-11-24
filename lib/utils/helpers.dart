import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../api/api_client.dart';

String formatCop(num v) {
  final s = v.round().abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return '${v < 0 ? '-' : ''}\$ $b';
}

String formatDate(String iso) {
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return iso;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}

String errMsg(Object e) => e is ApiException ? e.message : 'Ocurrió un error inesperado';

void showMsg(BuildContext context, String msg, {bool error = false}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: error ? Theme.of(context).colorScheme.error : null,
    behavior: SnackBarBehavior.floating,
  ));
}

/// En web, si el usuario llega desde el enlace del correo (#/reset-password?token=XXXX)
/// devuelve el token ('' si no trae). En móvil devuelve null.
String? resetTokenFromUrl() {
  if (!kIsWeb) return null;
  final f = Uri.base.fragment;
  if (!f.contains('reset-password')) return null;
  final i = f.indexOf('?');
  if (i < 0) return '';
  try {
    return Uri.splitQueryString(f.substring(i + 1))['token'] ?? '';
  } catch (_) {
    return '';
  }
}

// ---- validadores ----
final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? vRequired(String? v, [String label = 'Este campo']) =>
    (v == null || v.trim().isEmpty) ? '$label es obligatorio' : null;

String? vEmail(String? v) {
  final r = vRequired(v, 'El correo');
  if (r != null) return r;
  return _emailRe.hasMatch(v!.trim()) ? null : 'Ingresa un correo válido';
}

String? vMinLen(String? v, int min, [String label = 'La contraseña']) {
  final r = vRequired(v, label);
  if (r != null) return r;
  return v!.length < min ? '$label debe tener mínimo $min caracteres' : null;
}

String? vUsername(String? v) {
  final r = vRequired(v, 'El username');
  if (r != null) return r;
  return RegExp(r'^[a-zA-Z0-9_.]{3,20}$').hasMatch(v!.trim()) ? null : 'Usa 3-20 caracteres: letras, números, "_" o "."';
}
