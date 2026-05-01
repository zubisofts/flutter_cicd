import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../config/config_repository.dart';
import '../../services/credential_store.dart';

// ─── Events ───────────────────────────────────────────────────────────────

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => [];
}

class SettingsOpened extends SettingsEvent {
  final String projectId;
  final String envName;
  const SettingsOpened(this.projectId, this.envName);
  @override
  List<Object?> get props => [projectId, envName];
}

class SettingsEnvChanged extends SettingsEvent {
  final String envName;
  const SettingsEnvChanged(this.envName);
  @override
  List<Object?> get props => [envName];
}

class AndroidSigningSaved extends SettingsEvent {
  final String keystorePath;
  final String keyAlias;
  final String keystorePassword;
  final String keyPassword;
  const AndroidSigningSaved({
    required this.keystorePath,
    required this.keyAlias,
    required this.keystorePassword,
    required this.keyPassword,
  });
  @override
  List<Object?> get props =>
      [keystorePath, keyAlias];
}

class AppleCredentialsSaved extends SettingsEvent {
  final String appleId;
  final String appSpecificPassword;
  const AppleCredentialsSaved({
    required this.appleId,
    required this.appSpecificPassword,
  });
  @override
  List<Object?> get props => [appleId];
}

class FirebaseTokenSaved extends SettingsEvent {
  final String token;
  const FirebaseTokenSaved(this.token);
  @override
  List<Object?> get props => [token];
}

class EnvConfigFieldUpdated extends SettingsEvent {
  final String field;
  final String value;
  const EnvConfigFieldUpdated(this.field, this.value);
  @override
  List<Object?> get props => [field, value];
}

class EnvConfigSaved extends SettingsEvent {
  const EnvConfigSaved();
}

// ─── State ────────────────────────────────────────────────────────────────

class SettingsState extends Equatable {
  final String projectId;
  final String selectedEnv;
  final List<String> availableEnvs;
  final AndroidSigningCredentials androidCreds;
  final AppleCredentials appleCreds;
  final String firebaseToken;

  // Editable env config fields
  final String androidPackageName;
  final String androidFirebaseAppId;
  final String iosBundleId;
  final String iosFirebaseAppId;
  final String iosTeamId;
  final String iosExportMethod;
  final String iosProvisioningProfile;
  final String dartDefineFromFile;
  final String firebaseTesterGroups; // comma-separated

  final bool isLoading;
  final String? savedMessage;
  final String? error;

  const SettingsState({
    this.projectId = '',
    this.selectedEnv = 'dev',
    this.availableEnvs = const ['dev', 'staging', 'prod'],
    this.androidCreds = const AndroidSigningCredentials(
      keystorePath: '',
      keyAlias: '',
      keystorePassword: '',
      keyPassword: '',
    ),
    this.appleCreds = const AppleCredentials(
      appleId: '',
      appSpecificPassword: '',
    ),
    this.firebaseToken = '',
    this.androidPackageName = '',
    this.androidFirebaseAppId = '',
    this.iosBundleId = '',
    this.iosFirebaseAppId = '',
    this.iosTeamId = '',
    this.iosExportMethod = 'app-store',
    this.iosProvisioningProfile = '',
    this.dartDefineFromFile = '',
    this.firebaseTesterGroups = '',
    this.isLoading = false,
    this.savedMessage,
    this.error,
  });

