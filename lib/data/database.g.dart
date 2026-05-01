// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $RunRecordsTable extends RunRecords
    with TableInfo<$RunRecordsTable, RunRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RunRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectNameMeta = const VerificationMeta(
    'projectName',
  );
  @override
  late final GeneratedColumn<String> projectName = GeneratedColumn<String>(
    'project_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _envNameMeta = const VerificationMeta(
    'envName',
  );
  @override
  late final GeneratedColumn<String> envName = GeneratedColumn<String>(
    'env_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchMeta = const VerificationMeta('branch');
  @override
  late final GeneratedColumn<String> branch = GeneratedColumn<String>(
    'branch',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionLabelMeta = const VerificationMeta(
    'versionLabel',
  );
  @override
  late final GeneratedColumn<String> versionLabel = GeneratedColumn<String>(
    'version_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _platformsMeta = const VerificationMeta(
    'platforms',
  );
  @override
  late final GeneratedColumn<String> platforms = GeneratedColumn<String>(
    'platforms',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetsMeta = const VerificationMeta(
    'targets',
  );
  @override
  late final GeneratedColumn<String> targets = GeneratedColumn<String>(
    'targets',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> startedAt =
      GeneratedColumn<int>(
        'started_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($RunRecordsTable.$converterstartedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> finishedAt =
      GeneratedColumn<int>(
        'finished_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($RunRecordsTable.$converterfinishedAt);
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _successMeta = const VerificationMeta(
    'success',
  );
  @override
  late final GeneratedColumn<bool> success = GeneratedColumn<bool>(
    'success',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("success" IN (0, 1))',
    ),
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    projectName,
    envName,
    branch,
    versionLabel,
    platforms,
    targets,
    startedAt,
    finishedAt,
    durationSeconds,
    success,
    errorMessage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'run_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<RunRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('project_name')) {
      context.handle(
        _projectNameMeta,
        projectName.isAcceptableOrUnknown(
          data['project_name']!,
          _projectNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_projectNameMeta);
    }
    if (data.containsKey('env_name')) {
      context.handle(
        _envNameMeta,
        envName.isAcceptableOrUnknown(data['env_name']!, _envNameMeta),
      );
    } else if (isInserting) {
      context.missing(_envNameMeta);
    }
    if (data.containsKey('branch')) {
      context.handle(
        _branchMeta,
        branch.isAcceptableOrUnknown(data['branch']!, _branchMeta),
      );
    } else if (isInserting) {
      context.missing(_branchMeta);
    }
    if (data.containsKey('version_label')) {
      context.handle(
        _versionLabelMeta,
        versionLabel.isAcceptableOrUnknown(
          data['version_label']!,
          _versionLabelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_versionLabelMeta);
    }
    if (data.containsKey('platforms')) {
      context.handle(
        _platformsMeta,
        platforms.isAcceptableOrUnknown(data['platforms']!, _platformsMeta),
      );
    } else if (isInserting) {
      context.missing(_platformsMeta);
    }
    if (data.containsKey('targets')) {
      context.handle(
        _targetsMeta,
        targets.isAcceptableOrUnknown(data['targets']!, _targetsMeta),
      );
    } else if (isInserting) {
      context.missing(_targetsMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('success')) {
      context.handle(
        _successMeta,
        success.isAcceptableOrUnknown(data['success']!, _successMeta),
      );
    } else if (isInserting) {
      context.missing(_successMeta);
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RunRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RunRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      projectName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_name'],
      )!,
      envName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}env_name'],
      )!,
      branch: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch'],
      )!,
      versionLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version_label'],
      )!,
      platforms: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}platforms'],
      )!,
      targets: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}targets'],
      )!,
      startedAt: $RunRecordsTable.$converterstartedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}started_at'],
        )!,
      ),
      finishedAt: $RunRecordsTable.$converterfinishedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}finished_at'],
        ),
      ),
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      ),
      success: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}success'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
    );
  }

  @override
  $RunRecordsTable createAlias(String alias) {
    return $RunRecordsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterstartedAt =
      const DateTimeConverter();
  static TypeConverter<DateTime?, int?> $converterfinishedAt =
      const NullableDateTimeConverter();
}

