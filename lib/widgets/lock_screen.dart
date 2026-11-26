import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n.dart';
import '../services/app_lock.dart';
import '../services/app_state.dart';
import '../theme.dart';

/// طبقة تغطي التطبيق كله وهو مقفول.
class LockOverlay extends StatelessWidget {
  final Widget child;
  const LockOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final lock = context.watch<AppLock>();
    return Stack(children: [
      child,
      if (!lock.ready)
        Positioned.fill(
            child: ColoredBox(color: Theme.of(context).colorScheme.surface)),
      if (lock.ready && lock.locked) const Positioned.fill(child: _LockScreen()),
    ]);
  }
}

class _LockScreen extends StatefulWidget {
  const _LockScreen();
  @override
  State<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<_LockScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppLock>().unlock();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                    color: kPrimary, borderRadius: BorderRadius.circular(26)),
                child: const Icon(Icons.lock, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 20),
              Text(tr('lockedTitle'),
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: () => context.read<AppLock>().unlock(),
                icon: const Icon(Icons.fingerprint),
                label: Text(tr('unlock')),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  context.read<AppState>().signOut();
                  context.read<AppLock>().releaseAfterSignOut();
                },
                child: Text(tr('signOut'),
                    style: TextStyle(color: cs.onSurfaceVariant)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
