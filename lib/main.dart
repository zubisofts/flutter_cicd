import 'package:flutter/material.dart';
import 'package:local_notifier/local_notifier.dart';
import 'app.dart';
import 'di/injection.dart';
import 'services/theme_service.dart';
import 'services/tray_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await localNotifier.setup(appName: 'FlutterCI');
  final themeService = await ThemeService.load();
  setupDependencies(themeService: themeService);
  await getIt<TrayService>().init();
  runApp(const CicdApp());
}