class RunRecord extends DataClass implements Insertable<RunRecord> {
  final String id;
  final String projectId;
  final String projectName;
  final String envName;
  final String branch;
  final String versionLabel;
  final String platforms;
  final String targets;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int? durationSeconds;
  final bool success;
  final String? errorMessage;
  const RunRecord({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.envName,
    required this.branch,
    required this.versionLabel,
    required this.platforms,
    required this.targets,
    required this.startedAt,
    this.finishedAt,
    this.durationSeconds,
    required this.success,
    this.errorMessage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['project_name'] = Variable<String>(projectName);
    map['env_name'] = Variable<String>(envName);
    map['branch'] = Variable<String>(branch);
    map['version_label'] = Variable<String>(versionLabel);
    map['platforms'] = Variable<String>(platforms);
    map['targets'] = Variable<String>(targets);
    {
      map['started_at'] = Variable<int>(
        $RunRecordsTable.$converterstartedAt.toSql(startedAt),
      );
    }
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<int>(
        $RunRecordsTable.$converterfinishedAt.toSql(finishedAt),
      );
    }
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    map['success'] = Variable<bool>(success);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    return map;
  }

  RunRecordsCompanion toCompanion(bool nullToAbsent) {
    return RunRecordsCompanion(
      id: Value(id),
      projectId: Value(projectId),
      projectName: Value(projectName),
      envName: Value(envName),
      branch: Value(branch),
      versionLabel: Value(versionLabel),
      platforms: Value(platforms),
      targets: Value(targets),
      startedAt: Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      success: Value(success),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
    );
  }

