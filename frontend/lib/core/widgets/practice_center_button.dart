import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../features/auth/auth_facade.dart' show currentUserIdProvider;
import '../../features/gamification/gamification_facade.dart'
    show growthHeatmapProvider;
import '../../features/practice/practice_facade.dart'
    show practiceStreakProvider;
import '../../features/practice/presentation/widgets/practice_tools_modal.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// SVG icon for metronome (simple pyramid style)
const _metronomeIconSvg = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <!-- Metronome body (pyramid) -->
  <path d="M12 2 L20 22 L4 22 Z" stroke="white" stroke-width="2" fill="none" stroke-linejoin="round"/>
  <!-- Pendulum -->
  <line x1="12" y1="18" x2="7" y2="6" stroke="white" stroke-width="2" stroke-linecap="round"/>
  <!-- Pendulum weight -->
  <circle cx="7" cy="6" r="2" fill="white"/>
  <!-- Base decoration -->
  <line x1="6" y1="22" x2="18" y2="22" stroke="white" stroke-width="2" stroke-linecap="round"/>
</svg>
''';

/// Central practice button for bottom navigation bar.
///
/// Features:
/// - Tap: Open practice tools modal with Metronome tab
/// - Long press: Open practice tools modal with Tuner tab
/// - Pixel art style icon (tuning fork + metronome)
/// - Passes currentUserIdProvider as studentId so logMetronome fires on stop.
class PracticeCenterButton extends ConsumerStatefulWidget {
  const PracticeCenterButton({super.key, this.size = 56});

  /// Button size (width and height).
  final double size;

  @override
  ConsumerState<PracticeCenterButton> createState() =>
      _PracticeCenterButtonState();
}

class _PracticeCenterButtonState extends ConsumerState<PracticeCenterButton> {
  bool _isPressed = false;

  void _onTap() {
    HapticFeedback.mediumImpact();
    // Open modal with Metronome tab (index 0).
    unawaited(_openPracticeModal(0));
  }

  void _onLongPress() {
    HapticFeedback.heavyImpact();
    // Open modal with Tuner tab (index 1).
    unawaited(_openPracticeModal(1));
  }

  /// 모달을 열고, 연습 minutes 가 기록되면 heatmap/streak provider 를 무효화해
  /// 대시보드가 stale 되지 않게 한다 (practice_start_section 과 동일 — A4).
  /// studentId 전달 — stop 시 logMetronome 실행 (#932).
  Future<void> _openPracticeModal(int initialTab) async {
    final studentId = ref.read(currentUserIdProvider);
    final minutes = await PracticeToolsModal.show(
      context,
      initialTab: initialTab,
      studentId: studentId,
    );
    if (!mounted || minutes == null || minutes <= 0) {
      return;
    }
    ref.invalidate(growthHeatmapProvider(studentId));
    ref.invalidate(practiceStreakProvider(studentId));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      onLongPress: _onLongPress,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: AppColors.paperAccentSoft,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
            // ignore: notebook-boxshadow — special nav element exception
            boxShadow: [
              BoxShadow(
                color: AppColors.paperAccent.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: SvgPicture.string(
              _metronomeIconSvg,
              width: widget.size * 0.55,
              height: widget.size * 0.55,
            ),
          ),
        ),
      ),
    );
  }
}
