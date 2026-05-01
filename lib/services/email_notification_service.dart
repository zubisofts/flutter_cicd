import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../engine/pipeline_runner.dart';
import 'credential_store.dart';

class EmailNotificationService {
  final CredentialStore _creds;

  EmailNotificationService(this._creds);

  /// Loads SMTP config from Keychain and sends a build result email.
  /// Silently no-ops if notifications are disabled or not configured.
  Future<void> sendBuildResult({
    required RunRequest request,
    required bool success,
    required Duration duration,
  }) async {
    final config = await _creds.loadSmtpConfig();
    if (!config.enabled || !config.isConfigured) return;
    await _send(config: config, subject: _subject(request, success), html: _html(request, success, duration));
  }

  /// Sends a test email using the provided config (before it's saved).
  Future<void> sendTestEmail(SmtpConfig config) async {
    if (!config.isConfigured) {
      throw Exception('Host and recipient are required.');
    }
    final dummyRequest = RunRequest(
      projectId: 'test',
      projectName: 'Test Project',
      branch: 'main',
      envName: 'staging',
      versionName: '1.0.0',
      buildNumber: 0,
      platforms: const ['ios', 'android'],
      targets: const [],
    );
    await _send(
      config: config,
      subject: '[FlutterCI] Test notification',
      html: _html(dummyRequest, true, const Duration(seconds: 42)),
    );
  }

  Future<void> _send({
    required SmtpConfig config,
    required String subject,
    required String html,
  }) async {
    final smtpServer = SmtpServer(
      config.host,
      port: config.port,
      ssl: config.useSsl,
      username: config.username.isNotEmpty ? config.username : null,
      password: config.password.isNotEmpty ? config.password : null,
    );
    final message = Message()
      ..from = Address(
          config.username.isNotEmpty ? config.username : 'noreply',
          'FlutterCI')
      ..recipients.add(config.recipient)
      ..subject = subject
      ..html = html;
    await send(message, smtpServer);
  }

  String _subject(RunRequest r, bool success) {
    final icon = success ? '✓' : '✗';
    final status = success ? 'succeeded' : 'FAILED';
    return '[FlutterCI] $icon ${r.projectName} ${r.envName} '
        '${r.versionName}+${r.buildNumber} — $status';
  }

  String _html(RunRequest r, bool success, Duration duration) {
    final statusText = success ? 'Succeeded' : 'Failed';
    final statusColor = success ? '#3FB950' : '#F85149';
    final statusIcon = success ? '✓' : '✗';
    final timestamp = DateTime.now().toLocal().toString().substring(0, 19);

    return '''<!DOCTYPE html>
<html>
<body style="margin:0;padding:0;background:#0D1117;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;">
  <div style="max-width:560px;margin:32px auto;background:#161B22;border-radius:10px;border:1px solid #30363D;overflow:hidden;">
    <div style="background:${statusColor}22;border-bottom:1px solid #30363D;padding:20px 24px;">
      <span style="font-size:28px;margin-right:12px;">$statusIcon</span>
      <span style="font-size:18px;font-weight:700;color:$statusColor;vertical-align:middle;">Build $statusText</span>
    </div>
    <div style="padding:24px;">
      <table style="width:100%;border-collapse:collapse;">
        ${_row('Project', r.projectName)}
        ${_row('Environment', r.envName)}
        ${_row('Version', '${r.versionName}+${r.buildNumber}')}
        ${_row('Branch', r.branch)}
        ${_row('Platforms', r.platforms.join(', '))}
        ${_row('Duration', _fmt(duration))}
        ${_row('Completed at', timestamp)}
      </table>
    </div>
    <div style="padding:12px 24px;border-top:1px solid #30363D;text-align:center;">
      <span style="font-size:11px;color:#484F58;">Sent by FlutterCI</span>
    </div>
  </div>
</body>
</html>''';
  }

  String _row(String label, String value) =>
      '<tr>'
      '<td style="padding:7px 0;color:#8B949E;font-size:13px;width:130px;vertical-align:top;">$label</td>'
      '<td style="padding:7px 0;color:#E6EDF3;font-size:13px;font-weight:500;">$value</td>'
      '</tr>';

  String _fmt(Duration d) {
    if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    return '${d.inSeconds}s';
  }
}
