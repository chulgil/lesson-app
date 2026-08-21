// File-backed implementation of [BackupService] for practice §6.3 Phase 1.
//
// Writes/reads `.lessonbackup` ZIP archives using the `archive` package.
// The archive layout matches `docs/specs/practice/backup_implementation_spec.md`:
//   metadata.json      — magic + version + counters (BackupArchiveMetadata)
//   hive_snapshot.json — Hive boxes serialized as JSON
//   recordings/...     — verbatim copy of files under `Documents/recordings/`

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/domain/entities/backup_stage.dart';
import '../../domain/entities/backup_archive.dart';
import '../../domain/entities/practice_repertoire.dart';
import '../../domain/services/backup_service.dart';

/// Directory provider hook so tests can pump a temp dir into the service
/// without going through the platform channel-backed `path_provider`.
typedef DocumentsDirectoryProvider = Future<Directory> Function();

/// `archive`/Hive backed [BackupService] implementation.
class FileBackupService implements BackupService {
  /// Archive file extension (sans dot).
  static const String backupExtension = 'lessonbackup';

  /// Filename of the metadata entry inside the archive (must be first).
  static const String metadataFileName = 'metadata.json';

  /// Filename of the Hive snapshot entry inside the archive.
  static const String hiveSnapshotFileName = 'hive_snapshot.json';

  /// Archive prefix for recording files.
  static const String recordingsPrefix = 'recordings/';

  final DocumentsDirectoryProvider _documentsDirectory;

  FileBackupService({DocumentsDirectoryProvider? documentsDirectory})
    : _documentsDirectory =
          documentsDirectory ?? getApplicationDocumentsDirectory;

  @override
  Future<BackupArchive> create({BackupProgressCallback? onProgress}) async {
    onProgress?.call(0.0, BackupStage.preparing);

    final docsDir = await _documentsDirectory();
    final recordingsDir = Directory('${docsDir.path}/recordings');

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

    final metadata = BackupArchiveMetadata(
      magic: backupArchiveMagic,
      backupVersion: backupArchiveVersion,
      appVersion: EnvironmentConfig.appVersion,
      createdAt: DateTime.now().toUtc(),
      recordingCount: recordingFiles.length,
      totalSizeBytes: totalSize,
      deviceModel: Platform.operatingSystem,
      osVersion: Platform.operatingSystemVersion,
    );

    final archive = Archive();
    final metadataBytes = utf8.encode(jsonEncode(metadata.toJson()));
    archive.addFile(
      ArchiveFile(metadataFileName, metadataBytes.length, metadataBytes),
    );

    onProgress?.call(0.2, BackupStage.exportingHive);

    final hiveSnapshot = await _exportHiveBoxes();
    final hiveBytes = utf8.encode(jsonEncode(hiveSnapshot));
    archive.addFile(
      ArchiveFile(hiveSnapshotFileName, hiveBytes.length, hiveBytes),
    );

    onProgress?.call(0.3, BackupStage.addingRecordings);

    final manifest = <BackupRecordingEntry>[];
    for (var i = 0; i < recordingFiles.length; i++) {
      final file = recordingFiles[i];
      final relativePath = file.path.substring(docsDir.path.length + 1);
      final bytes = await file.readAsBytes();

      archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
      manifest.add(
        BackupRecordingEntry(
          relativePath: relativePath,
          sizeBytes: bytes.length,
        ),
      );

      final progress = 0.3 + (0.6 * (i + 1) / recordingFiles.length);
      onProgress?.call(
        progress,
        BackupStage.addingRecordings,
        current: i + 1,
        total: recordingFiles.length,
      );
    }

    onProgress?.call(0.9, BackupStage.compressing);

    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) {
      throw const BackupException(
        BackupFailure(BackupFailureKind.encodeFailed),
      );
    }

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

    onProgress?.call(1.0, BackupStage.backupCompleted);

