import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../models.dart';
import '../services/app_state.dart';
import '../services/pdf_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'invoice_form_screen.dart';
import 'invoice_preview_screen.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});
  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final _q = TextEditingController();
  DisplayStatus? _filter; // null = الكل

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final co = s.company!;
    final cs = Theme.of(context).colorScheme;
    final q = _q.text.trim().toLowerCase();

    final list = s.invoices.where((i) {
      if (_filter != null && i.display != _filter) return false;
      if (q.isEmpty) return true;
      return i.number.toLowerCase().contains(q) ||
          i.clientName.toLowerCase().contains(q);
    }).toList();

    int count(DisplayStatus? st) => st == null
        ? s.invoices.length
        : s.invoices.where((i) => i.display == st).length;

    Widget chip(String label, DisplayStatus? st) {
      final selected = _filter == st;
      return Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: ChoiceChip(
          selected: selected,
          showCheckmark: false,
          label: Text('$label  ${count(st)}'),
          onSelected: (_) => setState(() => _filter = st),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(tr('invoices'))),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _q,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: tr('searchInvoices'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: q.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(_q.clear)),
            ),
          ),
        ),
        SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              chip(tr('all'), null),
              chip(tr('paid'), DisplayStatus.paid),
              chip(tr('pending'), DisplayStatus.pending),
              chip(tr('overdue'), DisplayStatus.overdue),
              chip(tr('draft'), DisplayStatus.draft),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Text(tr('noInvoices'),
                      style: TextStyle(color: cs.onSurfaceVariant)))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _InvoiceCard(inv: list[i], co: co),
                ),
        ),
      ]),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Invoice inv;
  final Company co;
  const _InvoiceCard({required this.inv, required this.co});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final st = inv.display;
    final style = statusStyle(st, isDark(context));
    final app = context.read<AppState>();

    String sub;
    if (st == DisplayStatus.overdue) {
      final days = DateTime.now().difference(inv.dueDate).inDays;
      sub = tr('overdueBy', [days < 1 ? 1 : days]);
    } else {
      sub = tr('dueOn', [fmtDate(inv.dueDate)]);
    }

    void open() => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                InvoicePreviewScreen(invoiceId: inv.id, fallback: inv)));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: open,
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(width: 5, color: statusAccent(st)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(inv.number,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 15)),
                            const SizedBox(height: 2),
                            Text(inv.clientName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: cs.onSurfaceVariant, fontSize: 13)),
                          ]),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(money(inv.total, co.currency),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 4),
                      StatusChip(st),
                    ]),
                  ]),
                  const Divider(height: 18),
                  Row(children: [
                    Expanded(
                      child: Text(sub,
                          style: TextStyle(
                              fontSize: 12,
                              color: st == DisplayStatus.overdue
                                  ? style.fg
                                  : cs.onSurfaceVariant)),
                    ),
                    IconButton.filledTonal(
                      tooltip: tr('sendWhatsapp'),
                      style: IconButton.styleFrom(
                          backgroundColor: kWhatsapp.withValues(alpha: .18),
                          foregroundColor: kWhatsapp),
                      onPressed: () => PdfService.share(context, inv, co),
                      icon: const Icon(Icons.chat),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'view') open();
                        if (v == 'edit') {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => InvoiceFormScreen(existing: inv)));
                        }
                        if (v == 'paid') app.markPaid(inv);
                        if (v == 'delete' &&
                            await confirm(context, tr('confirmDelete'))) {
                          app.deleteInvoice(inv.id);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'view', child: Text(tr('view'))),
                        PopupMenuItem(value: 'edit', child: Text(tr('edit'))),
                        if (st != DisplayStatus.paid)
                          PopupMenuItem(
                              value: 'paid', child: Text(tr('markPaid'))),
                        PopupMenuItem(
                            value: 'delete', child: Text(tr('delete'))),
                      ],
                    ),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
