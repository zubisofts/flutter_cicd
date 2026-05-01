import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'log_line.dart';

class LogSink {
  final StreamController<LogLine> _controller =
      StreamController<LogLine>.broadcast();
  IOSink? _fileSink;

  Stream<LogLine> get stream => _controller.stream;

  Future<void> openFile(String runId, String baseDir) async {
    final logDir = Directory(p.join(baseDir, 'runs', runId));
    await logDir.create(recursive: true);
    final logFile = File(p.join(logDir.path, 'run.log'));
    _fileSink = logFile.openWrite(mode: FileMode.write);
  }

  void add(LogLine line) {
    if (!_controller.isClosed) {
      _controller.add(line);
      _fileSink?.writeln(line.toString());
    }
  }

  void addRaw(String stepId, LogLevel level, String message) {
    add(LogLine(
      stepId: stepId,
      level: level,
      message: message,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> close() async {
    await _fileSink?.flush();
    await _fileSink?.close();
    await _controller.close();
  }
}
