import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/logo_picker.dart';
import '../widgets/update_card.dart';
import '../services/app_lock.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _name, _phone, _email, _address, _tax, _reg,
      _prefix, _vat, _notes, _country, _next;
  late String _logo;

  @override
  void initState() {
    super.initState();
    final c = context.read<AppState>().company!;
    _name = TextEditingController(text: c.name);
    _phone = TextEditingController(text: c.phone);
    _email = TextEditingController(text: c.email);
    _address = TextEditingController(text: c.address);
    _tax = TextEditingController(text: c.taxNumber);
    _reg = TextEditingController(text: c.commercialReg);
    _prefix = TextEditingController(text: c.prefix);
    _vat = TextEditingController(text: fmtNum(c.taxRate));
    _notes = TextEditingController(text: c.defaultNotes);
    _country = TextEditingController(text: c.country);
    _next = TextEditingController(text: '${c.nextNumber}');
    _logo = c.logoBase64;
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _address, _tax, _reg, _prefix, _vat, _notes, _country, _next]) {
      c.dispose();
    }
    super.dispose();
  }

  void _saveAll() {
    final app = context.read<AppState>();
    if (_name.text.trim().isEmpty) {
      toast(context, tr('required'));
      return;
    }
    app.saveCompany(app.company!.copyWith(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      address: _address.text.trim(),
      taxNumber: _tax.text.trim(),
      commercialReg: _reg.text.trim(),
      prefix: _prefix.text.trim(),
      taxRate: parseNum(_vat.text),
      defaultNotes: _notes.text.trim(),
      country: _country.text.trim(),
      logoBase64: _logo,
    ), nextNumber: () {
      final n = int.tryParse(_next.text.trim());
      return (n != null && n > 0 && n != app.company!.nextNumber) ? n : null;
    }());
    FocusScope.of(context).unfocus();
    toast(context, tr('saved'));
  }

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
        child: Text(t,
            style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary)),
      );

  Widget _field(String label, TextEditingController c,
          {TextInputType? type, int lines = 1, bool ltr = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Labeled(
          label,
          TextField(
            controller: c,
            keyboardType: type,
            maxLines: lines,
            textDirection: ltr ? TextDirection.ltr : null,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final co = app.company!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(tr('settings'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // حالة المزامنة
          const SizedBox(height: 8),
          SectionCard(
            child: Row(children: [
              CircleAvatar(
                backgroundColor:
                    app.synced ? const Color(0xFF6CF8BB) : const Color(0xFFFFDDB8),
                child: Icon(app.synced ? Icons.cloud_done : Icons.cloud_sync,
                    color: app.synced ? kGreen : const Color(0xFF653E00)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr('cloudSync'),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(app.synced ? tr('syncedSub') : tr('syncingSub'),
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  if (app.user?.email != null)
                    Text(app.user!.email!,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ]),
              ),
            ]),
          ),

          _title(tr('companyData')),
          SectionCard(
            child: Column(children: [
              Row(children: [
                LogoPickerTile(
                    logoBase64: _logo,
                    size: 72,
                    onChanged: (b) => setState(() => _logo = b)),
                const SizedBox(width: 14),
                Expanded(
                    child: Text(tr('changeLogo'),
                        style: const TextStyle(fontWeight: FontWeight.w700))),
              ]),
              const SizedBox(height: 16),
              _field(tr('companyName'), _name),
              _field(tr('phone'), _phone, type: TextInputType.phone, ltr: true),
              _field(tr('email'), _email,
                  type: TextInputType.emailAddress, ltr: true),
              _field(tr('address'), _address, lines: 2),
              _field(tr('country'), _country),
              _field(tr('commercialReg'), _reg, type: TextInputType.number, ltr: true),
              _field(tr('taxNumber'), _tax, type: TextInputType.number, ltr: true),
            ]),
          ),

          _title(tr('defaults')),
          SectionCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Labeled(
                tr('currency'),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: [
                      const ButtonSegment(value: 'EGP', label: Text('EGP')),
                      const ButtonSegment(value: 'USD', label: Text('USD')),
                    ],
                    selected: {co.currency},
                    onSelectionChanged: (v) => app
                        .saveCompany(co.copyWith(currency: v.first)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _field(tr('prefix'), _prefix, ltr: true),
              _field(tr('nextNumber'), _next, type: TextInputType.number, ltr: true),
              _field(tr('defaultTax'), _vat,
                  type: const TextInputType.numberWithOptions(decimal: true)),
              _field(tr('defaultNotes'), _notes, lines: 4),
            ]),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saveAll,
            icon: const Icon(Icons.save),
            label: Text(tr('save')),
          ),

          _title(tr('appearance')),
          SectionCard(
            child: Column(children: [
              Row(children: [
                const Icon(Icons.language),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(tr('language'),
                        style: const TextStyle(fontWeight: FontWeight.w700))),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 'ar', label: Text('العربية')),
                    ButtonSegment(value: 'en', label: Text('English')),
                  ],
                  selected: {co.lang},
                  onSelectionChanged: (v) =>
                      app.saveCompany(co.copyWith(lang: v.first)),
                ),
              ]),
              const Divider(height: 24),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.dark_mode_outlined),
                title: Text(tr('darkMode'),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                value: co.dark,
                onChanged: (v) => app.saveCompany(co.copyWith(dark: v)),
              ),
            ]),
          ),
          _title(tr('security')),
          SectionCard(
            child: Builder(builder: (context) {
              final lock = context.watch<AppLock>();
              return SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.lock_outline),
                title: Text(tr('appLock'),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(tr('appLockSub'), style: const TextStyle(fontSize: 12)),
                value: lock.enabled,
                onChanged: (v) async {
                  final err = await lock.setEnabled(v);
                  if (err != null && context.mounted) toast(context, err);
                },
              );
            }),
          ),
          const SizedBox(height: 14),
          const UpdateCard(),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
                backgroundColor: cs.errorContainer,
                foregroundColor: cs.onErrorContainer),
            onPressed: () => app.signOut(),
            icon: const Icon(Icons.logout),
            label: Text(tr('signOut')),
          ),
          const SizedBox(height: 12),
          Center(
              child: Text('Invoicer',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant))),
        ],
      ),
    );
  }
}
