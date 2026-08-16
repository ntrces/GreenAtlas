import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateService {
  static const MethodChannel _appMetadataChannel =
      MethodChannel('com.example.greenatlas/app_updates');
  static const String _latestReleaseApi =
      'https://api.github.com/repos/ntrces/GreenAtlas/releases/latest';
  static const String _lastPromptedVersionKey =
      'github_update_last_prompted_version';
  static const String _lastPromptedAtKey = 'github_update_last_prompted_at';
  static const Duration _reminderDelay = Duration(hours: 24);

  static bool _checkedThisLaunch = false;

  static Future<void> checkAndPrompt(
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    if (_checkedThisLaunch || !Platform.isAndroid) return;
    _checkedThisLaunch = true;

    try {
      final update = await _fetchLatestRelease();
      if (update == null) return;

      final installedVersion =
          await _appMetadataChannel.invokeMethod<String>('getAppVersion');
      if (installedVersion == null ||
          !_isNewer(update.version, installedVersion)) {
        return;
      }

      final preferences = await SharedPreferences.getInstance();
      final lastVersion = preferences.getString(_lastPromptedVersionKey);
      final lastPromptedMilliseconds = preferences.getInt(_lastPromptedAtKey);
      final lastPromptedAt = lastPromptedMilliseconds == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastPromptedMilliseconds);

      if (lastVersion == update.version &&
          lastPromptedAt != null &&
          DateTime.now().difference(lastPromptedAt) < _reminderDelay) {
        return;
      }

      final context = navigatorKey.currentContext;
      if (context == null || !context.mounted) return;
      await _showUpdateDialog(context, update);
    } catch (error) {
      // Update checks must never prevent GreenAtlas from opening offline.
      debugPrint('Optional update check skipped: $error');
    }
  }

  static Future<_GitHubRelease?> _fetchLatestRelease() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.getUrl(Uri.parse(_latestReleaseApi));
      request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      request.headers.set(HttpHeaders.userAgentHeader, 'GreenAtlas-Android');

      final response = await request.close().timeout(const Duration(seconds: 10));
      if (response.statusCode != HttpStatus.ok) return null;

      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      if (json['draft'] == true || json['prerelease'] == true) return null;

      final tag = (json['tag_name'] as String? ?? '').trim();
      final version = _normaliseVersion(tag);
      if (version.isEmpty) return null;

      final assets = (json['assets'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>();
      final apkAssets = assets.where((asset) {
        final name = (asset['name'] as String? ?? '').toLowerCase();
        return name.endsWith('.apk');
      }).toList();

      final preferredAssets = apkAssets.where((asset) {
        final name = (asset['name'] as String? ?? '').toLowerCase();
        return name.contains('greenatlas') || name.contains('release');
      }).toList();
      final apkAsset = preferredAssets.isNotEmpty
          ? preferredAssets.first
          : (apkAssets.isNotEmpty ? apkAssets.first : null);
      final releasePage = (json['html_url'] as String? ?? '').trim();
      final downloadUrl =
          (apkAsset?['browser_download_url'] as String? ?? releasePage).trim();
      if (downloadUrl.isEmpty) return null;

      return _GitHubRelease(
        version: version,
        title: (json['name'] as String? ?? tag).trim(),
        notes: (json['body'] as String? ?? '').trim(),
        downloadUrl: Uri.parse(downloadUrl),
      );
    } finally {
      client.close(force: true);
    }
  }

  static Future<void> _showUpdateDialog(
    BuildContext context,
    _GitHubRelease update,
  ) async {
    final notes = update.notes.length > 500
        ? '${update.notes.substring(0, 500).trim()}…'
        : update.notes;

    final updateNow = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.system_update_alt_rounded),
        title: const Text('GreenAtlas update available'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                update.title.isEmpty
                    ? 'Version ${update.version}'
                    : '${update.title} • Version ${update.version}',
                style: Theme.of(dialogContext).textTheme.titleSmall,
              ),
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(notes),
              ],
              const SizedBox(height: 12),
              const Text(
                'Android will ask you to confirm the APK installation. Your GreenAtlas data will remain in place.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Later'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Update now'),
          ),
        ],
      ),
    );

    if (updateNow == true) {
      final opened = await launchUrl(
        update.downloadUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the update download. Try again later.'),
          ),
        );
      }
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_lastPromptedVersionKey, update.version);
    await preferences.setInt(
      _lastPromptedAtKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static bool _isNewer(String candidate, String installed) {
    final candidateParts = _versionParts(candidate);
    final installedParts = _versionParts(installed);
    final length = candidateParts.length > installedParts.length
        ? candidateParts.length
        : installedParts.length;

    for (var index = 0; index < length; index++) {
      final candidatePart =
          index < candidateParts.length ? candidateParts[index] : 0;
      final installedPart =
          index < installedParts.length ? installedParts[index] : 0;
      if (candidatePart != installedPart) return candidatePart > installedPart;
    }
    return false;
  }

  static List<int> _versionParts(String version) => _normaliseVersion(version)
      .split('.')
      .map((part) => int.tryParse(part) ?? 0)
      .toList();

  static String _normaliseVersion(String version) {
    final match = RegExp(r'\d+(?:\.\d+){0,3}').firstMatch(version);
    return match?.group(0) ?? '';
  }
}

class _GitHubRelease {
  final String version;
  final String title;
  final String notes;
  final Uri downloadUrl;

  const _GitHubRelease({
    required this.version,
    required this.title,
    required this.notes,
    required this.downloadUrl,
  });
}
