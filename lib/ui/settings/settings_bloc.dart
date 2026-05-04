import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../config/config_repository.dart';
import '../../services/credential_store.dart';
import '../../services/email_notification_service.dart';
import '../../services/google_chat_notification_service.dart';
import '../../services/slack_notification_service.dart';
import '../../services/teams_notification_service.dart';

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

class AppleApiKeySaved extends SettingsEvent {
  final String keyId;
  final String issuerId;
  final String privateKeyContent;
  const AppleApiKeySaved({
    required this.keyId,
    required this.issuerId,
    required this.privateKeyContent,
  });
  @override
  List<Object?> get props => [keyId, issuerId];
}

class FirebaseServiceAccountSaved extends SettingsEvent {
  final String content; // JSON file content, not a path
  final String displayEmail; // client_email extracted from the JSON
  const FirebaseServiceAccountSaved(this.content, {this.displayEmail = ''});
  @override
  List<Object?> get props => [content.length];
}

class PlayStoreKeyPathSaved extends SettingsEvent {
  final String content; // JSON file content, not a path
  final String displayEmail;
  const PlayStoreKeyPathSaved(this.content, {this.displayEmail = ''});
  @override
  List<Object?> get props => [content.length];
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

class EmailConfigSaved extends SettingsEvent {
  final SmtpConfig config;
  const EmailConfigSaved(this.config);
  @override
  List<Object?> get props => [config.host, config.recipient];
}

class EmailTestRequested extends SettingsEvent {
  final SmtpConfig config;
  const EmailTestRequested(this.config);
  @override
  List<Object?> get props => [config.host];
}

class SlackConfigSaved extends SettingsEvent {
  final SlackConfig config;
  const SlackConfigSaved(this.config);
  @override
  List<Object?> get props => [config.webhookUrl];
}

class SlackTestRequested extends SettingsEvent {
  final SlackConfig config;
  const SlackTestRequested(this.config);
  @override
  List<Object?> get props => [config.webhookUrl];
}

class TeamsConfigSaved extends SettingsEvent {
  final TeamsConfig config;
  const TeamsConfigSaved(this.config);
  @override
  List<Object?> get props => [config.webhookUrl];
}

class TeamsTestRequested extends SettingsEvent {
  final TeamsConfig config;
  const TeamsTestRequested(this.config);
  @override
  List<Object?> get props => [config.webhookUrl];
}

class GoogleChatConfigSaved extends SettingsEvent {
  final GoogleChatConfig config;
  const GoogleChatConfigSaved(this.config);
  @override
  List<Object?> get props => [config.webhookUrl];
}

class GoogleChatTestRequested extends SettingsEvent {
  final GoogleChatConfig config;
  const GoogleChatTestRequested(this.config);
  @override
  List<Object?> get props => [config.webhookUrl];
}

class MatchConfigSaved extends SettingsEvent {
  final String gitUrl;
  final String password;
  final bool readonly;
  const MatchConfigSaved({
    required this.gitUrl,
    required this.password,
    required this.readonly,
  });
  @override
  List<Object?> get props => [gitUrl];
}

// ─── State ────────────────────────────────────────────────────────────────

class SettingsState extends Equatable {
  final String projectId;
  final String selectedEnv;
  final List<String> availableEnvs;
  final AndroidSigningCredentials androidCreds;
  final AppleApiKey appleApiKey;
  final bool firebaseServiceAccountConfigured;
  final String firebaseServiceAccountEmail; // client_email shown in UI
  final bool playStoreKeyConfigured;
  final String playStoreKeyEmail;

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