    return BackupArchive(
      filePath: backupFile.path,
      metadata: metadata,
      recordings: manifest,
    );
  }

  @override
  Future<BackupArchive> open(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw const BackupException(BackupFailure(BackupFailureKind.invalidFile));
    }

    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    BackupArchiveMetadata? metadata;
    final manifest = <BackupRecordingEntry>[];

    for (final entry in archive) {
      if (entry.name == metadataFileName) {
        final json =
            jsonDecode(utf8.decode(entry.content as List<int>))
                as Map<String, dynamic>;
        metadata = BackupArchiveMetadata.fromJson(json);
      } else if (entry.isFile && entry.name.startsWith(recordingsPrefix)) {
        manifest.add(
          BackupRecordingEntry(relativePath: entry.name, sizeBytes: entry.size),
        );
      }
    }

    if (metadata == null) {
      throw const BackupException(BackupFailure(BackupFailureKind.invalidFile));
    }

    return BackupArchive(
      filePath: filePath,
      metadata: metadata,
      recordings: manifest,
    );
  }

  @override
  Future<BackupRestoreResult> restore(
    BackupArchive archive, {
    BackupProgressCallback? onProgress,
  }) async {
    onProgress?.call(0.0, BackupStage.readingFile);

    // Hard gate — magic + major version must match before touching state.
    if (archive.metadata.magic != backupArchiveMagic) {
      return BackupRestoreResult.failure(
        const BackupFailure(BackupFailureKind.invalidFile),
      );
    }
    if (!BackupArchive.isVersionCompatible(archive.metadata.backupVersion)) {
      return BackupRestoreResult.failure(
        BackupFailure(
          BackupFailureKind.unsupportedVersion,
          detail: archive.metadata.backupVersion,
        ),
      );
    }

    try {
      final file = File(archive.filePath);
      if (!await file.exists()) {
        return BackupRestoreResult.failure(
          const BackupFailure(BackupFailureKind.invalidFile),
        );
      }
      final bytes = await file.readAsBytes();
      final zipArchive = ZipDecoder().decodeBytes(bytes);
      final docsDir = await _documentsDirectory();

      onProgress?.call(0.1, BackupStage.checkingVersion);

      // Re-validate metadata from disk in case the [BackupArchive] passed
      // in was tampered with after [open]. Defence in depth.
      ArchiveFile? hiveSnapshotFile;
      BackupArchiveMetadata? diskMetadata;
      for (final entry in zipArchive) {
        if (entry.name == metadataFileName) {
          final json =
              jsonDecode(utf8.decode(entry.content as List<int>))
                  as Map<String, dynamic>;
          diskMetadata = BackupArchiveMetadata.fromJson(json);
        } else if (entry.name == hiveSnapshotFileName) {
          hiveSnapshotFile = entry;
        }
      }

      if (diskMetadata == null ||
          diskMetadata.magic != backupArchiveMagic ||
          !BackupArchive.isVersionCompatible(diskMetadata.backupVersion)) {
        return BackupRestoreResult.failure(
          const BackupFailure(BackupFailureKind.invalidFile),
        );
      }

      onProgress?.call(0.2, BackupStage.restoringHive);

      int restoredBoxEntries = 0;
      if (hiveSnapshotFile != null) {
        final hiveJson =
            jsonDecode(utf8.decode(hiveSnapshotFile.content as List<int>))
                as Map<String, dynamic>;
        restoredBoxEntries = await _restoreHiveBoxes(hiveJson);
      }

      onProgress?.call(0.4, BackupStage.restoringRecordings);

      final recordingEntries =
          zipArchive
              .where((f) => f.isFile && f.name.startsWith(recordingsPrefix))
              .toList();

      int restoredRecordings = 0;
      int skippedRecordings = 0;
      final total = recordingEntries.length;

      for (var i = 0; i < recordingEntries.length; i++) {
        final entry = recordingEntries[i];
        final destPath = '${docsDir.path}/${entry.name}';
        final destFile = File(destPath);

        if (await destFile.exists()) {
          skippedRecordings++;
        } else {
          await destFile.parent.create(recursive: true);
          await destFile.writeAsBytes(entry.content as List<int>);
          restoredRecordings++;
        }

        final progress = 0.4 + (0.5 * (i + 1) / (total == 0 ? 1 : total));
        onProgress?.call(
          progress,
          BackupStage.restoringRecordings,
          current: i + 1,
          total: total,
        );
      }

      onProgress?.call(1.0, BackupStage.restoreCompleted);

      return BackupRestoreResult(
        success: true,
        restoredRecordings: restoredRecordings,
        skippedRecordings: skippedRecordings,
        restoredBoxEntries: restoredBoxEntries,
      );
    } catch (e) {
      return BackupRestoreResult.failure(
        BackupFailure(BackupFailureKind.unknown, detail: e.toString()),
      );
    }
  }

  // ── Hive helpers ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _exportHiveBoxes() async {
    final export = <String, dynamic>{};

    if (Hive.isBoxOpen('practice_recordings')) {
      final box = Hive.box<PracticeRecording>('practice_recordings');
      export['practice_recordings'] =
          box.values.map(_practiceRecordingToJson).toList();
    }

    if (Hive.isBoxOpen('practice_repertoires')) {
      final box = Hive.box('practice_repertoires');
      final data = <String, dynamic>{};
      for (final key in box.keys) {
        data[key.toString()] = box.get(key);
      }
      export['practice_repertoires'] = data;
    }

    return export;
  }

  Future<int> _restoreHiveBoxes(Map<String, dynamic> data) async {
    int restored = 0;

    if (data['practice_recordings'] is List) {
      final box = await Hive.openBox<PracticeRecording>('practice_recordings');
      for (final raw in data['practice_recordings'] as List) {
        final recording = _practiceRecordingFromJson(
          Map<String, dynamic>.from(raw as Map),
        );
        if (!box.containsKey(recording.id)) {
          await box.put(recording.id, recording);
          restored++;
        }
      }
      await box.flush();
    }

    if (data['practice_repertoires'] is Map) {
      final box = await Hive.openBox('practice_repertoires');
      final entries = Map<String, dynamic>.from(
        data['practice_repertoires'] as Map,
      );
      for (final entry in entries.entries) {
        if (!box.containsKey(entry.key)) {
          await box.put(entry.key, entry.value);
          restored++;
        }
      }
      await box.flush();
    }

    return restored;
  }

  Map<String, dynamic> _practiceRecordingToJson(PracticeRecording r) => {
    'id': r.id,
    'sectionId': r.sectionId,
    'filePath': r.filePath,
    'durationSeconds': r.durationSeconds,
    'bpm': r.bpm,
    'usedMetronome': r.usedMetronome,
    'timeSignatureIndex': r.timeSignatureIndex,
    'isRepresentative': r.isRepresentative,
    'createdAt': r.createdAt.toIso8601String(),
  };

  PracticeRecording _practiceRecordingFromJson(Map<String, dynamic> json) =>
      PracticeRecording(
        id: json['id'] as String,
        sectionId: json['sectionId'] as String,
        filePath: json['filePath'] as String,
        durationSeconds: json['durationSeconds'] as int,
        bpm: json['bpm'] as int?,
        usedMetronome: json['usedMetronome'] as bool? ?? false,
        timeSignatureIndex: json['timeSignatureIndex'] as int?,
        isRepresentative: json['isRepresentative'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
