// Backup service for creating and restoring data backups.
//
// Part of the data backup feature (Issue #15).
// Handles ZIP archive creation/extraction for recordings and Hive data.

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/backup_state.dart';
import '../../../../features/practice/domain/entities/practice_repertoire.dart';

/// Service for creating and restoring backups.
class BackupService {
  static const String backupExtension = 'lessonbackup';
  static const String backupVersion = '1.0';

  /// Create a full backup archive.
  ///
  /// Returns the path to the created backup file.
  Future<File> createBackup({
    void Function(double progress, String status)? onProgress,
  }) async {
    onProgress?.call(0.0, '백업 준비 중...');

    final archive = Archive();
    final docsDir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${docsDir.path}/recordings');

    // Collect all recording files
    final recordingFiles = <File>[];
    int totalSize = 0;

    if (await recordingsDir.exists()) {
      await for (final entity in recordingsDir.list(recursive: true)) {
        if (entity is File) {
          recordingFiles.add(entity);
          totalSize += await entity.length();
        }
      }
    }

    onProgress?.call(0.1, '메타데이터 생성 중...');

    // Create metadata
    final metadata = await _createMetadata(
      recordingCount: recordingFiles.length,
      totalSizeBytes: totalSize,
    );
    final metadataJson = jsonEncode(metadata.toJson());
    archive.addFile(ArchiveFile(
      'metadata.json',
      metadataJson.length,
      utf8.encode(metadataJson),
    ));

    onProgress?.call(0.2, 'Hive 데이터 내보내기 중...');

    // Export Hive boxes
    final hiveSnapshot = await _exportHiveBoxes();
    final hiveJson = jsonEncode(hiveSnapshot);
    archive.addFile(ArchiveFile(
      'hive_snapshot.json',
      hiveJson.length,
      utf8.encode(hiveJson),
    ));

    onProgress?.call(0.3, '녹음 파일 추가 중...');

    // Add recording files
    for (var i = 0; i < recordingFiles.length; i++) {
      final file = recordingFiles[i];
      final relativePath = file.path.substring(docsDir.path.length + 1);
      final bytes = await file.readAsBytes();

      archive.addFile(ArchiveFile(
        relativePath,
        bytes.length,
        bytes,
      ));

      // Update progress
      final progress = 0.3 + (0.6 * (i + 1) / recordingFiles.length);
      onProgress?.call(progress, '녹음 파일 추가 중... (${i + 1}/${recordingFiles.length})');
    }

    onProgress?.call(0.9, 'ZIP 압축 중...');

    // Encode to ZIP
    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) {
      throw Exception('Failed to create ZIP archive');
    }

    // Save backup file
    final backupDir = Directory('${docsDir.path}/backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    final backupFile = File('${backupDir.path}/backup_$timestamp.$backupExtension');
    await backupFile.writeAsBytes(zipBytes);

    // Save last backup date
    await _saveLastBackupDate(DateTime.now());

    onProgress?.call(1.0, '백업 완료');

    return backupFile;
  }

