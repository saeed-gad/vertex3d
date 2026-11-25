import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../services/app_state.dart';
import '../widgets/common.dart';
import 'client_form_screen.dart';
import 'clients_screen.dart';
import 'invoice_preview_screen.dart';

class ClientDetailScreen extends StatelessWidget {
  final String clientId;
  const ClientDetailScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = s.clientById(clientId);
    final cs = Theme.of(context).colorScheme;
    if (c == null) {
      return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
    }
    final co = s.company!;
    final list = s.invoices.where((i) => i.clientId == clientId).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('clientDetails')),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ClientFormScreen(existing: c))),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              if (await confirm(context, tr('confirmDelete'))) {
                s.deleteClient(c.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (c.phone.isNotEmpty)
                Text(c.displayPhone, textDirection: TextDirection.ltr),
              if (c.email.isNotEmpty)
                Text(c.email, textDirection: TextDirection.ltr),
              if (c.address.isNotEmpty) Text(c.address),
              const Divider(height: 24),
              Row(children: [
                Expanded(
                    child: Text(tr('totalDue'),
                        style: TextStyle(color: cs.onSurfaceVariant))),
                Text(money(clientOwed(s, c.id), co.currency),
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: cs.primary)),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          Text(tr('invoices'),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                  child: Text(tr('noInvoices'),
                      style: TextStyle(color: cs.onSurfaceVariant))),
            ),
          for (final inv in list)
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
