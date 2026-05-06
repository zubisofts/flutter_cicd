import 'dart:async';
import '../config/models/resolved_environment.dart';
import '../execution/log_sink.dart';

class PipelineContext {
  final String runId;
  final String projectId;
  final ResolvedEnvironment environment;
  final BuildOptions options;
  final String workspaceDir;
  final LogSink logSink;
  final Map<String, dynamic> state;
  bool _aborted = false;
  final Completer<void> _abortCompleter = Completer<void>();

  PipelineContext({
    required this.runId,
    required this.projectId,
    required this.environment,
    required this.options,
    required this.workspaceDir,
    required this.logSink,
    Map<String, dynamic>? state,
  }) : state = state ?? {};

  bool get isAborted => _aborted;

  /// Completes when [abort] is called — pass to ProcessRunner as a cancel signal
  /// so the running process is killed immediately rather than waiting to finish.
  Future<void> get abortSignal => _abortCompleter.future;

  void abort() {
    if (!_aborted) {
      _aborted = true;
      _abortCompleter.complete();
    }
  }

  String? artifactPath(String platform) =>
      state['artifact_$platform'] as String?;

  void putArtifact(String platform, String path) =>
      state['artifact_$platform'] = path;

  /// The build number to use for this run. Prefers the value written by
  /// ResolveBuildNumberStep (auto-incremented from the store), falls back
  /// to the number the user entered in the Setup screen.
  int get resolvedBuildNumber =>
      (state['resolved_build_number'] as int?) ?? environment.buildNumber;

  String get versionLabel =>
      '${environment.resolvedVersion}+$resolvedBuildNumber';
}
