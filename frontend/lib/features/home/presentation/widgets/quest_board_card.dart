import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_glyph.dart';
import '../../../../core/widgets/notebook/section_header.dart';
import '../../../profile/presentation/providers/quest_celebration_provider.dart';
import '../../../profile/presentation/providers/quest_first_shown_provider.dart';
import '../providers/home_lesson_summary_provider.dart';
import '../providers/teacher_profile_completion_provider.dart';
import 'quest_celebration_card.dart';

/// 가입 직후 첫 도착 시 자동 완료된 카드를 표시하는 시간 (§8.2).
const _kFirstArrivalRevealDuration = Duration(seconds: 2);

/// Quest 분류 그룹 — §13 퀘스트 시스템 (3-group).
enum QuestGroup {
  /// Q1~Q5 — 학생에게 보일 정보 준비 (가용시간/사진/소개/레슨비/계좌).
  profile,

  /// Q6~Q10 — 학생 연결 → 실제 운영 흐름 (학생/수강권/레슨/노트/숙제).
  operation,

  /// Q11 — 선택 보너스 (전화인증 = 인증 선생님 배지).
  bonus,
}

/// Quest Board — profile completion gamification widget.
///
/// 학습 가이드 + 단축 진입점. 모든 퀘스트는 선택 (가입 흐름 첫 가용시간만 강제).
/// 3-group 시맨틱 분류 + Q6→{Q7~Q10} Lock 매트릭스 단순화 (§13).
///
/// 자동 완료 즉시 소거 (§8.2):
/// - 일반 진입: 완료된 카드는 build 시점에 filter out (이미 본 카드)
/// - 가입 직후 첫 도착 (5분 윈도우): 완료된 카드도 2초 표시 후 소거
class QuestBoardCard extends ConsumerStatefulWidget {
  const QuestBoardCard({super.key});

  @override
  ConsumerState<QuestBoardCard> createState() => _QuestBoardCardState();
}

