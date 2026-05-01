class PipelineDefinition {
  final String name;
  final String description;
  final List<StepDefinition> steps;

  const PipelineDefinition({
    required this.name,
    required this.description,
    required this.steps,
  });

  factory PipelineDefinition.fromMap(Map map) {
    final rawSteps = map['steps'] as List? ?? [];
    return PipelineDefinition(
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      steps: rawSteps
          .map((s) => StepDefinition.fromMap(s as Map))
          .toList(),
    );
  }
}

class StepDefinition {
  final String id;
  final String type;
  final String name;
  final bool abortOnFailure;
  final String? condition;
  final List<String> dependsOn;
  final Map<String, dynamic> params;
  final RetryPolicy? retry;

  const StepDefinition({
    required this.id,
    required this.type,
    required this.name,
    required this.abortOnFailure,
    this.condition,
    required this.dependsOn,
    required this.params,
    this.retry,
  });

  factory StepDefinition.fromMap(Map map) {
    final rawParams = map['params'] as Map?;
    final paramsMap = <String, dynamic>{};
    if (rawParams != null) {
      rawParams.forEach((k, v) => paramsMap[k.toString()] = v);
    }

    final rawDepends = map['depends_on'] as List?;
    final deps = rawDepends?.map((e) => e.toString()).toList() ?? [];

    final rawRetry = map['retry'] as Map?;

    return StepDefinition(
      id: map['id'] as String,
      type: map['type'] as String,
      name: map['name'] as String? ?? map['id'] as String,
      abortOnFailure: map['abort_on_failure'] != false,
      condition: map['condition'] as String?,
      dependsOn: deps,
      params: paramsMap,
      retry:
          rawRetry != null ? RetryPolicy.fromMap(rawRetry) : null,
    );
  }
}

class RetryPolicy {
  final int maxAttempts;
  final int delaySeconds;

  const RetryPolicy({
    required this.maxAttempts,
    required this.delaySeconds,
  });

  factory RetryPolicy.fromMap(Map map) => RetryPolicy(
        maxAttempts: map['max_attempts'] as int? ?? 3,
        delaySeconds: map['delay_seconds'] as int? ?? 5,
      );
}
