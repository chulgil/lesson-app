import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/spotlight_prompt.dart';
import 'spotlight_slot.dart';

/// 학생 게이미피케이션 P1 — 연습 종료 후 1.5초 비방해 축하 오버레이.
///
/// 스펙 §4.3 + §9 / 플랜 Job 5 Task 5.2. 페이드 인 (200ms) → 표시
/// (~1100ms) → 페이드 아웃 (200ms) 후 [onDismiss] 호출.
///
/// `AnimationController` 기반 — `Future.delayed` 회피
/// (feedback_spy_mock_for_router_tests.md: pending timer / 라우터 race).
///
/// P3 (Job 7 Task 7.2): [spotlightPrompt] 가 주어지면 1.5초 축하 후 자동
/// 으로 [SpotlightSlot] 표시 phase 진입. 사용자가 "지금 볼래" / "다음에"
/// 선택 후에 [onDismiss] 호출. [spotlightPrompt] 가 null 이면 기존 1.5초
/// 동작 회귀 0 (SC-1).
class PracticeCelebrationOverlay extends StatefulWidget {
  final int practiceMinutes;
  final int streakDays;
  final VoidCallback onDismiss;
  final Duration totalDuration;

  /// P3: 1.5초 축하 후 노출할 Spotlight prompt. null 이면 기존 1.5초 종료.
  final SpotlightPrompt? spotlightPrompt;

  /// "지금 볼래" tap 콜백 (overlay 종료 직전 호출).
  final ValueChanged<SpotlightPrompt>? onSpotlightAccept;

  /// "다음에" tap 콜백 (overlay 종료 직전 호출).
  final ValueChanged<SpotlightPrompt>? onSpotlightDecline;

  const PracticeCelebrationOverlay({
    super.key,
    required this.practiceMinutes,
    required this.streakDays,
    required this.onDismiss,
    this.totalDuration = const Duration(milliseconds: 1500),
    this.spotlightPrompt,
    this.onSpotlightAccept,
    this.onSpotlightDecline,
  });

  @override
  State<PracticeCelebrationOverlay> createState() =>
      _PracticeCelebrationOverlayState();
}

class _PracticeCelebrationOverlayState extends State<PracticeCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  bool _dismissed = false;
  bool _showSpotlight = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.totalDuration,
    );
    // fade-in 200ms (0~0.13) → 표시 (0.13~0.87) → fade-out 200ms (0.87~1)
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 200 / 1500),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 1100 / 1500),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 200 / 1500),
    ]).animate(_controller);
    _controller.forward().whenComplete(() {
      if (_dismissed || !mounted) return;
      if (widget.spotlightPrompt != null) {
        // P3 Job 7 Task 7.2 — 1.5초 축하 후 SpotlightSlot 표시 phase.
        setState(() => _showSpotlight = true);
        return;
      }
      _dismissed = true;
      widget.onDismiss();
    });
  }

  void _completeWithSpotlight(void Function(SpotlightPrompt prompt) action) {
    if (_dismissed || !mounted) return;
    final prompt = widget.spotlightPrompt;
    if (prompt != null) action(prompt);
    _dismissed = true;
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showSpotlight && widget.spotlightPrompt != null) {
      return ColoredBox(
        color: AppColors.inkScrim,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space6,
              ),
              child: SpotlightSlot(
                prompt: widget.spotlightPrompt!,
                onAccept:
                    () => _completeWithSpotlight(
                      (p) => widget.onSpotlightAccept?.call(p),
                    ),
                onDecline:
                    () => _completeWithSpotlight(
                      (p) => widget.onSpotlightDecline?.call(p),
                    ),
              ),
            ),
          ),
        ),
      );
    }
    return AnimatedBuilder(
      animation: _opacity,
      builder:
          (context, _) => Opacity(
            opacity: _opacity.value,
            child: ColoredBox(
              color: AppColors.inkScrim,
              child: Center(
                child: Column(
                  key: const ValueKey('celebration_content'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: AppSpacing.icon2XL,
                      color: AppColors.paper,
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      '${widget.practiceMinutes}분 했어요!',
                      key: const ValueKey('celebration_minutes'),
                      style: AppTypography.headingLarge.copyWith(
                        color: AppColors.paper,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      '${widget.streakDays}일 연속',
                      key: const ValueKey('celebration_streak'),
                      style: AppTypography.headingMedium.copyWith(
                        color: AppColors.paper,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
