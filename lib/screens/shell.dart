import 'package:flutter/material.dart';

import '../l10n.dart';
import 'clients_screen.dart';
import 'home_screen.dart';
import 'invoice_form_screen.dart';
import 'invoices_screen.dart';
import 'settings_screen.dart';
import '../widgets/update_card.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _i = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => checkUpdateSilently(context));
  }

  void goTo(int i) => setState(() => _i = i);

  void _newInvoice() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const InvoiceFormScreen()));

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onViewAll: () => goTo(1)),
      const InvoicesScreen(),
      const ClientsScreen(),
      const SettingsScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _i, children: pages),
      floatingActionButton: (_i == 0 || _i == 1)
          ? FloatingActionButton.extended(
              onPressed: _newInvoice,
              icon: const Icon(Icons.add),
              label: Text(tr('newInvoice')),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: goTo,
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: tr('home')),
          NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              selectedIcon: const Icon(Icons.receipt_long),
              label: tr('invoices')),
          NavigationDestination(
              icon: const Icon(Icons.groups_outlined),
              selectedIcon: const Icon(Icons.groups),
              label: tr('clients')),
          NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: tr('settings')),
        ],
      ),
    );
  }
}
