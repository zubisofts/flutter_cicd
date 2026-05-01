import 'package:flutter/material.dart';
import 'app.dart';
import 'di/injection.dart';
import 'services/tray_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();
  await getIt<TrayService>().init();
  runApp(const CicdApp());
}
