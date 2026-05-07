import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lessonaza/features/auth/auth_facade.dart';
import 'package:lessonaza/features/practice/domain/entities/journal_privacy.dart';
import 'package:lessonaza/features/practice/presentation/providers/journal_privacy_provider.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('journal_privacy_storage_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  ProviderContainer containerFor(String userId) {
    return ProviderContainer(
      overrides: [currentUserIdProvider.overrideWith((ref) => userId)],
    );
  }

  test('loads private by default for a student scope', () async {
    final container = containerFor('teacher_a');
    addTearDown(container.dispose);

    final state = await container.read(
      journalPrivacySettingProvider('student_1').future,
    );

    expect(state, JournalPrivacy.private);
  });

  test('persists privacy changes for the current user and student', () async {
    final container = containerFor('teacher_a');
    addTearDown(container.dispose);

    final notifier = container.read(
      journalPrivacySettingProvider('student_1').notifier,
    );
    await notifier.setShared();
    final saved = await container.read(
      journalPrivacySettingProvider('student_1').future,
    );

    expect(saved, JournalPrivacy.shared);

    final box = await Hive.openBox<Map>('practice_journal_privacy');
    expect(box.length, 1);
    expect(
      box.get('user:teacher_a:student:student_1'),
      containsPair('privacy', 'shared'),
    );
  });

  test('keeps privacy state isolated by user and by student', () async {
    final teacherA = containerFor('teacher_a');
    addTearDown(teacherA.dispose);

    await teacherA
        .read(journalPrivacySettingProvider('student_1').notifier)
        .setPartial();
    final teacherAStudent1 = await teacherA.read(
      journalPrivacySettingProvider('student_1').future,
    );
    expect(teacherAStudent1, JournalPrivacy.partial);

    final teacherAStudent2 = await teacherA.read(
      journalPrivacySettingProvider('student_2').future,
    );
    expect(teacherAStudent2, JournalPrivacy.private);

    final teacherB = containerFor('teacher_b');
    addTearDown(teacherB.dispose);

    final teacherBStudent1 = await teacherB.read(
      journalPrivacySettingProvider('student_1').future,
    );
    expect(teacherBStudent1, JournalPrivacy.private);

    final teacherAReloaded = containerFor('teacher_a');
    addTearDown(teacherAReloaded.dispose);

    final teacherAStudent1Reloaded = await teacherAReloaded.read(
      journalPrivacySettingProvider('student_1').future,
    );
    expect(teacherAStudent1Reloaded, JournalPrivacy.partial);
  });
}