class _QuestBoardCardState extends ConsumerState<QuestBoardCard>
    with TickerProviderStateMixin {
  /// 가입 직후 첫 도착 윈도우 안이면 true — 2초 후 false 로 전환.
  bool _revealCompleted = false;
  Timer? _revealTimer;

  /// §B4 자동 완료 카드 애니메이션 (감사 §4.6).
  /// ScaleTransition(0.9 → 1.0, 300ms) + sustain 1s + FadeOut(500ms).
  late final AnimationController _revealScaleController;
  late final AnimationController _revealFadeController;
  late final Animation<double> _revealScale;
  late final Animation<double> _revealFade;
  Timer? _revealFadeTimer;

  @override
  void initState() {
    super.initState();
    _revealScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _revealFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      value: 1.0,
    );
    _revealScale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _revealScaleController, curve: Curves.easeOut),
    );
    _revealFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _revealFadeController, curve: Curves.easeIn),
    );

    // build() async — 첫 frame 직후 future 완료를 await 한 뒤 reveal 판정.
    // `ref.read(provider).value` 는 sync 라 AsyncLoading 시점에 null 반환 — race 회피.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final value = await ref.read(questFirstShownProvider.future);
      if (!mounted) return;
      if (QuestFirstShown.isWithin(value)) {
        setState(() => _revealCompleted = true);
        // §B4 사운드 1회 + scale-up.
        unawaited(SystemSound.play(SystemSoundType.click));
        _revealScaleController.forward(from: 0);
        // 300ms scale + 1s sustain → 1.3s 후 fade-out (500ms).
        _revealFadeTimer = Timer(const Duration(milliseconds: 1300), () {
          if (mounted) _revealFadeController.forward(from: 0);
        });
        _revealTimer = Timer(_kFirstArrivalRevealDuration, () {
          if (mounted) setState(() => _revealCompleted = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    _revealFadeTimer?.cancel();
    _revealScaleController.dispose();
    _revealFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final percent = ref.watch(profileCompletionPercentProvider);
    final hasSlots = ref.watch(hasAvailableSlotsProvider);
    final studentsAsync = ref.watch(homeStudentsProvider);
    final hasStudents = studentsAsync.valueOrNull?.isNotEmpty ?? false;
    final hasPhoto = ref.watch(hasProfileImageProvider);
    final hasIntro = ref.watch(hasIntroductionProvider);
    final hasPrice = ref.watch(hasPriceTableProvider);
    final hasBankAcc = ref.watch(hasBankAccountProvider);
    final hasSubscription = ref.watch(hasIssuedSubscriptionProvider);
    final hasCompletedLesson = ref.watch(homeHasCompletedLessonProvider);
    final hasLessonNote = ref.watch(hasWrittenLessonNoteProvider);
    final hasPracticeAssigned = ref.watch(hasAssignedPracticeProvider);
    // Phase C 보상 — phone_verification_policy.md §2.
    final isPhoneVerified = ref.watch(homeTeacherPhoneVerifiedProvider);

    // Board dismissal aligns with profileCompletionPercent SSOT
    // (10 mandatory quests sum to 100%, Q11 is bonus weight 0).
    final allMandatoryDone =
        hasSlots &&
        hasPhoto &&
        hasIntro &&
        hasPrice &&
        hasBankAcc &&
        hasStudents &&
        hasSubscription &&
        hasCompletedLesson &&
        hasLessonNote &&
        hasPracticeAssigned;

    if (allMandatoryDone) {
      // §8.3 전체 완료 — 축하 카드 1회 표시 (#608 Job 7).
      // BE PATCH /users/me/quest-celebrated 가 1회성 보장 SSOT.
      // Hive local 은 같은 세션 내 BE 호출 실패 시 재표시 방지용 fallback.
      final celebrationDismissed = ref
          .watch(questCelebrationProvider)
          .valueOrNull;
      if (celebrationDismissed != null) return const SizedBox.shrink();
      return const QuestCelebrationCard();
    }

    final quests = _buildQuests(
      context: context,
      hasSlots: hasSlots,
      hasStudents: hasStudents,
      hasPhoto: hasPhoto,
      hasIntro: hasIntro,
      hasPrice: hasPrice,
      hasBankAcc: hasBankAcc,
      hasSubscription: hasSubscription,
      hasCompletedLesson: hasCompletedLesson,
      hasLessonNote: hasLessonNote,
      hasPracticeAssigned: hasPracticeAssigned,
      isPhoneVerified: isPhoneVerified,
    );

    // 그룹별 분류: counter 는 전체 (완료 포함), visible 은 reveal 윈도우 외이면
    // 미완료만 표시 (§8.2 즉시 소거 — "이미 본 카드 노출하지 않음").
    final byGroupAll = <QuestGroup, List<_Quest>>{
      for (final g in QuestGroup.values)
        g: quests.where((q) => q.group == g).toList(),
    };
    final byGroupVisible = <QuestGroup, List<_Quest>>{
      for (final g in QuestGroup.values)
        g: byGroupAll[g]!
            .where((q) => _revealCompleted || !q.isCompleted)
            .toList(),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space4),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: NotebookSectionHeader(
                    label: AppStrings.questBoardTitle,
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                _ProgressGauge(percent: percent),
              ],
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              AppStrings.questBoardIntro,
              style: NotebookTypography.handMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            for (final group in QuestGroup.values) ...[
              if (byGroupVisible[group]!.isNotEmpty) ...[
                _QuestGroupSection(
                  group: group,
                  quests: byGroupVisible[group]!,
                  totalInGroup: byGroupAll[group]!.length,
                  completedInGroup: byGroupAll[group]!
                      .where((q) => q.isCompleted)
                      .length,
                  // §B4 자동 reveal 윈도우 안의 완료 카드에만 애니메이션 적용.
                  revealScale: _revealCompleted ? _revealScale : null,
                  revealFade: _revealCompleted ? _revealFade : null,
                ),
                if (group != QuestGroup.bonus)
                  const SizedBox(height: AppSpacing.space3),
              ],
            ],
          ],
        ),
      ),
    );
  }

  List<_Quest> _buildQuests({
    required BuildContext context,
    required bool hasSlots,
    required bool hasStudents,
    required bool hasPhoto,
    required bool hasIntro,
    required bool hasPrice,
    required bool hasBankAcc,
    required bool hasSubscription,
    required bool hasCompletedLesson,
    required bool hasLessonNote,
    required bool hasPracticeAssigned,
    required bool isPhoneVerified,
  }) {
    // §7 Lock 매트릭스 — Q6 → {Q7, Q8, Q9, Q10} 만 유지.
    // slotsBlocker (모든 퀘스트 잠금) 패턴 제거 — 모든 퀘스트는 의무 아님.
    VoidCallback onLockedTap() => () {
      // Q6 (학생 초대) 로 자동 이동 + 토스트 안내.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.questLockedStudentRequiredToast),
          duration: Duration(seconds: 2),
        ),
      );
      context.push(AppRoutes.invite);
    };

    return [
      // ── 🪪 프로필 설정 그룹 (Q1~Q5) ──
      _Quest(
        id: 'q1',
        group: QuestGroup.profile,
        title: AppStrings.questTitleSlots,
        reward: AppStrings.questRewardSlots,
        isCompleted: hasSlots,
        // §5.1 — Q1 진입 라우트 변경: teacherFirstAvailability → teacherAvailability (split_page).
        onTap: () => context.push(AppRoutes.teacherAvailability),
      ),
      _Quest(
        id: 'q2',
        group: QuestGroup.profile,
        title: AppStrings.questTitlePhoto,
        reward: AppStrings.questRewardSearch,
        isCompleted: hasPhoto,
        onTap: () => context.push(AppRoutes.basicInfoEdit),
      ),
      _Quest(
        id: 'q3',
        group: QuestGroup.profile,
        title: AppStrings.questTitleIntro,
        reward: AppStrings.questRewardWebProfile,
        isCompleted: hasIntro,
        thresholdHint: AppStrings.questThresholdIntroHint,
        onTap: () => context.push(AppRoutes.basicInfoEdit),
      ),
      _Quest(
        id: 'q4',
        group: QuestGroup.profile,
        title: AppStrings.questTitlePrice,
        reward: AppStrings.questRewardPrice,
        isCompleted: hasPrice,
        thresholdHint: AppStrings.questThresholdPriceHint,
        onTap: () => context.push(AppRoutes.lessonTimeSettings),
      ),
      _Quest(
        id: 'q5',
        group: QuestGroup.profile,
        title: AppStrings.questTitleBankAccount,
        reward: AppStrings.questRewardBankAccount,
        isCompleted: hasBankAcc,
        onTap: () => context.push(AppRoutes.bankAccountEdit),
      ),
      // ── 🎓 운영 시작 그룹 (Q6~Q10) ──
      _Quest(
        id: 'q6',
        group: QuestGroup.operation,
        title: AppStrings.questTitleStudent,
        reward: AppStrings.questRewardConnection,
        isCompleted: hasStudents,
        onTap: () => context.push(AppRoutes.invite),
      ),
      _Quest(
        id: 'q7',
        group: QuestGroup.operation,
        title: AppStrings.questTitleSubscription,
        reward: AppStrings.questRewardSubscription,
        isCompleted: hasSubscription,
        isLocked: !hasStudents,
        onTap: hasStudents
            ? () => context.push(AppRoutes.issueSubscription)
            : onLockedTap(),
      ),
      _Quest(
        id: 'q8',
        group: QuestGroup.operation,
        title: AppStrings.questTitleFirstLesson,
        reward: AppStrings.questRewardFirstLesson,
        isCompleted: hasCompletedLesson,
        isLocked: !hasStudents,
        onTap: hasStudents
            ? () => context.push(AppRoutes.lessons)
            : onLockedTap(),
      ),
      _Quest(
        id: 'q9',
        group: QuestGroup.operation,
        title: AppStrings.questTitleLessonNote,
        reward: AppStrings.questRewardLessonNote,
        isCompleted: hasLessonNote,
        isLocked: !hasStudents,
        onTap: hasStudents
            ? () => context.push(AppRoutes.quickFeedbackList)
            : onLockedTap(),
      ),
      _Quest(
        id: 'q10',
        group: QuestGroup.operation,
        title: AppStrings.questTitlePracticeAssign,
        reward: AppStrings.questRewardPracticeAssign,
        isCompleted: hasPracticeAssigned,
        isLocked: !hasStudents,
        thresholdHint: AppStrings.questThresholdPracticeHint,
        onTap: hasStudents
            ? () => context.push(AppRoutes.assignmentDashboard)
            : onLockedTap(),
      ),
      // ── ✨ 선택 보너스 그룹 (Q11) ──
      _Quest(
        id: 'q11',
        group: QuestGroup.bonus,
        title: AppStrings.questTitlePhoneVerification,
        reward: AppStrings.questRewardVerified,
        isCompleted: isPhoneVerified,
        // Bonus — lock 없음, 자유 진입.
        onTap: () => context.push(AppRoutes.teacherPhoneVerification),
      ),
    ];
  }
}

