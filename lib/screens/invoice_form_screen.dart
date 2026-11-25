import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../models.dart';
import '../services/app_state.dart';
import '../widgets/common.dart';
import 'client_form_screen.dart';
import 'invoice_preview_screen.dart';

class _ItemCtl {
  final desc = TextEditingController();
  final qty = TextEditingController(text: '1');
  final price = TextEditingController();
  final disc = TextEditingController(text: '0');
  _ItemCtl([InvoiceItem? i]) {
    if (i != null) {
      desc.text = i.description;
      qty.text = fmtNum(i.qty).replaceAll(',', '');
      price.text = fmtNum(i.price).replaceAll(',', '');
      disc.text = fmtNum(i.discountPct).replaceAll(',', '');
    }
  }
  double get total =>
      parseNum(qty.text) * parseNum(price.text) * (1 - parseNum(disc.text) / 100);
  void dispose() {
    desc.dispose();
    qty.dispose();
    price.dispose();
    disc.dispose();
  }
}

class InvoiceFormScreen extends StatefulWidget {
  final Invoice? existing;
  const InvoiceFormScreen({super.key, this.existing});
  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  late String _number;
  String? _clientId;
  late DateTime _date, _due;
  final _items = <_ItemCtl>[];
  final _discount = TextEditingController(text: '0');
  final _taxRate = TextEditingController();
  final _paid = TextEditingController(text: '0');
  final _notes = TextEditingController();

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final co = context.read<AppState>().company!;
    final e = widget.existing;
    if (e != null) {
      _number = e.number;
      _clientId = e.clientId;
      _date = e.date;
      _due = e.dueDate;
      _items.addAll(e.items.map((i) => _ItemCtl(i)));
      _discount.text = fmtNum(e.discount).replaceAll(',', '');
      _taxRate.text = fmtNum(e.taxRate);
      _paid.text = fmtNum(e.paidAmount).replaceAll(',', '');
      _notes.text = e.notes;
    } else {
      _number = co.nextInvoiceNumber;
      _date = DateTime.now();
      _due = _date.add(const Duration(days: 30));
      _items.add(_ItemCtl());
      _taxRate.text = fmtNum(co.taxRate);
      _notes.text = co.defaultNotes;
    }
  }

  @override
  void dispose() {
    for (final i in _items) {
      i.dispose();
    }
    _discount.dispose();
    _taxRate.dispose();
    _paid.dispose();
    _notes.dispose();
    super.dispose();
  }

  double get _subtotal => _items.fold(0, (s, i) => s + i.total);
  double get _taxable =>
      (_subtotal - parseNum(_discount.text)).clamp(0, double.infinity);
  double get _tax => _taxable * parseNum(_taxRate.text) / 100;
  double get _total => _taxable + _tax;
  double get _paidAmt => parseNum(_paid.text).clamp(0, _total).toDouble();

  Future<void> _pickDate(bool due) async {
    final d = await showDatePicker(
      context: context,
      initialDate: due ? _due : _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    setState(() => due ? _due = d : _date = d);
  }

  Future<void> _addClient() async {
    final c = await Navigator.push<Client>(
        context, MaterialPageRoute(builder: (_) => const ClientFormScreen()));
    if (c != null) setState(() => _clientId = c.id);
  }

  void _save(bool draft) {
    final app = context.read<AppState>();
    final client = _clientId == null ? null : app.clientById(_clientId!);
    if (client == null) {
      toast(context, tr('pickClient'));
      return;
    }
    final items = _items
        .where((i) => i.desc.text.trim().isNotEmpty)
        .map((i) => InvoiceItem(i.desc.text.trim(), parseNum(i.qty.text),
            parseNum(i.price.text), parseNum(i.disc.text)))
        .toList();
    if (items.isEmpty) {
      toast(context, tr('addAnItem'));
      return;
    }
    final e = widget.existing;
    String status;
    if (draft) {
      status = 'draft';
    } else {
      status = (e != null && e.status == 'paid') ? 'paid' : 'pending';
    }
    final inv = Invoice(
      id: e?.id ?? '',
      number: _number,
      clientId: client.id,
      clientName: client.name,
      clientPhone: client.fullPhone.isEmpty ? '' : '+${client.fullPhone}',
      clientAddress: client.address,
      date: _date,
      dueDate: _due,
      items: items,
      discount: parseNum(_discount.text),
      taxRate: parseNum(_taxRate.text),
      notes: _notes.text.trim(),
      status: status,
      paidAmount: _paidAmt,
      paidDate: _paidAmt > 0 ? (e?.paidDate ?? DateTime.now()) : null,
      createdAt: e?.createdAt,
    );
    final id = app.saveInvoice(inv, isNew: !_editing);
    if (draft || _editing) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => InvoicePreviewScreen(
                  invoiceId: id,
                  fallback: Invoice(
                      id: id,
                      number: inv.number,
                      clientId: inv.clientId,
                      clientName: inv.clientName,
                      clientPhone: inv.clientPhone,
                      clientAddress: inv.clientAddress,
                      date: inv.date,
                      dueDate: inv.dueDate,
                      items: inv.items,
                      discount: inv.discount,
                      taxRate: inv.taxRate,
                      notes: inv.notes,
                      status: inv.status,
                      paidAmount: inv.paidAmount,
                      paidDate: inv.paidDate,
                      createdAt: inv.createdAt))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final co = app.company!;
    final cs = Theme.of(context).colorScheme;
    final cur = co.currency;
    final canDraft = !_editing || widget.existing!.status == 'draft';

    return Scaffold(
      appBar: AppBar(title: Text(_editing ? tr('editInvoice') : tr('newInvoice'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // رقم الفاتورة
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr('autoNumber'),
                      style: const TextStyle(color: Color(0xFFB6C4FF), fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(_number,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1)),
                ]),
              ),
              const Icon(Icons.receipt_long, color: Colors.white54, size: 32),
            ]),
          ),
          const SizedBox(height: 14),

          // العميل
          SectionCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(tr('client'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15))),
                TextButton.icon(
                    onPressed: _addClient,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(tr('addNewClient'))),
              ]),
              DropdownButtonFormField<String>(
                value: app.clientById(_clientId ?? '') == null ? null : _clientId,
                isExpanded: true,
                hint: Text(tr('chooseClient')),
                items: app.clients
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _clientId = v),
              ),
            ]),
          ),
          const SizedBox(height: 14),

          // التواريخ
          Row(children: [
            Expanded(child: _dateField(tr('invoiceDate'), _date, () => _pickDate(false))),
            const SizedBox(width: 12),
            Expanded(child: _dateField(tr('dueDate'), _due, () => _pickDate(true))),
          ]),
          const SizedBox(height: 14),

          // البنود
          SectionCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(tr('items'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15))),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 38)),
                  onPressed: () => setState(() => _items.add(_ItemCtl())),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(tr('addItem')),
                ),
              ]),
              const SizedBox(height: 10),
              for (var i = 0; i < _items.length; i++) _itemRow(i, cur),
            ]),
          ),
          const SizedBox(height: 14),

          // الإجماليات
          SectionCard(
            child: Column(children: [
              _line(tr('subtotal'), money(_subtotal, cur)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: Text(tr('discount'))),
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: _discount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: Text(tr('taxRate'))),
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: _taxRate,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              _line(tr('tax'), money(_tax, cur)),
              const Divider(height: 24),
              Row(children: [
                Expanded(
                    child: Text(tr('grandTotal'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16))),
                Text(money(_total, cur),
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: cs.primary)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: Text(tr('paidAmount'))),
                SizedBox(
                  width: 130,
                  child: TextField(
                    controller: _paid,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              _line(tr('amountDueShort'), money(_total - _paidAmt, cur)),
            ]),
          ),
          const SizedBox(height: 14),

          SectionCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('notes'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 8),
              TextField(controller: _notes, maxLines: 4),
            ]),
          ),
          const SizedBox(height: 18),

          Row(children: [
            if (canDraft) ...[
              Expanded(
                child: OutlinedButton.icon(
                    onPressed: () => _save(true),
                    icon: const Icon(Icons.save_outlined),
                    label: Text(tr('saveDraft'))),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: FilledButton.icon(
                  onPressed: () => _save(false),
                  icon: Icon(_editing && !canDraft ? Icons.check : Icons.send),
                  label: Text(_editing && !canDraft ? tr('save') : tr('issue'))),
            ),
          ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _line(String a, String b) => Row(children: [
        Expanded(child: Text(a)),
        Text(b, style: const TextStyle(fontWeight: FontWeight.w700)),
      ]);

  Widget _dateField(String label, DateTime d, VoidCallback onTap) => SectionCard(
        padding: const EdgeInsets.all(12),
        child: InkWell(
          onTap: onTap,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                  child: Text(fmtDate(d),
                      style: const TextStyle(fontWeight: FontWeight.w700))),
              const Icon(Icons.calendar_today, size: 18),
            ]),
          ]),
        ),
      );

  Widget _itemRow(int i, String cur) {
    final it = _items[i];
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: TextField(
              controller: it.desc,
              decoration: InputDecoration(
                  hintText: tr('description'), fillColor: cs.surface),
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: cs.error),
            onPressed: _items.length == 1
                ? null
                : () => setState(() => _items.removeAt(i).dispose()),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: it.qty,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                  labelText: tr('qty'), fillColor: cs.surface),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextField(
              controller: it.price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                  labelText: '${tr('price')} (${currencySymbol(cur)})',
                  fillColor: cs.surface),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: it.disc,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                  labelText: tr('discountPct'), fillColor: cs.surface),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Text(tr('total'), style: TextStyle(color: cs.onSurfaceVariant))),
          Text(money(it.total, cur),
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
      ]),
    );
  }
}
