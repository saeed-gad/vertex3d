import 'package:flutter/material.dart';

import '../l10n.dart';
import '../models.dart';
import '../theme.dart';

bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;

void toast(BuildContext c, String msg) {
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

String statusLabel(DisplayStatus s) {
  switch (s) {
    case DisplayStatus.paid:
      return tr('paid');
    case DisplayStatus.pending:
      return tr('pending');
    case DisplayStatus.overdue:
      return tr('overdue');
    case DisplayStatus.draft:
      return tr('draft');
  }
}

class StatusChip extends StatelessWidget {
  final DisplayStatus status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final st = statusStyle(status, isDark(context));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: st.bg, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: st.fg, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(statusLabel(status),
            style: TextStyle(
                color: st.fg, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class CompanyLogo extends StatelessWidget {
  final Company? company;
  final double size;
  const CompanyLogo(this.company, {super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final bytes = company?.logoBytes;
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 4),
      child: Container(
        width: size,
        height: size,
        color: cs.surfaceContainerHigh,
        child: bytes != null
            ? Image.memory(bytes, fit: BoxFit.cover)
            : Icon(Icons.business, size: size * .5, color: cs.primary),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const SectionCard(
      {super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) =>
      Card(child: Padding(padding: padding, child: child));
}

class Labeled extends StatelessWidget {
  final String label;
  final Widget child;
  const Labeled(this.label, this.child, {super.key});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          child,
        ],
      );
}

Future<bool> confirm(BuildContext context, String message) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(c, false), child: Text(tr('cancel'))),
        TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(tr('delete'),
                style: TextStyle(color: Theme.of(c).colorScheme.error))),
      ],
    ),
  );
  return r ?? false;
}

/// سطر فاتورة مختصر (للرئيسية وتفاصيل العميل).
class InvoiceTile extends StatelessWidget {
  final Invoice inv;
  final String currency;
  final VoidCallback onTap;
  const InvoiceTile(
      {super.key, required this.inv, required this.currency, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final st = statusStyle(inv.display, isDark(context));
    final initials = inv.clientName.trim().isEmpty
        ? '?'
        : inv.clientName.trim().characters.first;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            CircleAvatar(
                backgroundColor: st.bg,
                child: Text(initials,
                    style: TextStyle(color: st.fg, fontWeight: FontWeight.bold))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(inv.clientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text('${inv.number} • ${fmtDate(inv.date)}',
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(money(inv.total, currency),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                StatusChip(inv.display),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}
