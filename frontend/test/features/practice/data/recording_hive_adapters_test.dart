import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lessonaza/features/practice/data/models/recording_hive_adapters.dart';
import 'package:lessonaza/features/practice/domain/entities/recording.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('recording_hive_adapters_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('keeps legacy type ids for existing recording boxes', () {
    expect(RecordingTypeAdapter().typeId, 20);
    expect(StorageStatusAdapter().typeId, 21);
    expect(RecordingAdapter().typeId, 22);
  });

  test('round trips recording fields with the legacy Hive schema', () async {
    Hive
      ..registerAdapter(RecordingTypeAdapter())
      ..registerAdapter(StorageStatusAdapter())
      ..registerAdapter(RecordingAdapter());

    final box = await Hive.openBox<Recording>('recordings');
    final recordedAt = DateTime(2026, 5, 7, 10, 30);
    final sharedAt = DateTime(2026, 5, 7, 11, 45);
    final recording = Recording(
      id: 'recording-1',
      repertoireId: 'repertoire-1',
      studentId: 'student-1',
      type: RecordingType.teacher,
      localPath: '/tmp/recording.m4a',
      serverUrl: 'https://example.com/recording.m4a',
      durationSeconds: 91,
      isRepresentative: true,
      recordedAt: recordedAt,
      sharedAt: sharedAt,
      storageStatus: StorageStatus.archived,
      title: 'Etude take 1',
    );

    await box.put(recording.id, recording);

    expect(box.get(recording.id), recording);
    expect(box.get(recording.id)!.type, RecordingType.teacher);
    expect(box.get(recording.id)!.storageStatus, StorageStatus.archived);
    expect(box.get(recording.id)!.serverUrl, recording.serverUrl);
    expect(box.get(recording.id)!.recordedAt, recordedAt);
    expect(box.get(recording.id)!.sharedAt, sharedAt);
    expect(box.get(recording.id)!.title, recording.title);
  });
}
