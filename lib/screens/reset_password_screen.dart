import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../utils/helpers.dart';
import '../widgets/password_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String initialToken;
  const ResetPasswordScreen({super.key, this.initialToken = ''});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _token = TextEditingController(text: widget.initialToken);
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _token.dispose();
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final msg = await ApiClient.instance.reset(_token.text.trim(), _pass.text);
      if (!mounted) return;
      Navigator.popUntil(context, (r) => r.isFirst);
      showMsg(context, msg);
    } catch (e) {
      if (mounted) setState(() => _error = errMsg(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva contraseña')),
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
                      controller: _token,
                      textCapitalization: TextCapitalization.characters,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (v) => vRequired(v, 'El código'),
                      decoration: const InputDecoration(labelText: 'Código del correo', prefixIcon: Icon(Icons.vpn_key_outlined), border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 14),
                    PasswordField(controller: _pass, label: 'Nueva contraseña', validator: (v) => vMinLen(v, 8, 'La contraseña')),
                    const SizedBox(height: 14),
                    PasswordField(
                      controller: _pass2,
                      label: 'Confirmar contraseña',
                      validator: (v) {
                        final r = vRequired(v, 'La confirmación');
                        if (r != null) return r;
                        return v != _pass.text ? 'Las contraseñas no coinciden' : null;
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: cs.error)),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: _loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Restablecer contraseña'),
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