// ── Internal data model ───────────────────────────────────────────────────────

class _Quest {
  /// 퀘스트 고유 ID — q1~q11 (AnimatedSwitcher key 용).
  final String id;
  final QuestGroup group;
  final String title;
  final String? reward;
  final bool isCompleted;
  final VoidCallback? onTap;

  /// Lock 상태 — Q7~Q10 만 hasStudents == false 일 때 true.
  final bool isLocked;

  /// 임계값 hint (§9) — 완료 조건이 boolean 이 아닌 quest 만 표시.
  /// 예: Q3 "최소 20자", Q4 "최소 1개 가격", Q10 "1건 등록".
  final String? thresholdHint;

  const _Quest({
    required this.id,
    required this.group,
    required this.title,
    required this.reward,
    required this.isCompleted,
    required this.onTap,
    this.isLocked = false,
    this.thresholdHint,
  });
}

// ── Group section ─────────────────────────────────────────────────────────────

class _QuestGroupSection extends StatelessWidget {
  final QuestGroup group;

  /// 화면에 보이는 quest 목록 (완료 카드 filter 적용 후).
  final List<_Quest> quests;

  /// 그룹 내 전체 quest 수 (counter 표시용).
  final int totalInGroup;

  /// 그룹 내 완료된 quest 수 (counter 표시용).
  final int completedInGroup;

