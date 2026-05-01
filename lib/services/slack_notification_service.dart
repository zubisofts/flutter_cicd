import 'dart:convert';
import 'dart:io';
import '../engine/pipeline_runner.dart';
import 'credential_store.dart';

class SlackNotificationService {
  final CredentialStore _creds;

  SlackNotificationService(this._creds);

  /// Loads webhook URL from Keychain and posts a build result message.
  /// Silently no-ops if disabled or unconfigured.
  Future<void> sendBuildResult({
    required RunRequest request,
    required bool success,
    required Duration duration,
  }) async {
    final config = await _creds.loadSlackConfig();
    if (!config.enabled || !config.isConfigured) return;
    await _post(config.webhookUrl, _buildPayload(request, success, duration));
  }

  /// Posts a test message to the given webhook URL (before it's saved).
  Future<void> sendTestMessage(String webhookUrl) async {
    if (webhookUrl.isEmpty) throw Exception('Webhook URL is required.');
    await _post(webhookUrl, {
      'blocks': [
        {
          'type': 'section',
          'text': {
            'type': 'mrkdwn',
            'text':
                ':white_check_mark: *FlutterCI* — Slack notifications are connected!',
          },
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
      if (res.statusCode != 200) {
        throw Exception('Slack returned HTTP ${res.statusCode}');
      }
    } finally {
      client.close();
    }
  }

  Map<String, dynamic> _buildPayload(
      RunRequest r, bool success, Duration duration) {
    final icon = success ? ':white_check_mark:' : ':x:';
    final statusText = success ? 'Build Succeeded' : 'Build Failed';
    final color = success ? '#3FB950' : '#F85149';
    final timestamp = DateTime.now().toLocal().toString().substring(0, 19);

    return {
      'attachments': [
        {
          'color': color,
          'blocks': [
            {
              'type': 'header',
              'text': {
                'type': 'plain_text',
                'text': '$icon  $statusText',
                'emoji': true,
              },
            },
            {
              'type': 'section',
              'fields': [
                {'type': 'mrkdwn', 'text': '*Project:*\n${r.projectName}'},
                {'type': 'mrkdwn', 'text': '*Environment:*\n${r.envName}'},
                {
                  'type': 'mrkdwn',
                  'text':
                      '*Version:*\n${r.versionName}+${r.buildNumber}',
                },
                {'type': 'mrkdwn', 'text': '*Branch:*\n${r.branch}'},
                {
                  'type': 'mrkdwn',
                  'text': '*Platforms:*\n${r.platforms.join(', ')}',
                },
                {'type': 'mrkdwn', 'text': '*Duration:*\n${_fmt(duration)}'},
              ],
            },
            {
              'type': 'context',
              'elements': [
                {
                  'type': 'mrkdwn',
                  'text': 'Completed at $timestamp · Sent by FlutterCI',
                },
              ],
            },
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
