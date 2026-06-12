// Student gamification P3 — Spotlight providers (Job 6).

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/mock_spotlight_prompt_repository.dart';
import '../../domain/entities/spotlight_prompt.dart';
import '../../domain/repositories/spotlight_prompt_repository.dart';
import '../../domain/services/spotlight_decline_learning_service.dart';
import '../../domain/services/spotlight_eligibility_service.dart';
import '../../domain/services/spotlight_queue_service.dart';

part 'spotlight_provider.g.dart';

/// P3: Mock 우선 (P1/P2 패턴 일관). Hive 운영 통합은 Job 7/Job 9 단계에서 분기.
@Riverpod(keepAlive: true)
SpotlightPromptRepository spotlightPromptRepository(
  SpotlightPromptRepositoryRef ref,
) => MockSpotlightPromptRepository();

@Riverpod(keepAlive: true)
SpotlightEligibilityService spotlightEligibilityService(
  SpotlightEligibilityServiceRef ref,
) => const SpotlightEligibilityService();

@Riverpod(keepAlive: true)
SpotlightQueueService spotlightQueueService(SpotlightQueueServiceRef ref) =>
    SpotlightQueueService(ref.watch(spotlightPromptRepositoryProvider));

@Riverpod(keepAlive: true)
SpotlightDeclineLearningService spotlightDeclineLearningService(
  SpotlightDeclineLearningServiceRef ref,
) => SpotlightDeclineLearningService(
  ref.watch(spotlightPromptRepositoryProvider),
);

/// 축하 overlay 에 노출할 다음 prompt 평가.
///
/// 흐름:
/// 1. Queue.nextPromptableFor(studentId, now) — promptable 있는지 + 정렬된 후보
/// 2. lastShownAt 분포로 promptsShownToday / promptsShownThisWeek 도출
///    (월요일 시작, KST 기준)
/// 3. Eligibility.evaluate(ctx) — 6 조건 평가
/// 4. eligible → 후보 반환 / 아니면 null
@riverpod
Future<SpotlightPrompt?> currentSpotlightForCelebration(
  CurrentSpotlightForCelebrationRef ref,
  String studentId, {
  required Duration sessionDuration,
  required DateTime now,
  required bool studentIsUnder14,
  required bool studentHasParentConsent,
}) async {
  final repo = ref.watch(spotlightPromptRepositoryProvider);
  final queue = ref.watch(spotlightQueueServiceProvider);
  final eligibility = ref.watch(spotlightEligibilityServiceProvider);

  final candidate = await queue.nextPromptableFor(studentId, now);
  final all = await repo.listForStudent(studentId);

  // KST 자정 기준 오늘/주간 카운터 도출.
  final kstNow = now.toUtc().add(const Duration(hours: 9));
  final kstMidnight = DateTime.utc(
    kstNow.year,
    kstNow.month,
    kstNow.day,
  ).subtract(const Duration(hours: 9));
  // ISO 주: 월요일 시작. now.weekday: Mon=1, Sun=7.
  final daysSinceMonday = (kstNow.weekday - 1) % 7;
  final kstMondayMidnight = DateTime.utc(
    kstNow.year,
    kstNow.month,
    kstNow.day,
  ).subtract(Duration(days: daysSinceMonday, hours: 9));

  int countShown(DateTime since) =>
      all
          .where(
            (p) => p.lastShownAt != null && !p.lastShownAt!.isBefore(since),
          )
          .length;

  final promptsShownToday = countShown(kstMidnight);
  final promptsShownThisWeek = countShown(kstMondayMidnight);

  final ctx = SpotlightEligibilityContext(
    sessionDuration: sessionDuration,
    now: now,
    promptsShownToday: promptsShownToday,
    promptsShownThisWeek: promptsShownThisWeek,
    studentIsUnder14: studentIsUnder14,
    studentHasParentConsent: studentHasParentConsent,
    queueHasPromptableItem: candidate != null,
  );

  final verdict = eligibility.evaluate(ctx);
  if (!verdict.eligible) return null;
  return candidate;
}
