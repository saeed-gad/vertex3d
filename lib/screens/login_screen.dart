import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _register = false, _busy = false, _hide = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _run(Future<String?> Function() f) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await f();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = (err == null || err.isEmpty) ? null : err;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                            color: kPrimary,
                            borderRadius: BorderRadius.circular(24)),
                        child: const Icon(Icons.receipt_long,
                            color: Colors.white, size: 44),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(tr('appName'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(tr('tagline'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => _run(s.signInGoogle),
                      icon: const Icon(Icons.g_mobiledata, size: 32),
                      label: Text(tr('loginGoogle')),
                    ),
                    const SizedBox(height: 16),
                    Row(children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(tr('orEmail'),
                            style: TextStyle(
                                fontSize: 12, color: cs.onSurfaceVariant)),
                      ),
                      const Expanded(child: Divider()),
                    ]),
                    const SizedBox(height: 16),
                    Labeled(
                      tr('email'),
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        decoration:
                            const InputDecoration(hintText: 'name@company.com'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Labeled(
                      tr('password'),
                      TextField(
                        controller: _pass,
                        obscureText: _hide,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          suffixIcon: IconButton(
                            icon: Icon(_hide
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () => setState(() => _hide = !_hide),
                          ),
                        ),
                      ),
                    ),
                    if (!_register)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton(
                          onPressed: _busy
                              ? null
                              : () async {
                                  if (_email.text.trim().isEmpty) {
                                    toast(context, tr('enterEmail'));
                                    return;
                                  }
                                  final e = await s.resetPassword(_email.text);
                                  if (!context.mounted) return;
                                  toast(context, e ?? tr('resetSent'));
                                },
                          child: Text(tr('forgot')),
                        ),
                      ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_error!,
                            style: TextStyle(color: cs.error),
                            textAlign: TextAlign.center),
                      ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _busy
                          ? null
                          : () => _run(() => _register
                              ? s.register(_email.text, _pass.text)
                              : s.signInEmail(_email.text, _pass.text)),
                      child: _busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(_register
                              ? tr('createAccount')
                              : tr('login')),
                    ),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(_register ? tr('haveAccount') : tr('noAccount')),
                      TextButton(
                        onPressed: () => setState(() {
                          _register = !_register;
                          _error = null;
                        }),
                        child: Text(
                            _register ? tr('login') : tr('createAccount'),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ]),
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
