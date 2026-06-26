import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/challenge.dart';
import '../../domain/entities/quest_origin.dart';
import '../../domain/entities/student_quest.dart';
import '../providers/gamification_onboarding_dismissed_provider.dart';
import '../providers/student_quest_provider.dart';
import '../screens/student_gamification_onboarding_screen.dart';

/// 학생 게이미피케이션 P1 자동 onboarding 트리거.
///
/// 스펙 §4.6 / 플랜 Job 6 Task 6.2 / O7 결정.
///
/// 동작:
/// - [activeQuestsProvider] watch — `StudentQuest` 0 개 시 onboarding 화면을
///   [child] 대신 표시 (자동 트리거).
/// - accept 시 시스템 루틴 quest 1 개 생성 ('스케일 5분') → state 변경 →
///   trigger 해제 → child 표시.
/// - decline 시 quest 미생성 + 해제 플래그 영속 (재진입 시 미노출, #81).
class StudentGamificationOnboardingTrigger extends ConsumerWidget {
  final String studentId;
  final Widget child;
  final DateTime Function()? nowOverride;

  const StudentGamificationOnboardingTrigger({
    super.key,
    required this.studentId,
    required this.child,
    this.nowOverride,
  });

  DateTime _now() => nowOverride?.call() ?? DateTime.now();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(activeQuestsProvider(studentId));
    final dismissedAsync = ref.watch(
      gamificationOnboardingDismissedProvider(studentId),
    );

    return activeAsync.when(
      data: (quests) {
        final dismissed = dismissedAsync.valueOrNull ?? false;
        // #81: quest 0개라도 1회 해제('내가 정할래')한 학생에게는 재노출 금지.
        if (quests.isEmpty && !dismissed) {
          return StudentGamificationOnboardingScreen(
            onResult: (instrument, accepted) async {
              if (accepted) {
                final repo = ref.read(studentQuestRepositoryProvider);
                final n = _now();
                await repo.createQuest(
                  StudentQuest(
                    id: 'onboard-${n.microsecondsSinceEpoch}',
                    studentId: studentId,
                    origin: QuestOrigin.systemRoutine,
                    title: '스케일 5분',
                    type: ActivityType.practiceMinutes,
                    targetValue: 5,
                    currentValue: 0,
                    startDate: DateTime(n.year, n.month, n.day),
                    endDate: DateTime(n.year, n.month, n.day + 7),
                  ),
                );
                ref.invalidate(activeQuestsProvider(studentId));
              } else {
                // decline: quest 미생성. 해제 플래그를 영속화하여 재노출 차단.
                await ref
                    .read(gamificationOnboardingDismissStoreProvider)
                    .markDismissed(studentId);
                ref.invalidate(
                  gamificationOnboardingDismissedProvider(studentId),
                );
              }
            },
          );
        }
        return child;
      },
      loading:
          () => const Center(
            key: ValueKey('onboarding_trigger_loading'),
            child: CircularProgressIndicator(),
          ),
      error: (_, __) => child,
    );
  }
}