  final MatchConfig matchConfig;
  final SmtpConfig smtpConfig;
  final bool isSendingTestEmail;
  final SlackConfig slackConfig;
  final bool isSendingSlackTest;
  final TeamsConfig teamsConfig;
  final bool isSendingTeamsTest;
  final GoogleChatConfig googleChatConfig;
  final bool isSendingGoogleChatTest;
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
    this.appleApiKey = const AppleApiKey(),
    this.firebaseServiceAccountConfigured = false,
    this.firebaseServiceAccountEmail = '',
    this.playStoreKeyConfigured = false,
    this.playStoreKeyEmail = '',
    this.androidPackageName = '',
    this.androidFirebaseAppId = '',
    this.iosBundleId = '',
    this.iosFirebaseAppId = '',
    this.iosTeamId = '',
    this.iosExportMethod = 'app-store',
    this.iosProvisioningProfile = '',
    this.dartDefineFromFile = '',
    this.firebaseTesterGroups = '',
    this.matchConfig = const MatchConfig(),
    this.smtpConfig = const SmtpConfig(),
    this.isSendingTestEmail = false,
    this.slackConfig = const SlackConfig(),
    this.isSendingSlackTest = false,
    this.teamsConfig = const TeamsConfig(),
    this.isSendingTeamsTest = false,
    this.googleChatConfig = const GoogleChatConfig(),
    this.isSendingGoogleChatTest = false,
    this.isLoading = false,
    this.savedMessage,
    this.error,
  });

  SettingsState copyWith({
    String? projectId,
    String? selectedEnv,
    List<String>? availableEnvs,
    AndroidSigningCredentials? androidCreds,
    AppleApiKey? appleApiKey,
    bool? firebaseServiceAccountConfigured,
    String? firebaseServiceAccountEmail,
    bool? playStoreKeyConfigured,
    String? playStoreKeyEmail,
    String? androidPackageName,
    String? androidFirebaseAppId,
    String? iosBundleId,
    String? iosFirebaseAppId,
    String? iosTeamId,
    String? iosExportMethod,
    String? iosProvisioningProfile,
    String? dartDefineFromFile,
    String? firebaseTesterGroups,
    MatchConfig? matchConfig,
    SmtpConfig? smtpConfig,
    bool? isSendingTestEmail,
    SlackConfig? slackConfig,
    bool? isSendingSlackTest,
    TeamsConfig? teamsConfig,
    bool? isSendingTeamsTest,
    GoogleChatConfig? googleChatConfig,
    bool? isSendingGoogleChatTest,
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
        appleApiKey: appleApiKey ?? this.appleApiKey,
        firebaseServiceAccountConfigured:
            firebaseServiceAccountConfigured ?? this.firebaseServiceAccountConfigured,
        firebaseServiceAccountEmail:
            firebaseServiceAccountEmail ?? this.firebaseServiceAccountEmail,
        playStoreKeyConfigured: playStoreKeyConfigured ?? this.playStoreKeyConfigured,
        playStoreKeyEmail: playStoreKeyEmail ?? this.playStoreKeyEmail,
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
        matchConfig: matchConfig ?? this.matchConfig,
        smtpConfig: smtpConfig ?? this.smtpConfig,
        isSendingTestEmail: isSendingTestEmail ?? this.isSendingTestEmail,
        slackConfig: slackConfig ?? this.slackConfig,
        isSendingSlackTest: isSendingSlackTest ?? this.isSendingSlackTest,
        teamsConfig: teamsConfig ?? this.teamsConfig,
        isSendingTeamsTest: isSendingTeamsTest ?? this.isSendingTeamsTest,
        googleChatConfig: googleChatConfig ?? this.googleChatConfig,
        isSendingGoogleChatTest:
            isSendingGoogleChatTest ?? this.isSendingGoogleChatTest,
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
        appleApiKey.keyId,
        appleApiKey.issuerId,
        firebaseServiceAccountConfigured,
        firebaseServiceAccountEmail,
        playStoreKeyConfigured,
        playStoreKeyEmail,
        androidPackageName,
        androidFirebaseAppId,
        iosBundleId,
        iosFirebaseAppId,
        iosTeamId,
        iosExportMethod,
        iosProvisioningProfile,
        dartDefineFromFile,
        firebaseTesterGroups,
        matchConfig.gitUrl,
        matchConfig.readonly,
        smtpConfig.enabled,
        smtpConfig.host,
        smtpConfig.recipient,
        isSendingTestEmail,
        slackConfig.enabled,
        slackConfig.webhookUrl,
        isSendingSlackTest,
        teamsConfig.enabled,
        teamsConfig.webhookUrl,
        isSendingTeamsTest,
        googleChatConfig.enabled,
        googleChatConfig.webhookUrl,
        isSendingGoogleChatTest,
        isLoading,
        savedMessage,
        error,
      ];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final CredentialStore _creds;
  final ConfigRepository _configRepo;
  final EmailNotificationService _emailService;
  final SlackNotificationService _slackService;
  final TeamsNotificationService _teamsService;
  final GoogleChatNotificationService _googleChatService;

  SettingsBloc(
    this._creds,
    this._configRepo,
    this._emailService,
    this._slackService,
    this._teamsService,
    this._googleChatService,
  ) : super(const SettingsState()) {
    on<SettingsOpened>(_onOpened);
    on<SettingsEnvChanged>(_onEnvChanged);
    on<AndroidSigningSaved>(_onAndroidSigningSaved);
    on<AppleApiKeySaved>(_onAppleApiKeySaved);
    on<FirebaseServiceAccountSaved>(_onFirebaseServiceAccountSaved);
    on<PlayStoreKeyPathSaved>(_onPlayStoreKeyPathSaved);
    on<EnvConfigFieldUpdated>(_onFieldUpdated);
    on<EnvConfigSaved>(_onEnvConfigSaved);
    on<EmailConfigSaved>(_onEmailConfigSaved);
    on<EmailTestRequested>(_onEmailTestRequested);
    on<SlackConfigSaved>(_onSlackConfigSaved);
    on<SlackTestRequested>(_onSlackTestRequested);
    on<TeamsConfigSaved>(_onTeamsConfigSaved);
    on<TeamsTestRequested>(_onTeamsTestRequested);
    on<GoogleChatConfigSaved>(_onGoogleChatConfigSaved);
    on<GoogleChatTestRequested>(_onGoogleChatTestRequested);
    on<MatchConfigSaved>(_onMatchConfigSaved);
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
      final appleApiKey = await _creds.loadAppleApiKey(
          projectId: projectId, envName: envName);
      final firebaseContent = await _creds.loadFirebaseServiceAccount();
      final playStoreContent = await _creds.loadPlayStoreKey();
      String firebaseEmail = '';
      if (firebaseContent.isNotEmpty) {
        try {
          final j = jsonDecode(firebaseContent) as Map<String, dynamic>;
          firebaseEmail = j['client_email'] as String? ?? '';
        } catch (_) {}
      }
      String playStoreEmail = '';
      if (playStoreContent.isNotEmpty) {
        try {
          final j = jsonDecode(playStoreContent) as Map<String, dynamic>;
          playStoreEmail = j['client_email'] as String? ?? '';
        } catch (_) {}
      }
      final smtpConfig = await _creds.loadSmtpConfig();
      final slackConfig = await _creds.loadSlackConfig();
      final teamsConfig = await _creds.loadTeamsConfig();
      final googleChatConfig = await _creds.loadGoogleChatConfig();
      final matchConfig = await _creds.loadMatchConfig(projectId);
      final envConfig = await _configRepo.loadEnv(projectId, envName);

      emit(state.copyWith(
        availableEnvs: envs.isNotEmpty ? envs : ['dev', 'staging', 'prod'],
        androidCreds: androidCreds,
        appleApiKey: appleApiKey,
        firebaseServiceAccountConfigured: firebaseContent.isNotEmpty,
        firebaseServiceAccountEmail: firebaseEmail,
        playStoreKeyConfigured: playStoreContent.isNotEmpty,
        playStoreKeyEmail: playStoreEmail,
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
        matchConfig: matchConfig,
        smtpConfig: smtpConfig,
        slackConfig: slackConfig,
        teamsConfig: teamsConfig,
        googleChatConfig: googleChatConfig,
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

  Future<void> _onAppleApiKeySaved(
      AppleApiKeySaved event, Emitter<SettingsState> emit) async {
    try {
      await _creds.saveAppleApiKey(
        projectId: state.projectId,
        envName: state.selectedEnv,
        keyId: event.keyId,
        issuerId: event.issuerId,
        privateKeyContent: event.privateKeyContent,
      );
      emit(state.copyWith(
        appleApiKey: AppleApiKey(
          keyId: event.keyId,
          issuerId: event.issuerId,
          privateKeyContent: event.privateKeyContent,
        ),
        savedMessage: 'App Store Connect API key saved to Keychain',
      ));
      await Future.delayed(const Duration(seconds: 3));
      emit(state.copyWith(clearSaved: true));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onFirebaseServiceAccountSaved(
      FirebaseServiceAccountSaved event, Emitter<SettingsState> emit) async {
    try {
      await _creds.saveFirebaseServiceAccount(event.content);
      emit(state.copyWith(
        firebaseServiceAccountConfigured: true,
        firebaseServiceAccountEmail: event.displayEmail,
        savedMessage: 'Firebase service account saved to Keychain',
      ));
      await Future.delayed(const Duration(seconds: 3));
      emit(state.copyWith(clearSaved: true));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onPlayStoreKeyPathSaved(
      PlayStoreKeyPathSaved event, Emitter<SettingsState> emit) async {
    try {
      await _creds.savePlayStoreKey(event.content);
      emit(state.copyWith(
        playStoreKeyConfigured: true,
        playStoreKeyEmail: event.displayEmail,
        savedMessage: 'Play Store key saved to Keychain',
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

  Future<void> _onEmailConfigSaved(
      EmailConfigSaved event, Emitter<SettingsState> emit) async {
    try {
      await _creds.saveSmtpConfig(event.config);
      emit(state.copyWith(
        smtpConfig: event.config,
        savedMessage: 'Email notification settings saved to Keychain',
      ));
      await Future.delayed(const Duration(seconds: 3));
      emit(state.copyWith(clearSaved: true));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onEmailTestRequested(
      EmailTestRequested event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(isSendingTestEmail: true, clearError: true));
    try {
      await _emailService.sendTestEmail(event.config);
      emit(state.copyWith(
        isSendingTestEmail: false,
        savedMessage: 'Test email sent to ${event.config.recipient}',
      ));
      await Future.delayed(const Duration(seconds: 3));
      emit(state.copyWith(clearSaved: true));
    } catch (e) {
      emit(state.copyWith(
        isSendingTestEmail: false,
        error: 'Failed to send test email: $e',
      ));
    }
  }

  Future<void> _onSlackConfigSaved(
      SlackConfigSaved event, Emitter<SettingsState> emit) async {
    try {
      await _creds.saveSlackConfig(event.config);
      emit(state.copyWith(
        slackConfig: event.config,
        savedMessage: 'Slack settings saved to Keychain',
      ));
      await Future.delayed(const Duration(seconds: 3));
      emit(state.copyWith(clearSaved: true));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onSlackTestRequested(
      SlackTestRequested event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(isSendingSlackTest: true, clearError: true));
    try {
      await _slackService.sendTestMessage(event.config.webhookUrl);
      emit(state.copyWith(
        isSendingSlackTest: false,
        savedMessage: 'Test message posted to Slack',
      ));
      await Future.delayed(const Duration(seconds: 3));
      emit(state.copyWith(clearSaved: true));
    } catch (e) {
      emit(state.copyWith(
        isSendingSlackTest: false,
        error: 'Failed to post to Slack: $e',
      ));
    }
  }

  Future<void> _onTeamsConfigSaved(
      TeamsConfigSaved event, Emitter<SettingsState> emit) async {
    try {
      await _creds.saveTeamsConfig(event.config);
      emit(state.copyWith(
        teamsConfig: event.config,
        savedMessage: 'Teams settings saved to Keychain',
      ));
      await Future.delayed(const Duration(seconds: 3));
      emit(state.copyWith(clearSaved: true));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onTeamsTestRequested(
      TeamsTestRequested event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(isSendingTeamsTest: true, clearError: true));
    try {
      await _teamsService.sendTestMessage(event.config.webhookUrl);
      emit(state.copyWith(
        isSendingTeamsTest: false,
        savedMessage: 'Test message posted to Teams',
      ));
      await Future.delayed(const Duration(seconds: 3));
      emit(state.copyWith(clearSaved: true));
    } catch (e) {
      emit(state.copyWith(
        isSendingTeamsTest: false,
        error: 'Failed to post to Teams: $e',
      ));
    }
  }

  Future<void> _onGoogleChatConfigSaved(
      GoogleChatConfigSaved event, Emitter<SettingsState> emit) async {
    try {
      await _creds.saveGoogleChatConfig(event.config);
      emit(state.copyWith(
        googleChatConfig: event.config,
        savedMessage: 'Google Chat settings saved to Keychain',
      ));
      await Future.delayed(const Duration(seconds: 3));
      emit(state.copyWith(clearSaved: true));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onGoogleChatTestRequested(
      GoogleChatTestRequested event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(isSendingGoogleChatTest: true, clearError: true));
    try {
      await _googleChatService.sendTestMessage(event.config.webhookUrl);
      emit(state.copyWith(
        isSendingGoogleChatTest: false,
        savedMessage: 'Test message posted to Google Chat',
      ));
      await Future.delayed(const Duration(seconds: 3));
      emit(state.copyWith(clearSaved: true));
    } catch (e) {
      emit(state.copyWith(
        isSendingGoogleChatTest: false,
        error: 'Failed to post to Google Chat: $e',
      ));
    }
  }

  Future<void> _onMatchConfigSaved(
      MatchConfigSaved event, Emitter<SettingsState> emit) async {
    try {
      await _creds.saveMatchConfig(
        projectId: state.projectId,
        gitUrl: event.gitUrl,
        password: event.password,
        readonly: event.readonly,
      );
      emit(state.copyWith(
        matchConfig: MatchConfig(
          gitUrl: event.gitUrl,
          password: event.password,
          readonly: event.readonly,
        ),
        savedMessage: 'Fastlane Match config saved to Keychain',
      ));
      await Future.delayed(const Duration(seconds: 3));
      emit(state.copyWith(clearSaved: true));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
