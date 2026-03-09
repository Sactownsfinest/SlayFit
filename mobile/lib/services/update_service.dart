import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class UpdateInfo {
  final String version;
  final String downloadUrl;
  const UpdateInfo({required this.version, required this.downloadUrl});
}

class UpdateService {
  static const _owner = 'Sactownsfinest';
  static const _repo = 'SlayFit';

  /// Returns [UpdateInfo] if a newer release exists on GitHub, otherwise null.
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final current = info.version; // e.g. "1.0.0"

      final response = await http
          .get(
            Uri.parse(
                'https://api.github.com/repos/$_owner/$_repo/releases/latest'),
            headers: {'Accept': 'application/vnd.github.v3+json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rawTag = data['tag_name'] as String? ?? '';
      final latest = rawTag.replaceFirst(RegExp(r'^v'), '');

      if (!_isNewer(latest, current)) return null;

      final assets = (data['assets'] as List? ?? []);
      final apkAsset = assets.cast<Map<String, dynamic>>().firstWhere(
            (a) => (a['name'] as String).endsWith('.apk'),
            orElse: () => {},
          );

      final url = apkAsset['browser_download_url'] as String?;
      if (url == null || url.isEmpty) return null;

      return UpdateInfo(version: latest, downloadUrl: url);
    } catch (e) {
      debugPrint('[UpdateService] checkForUpdate error: $e');
      return null;
    }
  }

  /// Downloads the APK and opens the system installer.
  /// [onProgress] receives values 0.0–1.0.
  static Future<void> downloadAndInstall(
    String url, {
    void Function(double)? onProgress,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/slayfit_update.apk');

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final streamed = await client.send(request);
      final total = streamed.contentLength ?? 0;
      int received = 0;

      final sink = file.openWrite();
      await streamed.stream.map((chunk) {
        received += chunk.length;
        if (total > 0) onProgress?.call(received / total);
        return chunk;
      }).pipe(sink);
    } finally {
      client.close();
    }

    await OpenFile.open(file.path);
  }

  // ── Semver comparison ─────────────────────────────────────────────────────

  static bool _isNewer(String latest, String current) {
    try {
      final l = _parse(latest);
      final c = _parse(current);
      for (int i = 0; i < l.length && i < c.length; i++) {
        if (l[i] > c[i]) return true;
        if (l[i] < c[i]) return false;
      }
      return l.length > c.length;
    } catch (_) {
      return false;
    }
  }

  static List<int> _parse(String v) =>
      v.split('.').map((s) => int.tryParse(s) ?? 0).toList();
}
