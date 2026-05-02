import 'dart:io';
import 'package:path/path.dart' as p;
import '../pipeline_context.dart';
import '../step_result.dart';
import '../../execution/exceptions.dart';
import '../../execution/log_line.dart';
import '../../execution/process_runner.dart';
import 'pipeline_step.dart';

class IosArchiveStep extends PipelineStep {
  final ProcessRunner _runner;

  IosArchiveStep(super.definition, {ProcessRunner? runner})
      : _runner = runner ?? ProcessRunner();

  @override
  Future<StepResult> execute(PipelineContext ctx) async {
    final env = ctx.environment;
    final iosConfig = env.iosConfig;
    final workspaceDir = ctx.workspaceDir;

    final xcworkspace =
        Directory(p.join(workspaceDir, 'ios', 'Runner.xcworkspace'));
    if (!await xcworkspace.exists()) {
      throw FatalPipelineException(
        stepId: id,
        message:
            'ios/Runner.xcworkspace not found. Run flutter pub get first.',
      );
    }

    final scheme =
        env.iosFlavor.isNotEmpty ? env.iosFlavor : env.name;
    final exportPath = p.join(workspaceDir, 'build', 'ios', 'ipa');
    final exportMethod =
        iosConfig.exportMethod.isNotEmpty ? iosConfig.exportMethod : 'app-store';

    ctx.logSink.addRaw(id, LogLevel.info,
        'Building & signing iOS IPA (scheme: $scheme, method: $exportMethod)...');

    // flutter build ipa handles Dart compilation + xcodebuild archive +
    // xcodebuild -exportArchive in one pass — no double-build.
    final useDefineFromFile = env.dartDefineFromFile.isNotEmpty;
    final buildResult = await _runner.run(
      command: [
        'flutter',
        'build',
        'ipa',
        '--release',
        '--export-method=$exportMethod',
        '--build-name=${env.resolvedVersion}',
        '--build-number=${env.buildNumber}',
        if (scheme.isNotEmpty) '--flavor=$scheme',
        if (useDefineFromFile)
          '--dart-define-from-file=${env.dartDefineFromFile}'
        else ...[
          '--dart-define=ENV=${env.name}',
          if (env.iosBundleId.isNotEmpty)
            '--dart-define=BUNDLE_ID=${env.iosBundleId}',
        ],
      ],
      workingDir: workspaceDir,
      environment: {
        ...env.shellEnv,
        if (iosConfig.teamId.isNotEmpty)
          'DEVELOPMENT_TEAM': iosConfig.teamId,
      },
      timeout: const Duration(minutes: 45),
      logSink: ctx.logSink,
      stepId: id,
      cancelSignal: ctx.abortSignal,
    );

    if (!buildResult.success) {
      throw FatalPipelineException(
        stepId: id,
        message: 'flutter build ipa failed (exit ${buildResult.exitCode})',
        exitCode: buildResult.exitCode,
      );
    }

    // Find the .ipa and register it (overwrites unsigned .app from build step)
    final ipaFile = Directory(exportPath)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.ipa'))
        .firstOrNull;

    if (ipaFile != null) {
      ctx.putArtifact('ios', ipaFile.path);
      ctx.logSink.addRaw(id, LogLevel.success, 'IPA: ${ipaFile.path}');
    } else {
      ctx.logSink.addRaw(
          id, LogLevel.warning, 'IPA not found in export path: $exportPath');
    }

    return StepResult.success(
        metadata: {'ipa_path': ipaFile?.path ?? ''});
  }


}
