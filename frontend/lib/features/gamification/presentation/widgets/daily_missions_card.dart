// 오늘의 미션 — 고정1(연습 목표) + 로테이션2(메트로놈/튜너/녹음 중 2개) 데일리
// 미션 카드 (doc 46 §4④, P3a 데일리 만족 루프). ESL 앱의 "도장 3칸" 관행을
// Notebook × Score 스탬프 메타포로 미러링한다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_glyph.dart';
import '../../domain/entities/daily_mission.dart';
import '../../domain/services/daily_mission_rotation.dart';
import '../extensions/daily_mission_visuals.dart';
import '../providers/daily_missions_provider.dart';

/// 오늘의 미션 카드 — 학생 대시보드, [DailyGoalCard] 인근에 배치한다.
///
/// [DailyGoalCard]와의 관계: [DailyGoalCard]는 연습 "분(分)" 진행바만 보여
/// 준다. 이 카드는 그 목표를 고정 코어 미션으로 포함하되, 메트로놈/튜너/
/// 녹음 도구 사용을 매일 로테이션되는 2개의 추가 미션으로 얹어 다양성을
/// 준다 — 서로 대체 관계가 아니라 보완 관계.
///
/// 완료 표시는 [dailyMissionsProvider]가 계산한 `progress>=target`(derived)
/// 값을 그대로 렌더한다. 한 번 derived 로 완료된 미션을 그날 안에서 계속
/// 완료 상태로 고정(멱등 원장 기록)하는 책임은 이 위젯의 post-frame 콜백이
/// 맡는다 — provider 자기 자신이 아닌 다른 provider 를 build 도중 동기
/// mutate 하는 패턴을 피하기 위해서다.
class DailyMissionsCard extends ConsumerStatefulWidget {
  const DailyMissionsCard({super.key, required this.studentId});

  final String studentId;

  @override
  ConsumerState<DailyMissionsCard> createState() => _DailyMissionsCardState();
}

class _DailyMissionsCardState extends ConsumerState<DailyMissionsCard> {
  @override
  Widget build(BuildContext context) {
    // dailyMissionsProvider 는 동기 조합(각 의존 provider 를 valueOrNull ??
    // 기본값 으로 읽음) — 첫 프레임부터 항상 렌더 가능하고, 각 provider 가
    // 실제로 resolve 되는 순간 자동으로 재계산된다 (DailyGoalCard 와 동일
    // 패턴). AsyncValue.when 이 필요 없다.
    final missions = ref.watch(dailyMissionsProvider(widget.studentId));
    _scheduleLedgerLock(missions);
    return _buildCard(context, missions);
  }

  /// derived 로 완료된 미션을 완료 원장에 멱등 기록 — 프레임 렌더 이후
  /// (post-frame) 예약한다. [DailyMissionLedger.markCompleted] 자체가
  /// 멱등(이미 있으면 no-op)이라 매 프레임 재호출해도 안전하다.
  void _scheduleLedgerLock(List<DailyMission> missions) {
    final toLock = missions.where(
      (m) => m.target > 0 && m.progress >= m.target,
    );
    if (toLock.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final dateKst = DailyMissionRotation.kstCalendarDate(DateTime.now());
      final notifier = ref.read(
        dailyMissionLedgerProvider(widget.studentId, dateKst).notifier,
      );
      for (final mission in toLock) {
        notifier.markCompleted(mission.kind);
      }
    });
  }

  Widget _buildCard(BuildContext context, List<DailyMission> missions) {
    final doneCount = missions.where((m) => m.completed).length;
    final allDone = missions.isNotEmpty && doneCount == missions.length;

    return Container(
      key: const ValueKey('daily_missions_card'),
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                allDone ? Icons.check_circle : Icons.checklist_outlined,
                size: AppSpacing.iconMD,
                color: allDone ? AppColors.paperOk : AppColors.ink,
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Text(
                  AppStrings.dailyMissionsCardTitle,
                  style: NotebookTypography.sectionTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                AppStrings.dailyMissionsProgressLabel(
                  doneCount,
                  missions.length,
                ),
                key: const ValueKey('daily_missions_progress_label'),
                style: AppTypography.bodyMedium.copyWith(
                  color: allDone ? AppColors.paperOk : AppColors.inkSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          for (final mission in missions) ...[
            _MissionRow(mission: mission),
            if (mission != missions.last)
              const SizedBox(height: AppSpacing.space2),
          ],
          if (allDone) ...[
            const SizedBox(height: AppSpacing.space3),
            Text(
              AppStrings.dailyMissionsAllDoneBonus,
              key: const ValueKey('daily_missions_bonus_label'),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.paperOk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MissionRow extends StatelessWidget {
  const _MissionRow({required this.mission});

  final DailyMission mission;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: ValueKey('daily_mission_row_${mission.kind.name}'),
      children: [
        _StampSlot(done: mission.completed),
        const SizedBox(width: AppSpacing.space3),
        Icon(
          mission.kind.icon,
          size: AppSpacing.iconSM,
          color: mission.completed ? AppColors.paperOk : AppColors.inkTertiary,
        ),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: Text(
            mission.kind.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              color: mission.completed ? AppColors.ink : AppColors.inkSecondary,
              decoration: mission.completed ? TextDecoration.lineThrough : null,
              decorationColor: AppColors.inkTertiary,
            ),
          ),
        ),
      ],
    );
  }
}

/// 스탬프 칸 — 완료면 채워진 체크 글리프, 미완료면 점선 원.
class _StampSlot extends StatelessWidget {
  const _StampSlot({required this.done});

  final bool done;

  static const double _size = 22;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey('daily_mission_stamp_${done ? 'done' : 'pending'}'),
      width: _size,
      height: _size,
      child:
          done
              ? Center(
                child: NotebookGlyph(
                  NotebookGlyph.check,
                  size: 16,
                  color: AppColors.paperOk,
                  semanticLabel: AppStrings.confirm,
                ),
              )
              : CustomPaint(painter: _DashedCircleBorderPainter()),
    );
  }
}

/// 미완료 스탬프 칸의 점선 원 테두리 — [_DashedLinePainter] 계열과 동일하게
/// 파일별 private painter 컨벤션을 따른다.
class _DashedCircleBorderPainter extends CustomPainter {
  static const double _dashLength = 3;
  static const double _gapLength = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = AppColors.inkQuaternary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
    final radius = (size.shortestSide - paint.strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final circumference = 2 * 3.141592653589793 * radius;
    final dashCount = (circumference / (_dashLength + _gapLength)).floor();
    final angleStep = (2 * 3.141592653589793) / dashCount;
    final dashAngle = angleStep * (_dashLength / (_dashLength + _gapLength));

    for (var i = 0; i < dashCount; i++) {
      final startAngle = i * angleStep;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCircleBorderPainter oldDelegate) => false;
}
