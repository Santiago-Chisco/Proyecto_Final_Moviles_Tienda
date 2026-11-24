import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../utils/helpers.dart';
import '../widgets/password_field.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});
  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _first;
  late final TextEditingController _last;
  late final TextEditingController _user;
  final Map<String, String> _srv = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().user;
    _first = TextEditingController(text: u?.firstName ?? '');
    _last = TextEditingController(text: u?.lastName ?? '');
    _user = TextEditingController(text: u?.username ?? '');
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _user.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    _srv.clear();
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<AuthProvider>().updateProfile(
            firstName: _first.text.trim(),
            lastName: _last.text.trim(),
            username: _user.text.trim(),
          );
      if (mounted) showMsg(context, 'Datos actualizados correctamente');
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.fields.isNotEmpty) {
        setState(() => _srv.addAll(e.fields));
        _form.currentState!.validate();
      } else {
        showMsg(context, e.message, error: true);
      }
    } catch (e) {
      if (mounted) showMsg(context, errMsg(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    await showDialog<void>(context: context, builder: (_) => const _ChangePasswordDialog());
  }

  Future<void> _logout() async {
    context.read<CartProvider>().reset();
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final cs = Theme.of(context).colorScheme;
    const mode = AutovalidateMode.onUserInteraction;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: CircleAvatar(
                radius: 48,
                backgroundColor: cs.primaryContainer,
                child: Text(user?.initials ?? '', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: cs.onPrimaryContainer)),
              ),
            ),
            const SizedBox(height: 12),
            Text(user?.fullName ?? '', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Text('@${user?.username ?? ''}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text(user?.email ?? '', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Form(
              key: _form,
              child: Column(
                children: [
                  TextFormField(
                    controller: _first,
                    autovalidateMode: mode,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Nombre', prefixIcon: Icon(Icons.badge_outlined)),
                    validator: (v) => vRequired(v, 'El nombre') ?? _srv['firstName'],
                    onChanged: (_) => _srv.remove('firstName'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _last,
                    autovalidateMode: mode,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Apellidos', prefixIcon: Icon(Icons.badge_outlined)),
                    validator: (v) => vRequired(v, 'Los apellidos') ?? _srv['lastName'],
                    onChanged: (_) => _srv.remove('lastName'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _user,
                    autovalidateMode: mode,
                    decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Username', prefixIcon: Icon(Icons.alternate_email)),
                    validator: (v) => vUsername(v) ?? _srv['username'],
                    onChanged: (_) => _srv.remove('username'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    initialValue: user?.email ?? '',
                    enabled: false,
                    decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Correo electrónico (no editable)', prefixIcon: Icon(Icons.email_outlined)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Guardar cambios'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _changePassword,
              icon: const Icon(Icons.lock_reset),
              label: const Text('Cambiar contraseña'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _logout,
              icon: Icon(Icons.logout, color: cs.error),
              label: Text('Cerrar sesión', style: TextStyle(color: cs.error)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();
  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  final Map<String, String> _srv = {};
  bool _loading = false;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _srv.clear();
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ApiClient.instance.changePassword(_current.text, _new.text);
      if (!mounted) return;
      Navigator.pop(context);
      showMsg(context, 'Contraseña actualizada');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _srv.addAll(e.fields);
        _loading = false;
      });
      if (e.fields.isNotEmpty) {
        _form.currentState!.validate();
      } else {
        showMsg(context, e.message, error: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showMsg(context, errMsg(e), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cambiar contraseña'),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PasswordField(
                controller: _current,
                label: 'Contraseña actual',
                validator: (v) => vRequired(v, 'La contraseña actual') ?? _srv['currentPassword'],
                onChanged: (_) => _srv.remove('currentPassword'),
              ),
              const SizedBox(height: 12),
              PasswordField(
                controller: _new,
                label: 'Nueva contraseña',
                validator: (v) => vMinLen(v, 8) ?? _srv['newPassword'],
                onChanged: (_) => _srv.remove('newPassword'),
              ),
              const SizedBox(height: 12),
              PasswordField(
                controller: _confirm,
                label: 'Confirmar nueva contraseña',
                validator: (v) {
                  final r = vRequired(v, 'La confirmación');
                  if (r != null) return r;
                  return v != _new.text ? 'Las contraseñas no coinciden' : null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _loading ? null : () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _loading ? null : _submit, child: const Text('Guardar')),
      ],
    );
  }
}
