import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/practice/domain/entities/practice_repertoire.dart';
import '../../features/practice/domain/entities/recording.dart';
import '../../features/practice/data/repositories/hive_recording_repository.dart';

/// Startup recovery result for UI display.
typedef StartupRecoveryResult = ({int recovered, int cleanedUp, int total});

StartupRecoveryResult? _startupRecoveryResult;

/// Get the startup recovery result.
StartupRecoveryResult? getStartupRecoveryResult() => _startupRecoveryResult;

/// Clear the startup recovery result after showing.
void clearStartupRecoveryResult() {
  _startupRecoveryResult = null;
}

/// Recover recording paths at startup (fixes Issue #9).
Future<StartupRecoveryResult> recoverStartupRecordingPaths({
  required Box<Recording> recordingsBox,
  required Box<PracticeRecording> practiceRecordingsBox,
}) async {
  // We have two types of recordings: Recording and PracticeRecording.
  // The user's practice recordings are stored in practiceRecordingsBox.

  // 1. Recover Recording paths (for lesson recordings).
  final repository = HiveRecordingRepository();
  final recordingRecovered = await repository.migrateAndRecoverPaths();
  final recordingCleanedUp = await repository.cleanupOrphanedRecordings();

  // 2. Recover PracticeRecording paths (for practice recordings - this is the main one!).
  final practiceRecovered = await _recoverPracticeRecordingPaths(
    practiceRecordingsBox,
  );
  final practiceCleanedUp = await _cleanupOrphanedPracticeRecordings(
    practiceRecordingsBox,
  );

  // Combine results for UI display.
  final totalRecordings = recordingsBox.length + practiceRecordingsBox.length;
  final totalRecovered = recordingRecovered + practiceRecovered;
  final totalCleanedUp = recordingCleanedUp + practiceCleanedUp;

  final result = (
    recovered: totalRecovered,
    cleanedUp: totalCleanedUp,
    total: totalRecordings,
  );
  _startupRecoveryResult = result;
  return result;
}

/// Recover practice recording paths that became invalid due to container UUID changes.
/// Returns the number of recovered recordings.
Future<int> _recoverPracticeRecordingPaths(Box<PracticeRecording> box) async {
  final appDir = await getApplicationDocumentsDirectory();
  final currentBasePath = appDir.path;
  int recoveredCount = 0;

  // Pre-build file map for efficient lookup
  final fileMap = <String, List<String>>{};
  final recordingsDir = Directory('$currentBasePath/recordings');

  if (await recordingsDir.exists()) {
    await for (final entity in recordingsDir.list(recursive: true)) {
      if (entity is File) {
        final fileName = entity.path.split('/').last;
        fileMap.putIfAbsent(fileName, () => []).add(entity.path);
      }
    }
  }

  // Also check backup directory
  final backupDir = Directory('$currentBasePath/recording_backups');
  if (await backupDir.exists()) {
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
      continue;
    }

    String? newPath;

    // Strategy 1: Extract relative path and reconstruct with current base
    final documentsIndex = storedPath.indexOf('/Documents/');
    if (documentsIndex != -1) {
      final relativePath = storedPath.substring(
        documentsIndex + '/Documents/'.length,
      );
      final reconstructedPath = '$currentBasePath/$relativePath';
      final reconstructedFile = File(reconstructedPath);
      if (await reconstructedFile.exists()) {
        newPath = reconstructedPath;
      }
    }

    // Strategy 2: Look up in pre-built file map by exact filename
    if (newPath == null) {
      final fileName = storedPath.split('/').last;
      final matches = fileMap[fileName];
      if (matches != null && matches.isNotEmpty) {
        if (matches.length == 1) {
          newPath = matches.first;
        } else {
          // Multiple matches - try to find one in the same section folder
          for (final match in matches) {
            if (match.contains(recording.sectionId) ||
                match.contains('rep_') ||
                match.contains('/recordings/')) {
              newPath = match;
              break;
            }
          }
          newPath ??= matches.first;
        }
      }
    }

    // Strategy 3: Search by recording ID in filename
    if (newPath == null) {
      final recordingId = recording.id;
      for (final entry in fileMap.entries) {
        if (entry.key.contains(recordingId.substring(0, 8))) {
          newPath = entry.value.first;
          break;
        }
      }
    }

    // Update path if recovered
    if (newPath != null) {
      final updated = recording.copyWith(filePath: newPath);
      await box.put(recording.key, updated);
      recoveredCount++;
    }
  }

  if (recoveredCount > 0) {
    await box.flush();
  }

  return recoveredCount;
}

/// Clean up orphaned practice recordings (DB entries without actual files).
/// Returns the number of cleaned up recordings.
Future<int> _cleanupOrphanedPracticeRecordings(
  Box<PracticeRecording> box,
) async {
  final orphanedKeys = <dynamic>[];

  for (final recording in box.values) {
    final file = File(recording.filePath);
    if (!await file.exists()) {
      orphanedKeys.add(recording.key);
    }
  }

  if (orphanedKeys.isEmpty) {
    return 0;
  }

  // Delete orphaned recordings from DB
  for (final key in orphanedKeys) {
    await box.delete(key);
  }
  await box.flush();

  return orphanedKeys.length;
}
