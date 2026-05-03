import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../config/config_repository.dart';
import '../../config/models/app_project.dart';
import '../../engine/pipeline_runner.dart';

// ─── Events ───────────────────────────────────────────────────────────────

abstract class SetupEvent extends Equatable {
  const SetupEvent();
  @override
  List<Object?> get props => [];
}

class SetupInitialized extends SetupEvent {
  const SetupInitialized();
}

class ProjectSelected extends SetupEvent {
  final AppProject project;
  const ProjectSelected(this.project);
  @override
  List<Object?> get props => [project.id];
}

class BranchChanged extends SetupEvent {
  final String branch;
  const BranchChanged(this.branch);
  @override
  List<Object?> get props => [branch];
}

class EnvSelected extends SetupEvent {
  final String envName;
  const EnvSelected(this.envName);
  @override
  List<Object?> get props => [envName];
}

class VersionNameChanged extends SetupEvent {
  final String value;
  const VersionNameChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class BuildNumberChanged extends SetupEvent {
  final String value;
  const BuildNumberChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class PlatformToggled extends SetupEvent {
  final String platform;
  const PlatformToggled(this.platform);
  @override
  List<Object?> get props => [platform];
}

class TargetToggled extends SetupEvent {
  final String target;
  const TargetToggled(this.target);
  @override
  List<Object?> get props => [target];
}

class ReleaseNotesChanged extends SetupEvent {
  final String value;
  const ReleaseNotesChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class ManagedPublishingToggled extends SetupEvent {
  const ManagedPublishingToggled();
}

class RunPipelineRequested extends SetupEvent {
  const RunPipelineRequested();
}

class ResetReadyToRun extends SetupEvent {
  const ResetReadyToRun();
}

class ProjectDeleted extends SetupEvent {
  final String projectId;
  const ProjectDeleted(this.projectId);
  @override
  List<Object?> get props => [projectId];
}

class NewProjectRequested extends SetupEvent {
  final String id;
  final String name;
  final String repository;
  const NewProjectRequested(this.id, this.name, this.repository);
  @override
  List<Object?> get props => [id];
}

class RefsFetched extends SetupEvent {
  final List<String> branches;
  final List<String> tags;
  const RefsFetched({required this.branches, required this.tags});
  @override
  List<Object?> get props => [branches.length, tags.length];
}

// ─── States ───────────────────────────────────────────────────────────────

class SetupState extends Equatable {
  final List<AppProject> projects;
  final AppProject? selectedProject;
  final List<String> availableEnvs;
  final String selectedEnv;
  final String branch;
  final String versionName;
  final String buildNumber;
  final List<String> platforms;
  final List<String> targets;
  final List<String> branches;
  final List<String> tags;
  final bool isFetchingBranches;
  final bool branchValid; // false only when refs loaded and typed value not found
  final bool isLoading;
  final String? error;
  final bool requiresProductionConfirm;
  final bool readyToRun;
  final String releaseNotes;
  final bool managedPublishing;

  const SetupState({
    this.projects = const [],
    this.selectedProject,
    this.availableEnvs = const ['dev', 'staging', 'prod'],
    this.selectedEnv = 'dev',
    this.branch = 'main',
    this.versionName = '1.0.0',
    this.buildNumber = '1',
    this.platforms = const ['android', 'ios'],
    this.targets = const ['firebase_android', 'firebase_ios'],
    this.branches = const [],
    this.tags = const [],
    this.isFetchingBranches = false,
    this.branchValid = true,
    this.isLoading = false,
    this.error,
    this.requiresProductionConfirm = false,
    this.readyToRun = false,
    this.releaseNotes = '',
    this.managedPublishing = false,
  });

  bool get isValid =>
      selectedProject != null &&
      branch.isNotEmpty &&
      versionName.isNotEmpty &&
      int.tryParse(buildNumber) != null &&
      platforms.isNotEmpty;

  SetupState copyWith({
    List<AppProject>? projects,
    AppProject? selectedProject,
    List<String>? availableEnvs,
    String? selectedEnv,
    String? branch,
    String? versionName,
    String? buildNumber,
    List<String>? platforms,
    List<String>? targets,
    List<String>? branches,
    List<String>? tags,
    bool? isFetchingBranches,
    bool? branchValid,
    bool? isLoading,
    String? error,
    bool? requiresProductionConfirm,
    bool? readyToRun,
    String? releaseNotes,
    bool? managedPublishing,
    bool clearError = false,
    bool clearProject = false,
  }) =>
      SetupState(
        projects: projects ?? this.projects,
        selectedProject:
            clearProject ? null : (selectedProject ?? this.selectedProject),
        availableEnvs: availableEnvs ?? this.availableEnvs,
        selectedEnv: selectedEnv ?? this.selectedEnv,
        branch: branch ?? this.branch,
        versionName: versionName ?? this.versionName,
        buildNumber: buildNumber ?? this.buildNumber,
        platforms: platforms ?? this.platforms,
        targets: targets ?? this.targets,
        branches: branches ?? this.branches,
        tags: tags ?? this.tags,
        isFetchingBranches: isFetchingBranches ?? this.isFetchingBranches,
        branchValid: branchValid ?? this.branchValid,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        requiresProductionConfirm:
            requiresProductionConfirm ?? this.requiresProductionConfirm,
        readyToRun: readyToRun ?? this.readyToRun,
        releaseNotes: releaseNotes ?? this.releaseNotes,
        managedPublishing: managedPublishing ?? this.managedPublishing,
      );

  String get versionPreview {
    final suffix = selectedEnv == 'dev' ? '-dev' : '';
    return '$versionName$suffix+$buildNumber';
  }

  @override
  List<Object?> get props => [
        projects,
        selectedProject?.id,
        availableEnvs,
        selectedEnv,
        branch,
        versionName,
        buildNumber,
        platforms,
        targets,
        branches,
        tags,
        isFetchingBranches,
        branchValid,
        isLoading,
        error,
        requiresProductionConfirm,
        readyToRun,
        releaseNotes,
        managedPublishing,
      ];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────

class SetupBloc extends Bloc<SetupEvent, SetupState> {
  final ConfigRepository _configRepo;

  SetupBloc(this._configRepo) : super(const SetupState()) {
    on<SetupInitialized>(_onInit);
    on<ProjectSelected>(_onProjectSelected);
    on<BranchChanged>(_onBranchChanged);
    on<EnvSelected>(_onEnvSelected);
    on<VersionNameChanged>(_onVersionChanged);
    on<BuildNumberChanged>(_onBuildNumberChanged);
    on<PlatformToggled>(_onPlatformToggled);
    on<TargetToggled>(_onTargetToggled);
    on<ReleaseNotesChanged>((e, emit) =>
        emit(state.copyWith(releaseNotes: e.value)));
    on<ManagedPublishingToggled>((_, emit) =>
        emit(state.copyWith(managedPublishing: !state.managedPublishing)));
    on<RunPipelineRequested>(_onRunRequested);
    on<NewProjectRequested>(_onNewProject);
    on<ProjectDeleted>(_onProjectDeleted);
    on<RefsFetched>((e, emit) {
      final allRefs = [...e.branches, ...e.tags];
      final valid = allRefs.isEmpty || allRefs.contains(state.branch);
      emit(state.copyWith(
        branches: e.branches,
        tags: e.tags,
        isFetchingBranches: false,
        branchValid: valid,
      ));
    });
    on<ResetReadyToRun>((_, emit) => emit(state.copyWith(readyToRun: false)));
  }

  Future<void> _onInit(
      SetupInitialized event, Emitter<SetupState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final projects = await _configRepo.listProjects();
      emit(state.copyWith(
        projects: projects,
        isLoading: false,
        selectedProject: projects.isNotEmpty ? projects.first : null,
        isFetchingBranches: projects.isNotEmpty,
      ));
      if (projects.isNotEmpty) {
        await _loadEnvs(projects.first.id, emit);
        await _applyLastRunConfig(projects.first.id, emit);
        _fetchBranches(projects.first.repository);
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onProjectSelected(
      ProjectSelected event, Emitter<SetupState> emit) async {
    emit(state.copyWith(
      selectedProject: event.project,
      branches: [],
      tags: [],
      isFetchingBranches: true,
      clearError: true,
    ));
    await _loadEnvs(event.project.id, emit);
    await _applyLastRunConfig(event.project.id, emit);
    _fetchBranches(event.project.repository);
  }

  Future<void> _loadEnvs(String projectId, Emitter<SetupState> emit) async {
    try {
      final envs = await _configRepo.listEnvironments(projectId);
      final selectedEnv =
          envs.contains('dev') ? 'dev' : (envs.isNotEmpty ? envs.first : 'dev');
      emit(state.copyWith(
        availableEnvs: envs.isNotEmpty ? envs : ['dev', 'staging', 'prod'],
        selectedEnv: selectedEnv,
      ));
      await _syncTargetsFromEnv(projectId, selectedEnv, emit);
    } catch (_) {}
  }

  /// Reads the env YAML and sets the default targets to match what is
  /// actually enabled — so TestFlight, Firebase, Play Store are pre-selected
  /// without the user having to toggle them manually every run.
  Future<void> _syncTargetsFromEnv(
      String projectId, String envName, Emitter<SetupState> emit) async {
    try {
      final envConfig = await _configRepo.loadEnv(projectId, envName);
      final dist = envConfig.distribution;
      final targets = <String>[
        if (dist.firebase?.enabled ?? false) ...[
          'firebase_android',
          'firebase_ios',
        ],
        if (dist.testflight) 'testflight',
        if (dist.playStore?.enabled ?? false) 'playstore',
      ];
      emit(state.copyWith(targets: targets));
    } catch (_) {}
  }

  void _onBranchChanged(BranchChanged event, Emitter<SetupState> emit) {
    final allRefs = [...state.branches, ...state.tags];
    final valid = allRefs.isEmpty || allRefs.contains(event.branch);
    emit(state.copyWith(
        branch: event.branch, branchValid: valid, clearError: true));
  }

  Future<void> _onEnvSelected(
      EnvSelected event, Emitter<SetupState> emit) async {
    emit(state.copyWith(
      selectedEnv: event.envName,
      requiresProductionConfirm: event.envName == 'prod',
      clearError: true,
    ));
    final projectId = state.selectedProject?.id;
    if (projectId != null) {
      await _syncTargetsFromEnv(projectId, event.envName, emit);
    }
  }

  void _onVersionChanged(
      VersionNameChanged event, Emitter<SetupState> emit) =>
      emit(state.copyWith(versionName: event.value, clearError: true));

  void _onBuildNumberChanged(
      BuildNumberChanged event, Emitter<SetupState> emit) =>
      emit(state.copyWith(buildNumber: event.value, clearError: true));

  void _onPlatformToggled(
      PlatformToggled event, Emitter<SetupState> emit) {
    final list = List<String>.from(state.platforms);
    if (list.contains(event.platform)) {
      list.remove(event.platform);
    } else {
      list.add(event.platform);
    }
    emit(state.copyWith(platforms: list));
  }

  void _onTargetToggled(TargetToggled event, Emitter<SetupState> emit) {
    final list = List<String>.from(state.targets);
    if (list.contains(event.target)) {
      list.remove(event.target);
    } else {
      list.add(event.target);
    }
    emit(state.copyWith(targets: list));
  }

  Future<void> _onRunRequested(
      RunPipelineRequested event, Emitter<SetupState> emit) async {
    final project = state.selectedProject;
    if (project != null) {
      _configRepo.saveLastRunConfig(project.id, {
        'branch': state.branch,
        'versionName': state.versionName,
        'buildNumber': state.buildNumber,
        'selectedEnv': state.selectedEnv,
        'platforms': state.platforms,
        'targets': state.targets,
      }).ignore();
    }
    emit(state.copyWith(readyToRun: true));
  }

  Future<void> _applyLastRunConfig(
      String projectId, Emitter<SetupState> emit) async {
    try {
      final config = await _configRepo.loadLastRunConfig(projectId);
      if (config == null) return;

      final savedEnv = config['selectedEnv'] as String?;
      final envToApply = savedEnv != null &&
              state.availableEnvs.contains(savedEnv)
          ? savedEnv
          : null;

      emit(state.copyWith(
        branch: config['branch'] as String? ?? state.branch,
        versionName: config['versionName'] as String? ?? state.versionName,
        buildNumber: config['buildNumber'] as String? ?? state.buildNumber,
        selectedEnv: envToApply ?? state.selectedEnv,
        platforms:
            (config['platforms'] as List?)?.cast<String>() ?? state.platforms,
        targets:
            (config['targets'] as List?)?.cast<String>() ?? state.targets,
        requiresProductionConfirm:
            (envToApply ?? state.selectedEnv) == 'prod',
      ));
    } catch (_) {}
  }

  Future<void> _onNewProject(
      NewProjectRequested event, Emitter<SetupState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _configRepo.scaffold(event.id, event.name, event.repository);
      final projects = await _configRepo.listProjects();
      final newProject = projects.firstWhere((p) => p.id == event.id);
      emit(state.copyWith(
        projects: projects,
        selectedProject: newProject,
        branches: [],
        isFetchingBranches: true,
        isLoading: false,
        clearError: true,
      ));
      await _loadEnvs(event.id, emit);
      _fetchBranches(event.repository);
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onProjectDeleted(
      ProjectDeleted event, Emitter<SetupState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _configRepo.deleteProject(event.projectId);
      final projects = await _configRepo.listProjects();
      emit(state.copyWith(
        projects: projects,
        isLoading: false,
        clearProject: projects.isEmpty,
        selectedProject: projects.isNotEmpty ? projects.first : null,
        branches: [],
        tags: [],
        clearError: true,
      ));
      if (projects.isNotEmpty) {
        await _loadEnvs(projects.first.id, emit);
        _fetchBranches(projects.first.repository);
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void _fetchBranches(String repoUrl) {
    if (repoUrl.isEmpty) {
      add(const RefsFetched(branches: [], tags: []));
      return;
    }
    Process.run(
      '/usr/bin/git',
      ['ls-remote', '--heads', '--tags', repoUrl],
      runInShell: false,
    ).timeout(const Duration(seconds: 15), onTimeout: () {
      return ProcessResult(0, 1, '', 'timeout');
    }).then((result) {
      if (isClosed) return;
      if (result.exitCode != 0) {
        add(const RefsFetched(branches: [], tags: []));
        return;
      }
      final lines = (result.stdout as String)
          .split('\n')
          .where((l) => l.contains('\t'));

      final branches = lines
          .where((l) => l.contains('refs/heads/'))
          .map((l) => l.split('\t').last
              .replaceFirst('refs/heads/', '')
              .trim())
          .where((b) => b.isNotEmpty)
          .toList()
        ..sort();

      final tags = lines
          .where((l) => l.contains('refs/tags/') && !l.endsWith('^{}'))
          .map((l) => l.split('\t').last
              .replaceFirst('refs/tags/', '')
              .trim())
          .where((t) => t.isNotEmpty)
          .toList()
        ..sort();

      add(RefsFetched(branches: branches, tags: tags));
    }).catchError((_) {
      if (isClosed) return;
      add(const RefsFetched(branches: [], tags: []));
    });
  }

  RunRequest buildRunRequest() {
    return RunRequest(
      projectId: state.selectedProject!.id,
      projectName: state.selectedProject!.name,
      branch: state.branch,
      envName: state.selectedEnv,
      versionName: state.versionName,
      buildNumber: int.parse(state.buildNumber),
      platforms: state.platforms,
      targets: state.targets,
      releaseNotes: state.releaseNotes.isEmpty ? null : state.releaseNotes,
      managedPublishing: state.managedPublishing,
    );
  }
}
