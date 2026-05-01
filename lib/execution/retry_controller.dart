import 'log_line.dart';
import 'log_sink.dart';
import 'exceptions.dart';
import '../config/models/pipeline_definition.dart';

class RetryController {
  static Future<T> withRetry<T>({
    required Future<T> Function() fn,
    required RetryPolicy policy,
    required LogSink logSink,
    required String stepId,
  }) async {
    int attempt = 0;
    while (true) {
      try {
        return await fn();
      } on RetryableStepException catch (e) {
        attempt++;
        if (attempt >= policy.maxAttempts) rethrow;
        logSink.add(LogLine(
          stepId: stepId,
          level: LogLevel.warning,
          message:
              'Step failed (attempt $attempt/${policy.maxAttempts}), '
              'retrying in ${policy.delaySeconds}s... (${e.message})',
          timestamp: DateTime.now(),
        ));
        await Future.delayed(Duration(seconds: policy.delaySeconds));
      }
    }
  }
}
