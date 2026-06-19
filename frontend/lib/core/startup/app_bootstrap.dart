import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../features/lessons/data/local/lesson_cache_store.dart';
import '../../features/notifications/data/services/fcm_service.dart';
import '../../features/practice/data/models/practice_recording_hive_adapter.dart';
import '../../features/practice/data/models/recording_hive_adapters.dart';
import '../../features/practice/domain/entities/practice_repertoire.dart';
import '../../features/practice/domain/entities/recording.dart';
import '../../features/student_home/data/models/manual_teacher_hive_model.dart';
import '../../firebase_options.dart';
import '../audio/audio_session_manager.dart';
import 'startup_recovery.dart';

Future<StartupRecoveryResult> bootstrapApp() async {
  // Web is a QA / click-through dogfooding target only. Firebase has no web
  // options configured (see firebase_options.dart — currentPlatform throws
  // UnsupportedError on web), the native audio session and the dart:io-based
  // recording-path recovery are unavailable on web. Guard them so the app
  // boots in Chrome for the route/interaction/web-chrome gates (#731).
  // Real web Firebase/FCM configuration is tracked separately (#475).
  if (!kIsWeb) {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Configure audio session for simultaneous playback and recording
    // This prevents metronome interruption when tuner starts
    await AudioSessionManager.configureForPlayAndRecord();
  }

  // Initialize Hive for local storage (web uses the IndexedDB adapter)
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(RecordingTypeAdapter());
  Hive.registerAdapter(StorageStatusAdapter());
  Hive.registerAdapter(RecordingAdapter());
  Hive.registerAdapter(PracticeRecordingAdapter());
  Hive.registerAdapter(ManualTeacherAdapter());

  // Open Hive boxes at startup to ensure persistence
  final recordingsBox = await Hive.openBox<Recording>('recordings');
  final practiceRecordingsBox = await Hive.openBox<PracticeRecording>(
    'practice_recordings',
  );
  await Hive.openBox('notification_settings');
  await Hive.openBox<String>('app_review_state');
  await Hive.openBox<String>(LessonCacheStore.boxName);

  // Recording-path recovery uses dart:io (File/Directory) + path_provider,
  // which are native-only. Skip on web.
  final recoveryResult = kIsWeb
      ? (recovered: 0, cleanedUp: 0, total: 0)
      : await recoverStartupRecordingPaths(
          recordingsBox: recordingsBox,
          practiceRecordingsBox: practiceRecordingsBox,
        );

  // Initialize date formatting for Korean locale
  await initializeDateFormatting('ko');

  // Set preferred orientations (native only — no-op concept on web)
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  return recoveryResult;
}
