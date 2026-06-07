import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app/app.dart';
import 'app/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Hive for local storage
  await Hive.initFlutter();
  await Hive.openBox(AppConstants.hiveBoxSession);
  await Hive.openBox(AppConstants.hiveBoxProfile);
  await Hive.openBox(AppConstants.hiveBoxSettings);

  runApp(
    const ProviderScope(
      child: GigCreditApp(),
    ),
  );
}
