import 'package:flutter/material.dart';
import 'package:modula_lms/app/app.dart';
import 'package:modula_lms/core/di/service_locator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  setupLocator();

  runApp(const App());
}
