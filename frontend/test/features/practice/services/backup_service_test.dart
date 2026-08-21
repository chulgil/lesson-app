// Unit tests for practice §6.3 Phase 1 — FileBackupService.
//
// Round-trips:
// - create() produces a `.lessonbackup` ZIP with magic + version.
// - open() reads the metadata back without crashing.
// - restore() rejects archives with bad magic / incompatible version.
// - Progress callback is invoked at start (0.0) and finish (1.0).

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/data/services/file_backup_service.dart';
import 'package:lessonaza/features/practice/domain/entities/backup_archive.dart';
import 'package:lessonaza/core/domain/entities/backup_stage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('backup_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('FileBackupService.create', () {
    test('produces a .lessonbackup archive with magic and version', () async {
      // Seed a single recording so the manifest is non-empty.
      final recordingsDir = Directory('${tempDir.path}/recordings');
      await recordingsDir.create(recursive: true);
      final src = File('${recordingsDir.path}/sample.m4a');
      await src.writeAsBytes([1, 2, 3, 4, 5]);

      final service = FileBackupService(
        documentsDirectory: () async => tempDir,
      );

      final archive = await service.create();

      expect(File(archive.filePath).existsSync(), isTrue);
      expect(archive.filePath.endsWith('.lessonbackup'), isTrue);
      expect(archive.metadata.magic, backupArchiveMagic);
      expect(archive.metadata.backupVersion, backupArchiveVersion);
      expect(archive.metadata.recordingCount, 1);
      expect(archive.recordings.length, 1);
      expect(archive.recordings.first.relativePath, 'recordings/sample.m4a');
      expect(archive.isValid, isTrue);
    });

    test('reports progress at start and finish', () async {
      final service = FileBackupService(
        documentsDirectory: () async => tempDir,
      );

      final progressEvents = <double>[];
      await service.create(
        onProgress: (p, _, {current, total}) => progressEvents.add(p),
      );

      expect(progressEvents.first, 0.0);
      expect(progressEvents.last, 1.0);
      // Strictly monotonic across all callbacks.
      for (var i = 1; i < progressEvents.length; i++) {
        expect(
          progressEvents[i] >= progressEvents[i - 1],
          isTrue,
          reason: 'progress regressed at index $i: $progressEvents',
        );
      }
    });
  });

  group('FileBackupService.open', () {
    test('round-trips metadata from a freshly created archive', () async {
      final service = FileBackupService(
        documentsDirectory: () async => tempDir,
      );
      final created = await service.create();

      final reopened = await service.open(created.filePath);

      expect(reopened.metadata.magic, backupArchiveMagic);
      expect(reopened.metadata.backupVersion, backupArchiveVersion);
      expect(reopened.isValid, isTrue);
    });

    test('throws on missing file', () async {
      final service = FileBackupService(
        documentsDirectory: () async => tempDir,
      );
      expect(
        () => service.open('${tempDir.path}/does_not_exist.lessonbackup'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when archive has no metadata.json', () async {
      final junk = File('${tempDir.path}/junk.lessonbackup');
      // Empty ZIP — decodes but has no metadata entry.
      final emptyArchive = Archive();
      junk.writeAsBytesSync(ZipEncoder().encode(emptyArchive)!);

      final service = FileBackupService(
        documentsDirectory: () async => tempDir,
      );
      expect(() => service.open(junk.path), throwsA(isA<Exception>()));
    });
  });

  group('FileBackupService.restore validation', () {
    test('rejects archive with bad magic', () async {
      final service = FileBackupService(
        documentsDirectory: () async => tempDir,
      );
      final tampered = BackupArchive(
        filePath: '${tempDir.path}/whatever.lessonbackup',
        metadata: BackupArchiveMetadata(
          magic: 'not-our-magic',
          backupVersion: backupArchiveVersion,
          appVersion: 'test',
          createdAt: DateTime.utc(2026, 1, 1),
          recordingCount: 0,
          totalSizeBytes: 0,
          deviceModel: 'test',
          osVersion: 'test',
        ),
        recordings: const [],
      );

      final result = await service.restore(tampered);

      expect(result.success, isFalse);
      expect(result.failure, isNotNull);
    });

    test('rejects archive with incompatible major version', () async {
      final service = FileBackupService(
        documentsDirectory: () async => tempDir,
      );
      final tampered = BackupArchive(
        filePath: '${tempDir.path}/whatever.lessonbackup',
        metadata: BackupArchiveMetadata(
          magic: backupArchiveMagic,
          backupVersion: '99.0',
          appVersion: 'test',
          createdAt: DateTime.utc(2026, 1, 1),
          recordingCount: 0,
          totalSizeBytes: 0,
          deviceModel: 'test',
          osVersion: 'test',
        ),
        recordings: const [],
      );

      final result = await service.restore(tampered);

      expect(result.success, isFalse);
      expect(result.failure?.kind, BackupFailureKind.unsupportedVersion);
      expect(result.failure?.detail, '99.0');
    });

    test('rejects archive whose file no longer exists', () async {
      final service = FileBackupService(
        documentsDirectory: () async => tempDir,
      );
      final ghost = BackupArchive(
        filePath: '${tempDir.path}/missing.lessonbackup',
        metadata: BackupArchiveMetadata(
          magic: backupArchiveMagic,
          backupVersion: backupArchiveVersion,
          appVersion: 'test',
          createdAt: DateTime.utc(2026, 1, 1),
          recordingCount: 0,
          totalSizeBytes: 0,
          deviceModel: 'test',
          osVersion: 'test',
        ),
        recordings: const [],
      );

      final result = await service.restore(ghost);

      expect(result.success, isFalse);
    });
  });

  group('BackupArchive.isVersionCompatible', () {
    test('accepts 1.x archives', () {
      expect(BackupArchive.isVersionCompatible('1.0'), isTrue);
      expect(BackupArchive.isVersionCompatible('1.5'), isTrue);
    });
    test('rejects future major versions', () {
      expect(BackupArchive.isVersionCompatible('2.0'), isFalse);
      expect(BackupArchive.isVersionCompatible(''), isFalse);
    });
  });

  group('FileBackupService round-trip', () {
    test('restore copies recording files into documents dir', () async {
      final recordingsDir = Directory('${tempDir.path}/recordings');
      await recordingsDir.create(recursive: true);
      final original = File('${recordingsDir.path}/clip.m4a');
      await original.writeAsBytes(utf8.encode('audio-bytes'));

      final service = FileBackupService(
        documentsDirectory: () async => tempDir,
      );
      final archive = await service.create();

      // Wipe destination to force restore to write fresh.
      await original.delete();
      expect(original.existsSync(), isFalse);

      // Re-open from disk so we exercise the same path the UI uses.
      final reopened = await service.open(archive.filePath);
      final result = await service.restore(reopened);

      expect(result.success, isTrue);
      expect(result.restoredRecordings, 1);
      expect(File('${recordingsDir.path}/clip.m4a').existsSync(), isTrue);
    });

    test('restore skips existing recording files', () async {
      final recordingsDir = Directory('${tempDir.path}/recordings');
      await recordingsDir.create(recursive: true);
      await File('${recordingsDir.path}/clip.m4a').writeAsBytes([9, 9, 9]);

      final service = FileBackupService(
        documentsDirectory: () async => tempDir,
      );
      final archive = await service.create();

      final reopened = await service.open(archive.filePath);
      final result = await service.restore(reopened);

      expect(result.success, isTrue);
      expect(result.restoredRecordings, 0);
      expect(result.skippedRecordings, 1);
    });
  });
}