  SettingsState copyWith({
    String? projectId,
    String? selectedEnv,
    List<String>? availableEnvs,
    AndroidSigningCredentials? androidCreds,
    AppleCredentials? appleCreds,
    String? firebaseToken,
    String? androidPackageName,
    String? androidFirebaseAppId,
    String? iosBundleId,
    String? iosFirebaseAppId,
    String? iosTeamId,
    String? iosExportMethod,
    String? iosProvisioningProfile,
    String? dartDefineFromFile,
    String? firebaseTesterGroups,
    bool? isLoading,
    String? savedMessage,
    String? error,
    bool clearSaved = false,
    bool clearError = false,
  }) =>
      SettingsState(
        projectId: projectId ?? this.projectId,
        selectedEnv: selectedEnv ?? this.selectedEnv,
        availableEnvs: availableEnvs ?? this.availableEnvs,
        androidCreds: androidCreds ?? this.androidCreds,
        appleCreds: appleCreds ?? this.appleCreds,
        firebaseToken: firebaseToken ?? this.firebaseToken,
        androidPackageName: androidPackageName ?? this.androidPackageName,
        androidFirebaseAppId: androidFirebaseAppId ?? this.androidFirebaseAppId,
        iosBundleId: iosBundleId ?? this.iosBundleId,
        iosFirebaseAppId: iosFirebaseAppId ?? this.iosFirebaseAppId,
        iosTeamId: iosTeamId ?? this.iosTeamId,
        iosExportMethod: iosExportMethod ?? this.iosExportMethod,
        iosProvisioningProfile:
            iosProvisioningProfile ?? this.iosProvisioningProfile,
        dartDefineFromFile: dartDefineFromFile ?? this.dartDefineFromFile,
        firebaseTesterGroups: firebaseTesterGroups ?? this.firebaseTesterGroups,
        isLoading: isLoading ?? this.isLoading,
        savedMessage: clearSaved ? null : (savedMessage ?? this.savedMessage),
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [
        projectId,
        selectedEnv,
        androidCreds.keystorePath,
        androidCreds.keyAlias,
        appleCreds.appleId,
        firebaseToken,
        androidPackageName,
        androidFirebaseAppId,
        iosBundleId,
        iosFirebaseAppId,
        iosTeamId,
        iosExportMethod,
        iosProvisioningProfile,
        dartDefineFromFile,
        firebaseTesterGroups,
        isLoading,
        savedMessage,
        error,
      ];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final CredentialStore _creds;
  final ConfigRepository _configRepo;

  SettingsBloc(this._creds, this._configRepo) : super(const SettingsState()) {
    on<SettingsOpened>(_onOpened);
    on<SettingsEnvChanged>(_onEnvChanged);
    on<AndroidSigningSaved>(_onAndroidSigningSaved);
    on<AppleCredentialsSaved>(_onAppleSaved);
    on<FirebaseTokenSaved>(_onFirebaseTokenSaved);
    on<EnvConfigFieldUpdated>(_onFieldUpdated);
    on<EnvConfigSaved>(_onEnvConfigSaved);
  }

  Future<void> _onOpened(
      SettingsOpened event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(
        projectId: event.projectId,
        selectedEnv: event.envName,
        isLoading: true));
    await _loadForEnv(event.projectId, event.envName, emit);
  }

