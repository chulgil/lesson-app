import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../practice/practice_facade.dart'
    show
        PracticeRepertoire,
        PracticeSection,
        practiceLogsProvider,
        practiceStreakProvider,
        studentRepertoiresProvider;
import '../../../practice/practice_ui_facade.dart' show PracticeToolsModal;
import '../../../students/students_facade.dart' show studentProvider;
import '../providers/effective_streak_provider.dart';
import '../providers/growth_heatmap_provider.dart';
import 'practice_celebration_overlay.dart';
import 'practice_start_card.dart';

/// 학생 홈 [연습 시작] 통합 컨테이너.
///
/// 스펙 §4.1 / 플랜 Job 5 Task 5.3 — Provider watch + [PracticeStartCard]
/// wiring 의 단일 책임 컨테이너. Job 7 PR-B 부터 onStartTap 은
/// [PracticeToolsModal] (메트로놈) 진입점 — modal 이 학생 컨텍스트와 함께
/// `Future<int?>` 를 반환하면 [PracticeCelebrationOverlay] 1.5초 비방해
/// 표시 후 홈 복귀.
class PracticeStartSection extends ConsumerWidget {
  final String studentId;

  const PracticeStartSection({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentProvider(studentId));
    final heatmapAsync = ref.watch(growthHeatmapProvider(studentId));
    final streakAsync = ref.watch(effectiveStreakProvider(studentId));

    final name = studentAsync.value?.nickname ?? studentAsync.value?.name ?? '';
    final heatmap = heatmapAsync.value;
    // Heatmap cells are keyed by the *local* calendar date tagged as UTC
    // (PracticeRecordingService), so derive "today" from local time.
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayMinutes = heatmap?.days[yesterday]?.totalMinutes ?? 0;
    // 표시 streak 은 SSOT(effectiveStreakProvider) — freeze 로 이어진 공백을
    // 건너뛴 값. 전 학생 화면 일치 (#1214 Phase 3).
    final streakDays = streakAsync.value?.effectiveCurrentStreak ?? 0;
    final freezeRemaining = streakAsync.value?.freezeBalance ?? 0;

    // Slice 2 — 가장 최근 연습한 곡을 선택적 "이어서" 칩으로 노출. 없으면 null.
    final repertoiresAsync = ref.watch(studentRepertoiresProvider(studentId));
    final recentSection = mostRecentActivePracticeSection(
      repertoiresAsync.valueOrNull ?? const [],
    );

    return PracticeStartCard(
      studentName: name,
      streakDays: streakDays,
      freezeRemaining: freezeRemaining,
      yesterdayMinutes: yesterdayMinutes,
      onStartTap: () => _practice(context, ref),
      onMoreTap: () => _onMoreTap(context),
      continuePieceName: recentSection?.pieceName,
      onContinueTap:
          recentSection == null
              ? null
              : () => _practice(context, ref, sectionId: recentSection.id),
    );
  }

  void _onMoreTap(BuildContext context) {
    context.push('${AppRoutes.studentGrowthDetail}?studentId=$studentId');
  }

  Future<void> _practice(
    BuildContext context,
    WidgetRef ref, {
    String? sectionId,
  }) async {
    final practicedMinutes = await PracticeToolsModal.show(
      context,
      studentId: studentId,
      sectionId: sectionId,
    );
    if (!context.mounted) return;
    if (practicedMinutes == null || practicedMinutes <= 0) return;

    // recordPractice hub 가 heatmap+practice-logs 양쪽을 갱신 → 관련 provider 무효화.
    // 표시 streak 은 SSOT(effectiveStreakProvider) — raw streak + 연습 로그를
    // 재료로 쓰므로 둘 다 무효화해야 브리지 계산이 최신이 된다. heatmap 은 viz 갱신용.
    ref.invalidate(growthHeatmapProvider(studentId));
    ref.invalidate(practiceStreakProvider(studentId));
    ref.invalidate(practiceLogsProvider(studentId));
    ref.invalidate(effectiveStreakProvider(studentId));
    // 특정 곡에서 연습했으면 그 곡의 lastPracticedAt/차감이 반영되도록 목록도 무효화.
    if (sectionId != null) {
      ref.invalidate(studentRepertoiresProvider(studentId));
    }
    final streak = await ref.read(effectiveStreakProvider(studentId).future);

    if (!context.mounted) return;
    await _showCelebration(
      context,
      practiceMinutes: practicedMinutes,
      streakDays: streak.effectiveCurrentStreak,
    );
  }

  Future<void> _showCelebration(
    BuildContext context, {
    required int practiceMinutes,
    required int streakDays,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder:
          (ctx) => PracticeCelebrationOverlay(
            practiceMinutes: practiceMinutes,
            streakDays: streakDays,
            onDismiss: () {
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
          ),
    );
  }
}

/// 모든 repertoire 의 section 중, 아직 완료되지 않았고(`!isCompleted`)
/// 실제로 연습된 적이 있는(`lastPracticedAt != null`) 것 가운데
/// 가장 최근에 연습한 section 을 반환한다. 하나도 연습된 적 없으면 `null`.
///
/// Slice 2 "이어서" 칩의 대상 곡을 결정하는 순수 함수 — provider watch 결과를
/// 주입받아 UI 위젯과 독립적으로 테스트 가능하다.
@visibleForTesting
PracticeSection? mostRecentActivePracticeSection(
  List<PracticeRepertoire> repertoires,
) {
  PracticeSection? best;
  for (final repertoire in repertoires) {
    for (final section in repertoire.sections) {
      if (section.isCompleted) continue;
      final practicedAt = section.lastPracticedAt;
      if (practicedAt == null) continue;
      if (best == null || practicedAt.isAfter(best.lastPracticedAt!)) {
        best = section;
      }
    }
  }
  return best;
}
