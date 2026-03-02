import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lessonaza/models/recording.dart';

/// Initialize test environment with Hive and other dependencies.
Future<void> initializeTestEnvironment() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock path_provider
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall methodCall) async {
          return Directory.systemTemp.path;
        },
      );

  // Initialize Hive with temp directory
  final tempDir = Directory.systemTemp.createTempSync('lessonaza_test_');
  Hive.init(tempDir.path);

  // Register adapters if not already registered
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(RecordingTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(StorageStatusAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(RecordingAdapter());
  }
}

/// Clean up test environment.
Future<void> cleanupTestEnvironment() async {
  await Hive.close();
}
