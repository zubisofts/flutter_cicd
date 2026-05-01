import 'dart:convert';
import 'dart:io';
import '../engine/pipeline_runner.dart';
import 'credential_store.dart';

class TeamsNotificationService {
  final CredentialStore _creds;

  TeamsNotificationService(this._creds);

  Future<void> sendBuildResult({
    required RunRequest request,
    required bool success,
    required Duration duration,
  }) async {
    final config = await _creds.loadTeamsConfig();
    if (!config.enabled || !config.isConfigured) return;
    await _post(config.webhookUrl, _buildPayload(request, success, duration));
  }

  Future<void> sendTestMessage(String webhookUrl) async {
    if (webhookUrl.isEmpty) throw Exception('Webhook URL is required.');
    await _post(webhookUrl, {
      '@type': 'MessageCard',
      '@context': 'http://schema.org/extensions',
      'themeColor': '3FB950',
      'summary': 'FlutterCI connected',
      'sections': [
        {
          'activityTitle':
              '**FlutterCI** — Microsoft Teams notifications are connected!',
        },
      ],
    });
  }

  Future<void> _post(String url, Map<String, dynamic> payload) async {
    final uri = Uri.parse(url);
    final body = utf8.encode(jsonEncode(payload));
    final client = HttpClient();
    try {
      final req = await client.postUrl(uri);
      req.headers.set(
          HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      req.contentLength = body.length;
      req.add(body);
      final res = await req.close();
      await res.drain<void>();
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('Teams returned HTTP ${res.statusCode}');
      }
    } finally {
      client.close();
    }
  }

  Map<String, dynamic> _buildPayload(
      RunRequest r, bool success, Duration duration) {
    final color = success ? '3FB950' : 'F85149';
    final statusText = success ? 'Build Succeeded' : 'Build Failed';
    final timestamp = DateTime.now().toLocal().toString().substring(0, 19);

    return {
      '@type': 'MessageCard',
      '@context': 'http://schema.org/extensions',
      'themeColor': color,
      'summary': '$statusText: ${r.projectName}',
      'sections': [
        {
          'activityTitle': '**$statusText** — ${r.projectName}',
          'facts': [
            {'name': 'Environment', 'value': r.envName},
            {'name': 'Version', 'value': '${r.versionName}+${r.buildNumber}'},
            {'name': 'Branch', 'value': r.branch},
            {'name': 'Platforms', 'value': r.platforms.join(', ')},
            {'name': 'Duration', 'value': _fmt(duration)},
            {'name': 'Completed at', 'value': timestamp},
          ],
        },
      ],
    };
  }

  String _fmt(Duration d) {
    if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    return '${d.inSeconds}s';
  }
}
