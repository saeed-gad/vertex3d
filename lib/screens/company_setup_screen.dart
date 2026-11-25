import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../models.dart';
import '../services/app_state.dart';
import '../widgets/common.dart';
import '../widgets/logo_picker.dart';

class CompanySetupScreen extends StatefulWidget {
  const CompanySetupScreen({super.key});
  @override
  State<CompanySetupScreen> createState() => _CompanySetupScreenState();
}

class _CompanySetupScreenState extends State<CompanySetupScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _tax = TextEditingController();
  String _currency = 'EGP';
  String _logo = '';

  @override
  void initState() {
    super.initState();
    final u = context.read<AppState>().user;
    _email.text = u?.email ?? '';
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _address, _tax]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    context.read<AppState>().saveCompany(
          Company(
            name: _name.text.trim(),
            phone: _phone.text.trim(),
            email: _email.text.trim(),
            address: _address.text.trim(),
            taxNumber: _tax.text.trim(),
            currency: _currency,
            logoBase64: _logo,
            defaultNotes: tr('thanks'),
          ),
          first: true,
        );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('welcome')),
        actions: [
          IconButton(
              tooltip: tr('signOut'),
              onPressed: () => context.read<AppState>().signOut(),
              icon: const Icon(Icons.logout)),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(tr('setupSub'), style: TextStyle(color: cs.onSurfaceVariant)),
              const SizedBox(height: 16),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(children: [
                        LogoPickerTile(
                            logoBase64: _logo,
                            onChanged: (b) => setState(() => _logo = b)),
                        const SizedBox(height: 8),
                        Text(tr('tapLogo'),
                            style: TextStyle(
                                fontSize: 12, color: cs.onSurfaceVariant)),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    Labeled(
                      tr('companyName'),
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.apartment)),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? tr('required') : null,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Labeled(
                      tr('phone'),
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        textDirection: TextDirection.ltr,
                        decoration:
                            const InputDecoration(prefixIcon: Icon(Icons.phone_android)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Labeled(
                      tr('email'),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        decoration:
                            const InputDecoration(prefixIcon: Icon(Icons.mail_outline)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Labeled(
                      tr('address'),
                      TextFormField(
                        controller: _address,
                        maxLines: 2,
                        decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.location_on_outlined)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Labeled(
                      '${tr('taxNumber')} (${tr('optional')})',
                      TextFormField(
                        controller: _tax,
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.receipt_long_outlined)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Labeled(
                      tr('currency'),
                      DropdownButtonFormField<String>(
                        value: _currency,
                        decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.payments_outlined)),
                        items: [
                          DropdownMenuItem(value: 'EGP', child: Text(tr('egp'))),
                          DropdownMenuItem(value: 'USD', child: Text(tr('usd'))),
                        ],
                        onChanged: (v) => setState(() => _currency = v ?? 'EGP'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(tr('saveContinue')),
              ),
              const SizedBox(height: 10),
              Text(tr('editLater'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