  Future<void> _onEnvChanged(
      SettingsEnvChanged event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(selectedEnv: event.envName, isLoading: true));
    await _loadForEnv(state.projectId, event.envName, emit);
  }

  Future<void> _loadForEnv(
      String projectId, String envName, Emitter<SettingsState> emit) async {
    try {
      await _configRepo.ensureEnvExists(projectId, envName);
      final envs = await _configRepo.listEnvironments(projectId);
      final androidCreds = await _creds.loadAndroidSigning(
          projectId: projectId, envName: envName);
      final appleCreds = await _creds.loadAppleCredentials(
          projectId: projectId, envName: envName);
      final firebaseToken = await _creds.loadFirebaseToken();
      final envConfig = await _configRepo.loadEnv(projectId, envName);

      emit(state.copyWith(
        availableEnvs: envs.isNotEmpty ? envs : ['dev', 'staging', 'prod'],
        androidCreds: androidCreds,
        appleCreds: appleCreds,
        firebaseToken: firebaseToken,
        androidPackageName: envConfig.android.packageName,
        androidFirebaseAppId: envConfig.android.firebaseAppId,
        iosBundleId: envConfig.ios.bundleId,
        iosFirebaseAppId: envConfig.ios.firebaseAppId,
        iosTeamId: envConfig.ios.teamId,
        iosExportMethod: envConfig.ios.exportMethod,
        iosProvisioningProfile: envConfig.ios.provisioningProfile,
        dartDefineFromFile: envConfig.dartDefineFromFile,
        firebaseTesterGroups: envConfig.distribution.firebase
                ?.testerGroups.join(', ') ??
            '',
        isLoading: false,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onAndroidSigningSaved(
      AndroidSigningSaved event, Emitter<SettingsState> emit) async {
    try {
      await _creds.saveAndroidSigning(
        projectId: state.projectId,
        envName: state.selectedEnv,
        keystorePath: event.keystorePath,
        keyAlias: event.keyAlias,
        keystorePassword: event.keystorePassword,
        keyPassword: event.keyPassword,
      );
      emit(state.copyWith(
        androidCreds: AndroidSigningCredentials(
          keystorePath: event.keystorePath,
          keyAlias: event.keyAlias,
          keystorePassword: event.keystorePassword,
          keyPassword: event.keyPassword,
        ),
        savedMessage: 'Android signing saved to Keychain',
      ));
      await Future.delayed(const Duration(seconds: 3));
      emit(state.copyWith(clearSaved: true));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onAppleSaved(
      AppleCredentialsSaved event, Emitter<SettingsState> emit) async {
    try {
      await _creds.saveAppleCredentials(
        projectId: state.projectId,
        envName: state.selectedEnv,
        appleId: event.appleId,
        appSpecificPassword: event.appSpecificPassword,
      );
      emit(state.copyWith(
        appleCreds: AppleCredentials(
          appleId: event.appleId,
          appSpecificPassword: event.appSpecificPassword,
        ),
        savedMessage: 'Apple credentials saved to Keychain',
      ));
      await Future.delayed(const Duration(seconds: 3));
      emit(state.copyWith(clearSaved: true));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onFirebaseTokenSaved(
      FirebaseTokenSaved event, Emitter<SettingsState> emit) async {
    try {
      await _creds.saveFirebaseToken(event.token);
      emit(state.copyWith(
        firebaseToken: event.token,
        savedMessage: 'Firebase token saved to Keychain',
      ));
      await Future.delayed(const Duration(seconds: 3));
      emit(state.copyWith(clearSaved: true));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _onFieldUpdated(
      EnvConfigFieldUpdated event, Emitter<SettingsState> emit) {
    switch (event.field) {
      case 'android_package':
        emit(state.copyWith(androidPackageName: event.value));
      case 'android_firebase_id':
        emit(state.copyWith(androidFirebaseAppId: event.value));
      case 'ios_bundle_id':
        emit(state.copyWith(iosBundleId: event.value));
      case 'ios_firebase_id':
        emit(state.copyWith(iosFirebaseAppId: event.value));
      case 'ios_team_id':
        emit(state.copyWith(iosTeamId: event.value));
      case 'ios_export_method':
        emit(state.copyWith(iosExportMethod: event.value));
      case 'ios_provisioning_profile':
        emit(state.copyWith(iosProvisioningProfile: event.value));
      case 'dart_define_from_file':
        emit(state.copyWith(dartDefineFromFile: event.value));
      case 'firebase_tester_groups':
        emit(state.copyWith(firebaseTesterGroups: event.value));
    }
  }

  Future<void> _onEnvConfigSaved(
      EnvConfigSaved event, Emitter<SettingsState> emit) async {
    try {
      await _configRepo.updateEnvFields(
        projectId: state.projectId,
        envName: state.selectedEnv,
        fields: {
          'dart_define_from_file': state.dartDefineFromFile,
          'firebase_tester_groups': state.firebaseTesterGroups,
          'android_package_name': state.androidPackageName,
          'android_firebase_app_id': state.androidFirebaseAppId,
          'ios_bundle_id': state.iosBundleId,
          'ios_firebase_app_id': state.iosFirebaseAppId,
          'ios_team_id': state.iosTeamId,
          'ios_export_method': state.iosExportMethod,
          'ios_provisioning_profile': state.iosProvisioningProfile,
        },
      );
      emit(state.copyWith(savedMessage: 'Environment config saved'));
      await Future.delayed(const Duration(seconds: 3));
      emit(state.copyWith(clearSaved: true));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
