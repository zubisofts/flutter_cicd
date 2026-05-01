import 'package:flutter/material.dart';
import 'app.dart';
import 'di/injection.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();
  runApp(const CicdApp());
}
