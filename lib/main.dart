import 'package:flutter/material.dart';
import 'package:local_notifier/local_notifier.dart';
import 'app.dart';
import 'di/injection.dart';
import 'services/tray_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await localNotifier.setup(appName: 'FlutterCI');
  setupDependencies();
  await getIt<TrayService>().init();
  runApp(const CicdApp());
}
