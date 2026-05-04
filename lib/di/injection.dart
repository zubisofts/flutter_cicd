import 'package:get_it/get_it.dart';
import '../config/config_repository.dart';
import '../config/environment_resolver.dart';
import '../data/database.dart';
import '../data/run_repository.dart';
import '../engine/build_queue.dart';
import '../engine/pipeline_runner.dart';
import '../engine/step_registry.dart';
import '../services/credential_store.dart';
import '../services/email_notification_service.dart';
import '../services/google_chat_notification_service.dart';
import '../services/slack_notification_service.dart';
import '../services/teams_notification_service.dart';
import '../services/theme_service.dart';
import '../services/tray_service.dart';
import '../ui/execution/execution_bloc.dart';

final getIt = GetIt.instance;

void setupDependencies({required ThemeService themeService}) {
  getIt.registerSingleton<ThemeService>(themeService);
  // Credentials (macOS Keychain)
  getIt.registerLazySingleton<CredentialStore>(() => CredentialStore());
  getIt.registerLazySingleton<EmailNotificationService>(
      () => EmailNotificationService(getIt<CredentialStore>()));
  getIt.registerLazySingleton<SlackNotificationService>(
      () => SlackNotificationService(getIt<CredentialStore>()));
  getIt.registerLazySingleton<TeamsNotificationService>(
      () => TeamsNotificationService(getIt<CredentialStore>()));
  getIt.registerLazySingleton<GoogleChatNotificationService>(
      () => GoogleChatNotificationService(getIt<CredentialStore>()));

  // Tray (menu bar status icon)
  getIt.registerLazySingleton<TrayService>(() => TrayService());

  // Config
  getIt.registerLazySingleton<ConfigRepository>(() => ConfigRepository());
  getIt.registerLazySingleton<EnvironmentResolver>(
      () => EnvironmentResolver(
            getIt<ConfigRepository>(),
            getIt<CredentialStore>(),
          ));

  // Data
  getIt.registerLazySingleton<AppDatabase>(() => AppDatabase());
  getIt.registerLazySingleton<RunRepository>(
      () => RunRepository(getIt<AppDatabase>()));

  // Engine
  getIt.registerLazySingleton<StepRegistry>(() => StepRegistry.defaults);
  getIt.registerLazySingleton<PipelineRunner>(
    () => PipelineRunner(
      configRepo: getIt<ConfigRepository>(),
      envResolver: getIt<EnvironmentResolver>(),
      registry: getIt<StepRegistry>(),
    ),
  );
  getIt.registerLazySingleton<BuildQueue>(
    () => BuildQueue(
      configRepo: getIt<ConfigRepository>(),
      envResolver: getIt<EnvironmentResolver>(),
    ),
  );

  // UI — singleton so navigating away and back doesn't lose the active run
  getIt.registerLazySingleton<ExecutionBloc>(
    () => ExecutionBloc(
      getIt<PipelineRunner>(),
      getIt<RunRepository>(),
      getIt<EmailNotificationService>(),
      getIt<SlackNotificationService>(),
      getIt<TeamsNotificationService>(),
      getIt<GoogleChatNotificationService>(),
      getIt<TrayService>(),
    ),
  );
}
