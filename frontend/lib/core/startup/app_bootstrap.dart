import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show FlutterError, kIsWeb;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../features/gamification/data/repositories/hive_streak_freeze_repository.dart';
import '../../features/gamification/data/repositories/hive_student_quest_repository.dart';
import '../../features/gamification/data/services/growth_heatmap_chunk_cache.dart';
import '../../features/notifications/data/services/fcm_service.dart';
import '../../features/practice/data/models/practice_recording_hive_adapter.dart';
import '../../features/practice/data/models/recording_hive_adapters.dart';
import '../../features/practice/domain/entities/practice_repertoire.dart';
import '../../features/practice/domain/entities/recording.dart';
import '../../features/student_home/data/models/manual_teacher_hive_model.dart';
import '../../firebase_options.dart';
import '../analytics/analytics_provider.dart';
import '../audio/audio_session_manager.dart';
import '../network/cache/response_cache_store.dart';
import 'startup_recovery.dart';

Future<StartupRecoveryResult> bootstrapApp() async {
  // Signature fonts (Playfair Display / Gaegu / IBM Plex Mono) are bundled as
  // local assets under assets/google_fonts/. Force google_fonts to load from
  // the bundle only — never fetch at runtime — so the notebook signature
  // typography renders identically offline (offline-first) instead of silently
  // falling back to the default sans and looking the same as the body text.
  GoogleFonts.config.allowRuntimeFetching = false;

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

    // Crash reporting (§6.6 launch-readiness). Crashlytics collects crash
    // data by default (standard SDK behavior) — this must be disclosed in the
    // app's Korean privacy policy (개인정보처리방침). Wired only inside this
    // !kIsWeb block: Firebase has no web options (see comment above), so
    // touching FirebaseCrashlytics.instance on web throws before boot.
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

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
  // Offline-first read cache (offline-first plan §3 option A). The
  // ResponseCacheInterceptor reads/writes this box synchronously.
  await Hive.openBox<String>(ResponseCacheStore.boxName);

  // gamification 로컬 영속 (#422) — heatmap/streak/quest 휘발 해소.
  // provider 가 sync 로 Hive.box(...) 를 동기 참조하도록 부팅 시 미리 연다.
  await Hive.openBox<String>(GrowthHeatmapChunkCache.boxName);
  await Hive.openBox<String>(HiveStreakFreezeRepository.boxName);
  await Hive.openBox<String>(HiveStudentQuestRepository.boxName);

  // Recording-path recovery uses dart:io (File/Directory) + path_provider,
  // which are native-only. Skip on web.
  final recoveryResult =
      kIsWeb
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

  // #1209 — cold start. Fire-and-forget after init succeeded; the analytics
  // sink swallows its own failures and is a no-op wherever Firebase is not
  // configured (web), so this can never block or fail boot. The role is not
  // known yet at this point (auth resolves later), so it is omitted.
  unawaited(analytics.logAppOpened());

  return recoveryResult;
}
