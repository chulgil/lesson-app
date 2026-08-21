// Backup service for creating and restoring data backups.
//
// Part of the data backup feature (Issue #15).
// Handles ZIP archive creation/extraction for recordings and Hive data.

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/domain/entities/backup_stage.dart';
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
    void Function(
      double progress,
      BackupStage stage, {
      int? current,
      int? total,
    })?
    onProgress,
  }) async {
    onProgress?.call(0.0, BackupStage.preparing);

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

    onProgress?.call(0.1, BackupStage.creatingMetadata);

    // Create metadata
    final metadata = await _createMetadata(
      recordingCount: recordingFiles.length,
      totalSizeBytes: totalSize,
    );
    final metadataJson = jsonEncode(metadata.toJson());
    archive.addFile(
      ArchiveFile(
        'metadata.json',
        metadataJson.length,
        utf8.encode(metadataJson),
      ),
    );

    onProgress?.call(0.2, BackupStage.exportingHive);

    // Export Hive boxes
    final hiveSnapshot = await _exportHiveBoxes();
    final hiveJson = jsonEncode(hiveSnapshot);
    archive.addFile(
      ArchiveFile('hive_snapshot.json', hiveJson.length, utf8.encode(hiveJson)),
    );

    onProgress?.call(0.3, BackupStage.addingRecordings);

    // Add recording files
    for (var i = 0; i < recordingFiles.length; i++) {
      final file = recordingFiles[i];
      final relativePath = file.path.substring(docsDir.path.length + 1);
      final bytes = await file.readAsBytes();

      archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));

      // Update progress
      final progress = 0.3 + (0.6 * (i + 1) / recordingFiles.length);
      onProgress?.call(
        progress,
        BackupStage.addingRecordings,
        current: i + 1,
        total: recordingFiles.length,
      );
    }

    onProgress?.call(0.9, BackupStage.compressing);

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

    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final backupFile = File(
      '${backupDir.path}/backup_$timestamp.$backupExtension',
    );
    await backupFile.writeAsBytes(zipBytes);

    // Save last backup date
    await _saveLastBackupDate(DateTime.now());

    onProgress?.call(1.0, BackupStage.backupCompleted);

    return backupFile;
  }

  /// Restore from a backup file.
  Future<RestoreResult> restoreFromBackup(
    File backupFile, {
    void Function(
      double progress,
      BackupStage stage, {
      int? current,
      int? total,
    })?
    onProgress,
  }) async {
    try {
      onProgress?.call(0.0, BackupStage.readingFile);

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
        return RestoreResult.failure(
          const BackupFailure(BackupFailureKind.invalidFile),
        );
      }

      onProgress?.call(0.1, BackupStage.checkingVersion);

      // Check backup version compatibility
      if (!_isVersionCompatible(metadata.backupVersion)) {
        return RestoreResult.failure(
          BackupFailure(
            BackupFailureKind.unsupportedVersion,
            detail: metadata.backupVersion,
          ),
        );
      }

      onProgress?.call(0.2, BackupStage.restoringHive);

      // Restore Hive data first
      if (hiveSnapshotFile != null) {
        final hiveJson = jsonDecode(
          utf8.decode(hiveSnapshotFile.content as List<int>),
        );
        restoredBoxEntries = await _restoreHiveBoxes(hiveJson, docsDir.path);
      }

      onProgress?.call(0.4, BackupStage.restoringRecordings);

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
        onProgress?.call(
          progress,
          BackupStage.restoringRecordings,
          current: processedFiles,
          total: totalFiles,
        );
      }

      onProgress?.call(1.0, BackupStage.restoreCompleted);

      return RestoreResult(
        success: true,
        restoredRecordings: restoredRecordings,
        skippedRecordings: skippedRecordings,
        restoredBoxEntries: restoredBoxEntries,
      );
    } catch (e) {
      return RestoreResult.failure(
        BackupFailure(BackupFailureKind.unknown, detail: e.toString()),
      );
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
        backups.add(
          BackupFileInfo(
            file: entity,
            createdAt: stat.modified,
            sizeBytes: stat.size,
          ),
        );
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
      final practiceRecordingsBox = Hive.box<PracticeRecording>(
        'practice_recordings',
      );
      boxCounts['practice_recordings'] = practiceRecordingsBox.length;
    } catch (e) {
      // Box not open
    }

    return BackupMetadata(
      appVersion: EnvironmentConfig.appVersion,
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
      final practiceRecordingsBox = await Hive.openBox<PracticeRecording>(
        'practice_recordings',
      );
      export['practice_recordings'] =
          practiceRecordingsBox.values
              .map((r) => _practiceRecordingToJson(r))
              .toList();
    } catch (e) {
      // Could not export practice_recordings
    }

    // Export practice_repertoires box (NEW)
    try {
      final repertoiresBox = await Hive.openBox('practice_repertoires');
      final repertoireData = <String, dynamic>{};
      for (final key in repertoiresBox.keys) {
        repertoireData[key.toString()] = repertoiresBox.get(key);
      }
      export['practice_repertoires'] = repertoireData;
    } catch (e) {
      // Could not export practice_repertoires
    }

    // Export metronome_settings box
    try {
      final metronomeBox = await Hive.openBox('metronome_settings');
      export['metronome_settings'] = Map<String, dynamic>.from(
        metronomeBox.toMap(),
      );
    } catch (e) {
      // Could not export metronome_settings
    }

    // Export smart_recording_settings box
    try {
      final smartRecordingBox = await Hive.openBox<Map>(
        'smart_recording_settings',
      );
      final smartRecordingData = <String, dynamic>{};
      for (final key in smartRecordingBox.keys) {
        smartRecordingData[key.toString()] = smartRecordingBox.get(key);
      }
      export['smart_recording_settings'] = smartRecordingData;
    } catch (e) {
      // Could not export smart_recording_settings
    }

    return export;
  }

  Future<int> _restoreHiveBoxes(
    Map<String, dynamic> data,
    String currentDocsPath,
  ) async {
    int restoredCount = 0;

    // Restore practice_repertoires FIRST (before recordings)
    // This allows section matching for recordings
    Map<String, String>? sectionIdMapping; // old sectionId -> new sectionId
    if (data.containsKey('practice_repertoires')) {
      try {
        final box = await Hive.openBox('practice_repertoires');
        final repertoires =
            data['practice_repertoires'] as Map<String, dynamic>;

        for (final entry in repertoires.entries) {
          if (!box.containsKey(entry.key)) {
            await box.put(entry.key, entry.value);
            restoredCount++;
          }
        }
        await box.flush();

        // Build section ID mapping for recording restoration
        sectionIdMapping = await _buildSectionIdMapping(repertoires);
      } catch (e) {
        // Could not restore practice_repertoires
      }
    }

    // Restore practice_recordings (with section matching and path update)
    if (data.containsKey('practice_recordings')) {
      try {
        // Use openBox instead of box to ensure box is opened even on fresh install
        final box = await Hive.openBox<PracticeRecording>(
          'practice_recordings',
        );
        final recordings = data['practice_recordings'] as List;

        for (final item in recordings) {
          var recording = _practiceRecordingFromJson(
            item as Map<String, dynamic>,
          );

          // Update file path to current documents directory
          final updatedFilePath = _updateFilePath(
            recording.filePath,
            currentDocsPath,
          );
          if (updatedFilePath != recording.filePath) {
            recording = recording.copyWith(filePath: updatedFilePath);
          }

          // Try section matching if section doesn't exist
          if (sectionIdMapping != null &&
              sectionIdMapping.containsKey(recording.sectionId)) {
            final newSectionId = sectionIdMapping[recording.sectionId]!;
            if (newSectionId != recording.sectionId) {
              recording = recording.copyWith(sectionId: newSectionId);
            }
          }

          if (!box.containsKey(recording.id)) {
            await box.put(recording.id, recording);
            restoredCount++;
          }
        }
        await box.flush();
      } catch (e) {
        // Could not restore practice_recordings
      }
    }

    // Restore metronome_settings
    if (data.containsKey('metronome_settings')) {
      try {
        // Use openBox instead of box to ensure box is opened even on fresh install
        final box = await Hive.openBox('metronome_settings');
        final settings = data['metronome_settings'] as Map<String, dynamic>;

        for (final entry in settings.entries) {
          if (!box.containsKey(entry.key)) {
            await box.put(entry.key, entry.value);
            restoredCount++;
          }
        }
        await box.flush();
      } catch (e) {
        // Could not restore metronome_settings
      }
    }

    // Restore smart_recording_settings
    if (data.containsKey('smart_recording_settings')) {
      try {
        // Use openBox instead of box to ensure box is opened even on fresh install
        final box = await Hive.openBox<Map>('smart_recording_settings');
        final settings =
            data['smart_recording_settings'] as Map<String, dynamic>;

        for (final entry in settings.entries) {
          if (!box.containsKey(entry.key)) {
            await box.put(entry.key, Map<String, dynamic>.from(entry.value));
            restoredCount++;
          }
        }
        await box.flush();
      } catch (e) {
        // Could not restore smart_recording_settings
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

  /// Update file path to use current app's documents directory.
  ///
  /// When restoring from backup, the original file path points to the old app's
  /// documents directory. This method extracts the relative path (recordings/...)
  /// and rebuilds it with the current app's documents directory.
  String _updateFilePath(String originalPath, String currentDocsPath) {
    // Find 'recordings/' in the path and extract everything from there
    final recordingsIndex = originalPath.indexOf('recordings/');
    if (recordingsIndex != -1) {
      final relativePath = originalPath.substring(recordingsIndex);
      return '$currentDocsPath/$relativePath';
    }
    // If 'recordings/' not found, return original path
    return originalPath;
  }

  /// Build section ID mapping for recording restoration.
  ///
  /// When restoring a backup, section IDs may have changed (e.g., after reinstall).
  /// This method builds a mapping from old section IDs to new section IDs
  /// by matching sections based on their identifying properties:
  /// - repertoire name + piece name + range type + range values
  Future<Map<String, String>> _buildSectionIdMapping(
    Map<String, dynamic> backupRepertoires,
  ) async {
    final mapping = <String, String>{};

    // Get current repertoires from Hive
    final currentBox = await Hive.openBox('practice_repertoires');
    final currentRepertoires = <String, Map<String, dynamic>>{};
    for (final key in currentBox.keys) {
      final value = currentBox.get(key);
      if (value is Map) {
        currentRepertoires[key.toString()] = Map<String, dynamic>.from(value);
      }
    }

    // Build section lookup by unique key: repertoireName|pieceName|rangeType|startMeasure|endMeasure|startLine|endLine
    String buildSectionKey(
      String repertoireName,
      Map<String, dynamic> section,
    ) {
      final pieceName = section['pieceName'] as String? ?? '';
      final rangeType = section['rangeType'] as String? ?? 'measure';
      final startMeasure = section['startMeasure'] as int? ?? 0;
      final endMeasure = section['endMeasure'] as int? ?? 0;
      final startLine = section['startLine'] as int? ?? 0;
      final endLine = section['endLine'] as int? ?? 0;
      return '$repertoireName|$pieceName|$rangeType|$startMeasure|$endMeasure|$startLine|$endLine';
    }

    // Build lookup for current sections: key -> sectionId
    final currentSectionLookup = <String, String>{};
    for (final entry in currentRepertoires.entries) {
      final repertoireData = entry.value;
      final repertoireName = repertoireData['name'] as String? ?? '';
      final sections = repertoireData['sections'] as List? ?? [];
      for (final section in sections) {
        if (section is Map) {
          final sectionMap = Map<String, dynamic>.from(section);
          final key = buildSectionKey(repertoireName, sectionMap);
          final sectionId = sectionMap['id'] as String?;
          if (sectionId != null) {
            currentSectionLookup[key] = sectionId;
          }
        }
      }
    }

    // Match backup sections to current sections
    for (final entry in backupRepertoires.entries) {
      final repertoireData = entry.value;
      if (repertoireData is! Map) continue;

      final repertoireMap = Map<String, dynamic>.from(repertoireData);
      final repertoireName = repertoireMap['name'] as String? ?? '';
      final sections = repertoireMap['sections'] as List? ?? [];

      for (final section in sections) {
        if (section is! Map) continue;

        final sectionMap = Map<String, dynamic>.from(section);
        final oldSectionId = sectionMap['id'] as String?;
        if (oldSectionId == null) continue;

        final key = buildSectionKey(repertoireName, sectionMap);
        final newSectionId = currentSectionLookup[key];

        if (newSectionId != null && newSectionId != oldSectionId) {
          mapping[oldSectionId] = newSectionId;
        }
      }
    }

    return mapping;
  }

  Future<DateTime?> _getLastBackupDate() async {
    try {
      final box = await Hive.openBox('app_settings');
      final timestamp = box.get('last_backup_date');
      if (timestamp != null) {
        return DateTime.parse(timestamp as String);
      }
    } catch (e) {
      // Could not get last backup date
    }
    return null;
  }

  Future<void> _saveLastBackupDate(DateTime date) async {
    try {
      final box = await Hive.openBox('app_settings');
      await box.put('last_backup_date', date.toIso8601String());
      await box.flush();
    } catch (e) {
      // Could not save last backup date
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
