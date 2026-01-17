import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';

import 'core/audio/audio_session_manager.dart';
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
  debugPrint('  Total recordings in box: ${box.length}');

  // Pre-build file map for efficient lookup
  // Map structure: { fileName: [fullPath1, fullPath2, ...] }
  final fileMap = <String, List<String>>{};
  final recordingsDir = Directory('$currentBasePath/recordings');

  if (await recordingsDir.exists()) {
    debugPrint('  Building file map from recordings directory...');
    await for (final entity in recordingsDir.list(recursive: true)) {
      if (entity is File) {
        final fileName = entity.path.split('/').last;
        fileMap.putIfAbsent(fileName, () => []).add(entity.path);
      }
    }
    debugPrint('  File map built: ${fileMap.length} unique files found');

    // Log all found files for debugging
    for (final entry in fileMap.entries) {
      for (final path in entry.value) {
        debugPrint('    Found: $path');
      }
    }
  } else {
    debugPrint('  WARNING: Recordings directory does not exist!');
  }

  // Also check backup directory
  final backupDir = Directory('$currentBasePath/recording_backups');
  if (await backupDir.exists()) {
    debugPrint('  Also checking backup directory...');
    await for (final entity in backupDir.list(recursive: true)) {
      if (entity is File) {
        final fileName = entity.path.split('/').last;
        fileMap.putIfAbsent(fileName, () => []).add(entity.path);
      }
    }
  }

  for (final recording in box.values.toList()) {
    final storedPath = recording.filePath;
    final file = File(storedPath);

    // Skip if file exists at stored path
    if (await file.exists()) {
      debugPrint('  OK: ${recording.id.substring(0, 8)}... (file exists)');
      continue;
    }

    debugPrint('  Checking: ${recording.id.substring(0, 8)}...');
    debugPrint('    Stored path: $storedPath');
    debugPrint('    Section ID: ${recording.sectionId}');

    String? newPath;

    // Strategy 1: Extract relative path and reconstruct with current base
    // iOS path format: /var/mobile/Containers/Data/Application/[UUID]/Documents/recordings/...
    final documentsIndex = storedPath.indexOf('/Documents/');
    if (documentsIndex != -1) {
      final relativePath = storedPath.substring(documentsIndex + '/Documents/'.length);
      final reconstructedPath = '$currentBasePath/$relativePath';
      debugPrint('    Strategy 1: Trying $reconstructedPath');
      final reconstructedFile = File(reconstructedPath);
      if (await reconstructedFile.exists()) {
        newPath = reconstructedPath;
        debugPrint('    Strategy 1 (path reconstruction) succeeded');
      }
    }

    // Strategy 2: Look up in pre-built file map by exact filename
    if (newPath == null) {
      final fileName = storedPath.split('/').last;
      debugPrint('    Strategy 2: Looking for filename "$fileName" in file map');
      final matches = fileMap[fileName];
      if (matches != null && matches.isNotEmpty) {
        if (matches.length == 1) {
          newPath = matches.first;
          debugPrint('    Strategy 2 (exact match) succeeded');
        } else {
          // Multiple matches - try to find one in the same section folder
          debugPrint('    Strategy 2: Multiple matches (${matches.length}), checking section...');
          for (final match in matches) {
            // Check if path contains section ID or repertoire ID pattern
            if (match.contains(recording.sectionId) ||
                match.contains('rep_') ||
                match.contains('/recordings/')) {
              newPath = match;
              debugPrint('    Strategy 2 (section match) succeeded: $match');
              break;
            }
          }
          // If still no match, just use first one
          newPath ??= matches.first;
          debugPrint('    Strategy 2 (first match) used: $newPath');
        }
      }
    }

    // Strategy 3: Search by recording ID in filename
    if (newPath == null) {
      final recordingId = recording.id;
      debugPrint('    Strategy 3: Searching for ID pattern "$recordingId" in files');
      for (final entry in fileMap.entries) {
        if (entry.key.contains(recordingId.substring(0, 8))) {
          newPath = entry.value.first;
          debugPrint('    Strategy 3 (ID pattern) succeeded');
          break;
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

  // Configure audio session for simultaneous playback and recording
  // This prevents metronome interruption when tuner starts
  await AudioSessionManager.configureForPlayAndRecord();

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