  /// Restore from a backup file.
  Future<RestoreResult> restoreFromBackup(
    File backupFile, {
    void Function(double progress, String status)? onProgress,
  }) async {
    try {
      onProgress?.call(0.0, '백업 파일 읽는 중...');

      final bytes = await backupFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final docsDir = await getApplicationDocumentsDirectory();
      int restoredRecordings = 0;
      int skippedRecordings = 0;
      int restoredBoxEntries = 0;

      // Find metadata
      BackupMetadata? metadata;
      ArchiveFile? hiveSnapshotFile;

      for (final file in archive) {
        if (file.name == 'metadata.json') {
          final json = jsonDecode(utf8.decode(file.content as List<int>));
          metadata = BackupMetadata.fromJson(json);
        } else if (file.name == 'hive_snapshot.json') {
          hiveSnapshotFile = file;
        }
      }

      if (metadata == null) {
        return RestoreResult.failure('유효하지 않은 백업 파일입니다.');
      }

      onProgress?.call(0.1, '백업 버전 확인 중...');

      // Check backup version compatibility
      if (!_isVersionCompatible(metadata.backupVersion)) {
        return RestoreResult.failure(
          '지원되지 않는 백업 버전입니다: ${metadata.backupVersion}',
        );
      }

      onProgress?.call(0.2, 'Hive 데이터 복원 중...');

      // Restore Hive data first
      if (hiveSnapshotFile != null) {
        final hiveJson = jsonDecode(utf8.decode(hiveSnapshotFile.content as List<int>));
        restoredBoxEntries = await _restoreHiveBoxes(hiveJson);
      }

      onProgress?.call(0.4, '녹음 파일 복원 중...');

      // Restore recording files
      final recordingFiles = archive.where(
        (f) => f.name.startsWith('recordings/') && !f.isFile == false,
      );

      final totalFiles = recordingFiles.length;
      var processedFiles = 0;

      for (final file in recordingFiles) {
        if (!file.isFile) continue;

        final destPath = '${docsDir.path}/${file.name}';
        final destFile = File(destPath);

        if (await destFile.exists()) {
          skippedRecordings++;
        } else {
          await destFile.parent.create(recursive: true);
          await destFile.writeAsBytes(file.content as List<int>);
          restoredRecordings++;
        }

        processedFiles++;
        final progress = 0.4 + (0.5 * processedFiles / totalFiles);
        onProgress?.call(progress, '녹음 파일 복원 중... ($processedFiles/$totalFiles)');
      }

      onProgress?.call(1.0, '복원 완료');

      return RestoreResult(
        success: true,
        restoredRecordings: restoredRecordings,
        skippedRecordings: skippedRecordings,
        restoredBoxEntries: restoredBoxEntries,
      );
    } catch (e) {
      debugPrint('Restore error: $e');
      return RestoreResult.failure('복원 중 오류 발생: $e');
    }
  }

  /// Get current backup state (recording count, total size, last backup date).
  Future<BackupState> getBackupState() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${docsDir.path}/recordings');

    int recordingCount = 0;
    int totalSize = 0;

