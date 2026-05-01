import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// ─── Tables ───────────────────────────────────────────────────────────────

class RunRecords extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get projectName => text()();
  TextColumn get envName => text()();
  TextColumn get branch => text()();
  TextColumn get versionLabel => text()();
  TextColumn get platforms => text()(); // comma-separated
  TextColumn get targets => text()(); // comma-separated
  IntColumn get startedAt =>
      integer().map(const DateTimeConverter())();
  IntColumn get finishedAt =>
      integer().nullable().map(const NullableDateTimeConverter())();
  IntColumn get durationSeconds => integer().nullable()();
  BoolColumn get success => boolean()();
  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class StepRecords extends Table {
  IntColumn get pk => integer().autoIncrement()();
  TextColumn get runId => text().references(RunRecords, #id)();
  TextColumn get stepId => text()();
  TextColumn get stepName => text()();
  IntColumn get statusIndex => integer()();
  IntColumn get durationSeconds => integer().nullable()();
  TextColumn get errorMessage => text().nullable()();
}

// ─── Converters ────────────────────────────────────────────────────────────

class DateTimeConverter extends TypeConverter<DateTime, int> {
  const DateTimeConverter();
  @override
  DateTime fromSql(int fromDb) =>
      DateTime.fromMillisecondsSinceEpoch(fromDb);
  @override
  int toSql(DateTime value) => value.millisecondsSinceEpoch;
}

class NullableDateTimeConverter
    extends TypeConverter<DateTime?, int?> {
  const NullableDateTimeConverter();
  @override
  DateTime? fromSql(int? fromDb) => fromDb == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(fromDb);
  @override
  int? toSql(DateTime? value) => value?.millisecondsSinceEpoch;
}

// ─── Database ─────────────────────────────────────────────────────────────

@DriftDatabase(tables: [RunRecords, StepRecords])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  // ── Run queries ────────────────────────────────────────────────────────

  Future<List<RunRecord>> getAllRuns() =>
      (select(runRecords)
            ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
          .get();

  Future<RunRecord?> getRunById(String id) =>
      (select(runRecords)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<void> insertRun(RunRecordsCompanion run) =>
      into(runRecords).insert(run);

  Future<void> updateRun(RunRecordsCompanion run) =>
      (update(runRecords)..where((t) => t.id.equals(run.id.value)))
          .write(run);

  // ── Step queries ───────────────────────────────────────────────────────

  Future<List<StepRecord>> getStepsForRun(String runId) =>
      (select(stepRecords)
            ..where((t) => t.runId.equals(runId))
            ..orderBy([(t) => OrderingTerm.asc(t.pk)]))
          .get();

  Future<void> insertStep(StepRecordsCompanion step) =>
      into(stepRecords).insert(step);

  Future<void> updateStep(int pk, StepRecordsCompanion step) =>
      (update(stepRecords)..where((t) => t.pk.equals(pk)))
          .write(step);

  Future<void> deleteRun(String id) async {
    await (delete(stepRecords)..where((t) => t.runId.equals(id))).go();
    await (delete(runRecords)..where((t) => t.id.equals(id))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationSupportDirectory();
    final file = File(p.join(dbFolder.path, 'cicd.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
