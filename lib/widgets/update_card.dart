import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../l10n.dart';
import '../services/update_service.dart';
import 'common.dart';

Future<void> showUpdateDialog(BuildContext context, UpdateInfo info) {
  return showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(tr('updateAvailable', [info.build])),
      content: Text(tr('updateHint')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: Text(tr('later'))),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(110, 42)),
          onPressed: () {
            Navigator.pop(c);
            UpdateService.open(info.url);
          },
          child: Text(tr('updateNow')),
        ),
      ],
    ),
  );
}

/// فحص صامت عند فتح التطبيق: لو فيه تحديث يظهر ديالوج، وإلا ما يعملش حاجة.
Future<void> checkUpdateSilently(BuildContext context) async {
  try {
    final u = await UpdateService.check();
    if (u != null && context.mounted) await showUpdateDialog(context, u);
  } catch (_) {}
}

class UpdateCard extends StatefulWidget {
  const UpdateCard({super.key});
  @override
  State<UpdateCard> createState() => _UpdateCardState();
}

class _UpdateCardState extends State<UpdateCard> {
  bool _busy = false;
  String _version = '';
  String? _msg;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((p) {
      if (mounted) setState(() => _version = '${p.version} (${p.buildNumber})');
    });
  }

  Future<void> _check() async {
    setState(() {
      _busy = true;
      _msg = null;
    });
    try {
      final u = await UpdateService.check();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _msg = u == null ? tr('upToDate') : null;
      });
      if (u != null) await showUpdateDialog(context, u);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _msg = tr('updateFailed');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.system_update),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('updates'),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              if (_version.isNotEmpty)
                Text(tr('currentVersion', [_version]),
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _busy ? null : _check,
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.refresh),
          label: Text(_busy ? tr('checking') : tr('checkUpdate')),
        ),
        if (_msg != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(_msg!, style: TextStyle(color: cs.onSurfaceVariant)),
          ),
      ]),
    );
  }
}
