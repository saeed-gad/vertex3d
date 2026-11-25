import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../models.dart';
import '../services/app_state.dart';
import '../widgets/common.dart';

/// إضافة/تعديل عميل. بيرجّع الـ Client المحفوظ (بـ id) عن طريق Navigator.pop.
class ClientFormScreen extends StatefulWidget {
  final Client? existing;
  const ClientFormScreen({super.key, this.existing});
  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _code, _phone, _email, _address;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _name = TextEditingController(text: c?.name ?? '');
    _code = TextEditingController(text: c?.countryCode ?? '+20');
    _phone = TextEditingController(text: c?.phone ?? '');
    _email = TextEditingController(text: c?.email ?? '');
    _address = TextEditingController(text: c?.address ?? '');
  }

  @override
  void dispose() {
    for (final c in [_name, _code, _phone, _email, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    var code = _code.text.trim();
    if (code.isNotEmpty && !code.startsWith('+')) code = '+$code';
    final c = Client(
      id: widget.existing?.id ?? '',
      name: _name.text.trim(),
      countryCode: code.isEmpty ? '+20' : code,
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      address: _address.text.trim(),
    );
    final id = context.read<AppState>().saveClient(c);
    Navigator.pop(
        context,
        Client(
            id: id,
            name: c.name,
            countryCode: c.countryCode,
            phone: c.phone,
            email: c.email,
            address: c.address));
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? tr('editClient') : tr('addClient'))),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              child: Column(children: [
                Labeled(
                  tr('clientName'),
                  TextFormField(
                    controller: _name,
                    decoration:
                        const InputDecoration(prefixIcon: Icon(Icons.person_outline)),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? tr('required') : null,
                  ),
                ),
                const SizedBox(height: 14),
                Labeled(
                  tr('phone'),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(
                      width: 92,
                      child: TextFormField(
                        controller: _code,
                        keyboardType: TextInputType.phone,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                            hintText: '1012345678',
                            prefixIcon: Icon(Icons.phone_android)),
                      ),
                    ),
                  ]),
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
              ]),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: Text(tr('save'))),
          ],
        ),
      ),
    );
  }
}
