import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'exceptions.dart';
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

/// Shell environment vars captured from the user's interactive login shell.
/// GUI apps on macOS inherit a minimal environment from launchd — not the
/// user's full shell session — so PATH, SSH_AUTH_SOCK, etc. are missing.
class _ShellEnv {
  final String path;
  final String? sshAuthSock;
  const _ShellEnv({required this.path, this.sshAuthSock});
}

Future<_ShellEnv> _resolveShellEnv() async {
  const fallbackPath = '/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:'
      '/usr/sbin:/sbin';
  try {
    // Print PATH and SSH_AUTH_SOCK separated by a NUL so we can split safely
    // even if either value contains newlines (PATH sometimes does on broken configs).
    final result = await Process.run(
      '/bin/zsh',
      ['-ilc', r'printf "%s\0%s" "$PATH" "$SSH_AUTH_SOCK"'],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    // zsh -il may emit shell init noise before our printf; take the last line.
    final raw = (result.stdout as String).trim().split('\n').last.trim();
    final parts = raw.split('\x00');
    final path = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0] : fallbackPath;
    final sock = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;
    return _ShellEnv(path: path, sshAuthSock: sock);
  } catch (_) {}
  return _ShellEnv(
    path: '$fallbackPath:${Platform.environment['HOME'] ?? ''}/flutter/bin:'
        '${Platform.environment['PATH'] ?? ''}',
  );
}

_ShellEnv? _cachedShellEnv;

Future<_ShellEnv> _shellEnv() async {
  _cachedShellEnv ??= await _resolveShellEnv();
  return _cachedShellEnv!;
}

/// Returns the SSH_AUTH_SOCK from the user's interactive shell, if available.
/// Useful for bare [Process.run] calls that bypass [ProcessRunner].
Future<Map<String, String>> sshAgentEnv() async {
  final env = await _shellEnv();
  if (env.sshAuthSock != null) return {'SSH_AUTH_SOCK': env.sshAuthSock!};
  return {};
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
    /// When this future completes the running process is killed immediately
    /// and [PipelineAbortedException] is thrown.
    Future<void>? cancelSignal,
  }) async {
    // Merge platform env with shell env. The user's interactive zsh session
    // knows PATH, SSH_AUTH_SOCK, etc. — GUI apps launched from Finder/Dock
    // don't inherit these, so git (and other tools) fail to find SSH keys.
    final shell = await _shellEnv();
    final mergedEnv = {
      ...Platform.environment,
      ...environment,
      'PATH': shell.path,
      // Forward the SSH agent socket so git can authenticate over SSH.
      // Caller-supplied environment takes precedence if already set.
      if (shell.sshAuthSock != null && !environment.containsKey('SSH_AUTH_SOCK'))
        'SSH_AUTH_SOCK': shell.sshAuthSock!,
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

    // Register abort handler AFTER process starts so proc is always valid.
    bool killedByAbort = false;
    if (cancelSignal != null) {
      cancelSignal.then((_) {
        killedByAbort = true;
        try { proc.kill(ProcessSignal.sigterm); } catch (_) {}
        // Hard-kill if still alive after 5 s
        Future<void>.delayed(const Duration(seconds: 5), () {
          try { proc.kill(ProcessSignal.sigkill); } catch (_) {}
        });
      });
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

    if (killedByAbort) throw const PipelineAbortedException();

    return ProcessResult(
      exitCode: exitCode,
      output: buffer,
      success: exitCode == 0,
    );
  }
}
