import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'log_line.dart';
import 'log_sink.dart';

class ProcessResult {
  final int exitCode;
  final List<String> output;
  final bool success;

  const ProcessResult({
    required this.exitCode,
    required this.output,
    required this.success,
  });
}

/// Resolves the user's shell PATH by running `zsh -ilc echo $PATH`.
/// GUI apps on macOS inherit a minimal /usr/bin PATH, not the user's
/// shell PATH, so flutter/fastlane/firebase won't be found without this.
Future<String> _resolveShellPath() async {
  try {
    final result = await Process.run(
      '/bin/zsh',
      ['-ilc', 'echo \$PATH'],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    final path = (result.stdout as String).trim().split('\n').last.trim();
    if (path.isNotEmpty) return path;
  } catch (_) {}
  // Fallback: common tool locations
  return '/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:'
      '/usr/sbin:/sbin:${Platform.environment['HOME']}/flutter/bin:'
      '${Platform.environment['PATH'] ?? ''}';
}

String? _cachedPath;

Future<String> _shellPath() async {
  _cachedPath ??= await _resolveShellPath();
  return _cachedPath!;
}

/// Cache of resolved executable paths (e.g. 'fastlane' → '/opt/homebrew/bin/fastlane').
final Map<String, String> _resolvedExecutables = {};

/// Resolves [name] to its absolute path using the user's shell PATH.
/// On macOS, `Process.start` uses the parent app's minimal PATH for the
/// executable lookup even when a custom environment is provided, so tools
/// installed via Homebrew/rbenv/gems are not found unless we resolve them first.
Future<String> _resolveExecutable(String name) async {
  if (name.startsWith('/')) return name; // already absolute
  if (_resolvedExecutables.containsKey(name)) return _resolvedExecutables[name]!;
  try {
    final result = await Process.run(
      '/bin/zsh',
      ['-lc', 'which $name'],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    final path = (result.stdout as String).trim().split('\n').last.trim();
    if (path.isNotEmpty && path.startsWith('/')) {
      _resolvedExecutables[name] = path;
      return path;
    }
  } catch (_) {}
  return name; // fall back to name and let the OS error naturally
}

class ProcessRunner {
  Future<ProcessResult> run({
    required List<String> command,
    required String workingDir,
    Map<String, String> environment = const {},
    Duration timeout = const Duration(minutes: 30),
    LogSink? logSink,
    String stepId = 'process',
    /// When set, only lines for which this returns true are sent to [logSink].
    /// Lines are always captured in the result buffer regardless.
    bool Function(String line)? lineFilter,
  }) async {
    // Merge: resolved shell PATH takes precedence over the app's inherited PATH
    final shellPath = await _shellPath();
    final mergedEnv = {
      ...Platform.environment,
      ...environment,
      'PATH': shellPath,
    };

    // Resolve the executable to an absolute path using the shell so that tools
    // installed via Homebrew / rbenv / RubyGems are found even from a GUI app.
    final executable = await _resolveExecutable(command.first);

    final buffer = <String>[];

    Process proc;
    try {
      proc = await Process.start(
        executable,
        command.sublist(1),
        workingDirectory: workingDir,
        environment: mergedEnv,
        runInShell: false,
      );
    } catch (e) {
      throw Exception(
          'Failed to start process "${command.join(' ')}": $e');
    }

    final stdoutDone = Completer<void>();
    final stderrDone = Completer<void>();

    proc.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) {
            buffer.add(line);
            if (lineFilter == null || lineFilter(line)) {
              logSink?.add(LogLine(
                stepId: stepId,
                level: LogLevel.info,
                message: line,
                timestamp: DateTime.now(),
              ));
            }
          },
          onDone: stdoutDone.complete,
          onError: (_) => stdoutDone.complete(),
        );

    proc.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) {
            buffer.add(line);
            if (lineFilter == null || lineFilter(line)) {
              logSink?.add(LogLine(
                stepId: stepId,
                level: LogLevel.error,
                message: line,
                timestamp: DateTime.now(),
              ));
            }
          },
          onDone: stderrDone.complete,
          onError: (_) => stderrDone.complete(),
        );

    int exitCode;
    try {
      await Future.wait([stdoutDone.future, stderrDone.future]);
      exitCode = await proc.exitCode.timeout(
        timeout,
        onTimeout: () {
          proc.kill(ProcessSignal.sigterm);
          throw TimeoutException(
              'Command timed out after ${timeout.inMinutes}m: '
              '${command.join(' ')}');
        },
      );
    } on TimeoutException {
      rethrow;
    }

    return ProcessResult(
      exitCode: exitCode,
      output: buffer,
      success: exitCode == 0,
    );
  }
}
