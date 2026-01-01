import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/practice/domain/entities/practice_repertoire.dart';
import 'models/recording.dart';
import 'providers/metronome/metronome_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(RecordingTypeAdapter());
  Hive.registerAdapter(StorageStatusAdapter());
  Hive.registerAdapter(RecordingAdapter());
  Hive.registerAdapter(PracticeRecordingAdapter());

  // Open Hive boxes at startup to ensure persistence
  final recordingsBox = await Hive.openBox<Recording>('recordings');
  final practiceRecordingsBox = await Hive.openBox<PracticeRecording>('practice_recordings');
  debugPrint('=== Main: Hive boxes opened at startup ===');
  debugPrint('Main: recordings box length: ${recordingsBox.length}');
  debugPrint('Main: practice_recordings box length: ${practiceRecordingsBox.length}');
  for (final r in practiceRecordingsBox.values) {
    debugPrint('  Main: ${r.id.substring(0, 8)}... -> ${r.filePath}');
  }
  debugPrint('=== End of startup box check ===');

  // Initialize date formatting for Korean locale
  await initializeDateFormatting('ko');

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    const ProviderScope(
      child: LessonApp(),
    ),
  );
}

class LessonApp extends ConsumerStatefulWidget {
  const LessonApp({super.key});

  @override
  ConsumerState<LessonApp> createState() => _LessonAppState();
}

class _LessonAppState extends ConsumerState<LessonApp> {
  @override
  void initState() {
    super.initState();
    // Pre-initialize metronome engine at app startup to eliminate play delay
    Future.microtask(() {
      ref.read(metronomeProvider.notifier).warmUp();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Lesson App',
      debugShowCheckedModeBanner: false,

      // Localization
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ko', 'KR'),

      // Theme
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,

      // Router
      routerConfig: AppRouter.router,
    );
  }
}