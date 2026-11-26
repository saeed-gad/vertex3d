import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n.dart';

/// قفل التطبيق ببصمة/PIN الموبايل. الإعداد محفوظ على الجهاز نفسه.
/// بيتقفل عند الفتح من جديد وبعد 15 ثانية في الخلفية، وبيمنع لقطات الشاشة.
class AppLock extends ChangeNotifier with WidgetsBindingObserver {
  static const _channel = MethodChannel('invoicer/secure');
  static const _graceSeconds = 15;

  final _auth = LocalAuthentication();
  bool enabled = false;
  bool locked = true; // مقفول لحد ما نعرف الإعداد
  bool ready = false;
  bool _authing = false;
  DateTime? _pausedAt;

  AppLock() {
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    try {
      final p = await SharedPreferences.getInstance();
      enabled = p.getBool('appLock') ?? false;
    } catch (_) {
      enabled = false;
    }
    locked = enabled;
    ready = true;
    await _applySecure();
    notifyListeners();
  }

  Future<void> _applySecure() async {
    try {
      await _channel.invokeMethod('setSecure', enabled);
    } catch (_) {}
  }

  Future<bool> _authenticate() async {
    if (_authing) return false;
    _authing = true;
    try {
      return await _auth.authenticate(
        localizedReason: tr('unlockPrompt'),
        options: const AuthenticationOptions(
            biometricOnly: false, stickyAuth: true),
      );
    } catch (_) {
      return false;
    } finally {
      _authing = false;
      _pausedAt = null;
    }
  }

  Future<bool> unlock() async {
    if (await _authenticate()) {
      locked = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// يرجّع نص الخطأ لو فشل، أو null لو نجح.
  Future<String?> setEnabled(bool v) async {
    if (v) {
      bool supported = false;
      try {
        supported = await _auth.isDeviceSupported();
      } catch (_) {}
      if (!supported) return tr('noDeviceLock');
    }
    if (!await _authenticate()) return tr('error');
    enabled = v;
    locked = false;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool('appLock', v);
    } catch (_) {}
    await _applySecure();
    notifyListeners();
    return null;
  }

  /// للخروج من الشاشة المقفولة عند تسجيل الخروج من الحساب.
  void releaseAfterSignOut() {
    locked = false;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_authing) return;
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed && enabled && _pausedAt != null) {
      if (DateTime.now().difference(_pausedAt!).inSeconds >= _graceSeconds) {
        locked = true;
        notifyListeners();
      }
      _pausedAt = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
