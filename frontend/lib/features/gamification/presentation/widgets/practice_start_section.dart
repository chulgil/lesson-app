import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../practice/presentation/widgets/practice_tools_modal.dart';
import '../../../students/presentation/providers/student_crud_provider.dart';
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

    final name = studentAsync.value?.nickname ?? studentAsync.value?.name ?? '';
    final heatmap = heatmapAsync.value;
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayMinutes = heatmap?.days[yesterday]?.totalMinutes ?? 0;
    final streakDays = heatmap?.streakDays(today) ?? 0;

    return PracticeStartCard(
      studentName: name,
      streakDays: streakDays,
      yesterdayMinutes: yesterdayMinutes,
      onStartTap: () => _onStartTap(context, ref),
      onMoreTap: () => _onMoreTap(context),
    );
  }

  void _onMoreTap(BuildContext context) {
    context.go('${AppRoutes.studentGrowthDetail}?studentId=$studentId');
  }

  Future<void> _onStartTap(BuildContext context, WidgetRef ref) async {
    final practicedMinutes = await PracticeToolsModal.show(
      context,
      studentId: studentId,
    );
    if (!context.mounted) return;
    if (practicedMinutes == null || practicedMinutes <= 0) return;

    // heatmap 은 stop hook 의 logger 호출 결과로 갱신됨 — 최신 streak 조회.
    ref.invalidate(growthHeatmapProvider(studentId));
    final heatmap = await ref.read(growthHeatmapProvider(studentId).future);
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    final streak = heatmap.streakDays(today);

    if (!context.mounted) return;
    await _showCelebration(
      context,
      practiceMinutes: practicedMinutes,
      streakDays: streak,
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
