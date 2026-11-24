import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../utils/helpers.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _message;
  String? _devToken;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
      _devToken = null;
    });
    try {
      final r = await ApiClient.instance.forgot(_email.text.trim());
      if (mounted) setState(() {
        _message = r.message;
        _devToken = r.devToken;
      });
    } catch (e) {
      if (mounted) setState(() => _error = errMsg(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openReset([String? token]) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ResetPasswordScreen(initialToken: token ?? '')));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
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
                    const Text('Ingresa tu correo registrado y te enviaremos un enlace para restablecer tu contraseña.'),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: vEmail,
                      decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder()),
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
                          : const Text('Enviar enlace'),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 20),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_message!),
                              if (_devToken != null) ...[
                                const SizedBox(height: 10),
                                const Text('Modo demostración (sin servicio de correo configurado):', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                SelectableText(_devToken!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 3)),
                                const SizedBox(height: 8),
                                FilledButton.tonal(onPressed: () => _openReset(_devToken), child: const Text('Usar este código')),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                    TextButton(onPressed: _openReset, child: const Text('Ya tengo mi código')),
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
