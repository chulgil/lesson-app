import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/smart_recording.dart';

/// Service for trimming audio files.
///
/// Provides functionality to trim silent sections from the start and end
/// of audio recordings while preserving the original file for recovery.
class AudioTrimmerService {
  AudioTrimmerService._();
  static final instance = AudioTrimmerService._();

  /// Trim silent sections from audio file based on smart recording state.
  ///
  /// Returns [TrimResult] with trimmed file path and original backup path.
  /// [silencePeriods] contains middle silence periods to skip.
  Future<TrimResult> trimAudio({
    required String inputPath,
    required Duration trimStart,
    required Duration trimEnd,
    required Duration totalDuration,
    List<SilencePeriod> silencePeriods = const [],
  }) async {
    try {
      // Validate durations
      if (trimStart < Duration.zero || trimEnd < Duration.zero) {
        return TrimResult.noTrim(inputPath);
      }

      // Check if trimming is needed (including middle silence)
      if (trimStart == Duration.zero && trimEnd == Duration.zero && silencePeriods.isEmpty) {
        debugPrint('AudioTrimmer: No trimming needed');
        return TrimResult.noTrim(inputPath);
      }

      // Calculate actual content duration
      final contentDuration = totalDuration - trimStart - trimEnd;
      if (contentDuration.inSeconds < 1) {
        debugPrint('AudioTrimmer: Content too short after trimming, skipping');
        return TrimResult.failed(
          inputPath,
          'Recording too short after trimming (less than 1 second)',
        );
      }

      // Create backup of original file
      final originalBackupPath = await _createBackup(inputPath);
      if (originalBackupPath == null) {
        debugPrint('AudioTrimmer: Failed to create backup');
        return TrimResult.failed(inputPath, 'Failed to create backup');
      }

      // For now, we store trim metadata and let the player handle the actual trimming
      // This is more efficient than re-encoding the audio file
      final trimmedPath = await _createTrimmedCopy(
        inputPath,
        trimStart,
        trimEnd,
        totalDuration,
        silencePeriods,
      );

      if (trimmedPath == null) {
        // Restore original if trimming failed
        await _restoreBackup(originalBackupPath, inputPath);
        return TrimResult.failed(inputPath, 'Failed to create trimmed file');
      }

      debugPrint('AudioTrimmer: Successfully trimmed');
      debugPrint('  Original: $originalBackupPath');
      debugPrint('  Trimmed: $trimmedPath');
      debugPrint('  Start: ${trimStart.inMilliseconds}ms');
      debugPrint('  End: ${trimEnd.inMilliseconds}ms');

      return TrimResult(
        success: true,
        trimmedFilePath: trimmedPath,
        originalFilePath: originalBackupPath,
        trimmedStart: trimStart,
        trimmedEnd: trimEnd,
      );
    } catch (e) {
      debugPrint('AudioTrimmer: Error trimming audio: $e');
      return TrimResult.failed(inputPath, e.toString());
    }
  }

  /// Restore original file from backup.
  Future<bool> restoreOriginal({
    required String originalPath,
    required String trimmedPath,
  }) async {
    try {
      final originalFile = File(originalPath);
      final trimmedFile = File(trimmedPath);

      if (!await originalFile.exists()) {
        debugPrint('AudioTrimmer: Original file not found for restore');
        return false;
      }

      // Delete trimmed file
      if (await trimmedFile.exists()) {
        await trimmedFile.delete();
      }

      // Copy original back to trimmed location
      await originalFile.copy(trimmedPath);

      debugPrint('AudioTrimmer: Restored original file');
      return true;
    } catch (e) {
      debugPrint('AudioTrimmer: Error restoring original: $e');
      return false;
    }
  }

