import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../practice/presentation/widgets/manual_practice_entry_dialog.dart';
import '../../../practice/presentation/providers/practice_recording_provider.dart';
import '../../../students/presentation/providers/student_crud_provider.dart';
import '../providers/growth_heatmap_provider.dart';
import 'practice_start_card.dart';

/// 학생 홈 [연습 시작] 통합 컨테이너.
///
/// 스펙 §4.1 / 플랜 Job 5 Task 5.3 — Provider watch + [PracticeStartCard]
/// wiring 의 단일 책임 컨테이너. P1 의 onStartTap 은 보수적으로
/// [ManualPracticeEntryDialog] 노출 — 메트로놈/튜너/YouTube 자동 진입은
/// Job 7 시점에 사용자 검증 후 라우팅 추가.
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
    );
  }

  Future<void> _onStartTap(BuildContext context, WidgetRef ref) async {
    final loggers = ref.read(practiceSourceLoggersProvider);
    await showDialog<void>(
      context: context,
      builder:
          (ctx) => ManualPracticeEntryDialog(
            onConfirm: (minutes, note) async {
              await loggers.logManual(
                studentId: studentId,
                durationMinutes: minutes,
                note: note,
              );
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
          ),
    );
  }
}