  /// §B4 자동 reveal 윈도우 동안 완료 카드에 적용할 scale 애니메이션.
  /// null = 적용 안 함 (일반 진입 또는 윈도우 밖).
  final Animation<double>? revealScale;

  /// §B4 자동 reveal 윈도우 종료 직전 완료 카드에 적용할 fade-out.
  final Animation<double>? revealFade;

  const _QuestGroupSection({
    required this.group,
    required this.quests,
    required this.totalInGroup,
    required this.completedInGroup,
    this.revealScale,
    this.revealFade,
  });

  String get _label {
    switch (group) {
      case QuestGroup.profile:
        return AppStrings.questGroupProfileLabel;
      case QuestGroup.operation:
        return AppStrings.questGroupOperationLabel;
      case QuestGroup.bonus:
        return AppStrings.questGroupBonusLabel;
    }
  }

  /// §B4 — 완료 카드에만 scale + fade-out 애니메이션 적용.
  /// 미완료 카드는 평소 그대로 렌더.
  Widget _maybeAnimate({required _Quest quest, required Widget child}) {
    if (!quest.isCompleted || revealScale == null || revealFade == null) {
      return child;
    }
    return FadeTransition(
      opacity: revealFade!,
      child: ScaleTransition(scale: revealScale!, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.space2),
          child: Row(
            children: [
              Text(
                _label,
                style: NotebookTypography.pieceTitle.copyWith(
                  fontSize: 14,
                  color: AppColors.inkSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '($completedInGroup/$totalInGroup)',
                style: NotebookTypography.roman.copyWith(
                  fontSize: 12,
                  color: AppColors.inkTertiary,
                ),
              ),
              if (group == QuestGroup.bonus) ...[
                const SizedBox(width: AppSpacing.space2),
                Text(
                  AppStrings.questGroupBonusOptionalTag,
                  style: NotebookTypography.roman.copyWith(
                    fontSize: 11,
                    color: AppColors.inkTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
        for (int i = 0; i < quests.length; i++) ...[
          _maybeAnimate(
            quest: quests[i],
            child: _QuestItem(
              quest: quests[i],
              isBonus: group == QuestGroup.bonus,
            ),
          ),
          if (i < quests.length - 1) const SizedBox(height: AppSpacing.space2),
        ],
      ],
    );
  }
}

// ── Progress gauge ────────────────────────────────────────────────────────────

class _ProgressGauge extends StatelessWidget {
  final int percent;

  const _ProgressGauge({required this.percent});

  @override
  Widget build(BuildContext context) {
    const gaugeWidth = 80.0;
    const gaugeHeight = 8.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: gaugeWidth,
          height: gaugeHeight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: AppColors.inkQuaternary,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.ink),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        Text(
          '$percent%',
          style: NotebookTypography.roman.copyWith(
            color: AppColors.inkSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ── Quest item row ─────────────────────────────────────────────────────────────

class _QuestItem extends StatelessWidget {
  final _Quest quest;

  /// Bonus 그룹은 외곽 점선 카드 (§10.1).
  final bool isBonus;

  const _QuestItem({required this.quest, this.isBonus = false});

  @override
  Widget build(BuildContext context) {
    final isEnabled = quest.onTap != null;
    final accentColor = quest.isCompleted
        ? AppColors.paperOk
        : isEnabled
        ? AppColors.ink
        : AppColors.inkTertiary;

    final content = InkWell(
      onTap: quest.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              child: quest.isCompleted
                  ? const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: NotebookGlyph(
                        NotebookGlyph.check,
                        size: 16,
                        color: AppColors.paperOk,
                      ),
                    )
                  : quest.isLocked
                  ? Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.lock_outline,
                        size: 14,
                        color: accentColor,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.title,
                    style: NotebookTypography.pieceTitle.copyWith(
                      fontSize: 15,
                      color: quest.isCompleted
                          ? AppColors.inkTertiary
                          : AppColors.ink,
                      decoration: quest.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (quest.reward != null && !quest.isCompleted) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const NotebookGlyph(
                          NotebookGlyph.arrowRight,
                          size: 12,
                          color: AppColors.inkTertiary,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            quest.isLocked
                                ? AppStrings.questLockedStudentRequiredHint
                                : quest.reward!,
                            style: NotebookTypography.roman.copyWith(
                              fontSize: 12,
                              color: AppColors.inkTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  // §9 임계값 hint — 조건이 boolean 이 아닌 quest 만 (Q3/Q4/Q10).
                  // lock 상태에선 lock hint 우선 (임계값 안 보이게).
                  if (quest.thresholdHint != null &&
                      !quest.isCompleted &&
                      !quest.isLocked) ...[
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: Text(
                        '· ${quest.thresholdHint}',
                        style: NotebookTypography.roman.copyWith(
                          fontSize: 11,
                          color: AppColors.inkTertiary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isEnabled && !quest.isCompleted)
              const Icon(Icons.chevron_right, color: AppColors.ink, size: 18),
          ],
        ),
      ),
    );

    if (isBonus) {
      return DottedBorderContainer(child: content);
    }
    return content;
  }
}

// ── Dotted border (Bonus 그룹 카드) ─────────────────────────────────────────────

class DottedBorderContainer extends StatelessWidget {
  final Widget child;

  const DottedBorderContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedBorderPainter(color: AppColors.inkTertiary),
      child: child,
    );
  }
}

class _DottedBorderPainter extends CustomPainter {
  final Color color;
  static const double _dashWidth = 4;
  static const double _dashGap = 3;

  _DottedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()..addRect(rect);
    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path source, Paint paint) {
    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + _dashWidth;
        dashed.addPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          Offset.zero,
        );
        distance = next + _dashGap;
      }
    }
    canvas.drawPath(dashed, paint);
  }

  @override
  bool shouldRepaint(_DottedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