  /// Delete backup file after it's no longer needed.
  Future<void> deleteBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('AudioTrimmer: Deleted backup file');
      }
    } catch (e) {
      debugPrint('AudioTrimmer: Error deleting backup: $e');
    }
  }

  Future<String?> _createBackup(String inputPath) async {
    try {
      final inputFile = File(inputPath);
      if (!await inputFile.exists()) {
        return null;
      }

      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/recording_backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // Extract filename and extension manually
      final lastSlash = inputPath.lastIndexOf('/');
      final fullName = lastSlash >= 0 ? inputPath.substring(lastSlash + 1) : inputPath;
      final lastDot = fullName.lastIndexOf('.');
      final fileName = lastDot >= 0 ? fullName.substring(0, lastDot) : fullName;
      final extension = lastDot >= 0 ? fullName.substring(lastDot) : '';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = '${backupDir.path}/${fileName}_original_$timestamp$extension';

      await inputFile.copy(backupPath);
      return backupPath;
    } catch (e) {
      debugPrint('AudioTrimmer: Error creating backup: $e');
      return null;
    }
  }

  Future<void> _restoreBackup(String backupPath, String targetPath) async {
    try {
      final backupFile = File(backupPath);
      if (await backupFile.exists()) {
        await backupFile.copy(targetPath);
        await backupFile.delete();
      }
    } catch (e) {
      debugPrint('AudioTrimmer: Error restoring backup: $e');
    }
  }

  Future<String?> _createTrimmedCopy(
    String inputPath,
    Duration trimStart,
    Duration trimEnd,
    Duration totalDuration,
    List<SilencePeriod> silencePeriods,
  ) async {
    try {
      // For m4a/aac files, we cannot easily trim without FFmpeg
      // Instead, we store trim metadata in a companion file
      // The player will use this metadata to skip the trimmed sections

      final inputFile = File(inputPath);
      if (!await inputFile.exists()) {
        return null;
      }

      final contentStart = trimStart;
      final contentEnd = totalDuration - trimEnd;

      // Calculate playable segments
      List<Map<String, dynamic>> segments = [];
      if (silencePeriods.isNotEmpty) {
        // Filter and adjust silence periods to be within content range
        final validSilencePeriods = <SilencePeriod>[];
        for (final silence in silencePeriods) {
          // Skip silence periods that are completely outside content range
          if (silence.endTime <= contentStart || silence.startTime >= contentEnd) {
            debugPrint('AudioTrimmer: Skipping silence period outside content range: ${silence.startTime} ~ ${silence.endTime}');
            continue;
          }

          // Adjust silence periods that partially overlap with content boundaries
          Duration adjustedStart = silence.startTime;
          Duration adjustedEnd = silence.endTime;

          if (adjustedStart < contentStart) {
            adjustedStart = contentStart;
          }
          if (adjustedEnd > contentEnd) {
            adjustedEnd = contentEnd;
          }

          // Only add if there's still a valid silence period after adjustment
          if (adjustedEnd > adjustedStart) {
            validSilencePeriods.add(SilencePeriod(
              startTime: adjustedStart,
              endTime: adjustedEnd,
            ));
          }
        }

        debugPrint('AudioTrimmer: Valid silence periods: ${validSilencePeriods.length} (original: ${silencePeriods.length})');

        // Build segments by excluding valid silence periods
        Duration currentStart = contentStart;
        for (final silence in validSilencePeriods) {
          // Add segment before this silence (only if there's content)
          if (silence.startTime > currentStart) {
            segments.add({
              'start': currentStart.inMilliseconds,
              'end': silence.startTime.inMilliseconds,
            });
            debugPrint('AudioTrimmer: Added segment ${currentStart.inMilliseconds}ms ~ ${silence.startTime.inMilliseconds}ms');
          }
          // Move past this silence period
          currentStart = silence.endTime;
        }
        // Add final segment after last silence
        if (currentStart < contentEnd) {
          segments.add({
            'start': currentStart.inMilliseconds,
            'end': contentEnd.inMilliseconds,
          });
          debugPrint('AudioTrimmer: Added final segment ${currentStart.inMilliseconds}ms ~ ${contentEnd.inMilliseconds}ms');
        }
      }

      // Create metadata file
      final metadataPath = '$inputPath.trim';
      final metadataFile = File(metadataPath);

      final metadata = {
        'trimStart': trimStart.inMilliseconds,
        'trimEnd': trimEnd.inMilliseconds,
        'totalDuration': totalDuration.inMilliseconds,
        'contentStart': contentStart.inMilliseconds,
        'contentEnd': contentEnd.inMilliseconds,
        'segments': segments,
      };

      await metadataFile.writeAsString(jsonEncode(metadata));

      debugPrint('AudioTrimmer: Created trim metadata file');
      debugPrint('  contentStart: ${contentStart.inMilliseconds}ms');
      debugPrint('  contentEnd: ${contentEnd.inMilliseconds}ms');
      debugPrint('  Segments: ${segments.length}');
      for (int i = 0; i < segments.length; i++) {
        final seg = segments[i];
        debugPrint('    [$i] ${seg['start']}ms ~ ${seg['end']}ms');
      }
      return inputPath; // Return same path, player will use metadata
    } catch (e) {
      debugPrint('AudioTrimmer: Error creating trimmed copy: $e');
      return null;
    }
  }

  /// Read trim metadata for a recording.
  Future<TrimMetadata?> readTrimMetadata(String audioPath) async {
    try {
      final metadataFile = File('$audioPath.trim');
      if (!await metadataFile.exists()) {
        return null;
      }

      final content = await metadataFile.readAsString();

      // Try JSON format first (new format)
      try {
        final json = jsonDecode(content) as Map<String, dynamic>;
        final segmentsJson = json['segments'] as List<dynamic>? ?? [];
        final segments = segmentsJson
            .map((s) => PlayableSegment.fromJson(s as Map<String, dynamic>))
            .toList();

        return TrimMetadata(
          trimStart: Duration(milliseconds: json['trimStart'] as int? ?? 0),
          trimEnd: Duration(milliseconds: json['trimEnd'] as int? ?? 0),
          totalDuration: Duration(milliseconds: json['totalDuration'] as int? ?? 0),
          contentStart: Duration(milliseconds: json['contentStart'] as int? ?? 0),
          contentEnd: Duration(milliseconds: json['contentEnd'] as int? ?? 0),
          segments: segments,
        );
      } catch (_) {
        // Fall back to legacy key=value format
        final lines = content.split('\n');
        final map = <String, int>{};

        for (final line in lines) {
          final parts = line.split('=');
          if (parts.length == 2) {
            map[parts[0]] = int.tryParse(parts[1]) ?? 0;
          }
        }

        return TrimMetadata(
          trimStart: Duration(milliseconds: map['trimStart'] ?? 0),
          trimEnd: Duration(milliseconds: map['trimEnd'] ?? 0),
          totalDuration: Duration(milliseconds: map['totalDuration'] ?? 0),
          contentStart: Duration(milliseconds: map['contentStart'] ?? 0),
          contentEnd: Duration(milliseconds: map['contentEnd'] ?? 0),
        );
      }
    } catch (e) {
      debugPrint('AudioTrimmer: Error reading trim metadata: $e');
      return null;
    }
  }

  /// Delete trim metadata file.
  Future<void> deleteTrimMetadata(String audioPath) async {
    try {
      final metadataFile = File('$audioPath.trim');
      if (await metadataFile.exists()) {
        await metadataFile.delete();
      }
    } catch (e) {
      debugPrint('AudioTrimmer: Error deleting trim metadata: $e');
    }
  }
}