  factory RunRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RunRecord(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      projectName: serializer.fromJson<String>(json['projectName']),
      envName: serializer.fromJson<String>(json['envName']),
      branch: serializer.fromJson<String>(json['branch']),
      versionLabel: serializer.fromJson<String>(json['versionLabel']),
      platforms: serializer.fromJson<String>(json['platforms']),
      targets: serializer.fromJson<String>(json['targets']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      success: serializer.fromJson<bool>(json['success']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'projectName': serializer.toJson<String>(projectName),
      'envName': serializer.toJson<String>(envName),
      'branch': serializer.toJson<String>(branch),
      'versionLabel': serializer.toJson<String>(versionLabel),
      'platforms': serializer.toJson<String>(platforms),
      'targets': serializer.toJson<String>(targets),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'success': serializer.toJson<bool>(success),
      'errorMessage': serializer.toJson<String?>(errorMessage),
    };
  }

  RunRecord copyWith({
    String? id,
    String? projectId,
    String? projectName,
    String? envName,
    String? branch,
    String? versionLabel,
    String? platforms,
    String? targets,
    DateTime? startedAt,
    Value<DateTime?> finishedAt = const Value.absent(),
    Value<int?> durationSeconds = const Value.absent(),
    bool? success,
    Value<String?> errorMessage = const Value.absent(),
  }) => RunRecord(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    projectName: projectName ?? this.projectName,
    envName: envName ?? this.envName,
    branch: branch ?? this.branch,
    versionLabel: versionLabel ?? this.versionLabel,
    platforms: platforms ?? this.platforms,
    targets: targets ?? this.targets,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
    success: success ?? this.success,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
  );
  RunRecord copyWithCompanion(RunRecordsCompanion data) {
    return RunRecord(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      projectName: data.projectName.present
          ? data.projectName.value
          : this.projectName,
      envName: data.envName.present ? data.envName.value : this.envName,
      branch: data.branch.present ? data.branch.value : this.branch,
      versionLabel: data.versionLabel.present
          ? data.versionLabel.value
          : this.versionLabel,
      platforms: data.platforms.present ? data.platforms.value : this.platforms,
      targets: data.targets.present ? data.targets.value : this.targets,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      success: data.success.present ? data.success.value : this.success,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RunRecord(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('projectName: $projectName, ')
          ..write('envName: $envName, ')
          ..write('branch: $branch, ')
          ..write('versionLabel: $versionLabel, ')
          ..write('platforms: $platforms, ')
          ..write('targets: $targets, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('success: $success, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    projectName,
    envName,
    branch,
    versionLabel,
    platforms,
    targets,
    startedAt,
    finishedAt,
    durationSeconds,
    success,
    errorMessage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RunRecord &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.projectName == this.projectName &&
          other.envName == this.envName &&
          other.branch == this.branch &&
          other.versionLabel == this.versionLabel &&
          other.platforms == this.platforms &&
          other.targets == this.targets &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt &&
          other.durationSeconds == this.durationSeconds &&
          other.success == this.success &&
          other.errorMessage == this.errorMessage);
}

class RunRecordsCompanion extends UpdateCompanion<RunRecord> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> projectName;
  final Value<String> envName;
  final Value<String> branch;
  final Value<String> versionLabel;
  final Value<String> platforms;
  final Value<String> targets;
  final Value<DateTime> startedAt;
  final Value<DateTime?> finishedAt;
  final Value<int?> durationSeconds;
  final Value<bool> success;
  final Value<String?> errorMessage;
  final Value<int> rowid;
  const RunRecordsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.projectName = const Value.absent(),
    this.envName = const Value.absent(),
    this.branch = const Value.absent(),
    this.versionLabel = const Value.absent(),
    this.platforms = const Value.absent(),
    this.targets = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.success = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RunRecordsCompanion.insert({
    required String id,
    required String projectId,
    required String projectName,
    required String envName,
    required String branch,
    required String versionLabel,
    required String platforms,
    required String targets,
    required DateTime startedAt,
    this.finishedAt = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    required bool success,
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       projectName = Value(projectName),
       envName = Value(envName),
       branch = Value(branch),
       versionLabel = Value(versionLabel),
       platforms = Value(platforms),
       targets = Value(targets),
       startedAt = Value(startedAt),
       success = Value(success);
  static Insertable<RunRecord> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? projectName,
    Expression<String>? envName,
    Expression<String>? branch,
    Expression<String>? versionLabel,
    Expression<String>? platforms,
    Expression<String>? targets,
    Expression<int>? startedAt,
    Expression<int>? finishedAt,
    Expression<int>? durationSeconds,
    Expression<bool>? success,
    Expression<String>? errorMessage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (projectName != null) 'project_name': projectName,
      if (envName != null) 'env_name': envName,
      if (branch != null) 'branch': branch,
      if (versionLabel != null) 'version_label': versionLabel,
      if (platforms != null) 'platforms': platforms,
      if (targets != null) 'targets': targets,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (success != null) 'success': success,
      if (errorMessage != null) 'error_message': errorMessage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RunRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? projectId,
    Value<String>? projectName,
    Value<String>? envName,
    Value<String>? branch,
    Value<String>? versionLabel,
    Value<String>? platforms,
    Value<String>? targets,
    Value<DateTime>? startedAt,
    Value<DateTime?>? finishedAt,
    Value<int?>? durationSeconds,
    Value<bool>? success,
    Value<String?>? errorMessage,
    Value<int>? rowid,
  }) {
    return RunRecordsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      envName: envName ?? this.envName,
      branch: branch ?? this.branch,
      versionLabel: versionLabel ?? this.versionLabel,
      platforms: platforms ?? this.platforms,
      targets: targets ?? this.targets,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      success: success ?? this.success,
      errorMessage: errorMessage ?? this.errorMessage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (projectName.present) {
      map['project_name'] = Variable<String>(projectName.value);
    }
    if (envName.present) {
      map['env_name'] = Variable<String>(envName.value);
    }
    if (branch.present) {
      map['branch'] = Variable<String>(branch.value);
    }
    if (versionLabel.present) {
      map['version_label'] = Variable<String>(versionLabel.value);
    }
    if (platforms.present) {
      map['platforms'] = Variable<String>(platforms.value);
    }
    if (targets.present) {
      map['targets'] = Variable<String>(targets.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(
        $RunRecordsTable.$converterstartedAt.toSql(startedAt.value),
      );
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<int>(
        $RunRecordsTable.$converterfinishedAt.toSql(finishedAt.value),
      );
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (success.present) {
      map['success'] = Variable<bool>(success.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RunRecordsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('projectName: $projectName, ')
          ..write('envName: $envName, ')
          ..write('branch: $branch, ')
          ..write('versionLabel: $versionLabel, ')
          ..write('platforms: $platforms, ')
          ..write('targets: $targets, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('success: $success, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StepRecordsTable extends StepRecords
    with TableInfo<$StepRecordsTable, StepRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StepRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pkMeta = const VerificationMeta('pk');
  @override
  late final GeneratedColumn<int> pk = GeneratedColumn<int>(
    'pk',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  @override
  late final GeneratedColumn<String> runId = GeneratedColumn<String>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES run_records (id)',
    ),
  );
  static const VerificationMeta _stepIdMeta = const VerificationMeta('stepId');
  @override
  late final GeneratedColumn<String> stepId = GeneratedColumn<String>(
    'step_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stepNameMeta = const VerificationMeta(
    'stepName',
  );
  @override
  late final GeneratedColumn<String> stepName = GeneratedColumn<String>(
    'step_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusIndexMeta = const VerificationMeta(
    'statusIndex',
  );
  @override
  late final GeneratedColumn<int> statusIndex = GeneratedColumn<int>(
    'status_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    pk,
    runId,
    stepId,
    stepName,
    statusIndex,
    durationSeconds,
    errorMessage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'step_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<StepRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('pk')) {
      context.handle(_pkMeta, pk.isAcceptableOrUnknown(data['pk']!, _pkMeta));
    }
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('step_id')) {
      context.handle(
        _stepIdMeta,
        stepId.isAcceptableOrUnknown(data['step_id']!, _stepIdMeta),
      );
    } else if (isInserting) {
      context.missing(_stepIdMeta);
    }
    if (data.containsKey('step_name')) {
      context.handle(
        _stepNameMeta,
        stepName.isAcceptableOrUnknown(data['step_name']!, _stepNameMeta),
      );
    } else if (isInserting) {
      context.missing(_stepNameMeta);
    }
    if (data.containsKey('status_index')) {
      context.handle(
        _statusIndexMeta,
        statusIndex.isAcceptableOrUnknown(
          data['status_index']!,
          _statusIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_statusIndexMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {pk};
  @override
  StepRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StepRecord(
      pk: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pk'],
      )!,
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_id'],
      )!,
      stepId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}step_id'],
      )!,
      stepName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}step_name'],
      )!,
      statusIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status_index'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      ),
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
    );
  }

  @override
  $StepRecordsTable createAlias(String alias) {
    return $StepRecordsTable(attachedDatabase, alias);
  }
}

class StepRecord extends DataClass implements Insertable<StepRecord> {
  final int pk;
  final String runId;
  final String stepId;
  final String stepName;
  final int statusIndex;
  final int? durationSeconds;
  final String? errorMessage;
  const StepRecord({
    required this.pk,
    required this.runId,
    required this.stepId,
    required this.stepName,
    required this.statusIndex,
    this.durationSeconds,
    this.errorMessage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pk'] = Variable<int>(pk);
    map['run_id'] = Variable<String>(runId);
    map['step_id'] = Variable<String>(stepId);
    map['step_name'] = Variable<String>(stepName);
    map['status_index'] = Variable<int>(statusIndex);
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    return map;
  }

  StepRecordsCompanion toCompanion(bool nullToAbsent) {
    return StepRecordsCompanion(
      pk: Value(pk),
      runId: Value(runId),
      stepId: Value(stepId),
      stepName: Value(stepName),
      statusIndex: Value(statusIndex),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
    );
  }

  factory StepRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StepRecord(
      pk: serializer.fromJson<int>(json['pk']),
      runId: serializer.fromJson<String>(json['runId']),
      stepId: serializer.fromJson<String>(json['stepId']),
      stepName: serializer.fromJson<String>(json['stepName']),
      statusIndex: serializer.fromJson<int>(json['statusIndex']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'pk': serializer.toJson<int>(pk),
      'runId': serializer.toJson<String>(runId),
      'stepId': serializer.toJson<String>(stepId),
      'stepName': serializer.toJson<String>(stepName),
      'statusIndex': serializer.toJson<int>(statusIndex),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'errorMessage': serializer.toJson<String?>(errorMessage),
    };
  }

  StepRecord copyWith({
    int? pk,
    String? runId,
    String? stepId,
    String? stepName,
    int? statusIndex,
    Value<int?> durationSeconds = const Value.absent(),
    Value<String?> errorMessage = const Value.absent(),
  }) => StepRecord(
    pk: pk ?? this.pk,
    runId: runId ?? this.runId,
    stepId: stepId ?? this.stepId,
    stepName: stepName ?? this.stepName,
    statusIndex: statusIndex ?? this.statusIndex,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
  );
  StepRecord copyWithCompanion(StepRecordsCompanion data) {
    return StepRecord(
      pk: data.pk.present ? data.pk.value : this.pk,
      runId: data.runId.present ? data.runId.value : this.runId,
      stepId: data.stepId.present ? data.stepId.value : this.stepId,
      stepName: data.stepName.present ? data.stepName.value : this.stepName,
      statusIndex: data.statusIndex.present
          ? data.statusIndex.value
          : this.statusIndex,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StepRecord(')
          ..write('pk: $pk, ')
          ..write('runId: $runId, ')
          ..write('stepId: $stepId, ')
          ..write('stepName: $stepName, ')
          ..write('statusIndex: $statusIndex, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    pk,
    runId,
    stepId,
    stepName,
    statusIndex,
    durationSeconds,
    errorMessage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StepRecord &&
          other.pk == this.pk &&
          other.runId == this.runId &&
          other.stepId == this.stepId &&
          other.stepName == this.stepName &&
          other.statusIndex == this.statusIndex &&
          other.durationSeconds == this.durationSeconds &&
          other.errorMessage == this.errorMessage);
}

class StepRecordsCompanion extends UpdateCompanion<StepRecord> {
  final Value<int> pk;
  final Value<String> runId;
  final Value<String> stepId;
  final Value<String> stepName;
  final Value<int> statusIndex;
  final Value<int?> durationSeconds;
  final Value<String?> errorMessage;
  const StepRecordsCompanion({
    this.pk = const Value.absent(),
    this.runId = const Value.absent(),
    this.stepId = const Value.absent(),
    this.stepName = const Value.absent(),
    this.statusIndex = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.errorMessage = const Value.absent(),
  });
  StepRecordsCompanion.insert({
    this.pk = const Value.absent(),
    required String runId,
    required String stepId,
    required String stepName,
    required int statusIndex,
    this.durationSeconds = const Value.absent(),
    this.errorMessage = const Value.absent(),
  }) : runId = Value(runId),
       stepId = Value(stepId),
       stepName = Value(stepName),
       statusIndex = Value(statusIndex);
  static Insertable<StepRecord> custom({
    Expression<int>? pk,
    Expression<String>? runId,
    Expression<String>? stepId,
    Expression<String>? stepName,
    Expression<int>? statusIndex,
    Expression<int>? durationSeconds,
    Expression<String>? errorMessage,
  }) {
    return RawValuesInsertable({
      if (pk != null) 'pk': pk,
      if (runId != null) 'run_id': runId,
      if (stepId != null) 'step_id': stepId,
      if (stepName != null) 'step_name': stepName,
      if (statusIndex != null) 'status_index': statusIndex,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (errorMessage != null) 'error_message': errorMessage,
    });
  }

  StepRecordsCompanion copyWith({
    Value<int>? pk,
    Value<String>? runId,
    Value<String>? stepId,
    Value<String>? stepName,
    Value<int>? statusIndex,
    Value<int?>? durationSeconds,
    Value<String?>? errorMessage,
  }) {
    return StepRecordsCompanion(
      pk: pk ?? this.pk,
      runId: runId ?? this.runId,
      stepId: stepId ?? this.stepId,
      stepName: stepName ?? this.stepName,
      statusIndex: statusIndex ?? this.statusIndex,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (pk.present) {
      map['pk'] = Variable<int>(pk.value);
    }
    if (runId.present) {
      map['run_id'] = Variable<String>(runId.value);
    }
    if (stepId.present) {
      map['step_id'] = Variable<String>(stepId.value);
    }
    if (stepName.present) {
      map['step_name'] = Variable<String>(stepName.value);
    }
    if (statusIndex.present) {
      map['status_index'] = Variable<int>(statusIndex.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StepRecordsCompanion(')
          ..write('pk: $pk, ')
          ..write('runId: $runId, ')
          ..write('stepId: $stepId, ')
          ..write('stepName: $stepName, ')
          ..write('statusIndex: $statusIndex, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RunRecordsTable runRecords = $RunRecordsTable(this);
  late final $StepRecordsTable stepRecords = $StepRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [runRecords, stepRecords];
}

typedef $$RunRecordsTableCreateCompanionBuilder =
    RunRecordsCompanion Function({
      required String id,
      required String projectId,
      required String projectName,
      required String envName,
      required String branch,
      required String versionLabel,
      required String platforms,
      required String targets,
      required DateTime startedAt,
      Value<DateTime?> finishedAt,
      Value<int?> durationSeconds,
      required bool success,
      Value<String?> errorMessage,
      Value<int> rowid,
    });
typedef $$RunRecordsTableUpdateCompanionBuilder =
    RunRecordsCompanion Function({
      Value<String> id,
      Value<String> projectId,
      Value<String> projectName,
      Value<String> envName,
      Value<String> branch,
      Value<String> versionLabel,
      Value<String> platforms,
      Value<String> targets,
      Value<DateTime> startedAt,
      Value<DateTime?> finishedAt,
      Value<int?> durationSeconds,
      Value<bool> success,
      Value<String?> errorMessage,
      Value<int> rowid,
    });

final class $$RunRecordsTableReferences
    extends BaseReferences<_$AppDatabase, $RunRecordsTable, RunRecord> {
  $$RunRecordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$StepRecordsTable, List<StepRecord>>
  _stepRecordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.stepRecords,
    aliasName: $_aliasNameGenerator(db.runRecords.id, db.stepRecords.runId),
  );

  $$StepRecordsTableProcessedTableManager get stepRecordsRefs {
    final manager = $$StepRecordsTableTableManager(
      $_db,
      $_db.stepRecords,
    ).filter((f) => f.runId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_stepRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RunRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $RunRecordsTable> {
  $$RunRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get envName => $composableBuilder(
    column: $table.envName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branch => $composableBuilder(
    column: $table.branch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get versionLabel => $composableBuilder(
    column: $table.versionLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get platforms => $composableBuilder(
    column: $table.platforms,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targets => $composableBuilder(
    column: $table.targets,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get startedAt =>
      $composableBuilder(
        column: $table.startedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get finishedAt =>
      $composableBuilder(
        column: $table.finishedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get success => $composableBuilder(
    column: $table.success,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> stepRecordsRefs(
    Expression<bool> Function($$StepRecordsTableFilterComposer f) f,
  ) {
    final $$StepRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stepRecords,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StepRecordsTableFilterComposer(
            $db: $db,
            $table: $db.stepRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RunRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $RunRecordsTable> {
  $$RunRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get envName => $composableBuilder(
    column: $table.envName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branch => $composableBuilder(
    column: $table.branch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get versionLabel => $composableBuilder(
    column: $table.versionLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get platforms => $composableBuilder(
    column: $table.platforms,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targets => $composableBuilder(
    column: $table.targets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get success => $composableBuilder(
    column: $table.success,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RunRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RunRecordsTable> {
  $$RunRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get envName =>
      $composableBuilder(column: $table.envName, builder: (column) => column);

  GeneratedColumn<String> get branch =>
      $composableBuilder(column: $table.branch, builder: (column) => column);

  GeneratedColumn<String> get versionLabel => $composableBuilder(
    column: $table.versionLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get platforms =>
      $composableBuilder(column: $table.platforms, builder: (column) => column);

  GeneratedColumn<String> get targets =>
      $composableBuilder(column: $table.targets, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get finishedAt =>
      $composableBuilder(
        column: $table.finishedAt,
        builder: (column) => column,
      );

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get success =>
      $composableBuilder(column: $table.success, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  Expression<T> stepRecordsRefs<T extends Object>(
    Expression<T> Function($$StepRecordsTableAnnotationComposer a) f,
  ) {
    final $$StepRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stepRecords,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StepRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.stepRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RunRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RunRecordsTable,
          RunRecord,
          $$RunRecordsTableFilterComposer,
          $$RunRecordsTableOrderingComposer,
          $$RunRecordsTableAnnotationComposer,
          $$RunRecordsTableCreateCompanionBuilder,
          $$RunRecordsTableUpdateCompanionBuilder,
          (RunRecord, $$RunRecordsTableReferences),
          RunRecord,
          PrefetchHooks Function({bool stepRecordsRefs})
        > {
  $$RunRecordsTableTableManager(_$AppDatabase db, $RunRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RunRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RunRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RunRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> projectName = const Value.absent(),
                Value<String> envName = const Value.absent(),
                Value<String> branch = const Value.absent(),
                Value<String> versionLabel = const Value.absent(),
                Value<String> platforms = const Value.absent(),
                Value<String> targets = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<bool> success = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RunRecordsCompanion(
                id: id,
                projectId: projectId,
                projectName: projectName,
                envName: envName,
                branch: branch,
                versionLabel: versionLabel,
                platforms: platforms,
                targets: targets,
                startedAt: startedAt,
                finishedAt: finishedAt,
                durationSeconds: durationSeconds,
                success: success,
                errorMessage: errorMessage,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String projectId,
                required String projectName,
                required String envName,
                required String branch,
                required String versionLabel,
                required String platforms,
                required String targets,
                required DateTime startedAt,
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                required bool success,
                Value<String?> errorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RunRecordsCompanion.insert(
                id: id,
                projectId: projectId,
                projectName: projectName,
                envName: envName,
                branch: branch,
                versionLabel: versionLabel,
                platforms: platforms,
                targets: targets,
                startedAt: startedAt,
                finishedAt: finishedAt,
                durationSeconds: durationSeconds,
                success: success,
                errorMessage: errorMessage,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RunRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({stepRecordsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (stepRecordsRefs) db.stepRecords],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (stepRecordsRefs)
                    await $_getPrefetchedData<
                      RunRecord,
                      $RunRecordsTable,
                      StepRecord
                    >(
                      currentTable: table,
                      referencedTable: $$RunRecordsTableReferences
                          ._stepRecordsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$RunRecordsTableReferences(
                            db,
                            table,
                            p0,
                          ).stepRecordsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.runId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RunRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RunRecordsTable,
      RunRecord,
      $$RunRecordsTableFilterComposer,
      $$RunRecordsTableOrderingComposer,
      $$RunRecordsTableAnnotationComposer,
      $$RunRecordsTableCreateCompanionBuilder,
      $$RunRecordsTableUpdateCompanionBuilder,
      (RunRecord, $$RunRecordsTableReferences),
      RunRecord,
      PrefetchHooks Function({bool stepRecordsRefs})
    >;
typedef $$StepRecordsTableCreateCompanionBuilder =
    StepRecordsCompanion Function({
      Value<int> pk,
      required String runId,
      required String stepId,
      required String stepName,
      required int statusIndex,
      Value<int?> durationSeconds,
      Value<String?> errorMessage,
    });
typedef $$StepRecordsTableUpdateCompanionBuilder =
    StepRecordsCompanion Function({
      Value<int> pk,
      Value<String> runId,
      Value<String> stepId,
      Value<String> stepName,
      Value<int> statusIndex,
      Value<int?> durationSeconds,
      Value<String?> errorMessage,
    });

final class $$StepRecordsTableReferences
    extends BaseReferences<_$AppDatabase, $StepRecordsTable, StepRecord> {
  $$StepRecordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RunRecordsTable _runIdTable(_$AppDatabase db) =>
      db.runRecords.createAlias(
        $_aliasNameGenerator(db.stepRecords.runId, db.runRecords.id),
      );

  $$RunRecordsTableProcessedTableManager get runId {
    final $_column = $_itemColumn<String>('run_id')!;

    final manager = $$RunRecordsTableTableManager(
      $_db,
      $_db.runRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_runIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StepRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $StepRecordsTable> {
  $$StepRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get pk => $composableBuilder(
    column: $table.pk,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stepId => $composableBuilder(
    column: $table.stepId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stepName => $composableBuilder(
    column: $table.stepName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get statusIndex => $composableBuilder(
    column: $table.statusIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  $$RunRecordsTableFilterComposer get runId {
    final $$RunRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.runRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RunRecordsTableFilterComposer(
            $db: $db,
            $table: $db.runRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StepRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $StepRecordsTable> {
  $$StepRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get pk => $composableBuilder(
    column: $table.pk,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stepId => $composableBuilder(
    column: $table.stepId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stepName => $composableBuilder(
    column: $table.stepName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get statusIndex => $composableBuilder(
    column: $table.statusIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  $$RunRecordsTableOrderingComposer get runId {
    final $$RunRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.runRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RunRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.runRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StepRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StepRecordsTable> {
  $$StepRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get pk =>
      $composableBuilder(column: $table.pk, builder: (column) => column);

  GeneratedColumn<String> get stepId =>
      $composableBuilder(column: $table.stepId, builder: (column) => column);

  GeneratedColumn<String> get stepName =>
      $composableBuilder(column: $table.stepName, builder: (column) => column);

  GeneratedColumn<int> get statusIndex => $composableBuilder(
    column: $table.statusIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  $$RunRecordsTableAnnotationComposer get runId {
    final $$RunRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.runRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RunRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.runRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StepRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StepRecordsTable,
          StepRecord,
          $$StepRecordsTableFilterComposer,
          $$StepRecordsTableOrderingComposer,
          $$StepRecordsTableAnnotationComposer,
          $$StepRecordsTableCreateCompanionBuilder,
          $$StepRecordsTableUpdateCompanionBuilder,
          (StepRecord, $$StepRecordsTableReferences),
          StepRecord,
          PrefetchHooks Function({bool runId})
        > {
  $$StepRecordsTableTableManager(_$AppDatabase db, $StepRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StepRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StepRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StepRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> pk = const Value.absent(),
                Value<String> runId = const Value.absent(),
                Value<String> stepId = const Value.absent(),
                Value<String> stepName = const Value.absent(),
                Value<int> statusIndex = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
              }) => StepRecordsCompanion(
                pk: pk,
                runId: runId,
                stepId: stepId,
                stepName: stepName,
                statusIndex: statusIndex,
                durationSeconds: durationSeconds,
                errorMessage: errorMessage,
              ),
          createCompanionCallback:
              ({
                Value<int> pk = const Value.absent(),
                required String runId,
                required String stepId,
                required String stepName,
                required int statusIndex,
                Value<int?> durationSeconds = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
              }) => StepRecordsCompanion.insert(
                pk: pk,
                runId: runId,
                stepId: stepId,
                stepName: stepName,
                statusIndex: statusIndex,
                durationSeconds: durationSeconds,
                errorMessage: errorMessage,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StepRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({runId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (runId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.runId,
                                referencedTable: $$StepRecordsTableReferences
                                    ._runIdTable(db),
                                referencedColumn: $$StepRecordsTableReferences
                                    ._runIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$StepRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StepRecordsTable,
      StepRecord,
      $$StepRecordsTableFilterComposer,
      $$StepRecordsTableOrderingComposer,
      $$StepRecordsTableAnnotationComposer,
      $$StepRecordsTableCreateCompanionBuilder,
      $$StepRecordsTableUpdateCompanionBuilder,
      (StepRecord, $$StepRecordsTableReferences),
      StepRecord,
      PrefetchHooks Function({bool runId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RunRecordsTableTableManager get runRecords =>
      $$RunRecordsTableTableManager(_db, _db.runRecords);
  $$StepRecordsTableTableManager get stepRecords =>
      $$StepRecordsTableTableManager(_db, _db.stepRecords);
}
