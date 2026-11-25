import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'client_detail_screen.dart';
import 'client_form_screen.dart';

double clientOwed(AppState s, String clientId) => s.invoices
    .where((i) =>
        i.clientId == clientId &&
        (i.display == DisplayStatus.pending ||
            i.display == DisplayStatus.overdue))
    .fold(0.0, (a, i) => a + i.due);

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});
  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _q = TextEditingController();

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
    final dark = isDark(context);
    final q = _q.text.trim().toLowerCase();
    final list = s.clients
        .where((c) =>
            q.isEmpty ||
            c.name.toLowerCase().contains(q) ||
            c.phone.contains(q) ||
            c.email.toLowerCase().contains(q))
        .toList();
    final totalOwed = s.invoices
        .where((i) =>
            i.display == DisplayStatus.pending ||
            i.display == DisplayStatus.overdue)
        .fold(0.0, (a, i) => a + i.due);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('clients')),
        actions: [
          IconButton(
            tooltip: tr('addClient'),
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ClientFormScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _q,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
                hintText: tr('searchClients'),
                prefixIcon: const Icon(Icons.search)),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: dark ? const Color(0xFF1E2A55) : const Color(0xFFDCE1FF),
                borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr('totalDue'),
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(money(totalOwed, co.currency),
                      style: TextStyle(
                          color: cs.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                ]),
              ),
              Text(tr('clientsCount', [s.clients.length]),
                  style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(height: 14),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                  child: Text(tr('noClients'),
                      style: TextStyle(color: cs.onSurfaceVariant))),
            ),
          for (final c in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ClientCard(client: c),
            ),
        ],
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final Client client;
  const _ClientCard({required this.client});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final co = s.company!;
    final cs = Theme.of(context).colorScheme;
    final owed = clientOwed(s, client.id);
    final hasOverdue = s.invoices.any(
        (i) => i.clientId == client.id && i.display == DisplayStatus.overdue);
    final count = s.invoices.where((i) => i.clientId == client.id).length;
    final st = owed == 0
        ? DisplayStatus.paid
        : (hasOverdue ? DisplayStatus.overdue : DisplayStatus.pending);
    final style = statusStyle(st, isDark(context));

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ClientDetailScreen(clientId: client.id))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: style.bg,
              child: Text(client.name.trim().isEmpty ? '?' : client.name.trim()[0],
                  style: TextStyle(
                      color: style.fg, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(client.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                if (client.phone.isNotEmpty)
                  Text(client.displayPhone,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                Text(tr('invoicesCount', [count]),
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(money(owed, co.currency),
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: owed == 0 ? cs.onSurface : style.fg)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                    color: style.bg, borderRadius: BorderRadius.circular(20)),
                child: Text(owed == 0 ? tr('settled') : tr('owed'),
                    style: TextStyle(
                        color: style.fg,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