    if (await recordingsDir.exists()) {
      await for (final entity in recordingsDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.m4a')) {
          recordingCount++;
          totalSize += await entity.length();
        }
      }
    }

    final lastBackupDate = await _getLastBackupDate();

    return BackupState(
      recordingCount: recordingCount,
      totalSizeBytes: totalSize,
      lastBackupDate: lastBackupDate,
    );
  }

  /// List available backup files.
  Future<List<BackupFileInfo>> listBackups() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${docsDir.path}/backups');

    if (!await backupDir.exists()) {
      return [];
    }

    final backups = <BackupFileInfo>[];

    await for (final entity in backupDir.list()) {
      if (entity is File && entity.path.endsWith('.$backupExtension')) {
        final stat = await entity.stat();
        backups.add(BackupFileInfo(
          file: entity,
          createdAt: stat.modified,
          sizeBytes: stat.size,
        ));
      }
    }

    // Sort by date (newest first)
    backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return backups;
  }

  /// Delete a backup file.
  Future<void> deleteBackup(File backupFile) async {
    if (await backupFile.exists()) {
      await backupFile.delete();
    }
  }

  // Private methods

  Future<BackupMetadata> _createMetadata({
    required int recordingCount,
    required int totalSizeBytes,
  }) async {
    // Get box counts
    final boxCounts = <String, int>{};

    try {
      final practiceRecordingsBox = Hive.box<PracticeRecording>('practice_recordings');
      boxCounts['practice_recordings'] = practiceRecordingsBox.length;
    } catch (e) {
      // Box not open
    }

    return BackupMetadata(
      appVersion: '1.0.0', // TODO: Get from package_info
      backupVersion: backupVersion,
      createdAt: DateTime.now(),
      recordingCount: recordingCount,
      totalSizeBytes: totalSizeBytes,
      deviceModel: Platform.operatingSystem,
      osVersion: Platform.operatingSystemVersion,
      boxCounts: boxCounts,
    );
  }

  Future<Map<String, dynamic>> _exportHiveBoxes() async {
    final export = <String, dynamic>{};

    // Export practice_recordings box
    try {
      final practiceRecordingsBox = Hive.box<PracticeRecording>('practice_recordings');
      export['practice_recordings'] = practiceRecordingsBox.values
          .map((r) => _practiceRecordingToJson(r))
          .toList();
    } catch (e) {
      debugPrint('Could not export practice_recordings: $e');
    }

    // Export metronome_settings box
    try {
      final metronomeBox = Hive.box('metronome_settings');
      export['metronome_settings'] = Map<String, dynamic>.from(metronomeBox.toMap());
    } catch (e) {
      debugPrint('Could not export metronome_settings: $e');
    }

    // Export smart_recording_settings box
    try {
      final smartRecordingBox = Hive.box<Map>('smart_recording_settings');
      final smartRecordingData = <String, dynamic>{};
      for (final key in smartRecordingBox.keys) {
        smartRecordingData[key.toString()] = smartRecordingBox.get(key);
      }
      export['smart_recording_settings'] = smartRecordingData;
    } catch (e) {
      debugPrint('Could not export smart_recording_settings: $e');
    }

    return export;
  }

  Future<int> _restoreHiveBoxes(Map<String, dynamic> data) async {
    int restoredCount = 0;

    // Restore practice_recordings
    if (data.containsKey('practice_recordings')) {
      try {
        final box = Hive.box<PracticeRecording>('practice_recordings');
        final recordings = data['practice_recordings'] as List;

        for (final item in recordings) {
          final recording = _practiceRecordingFromJson(item);
          if (!box.containsKey(recording.id)) {
            await box.put(recording.id, recording);
            restoredCount++;
          }
        }
        await box.flush();
      } catch (e) {
        debugPrint('Could not restore practice_recordings: $e');
      }
    }

    // Restore metronome_settings
    if (data.containsKey('metronome_settings')) {
      try {
        final box = Hive.box('metronome_settings');
        final settings = data['metronome_settings'] as Map<String, dynamic>;

        for (final entry in settings.entries) {
          if (!box.containsKey(entry.key)) {
            await box.put(entry.key, entry.value);
            restoredCount++;
          }
        }
        await box.flush();
      } catch (e) {
        debugPrint('Could not restore metronome_settings: $e');
      }
    }

    // Restore smart_recording_settings
    if (data.containsKey('smart_recording_settings')) {
      try {
        final box = Hive.box<Map>('smart_recording_settings');
        final settings = data['smart_recording_settings'] as Map<String, dynamic>;

        for (final entry in settings.entries) {
          if (!box.containsKey(entry.key)) {
            await box.put(entry.key, Map<String, dynamic>.from(entry.value));
            restoredCount++;
          }
        }
        await box.flush();
      } catch (e) {
        debugPrint('Could not restore smart_recording_settings: $e');
      }
    }

    return restoredCount;
  }

  Map<String, dynamic> _practiceRecordingToJson(PracticeRecording recording) {
    return {
      'id': recording.id,
      'sectionId': recording.sectionId,
      'filePath': recording.filePath,
      'durationSeconds': recording.durationSeconds,
      'createdAt': recording.createdAt.toIso8601String(),
      'isRepresentative': recording.isRepresentative,
      'bpm': recording.bpm,
    };
  }

  PracticeRecording _practiceRecordingFromJson(Map<String, dynamic> json) {
    return PracticeRecording(
      id: json['id'] as String,
      sectionId: json['sectionId'] as String,
      filePath: json['filePath'] as String,
      durationSeconds: json['durationSeconds'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRepresentative: json['isRepresentative'] as bool? ?? false,
      bpm: json['bpm'] as int?,
    );
  }

  bool _isVersionCompatible(String version) {
    // For now, accept version 1.x
    return version.startsWith('1.');
  }

  Future<DateTime?> _getLastBackupDate() async {
    try {
      final box = await Hive.openBox('app_settings');
      final timestamp = box.get('last_backup_date');
      if (timestamp != null) {
        return DateTime.parse(timestamp as String);
      }
    } catch (e) {
      debugPrint('Could not get last backup date: $e');
    }
    return null;
  }

  Future<void> _saveLastBackupDate(DateTime date) async {
    try {
      final box = await Hive.openBox('app_settings');
      await box.put('last_backup_date', date.toIso8601String());
      await box.flush();
    } catch (e) {
      debugPrint('Could not save last backup date: $e');
    }
  }
}

/// Information about a backup file.
class BackupFileInfo {
  final File file;
  final DateTime createdAt;
  final int sizeBytes;

  const BackupFileInfo({
    required this.file,
    required this.createdAt,
    required this.sizeBytes,
  });

  String get fileName => file.uri.pathSegments.last;

  String get formattedSize {
    if (sizeBytes < 1024) {
      return '$sizeBytes B';
    } else if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
