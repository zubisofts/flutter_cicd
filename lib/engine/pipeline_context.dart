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

  void abort() => _aborted = true;

  String? artifactPath(String platform) =>
      state['artifact_$platform'] as String?;

  void putArtifact(String platform, String path) =>
      state['artifact_$platform'] = path;

  String get versionLabel =>
      '${environment.resolvedVersion}+${environment.buildNumber}';
}
