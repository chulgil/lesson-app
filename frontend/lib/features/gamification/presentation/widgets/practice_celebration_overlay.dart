import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// 학생 게이미피케이션 P1 — 연습 종료 후 1.5초 비방해 축하 오버레이.
///
/// 스펙 §4.3 + §9 / 플랜 Job 5 Task 5.2. 페이드 인 (200ms) → 표시
/// (~1100ms) → 페이드 아웃 (200ms) 후 [onDismiss] 호출.
///
/// `AnimationController` 기반 — `Future.delayed` 회피
/// (feedback_spy_mock_for_router_tests.md: pending timer / 라우터 race).
class PracticeCelebrationOverlay extends StatefulWidget {
  final int practiceMinutes;
  final int streakDays;
  final VoidCallback onDismiss;
  final Duration totalDuration;

  const PracticeCelebrationOverlay({
    super.key,
    required this.practiceMinutes,
    required this.streakDays,
    required this.onDismiss,
    this.totalDuration = const Duration(milliseconds: 1500),
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
      _dismissed = true;
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder:
          (context, _) => Opacity(
            opacity: _opacity.value,
            child: ColoredBox(
              color: Colors.black54,
              child: Center(
                child: Column(
                  key: const ValueKey('celebration_content'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      '${widget.practiceMinutes}분 했어요!',
                      key: const ValueKey('celebration_minutes'),
                      style: AppTypography.headingLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      '🔥 ${widget.streakDays}일 연속',
                      key: const ValueKey('celebration_streak'),
                      style: AppTypography.headingMedium.copyWith(
                        color: Colors.white,
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
