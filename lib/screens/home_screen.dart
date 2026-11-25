import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'invoice_preview_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onViewAll;
  const HomeScreen({super.key, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final co = s.company!;
    final cs = Theme.of(context).colorScheme;
    final dark = isDark(context);

    final real = s.invoices.where((i) => i.display != DisplayStatus.draft);
    final paid = s.totalPaid;
    final pending = s.dueFor(DisplayStatus.pending);
    final overdue = s.dueFor(DisplayStatus.overdue);
    final total = s.totalBilled;
    final pct = total == 0 ? 0 : (paid / total * 100).round();
    final recent = s.invoices.take(5).toList();

    Widget stat(String label, double v, IconData icon, DisplayStatus? st) {
      final style = st == null ? null : statusStyle(st, dark);
      return Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: style?.bg ?? cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, size: 20, color: style?.fg ?? cs.primary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: style?.fg ?? cs.onSurfaceVariant)),
                ),
              ]),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(money(v, co.currency),
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(co.name, overflow: TextOverflow.ellipsis),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: Center(child: CompanyLogo(co, size: 34)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr('hello'),
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                Text(co.name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
              ]),
            ),
            Chip(
              avatar: Icon(s.synced ? Icons.cloud_done : Icons.cloud_sync,
                  size: 18, color: s.synced ? kGreen : cs.tertiary),
              label: Text(s.synced ? tr('synced') : tr('notSynced'),
                  style: const TextStyle(fontSize: 12)),
              side: BorderSide.none,
              backgroundColor: cs.surfaceContainerHigh,
            ),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [kPrimary, kPrimaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF6CF8BB),
                  child: const Icon(Icons.trending_up, color: kGreen, size: 30)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr('quickReport'),
                      style: const TextStyle(
                          color: Color(0xFF90A8FF), fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(tr('collectedPct', [pct]),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 6,
                      backgroundColor: Colors.white24,
                      color: const Color(0xFF6CF8BB),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          Row(children: [
            stat(tr('totalInvoices'), total, Icons.receipt_long, null),
            const SizedBox(width: 12),
            stat(tr('paid'), paid, Icons.check_circle_outline, DisplayStatus.paid),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            stat(tr('pending'), pending, Icons.schedule, DisplayStatus.pending),
            const SizedBox(width: 12),
            stat(tr('overdue'), overdue, Icons.warning_amber_rounded,
                DisplayStatus.overdue),
          ]),
          const SizedBox(height: 22),
          Row(children: [
            Expanded(
              child: Text(tr('recent'),
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800)),
            ),
            TextButton(onPressed: onViewAll, child: Text(tr('viewAll'))),
          ]),
          const SizedBox(height: 6),
          if (real.isEmpty && recent.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                  child: Text(tr('noInvoices'),
                      style: TextStyle(color: cs.onSurfaceVariant))),
            ),
          for (final inv in recent)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InvoiceTile(
                inv: inv,
                currency: co.currency,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => InvoicePreviewScreen(
                            invoiceId: inv.id, fallback: inv))),
              ),
            ),
        ],
      ),
    );
  }
}
