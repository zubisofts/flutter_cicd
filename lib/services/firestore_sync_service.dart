import 'dart:convert';
import 'package:googleapis_auth/auth_io.dart' as gauth;
import 'package:http/http.dart' as http;
import 'credential_store.dart';

/// Syncs CI run records to Firestore after each pipeline completes.
///
/// Reuses the Firebase service account already stored in the Keychain
/// (the same one used for App Distribution). The project_id field inside
/// that JSON determines which Firestore database receives the data.
///
/// Collection: ci_runs/{runId}
/// All writes are best-effort — a Firestore failure never fails a build.
class FirestoreSyncService {
  final CredentialStore _credentials;

  FirestoreSyncService(this._credentials);

  Future<void> syncRun({
    required String runId,
    required String projectId,
    required String projectName,
    required String envName,
    required String branch,
    required String versionLabel,
    required List<String> platforms,
    required List<String> targets,
    required DateTime startedAt,
    required DateTime finishedAt,
    required bool success,
    required int durationSeconds,
    String? errorMessage,
    required List<StepSyncRecord> steps,
  }) async {
    try {
      final serviceAccountJson = await _credentials.loadFirebaseServiceAccount();
      if (serviceAccountJson.isEmpty) return;

      final accountData = jsonDecode(serviceAccountJson) as Map<String, dynamic>;
      final firestoreProjectId = accountData['project_id'] as String?;
      if (firestoreProjectId == null || firestoreProjectId.isEmpty) return;

      final credentials =
          gauth.ServiceAccountCredentials.fromJson(serviceAccountJson);
      final authClient = await gauth.clientViaServiceAccount(
        credentials,
        ['https://www.googleapis.com/auth/datastore'],
        baseClient: http.Client(),
      );

      try {
        final url =
            'https://firestore.googleapis.com/v1/projects/$firestoreProjectId'
            '/databases/(default)/documents/ci_runs/$runId';

        final body = jsonEncode({
          'fields': {
            'runId': _str(runId),
            'projectId': _str(projectId),
            'projectName': _str(projectName),
            'envName': _str(envName),
            'branch': _str(branch),
            'versionLabel': _str(versionLabel),
            'platforms': _strArray(platforms),
            'targets': _strArray(targets),
            'startedAt': _ts(startedAt),
            'finishedAt': _ts(finishedAt),
            'durationSeconds': _int(durationSeconds),
            'success': _bool(success),
            if (errorMessage != null && errorMessage.isNotEmpty)
              'errorMessage': _str(errorMessage),
            'steps': _stepsArray(steps),
          },
        });

        await authClient.patch(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: body,
        );
      } finally {
        authClient.close();
      }
    } catch (_) {
      // Best-effort — never surface Firestore errors to the user.
    }
  }

  // ── Firestore field encoders ──────────────────────────────────────────────

  static Map<String, dynamic> _str(String v) => {'stringValue': v};
  static Map<String, dynamic> _int(int v) => {'integerValue': '$v'};
  static Map<String, dynamic> _bool(bool v) => {'booleanValue': v};
  static Map<String, dynamic> _ts(DateTime dt) =>
      {'timestampValue': dt.toUtc().toIso8601String()};

  static Map<String, dynamic> _strArray(List<String> values) => {
        'arrayValue': {
          'values': values.map(_str).toList(),
        },
      };

  static Map<String, dynamic> _stepsArray(List<StepSyncRecord> steps) => {
        'arrayValue': {
          'values': steps
              .map((s) => {
                    'mapValue': {
                      'fields': {
                        'stepId': _str(s.stepId),
                        'stepName': _str(s.stepName),
                        'status': _str(s.status),
                        'durationSeconds': _int(s.durationSeconds),
                        if (s.errorMessage != null &&
                            s.errorMessage!.isNotEmpty)
                          'errorMessage': _str(s.errorMessage!),
                      },
                    },
                  })
              .toList(),
        },
      };
}

class StepSyncRecord {
  final String stepId;
  final String stepName;
  final String status;
  final int durationSeconds;
  final String? errorMessage;

  const StepSyncRecord({
    required this.stepId,
    required this.stepName,
    required this.status,
    required this.durationSeconds,
    this.errorMessage,
  });
}
