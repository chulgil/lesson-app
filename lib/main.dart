import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/practice/domain/entities/practice_repertoire.dart';
import 'models/recording.dart';
import 'providers/metronome/metronome_provider.dart';
import 'repositories/recording_repository.dart';

/// Startup recovery result for UI display.
({int recovered, int cleanedUp, int total})? _startupRecoveryResult;

/// Recover practice recording paths that became invalid due to container UUID changes.
/// Returns the number of recovered recordings.
Future<int> _recoverPracticeRecordingPaths(Box<PracticeRecording> box) async {
  final appDir = await getApplicationDocumentsDirectory();
  final currentBasePath = appDir.path;
  int recoveredCount = 0;

  debugPrint('=== Main: Recovering practice recording paths ===');
  debugPrint('  Current base path: $currentBasePath');

  for (final recording in box.values.toList()) {
    final storedPath = recording.filePath;
    final file = File(storedPath);

    // Skip if file exists at stored path
    if (await file.exists()) {
      continue;
    }

    debugPrint('  Checking: ${recording.id.substring(0, 8)}...');
    debugPrint('    Stored path: $storedPath');

    String? newPath;

    // Strategy 1: Extract relative path and reconstruct with current base
    // iOS path format: /var/mobile/Containers/Data/Application/[UUID]/Documents/recordings/...
    final documentsIndex = storedPath.indexOf('/Documents/');
    if (documentsIndex != -1) {
      final relativePath = storedPath.substring(documentsIndex + '/Documents/'.length);
      final reconstructedPath = '$currentBasePath/$relativePath';
      final reconstructedFile = File(reconstructedPath);
      if (await reconstructedFile.exists()) {
        newPath = reconstructedPath;
        debugPrint('    Strategy 1 (path reconstruction) succeeded');
      }
    }

    // Strategy 2: Search by filename in recordings directory
    if (newPath == null) {
      final fileName = storedPath.split('/').last;
      final recordingsDir = Directory('$currentBasePath/recordings');
      if (await recordingsDir.exists()) {
        await for (final entity in recordingsDir.list(recursive: true)) {
          if (entity is File && entity.path.endsWith(fileName)) {
            newPath = entity.path;
            debugPrint('    Strategy 2 (filename search) succeeded');
            break;
          }
        }
      }
    }

    // Update path if recovered
    if (newPath != null) {
      debugPrint('    Recovered path: $newPath');
      final updated = recording.copyWith(filePath: newPath);
      await box.put(recording.key, updated);
      recoveredCount++;
    } else {
      debugPrint('    Could not recover - file may be deleted');
    }
  }

  if (recoveredCount > 0) {
    await box.flush();
    debugPrint('  Recovered $recoveredCount practice recordings');
  } else {
    debugPrint('  No practice recording paths needed recovery');
  }

  debugPrint('=== Practice recording recovery complete ===');
  return recoveredCount;
}

/// Clean up orphaned practice recordings (DB entries without actual files).
/// Returns the number of cleaned up recordings.
Future<int> _cleanupOrphanedPracticeRecordings(Box<PracticeRecording> box) async {
  final orphanedKeys = <dynamic>[];

  debugPrint('=== Main: Checking for orphaned practice recordings ===');

  for (final recording in box.values) {
    final file = File(recording.filePath);
    if (!await file.exists()) {
      orphanedKeys.add(recording.key);
      debugPrint('  Orphaned: ${recording.id.substring(0, 8)}... (file not found: ${recording.filePath})');
    }
  }

  if (orphanedKeys.isEmpty) {
    debugPrint('  No orphaned practice recordings found');
    return 0;
  }

  // Delete orphaned recordings from DB
  for (final key in orphanedKeys) {
    await box.delete(key);
  }
  await box.flush();

  debugPrint('  Cleaned up ${orphanedKeys.length} orphaned practice recordings');
  debugPrint('=== Practice recording cleanup complete ===');

  return orphanedKeys.length;
}

/// Get the startup recovery result.
({int recovered, int cleanedUp, int total})? getStartupRecoveryResult() => _startupRecoveryResult;

/// Clear the startup recovery result after showing.
void clearStartupRecoveryResult() {
  _startupRecoveryResult = null;
}

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

  // Recover recording paths at startup (fixes Issue #9)
  // We have two types of recordings: Recording and PracticeRecording
  // The user's practice recordings are stored in practiceRecordingsBox

  // 1. Recover Recording paths (for lesson recordings)
  final repository = HiveRecordingRepository();
  final recordingRecovered = await repository.migrateAndRecoverPaths();
  final recordingCleanedUp = await repository.cleanupOrphanedRecordings();

  // 2. Recover PracticeRecording paths (for practice recordings - this is the main one!)
  final practiceRecovered = await _recoverPracticeRecordingPaths(practiceRecordingsBox);
  final practiceCleanedUp = await _cleanupOrphanedPracticeRecordings(practiceRecordingsBox);

  // Combine results for UI display
  final totalRecordings = recordingsBox.length + practiceRecordingsBox.length;
  final totalRecovered = recordingRecovered + practiceRecovered;
  final totalCleanedUp = recordingCleanedUp + practiceCleanedUp;

  // Always store result for diagnostic purposes
  _startupRecoveryResult = (
    recovered: totalRecovered,
    cleanedUp: totalCleanedUp,
    total: totalRecordings,
  );
  debugPrint('=== Main: All recording recovery complete ===');
  debugPrint('Main: Total=$totalRecordings (recordings=${recordingsBox.length}, practice=${practiceRecordingsBox.length})');
  debugPrint('Main: Recovered=$totalRecovered (recordings=$recordingRecovered, practice=$practiceRecovered)');
  debugPrint('Main: CleanedUp=$totalCleanedUp (recordings=$recordingCleanedUp, practice=$practiceCleanedUp)');

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