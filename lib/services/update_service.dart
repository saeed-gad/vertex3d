import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateInfo {
  final int build;
  final String tag;
  final String url;
  UpdateInfo(this.build, this.tag, this.url);
}

/// يتحقق من آخر Release على GitHub (الوسم بيكون build-N ورقم البناء N).
/// لو الريبو Private لازم UPDATE_TOKEN (توكن قراءة فقط) يتمرر وقت البناء.
class UpdateService {
  static const repo = 'saeed-gad/vertex3d';
  static const _token = String.fromEnvironment('UPDATE_TOKEN');

  static Future<int> currentBuild() async {
    final p = await PackageInfo.fromPlatform();
    return int.tryParse(p.buildNumber) ?? 0;
  }

  static Future<UpdateInfo?> latest() async {
    final r = await http.get(
      Uri.parse('https://api.github.com/repos/$repo/releases/latest'),
      headers: {
        'Accept': 'application/vnd.github+json',
        if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
      },
    ).timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    final tag = (j['tag_name'] ?? '') as String;
    final build = int.tryParse(tag.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    String url = (j['html_url'] ?? '') as String;
    if (_token.isEmpty) {
      for (final a in (j['assets'] ?? []) as List) {
        final name = (a['name'] ?? '') as String;
        if (name.endsWith('.apk')) {
          url = a['browser_download_url'] as String;
          break;
        }
      }
    }
    return UpdateInfo(build, tag, url);
  }

  /// يرجّع التحديث لو فيه إصدار أحدث، وإلا null. يرمي استثناء لو فشل الاتصال.
  static Future<UpdateInfo?> check() async {
    final cur = await currentBuild();
    final l = await latest();
    return (l != null && l.build > cur) ? l : null;
  }

  static Future<void> open(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
