import 'dart:convert';
import 'dart:io';
import '../engine/pipeline_runner.dart';
import 'credential_store.dart';

class GoogleChatNotificationService {
  final CredentialStore _creds;

  GoogleChatNotificationService(this._creds);

  Future<void> sendBuildResult({
    required RunRequest request,
    required bool success,
    required Duration duration,
  }) async {
    final config = await _creds.loadGoogleChatConfig();
    if (!config.enabled || !config.isConfigured) return;
    await _post(config.webhookUrl, _buildPayload(request, success, duration));
  }

  Future<void> sendTestMessage(String webhookUrl) async {
    if (webhookUrl.isEmpty) throw Exception('Webhook URL is required.');
    await _post(webhookUrl, {
      'text': '*FlutterCI* — Google Chat notifications are connected! ✅',
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
        throw Exception('Google Chat returned HTTP ${res.statusCode}');
      }
    } finally {
      client.close();
    }
  }

  Map<String, dynamic> _buildPayload(
      RunRequest r, bool success, Duration duration) {
    final icon = success ? 'check_circle' : 'cancel';
    final statusText = success ? 'Build Succeeded' : 'Build Failed';
    final timestamp = DateTime.now().toLocal().toString().substring(0, 19);

    return {
      'cardsV2': [
        {
          'cardId': 'build-result',
          'card': {
            'header': {
              'title': statusText,
              'subtitle': '${r.projectName} — ${r.envName}',
              'imageType': 'CIRCLE',
              'imageUrl':
                  'https://fonts.gstatic.com/s/i/short-term/release/materialsymbolsrounded/$icon/default/48px.svg',
            },
            'sections': [
              {
                'widgets': [
                  {
                    'columns': {
                      'columnItems': [
                        {
                          'horizontalSizeStyle': 'FILL_AVAILABLE_SPACE',
                          'widgets': [
                            {
                              'decoratedText': {
                                'topLabel': 'Version',
                                'text': '${r.versionName}+${r.buildNumber}',
                              }
                            },
                            {
                              'decoratedText': {
                                'topLabel': 'Branch',
                                'text': r.branch,
                              }
                            },
                          ],
                        },
                        {
                          'horizontalSizeStyle': 'FILL_AVAILABLE_SPACE',
                          'widgets': [
                            {
                              'decoratedText': {
                                'topLabel': 'Platforms',
                                'text': r.platforms.join(', '),
                              }
                            },
                            {
                              'decoratedText': {
                                'topLabel': 'Duration',
                                'text': _fmt(duration),
                              }
                            },
                          ],
                        },
                      ],
                    },
                  },
                ],
              },
              {
                'widgets': [
                  {
                    'textParagraph': {
                      'text': 'Completed at $timestamp',
                    }
                  }
                ],
              },
            ],
          },
        },
      ],
    };
  }

  String _fmt(Duration d) {
    if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    return '${d.inSeconds}s';
  }
}