/// Trim metadata for audio playback.
class TrimMetadata {
  const TrimMetadata({
    required this.trimStart,
    required this.trimEnd,
    required this.totalDuration,
    required this.contentStart,
    required this.contentEnd,
    this.segments = const [],
  });

  /// Duration trimmed from start.
  final Duration trimStart;

  /// Duration trimmed from end.
  final Duration trimEnd;

  /// Original total duration.
  final Duration totalDuration;

  /// Start position of actual content.
  final Duration contentStart;

  /// End position of actual content.
  final Duration contentEnd;

  /// Playable segments (for middle silence skip).
  /// If empty, the entire contentStart~contentEnd range is played.
  final List<PlayableSegment> segments;

  /// Duration of actual content.
  Duration get contentDuration => contentEnd - contentStart;

  /// Whether file has been trimmed.
  bool get hasTrimming => trimStart > Duration.zero || trimEnd > Duration.zero;

  /// Whether there are middle silence skips.
  bool get hasMiddleSilenceSkip => segments.isNotEmpty;

  /// Effective play duration (accounting for middle silence skips).
  Duration get effectivePlayDuration {
    if (segments.isEmpty) {
      return contentDuration;
    }
    return segments.fold(
      Duration.zero,
      (sum, seg) => sum + seg.duration,
    );
  }
}

/// A playable segment within the audio file.
class PlayableSegment {
  const PlayableSegment({
    required this.start,
    required this.end,
  });

  final Duration start;
  final Duration end;

  Duration get duration => end - start;

  Map<String, dynamic> toJson() => {
        'start': start.inMilliseconds,
        'end': end.inMilliseconds,
      };

  factory PlayableSegment.fromJson(Map<String, dynamic> json) => PlayableSegment(
        start: Duration(milliseconds: json['start'] as int),
        end: Duration(milliseconds: json['end'] as int),
      );
}
