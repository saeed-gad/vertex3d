import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../models.dart';
import '../services/app_state.dart';
import '../services/pdf_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'invoice_form_screen.dart';

class InvoicePreviewScreen extends StatelessWidget {
  final String invoiceId;
  final Invoice fallback;
  const InvoicePreviewScreen(
      {super.key, required this.invoiceId, required this.fallback});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final co = app.company;
    final inv = app.invoiceById(invoiceId);
    if (co == null) return const SizedBox.shrink();
    // لو لسه ما وصلتش من الـ stream نستخدم النسخة المحلية
    final i = inv ?? fallback;
    final cs = Theme.of(context).colorScheme;
    final st = i.display;
    final style = statusStyle(st, isDark(context));
    final cur = co.currency;

    Widget kv(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Expanded(child: Text(k, style: TextStyle(color: cs.onSurfaceVariant))),
            Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
        );

    return Scaffold(
      appBar: AppBar(title: Text(tr('invoiceDetails'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: style.bg, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Icon(
                  st == DisplayStatus.paid
                      ? Icons.check_circle
                      : st == DisplayStatus.overdue
                          ? Icons.warning_amber_rounded
                          : st == DisplayStatus.draft
                              ? Icons.edit_note
                              : Icons.schedule,
                  color: style.fg,
                  size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(statusLabel(st),
                      style: TextStyle(
                          color: style.fg,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                  Text(i.number, style: TextStyle(color: style.fg)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 14),

          // ورقة الفاتورة
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CompanyLogo(co, size: 56),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(co.name,
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: cs.primary)),
                      if (co.address.isNotEmpty)
                        Text(co.address,
                            style: TextStyle(color: cs.onSurfaceVariant)),
                      if (co.phone.isNotEmpty)
                        Text(co.phone,
                            textDirection: TextDirection.ltr,
                            style: TextStyle(color: cs.onSurfaceVariant)),
                      if (co.taxNumber.isNotEmpty)
                        Text('${tr('taxNumber')}: ${co.taxNumber}',
                            style: TextStyle(color: cs.onSurfaceVariant)),
                    ]),
                  ),
                ]),
                const Divider(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(tr('billTo'),
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                    Text(i.clientName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    if (i.clientAddress.isNotEmpty) Text(i.clientAddress),
                    if (i.clientPhone.isNotEmpty)
                      Text(i.clientPhone, textDirection: TextDirection.ltr),
                    const Divider(height: 20),
                    kv(tr('issueDate'), fmtDate(i.date)),
                    kv(tr('dueDate'), fmtDate(i.dueDate)),
                  ]),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    Expanded(
                        flex: 5,
                        child: Text(tr('statement'),
                            style: const TextStyle(fontWeight: FontWeight.w700))),
                    Expanded(
                        flex: 2,
                        child: Text(tr('qty'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w700))),
                    Expanded(
                        flex: 3,
                        child: Text(tr('total'),
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontWeight: FontWeight.w700))),
                  ]),
                ),
                for (final it in i.items)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: cs.outlineVariant.withValues(alpha: .5)))),
                    child: Row(children: [
                      Expanded(flex: 5, child: Text(it.description)),
                      Expanded(
                          flex: 2,
                          child: Text(fmtNum(it.qty), textAlign: TextAlign.center)),
                      Expanded(
                          flex: 3,
                          child: Text(fmtNum(it.total), textAlign: TextAlign.end)),
                    ]),
                  ),
                const SizedBox(height: 12),
                kv(tr('subtotal'), money(i.subtotal, cur)),
                if (i.discount > 0) kv(tr('discount'), '- ${money(i.discount, cur)}'),
                kv('${tr('tax')} (${fmtNum(i.taxRate)}%)', money(i.tax, cur)),
                const Divider(height: 20),
                Row(children: [
                  Expanded(
                      child: Text(tr('grandTotal'),
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: cs.primary))),
                  Text(money(i.total, cur),
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: cs.primary)),
                ]),
                if (i.paidEff > 0) ...[
                  const SizedBox(height: 8),
                  kv(tr('paidAmount'), money(i.paidEff, cur)),
                  kv(tr('amountDue'), money(i.due, cur)),
                ],
                if (i.notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: isDark(context)
                            ? const Color(0xFF3A2A12)
                            : const Color(0xFFFFF4E8),
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(tr('notes'),
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(i.notes),
                    ]),
                  ),
                ],
              ]),
            ),
          ),
          const SizedBox(height: 16),

          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: kWhatsapp),
            onPressed: () => PdfService.share(context, i, co),
            icon: const Icon(Icons.chat),
            label: Text(tr('sendWhatsapp')),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                  onPressed: () => PdfService.share(context, i, co),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(tr('sharePdf'))),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                  onPressed: () => PdfService.printInvoice(context, i, co),
                  icon: const Icon(Icons.print_outlined),
                  label: Text(tr('print'))),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: st == DisplayStatus.paid
                        ? cs.outline
                        : const Color(0xFF006C49)),
                onPressed: st == DisplayStatus.paid
                    ? null
                    : () {
                        app.markPaid(i);
                        toast(context, tr('saved'));
                      },
                icon: const Icon(Icons.done_all),
                label: Text(tr('markPaid')),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => InvoiceFormScreen(existing: i))),
                icon: const Icon(Icons.edit),
                label: Text(tr('edit')),
              ),
            ),
          ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
