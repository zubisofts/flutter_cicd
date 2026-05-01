import 'package:get_it/get_it.dart';
import '../config/config_repository.dart';
import '../config/environment_resolver.dart';
import '../data/database.dart';
import '../data/run_repository.dart';
import '../engine/pipeline_runner.dart';
import '../engine/step_registry.dart';
import '../services/credential_store.dart';
import '../ui/execution/execution_bloc.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Credentials (macOS Keychain)
  getIt.registerLazySingleton<CredentialStore>(() => CredentialStore());

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

  // UI — singleton so navigating away and back doesn't lose the active run
  getIt.registerLazySingleton<ExecutionBloc>(
    () => ExecutionBloc(getIt<PipelineRunner>(), getIt<RunRepository>()),
  );
}
