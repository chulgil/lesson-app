import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lessonaza/features/auth/auth_facade.dart';
import 'package:lessonaza/features/onboarding/presentation/providers/onboarding_progress_storage_provider.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync(
      'onboarding_progress_storage_',
    );
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('loads default state for the current teacher', () async {
    final container = ProviderContainer(
      overrides: [currentUserIdProvider.overrideWith((ref) => 'teacher_a')],
    );
    addTearDown(container.dispose);

    final state = await container.read(
      onboardingProgressStorageProvider.future,
    );

    expect(state.teacherOnboardingCompleted, isFalse);
    expect(state.demoOverlayDismissed, isFalse);
  });

  test('persists teacher onboarding and demo overlay state', () async {
    final container = ProviderContainer(
      overrides: [currentUserIdProvider.overrideWith((ref) => 'teacher_a')],
    );
    addTearDown(container.dispose);

    final notifier = container.read(onboardingProgressStorageProvider.notifier);
    await notifier.setTeacherOnboardingCompleted(true);
    await notifier.setDemoOverlayDismissed(true);
    await container.read(onboardingProgressStorageProvider.future);

    final reloaded = ProviderContainer(
      overrides: [currentUserIdProvider.overrideWith((ref) => 'teacher_a')],
    );
    addTearDown(reloaded.dispose);

    final state = await reloaded.read(onboardingProgressStorageProvider.future);

    expect(state.teacherOnboardingCompleted, isTrue);
    expect(state.demoOverlayDismissed, isTrue);
  });

  test('keeps teacher states isolated by user id', () async {
    final teacherA = ProviderContainer(
      overrides: [currentUserIdProvider.overrideWith((ref) => 'teacher_a')],
    );
    addTearDown(teacherA.dispose);

    final teacherANotifier = teacherA.read(
      onboardingProgressStorageProvider.notifier,
    );
    await teacherANotifier.setTeacherOnboardingCompleted(true);
    await teacherANotifier.setDemoOverlayDismissed(true);
    await teacherA.read(onboardingProgressStorageProvider.future);

    final teacherB = ProviderContainer(
      overrides: [currentUserIdProvider.overrideWith((ref) => 'teacher_b')],
    );
    addTearDown(teacherB.dispose);

    final teacherBState = await teacherB.read(
      onboardingProgressStorageProvider.future,
    );
    expect(teacherBState.teacherOnboardingCompleted, isFalse);
    expect(teacherBState.demoOverlayDismissed, isFalse);

    final teacherAReloaded = ProviderContainer(
      overrides: [currentUserIdProvider.overrideWith((ref) => 'teacher_a')],
    );
    addTearDown(teacherAReloaded.dispose);

    final teacherAState = await teacherAReloaded.read(
      onboardingProgressStorageProvider.future,
    );
    expect(teacherAState.teacherOnboardingCompleted, isTrue);
    expect(teacherAState.demoOverlayDismissed, isTrue);
  });
}
