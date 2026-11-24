import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../utils/helpers.dart';
import '../widgets/password_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _user = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  final _userFocus = FocusNode();

  /// Errores devueltos por el backend, por campo.
  final Map<String, String> _srv = {};
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Verifica en el backend que el username sea único al salir del campo.
    _userFocus.addListener(() async {
      if (_userFocus.hasFocus) return;
      final u = _user.text.trim();
      if (vUsername(u) != null) return;
      try {
        final ok = await ApiClient.instance.usernameAvailable(u);
        if (!mounted) return;
        setState(() {
          if (ok) {
            _srv.remove('username');
          } else {
            _srv['username'] = 'Este username ya está en uso';
          }
        });
        _form.currentState?.validate();
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    for (final c in [_first, _last, _user, _email, _pass, _pass2]) {
      c.dispose();
    }
    _userFocus.dispose();
    super.dispose();
  }

  void _clearSrv(String key) {
    if (_srv.containsKey(key)) _srv.remove(key);
  }

  Future<void> _submit() async {
    _srv.clear();
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ApiClient.instance.register(
        firstName: _first.text.trim(),
        lastName: _last.text.trim(),
        username: _user.text.trim(),
        email: _email.text.trim(),
        password: _pass.text,
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _srv
          ..clear()
          ..addAll(e.fields);
        _error = e.fields.isEmpty ? e.message : null;
      });
      _form.currentState!.validate();
    } catch (e) {
      if (mounted) setState(() => _error = errMsg(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _dec(String label, IconData icon) =>
      InputDecoration(labelText: label, prefixIcon: Icon(icon), border: const OutlineInputBorder());

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const mode = AutovalidateMode.onUserInteraction;
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _first,
                      autovalidateMode: mode,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: _dec('Nombre', Icons.badge_outlined),
                      validator: (v) => vRequired(v, 'El nombre') ?? _srv['firstName'],
                      onChanged: (_) => _clearSrv('firstName'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _last,
                      autovalidateMode: mode,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: _dec('Apellidos', Icons.badge_outlined),
                      validator: (v) => vRequired(v, 'Los apellidos') ?? _srv['lastName'],
                      onChanged: (_) => _clearSrv('lastName'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _user,
                      focusNode: _userFocus,
                      autovalidateMode: mode,
                      textInputAction: TextInputAction.next,
                      decoration: _dec('Username', Icons.alternate_email),
                      validator: (v) => vUsername(v) ?? _srv['username'],
                      onChanged: (_) => _clearSrv('username'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _email,
                      autovalidateMode: mode,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: _dec('Correo electrónico', Icons.email_outlined),
                      validator: (v) => vEmail(v) ?? _srv['email'],
                      onChanged: (_) => _clearSrv('email'),
                    ),
                    const SizedBox(height: 14),
                    PasswordField(
                      controller: _pass,
                      textInputAction: TextInputAction.next,
                      validator: (v) => vMinLen(v, 8) ?? _srv['password'],
                      onChanged: (_) => _clearSrv('password'),
                    ),
                    const SizedBox(height: 14),
                    PasswordField(
                      controller: _pass2,
                      label: 'Verificar contraseña',
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      validator: (v) {
                        final r = vRequired(v, 'La verificación');
                        if (r != null) return r;
                        return v != _pass.text ? 'Las contraseñas no coinciden' : null;
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: cs.error), textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: _loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Registrarse'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('¿Ya tienes cuenta?'),
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ya tengo cuenta')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
