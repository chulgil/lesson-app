import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../features/practice/presentation/widgets/practice_tools_modal.dart';
import '../theme/app_colors.dart';

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
/// - Tap: Open practice tools modal with Tuner tab
/// - Long press: Open practice tools modal with Metronome tab
/// - Pixel art style icon (tuning fork + metronome)
class PracticeCenterButton extends StatefulWidget {
  const PracticeCenterButton({
    super.key,
    this.size = 56,
  });

  /// Button size (width and height).
  final double size;

  @override
  State<PracticeCenterButton> createState() => _PracticeCenterButtonState();
}

class _PracticeCenterButtonState extends State<PracticeCenterButton> {
  bool _isPressed = false;

  void _onTap() {
    HapticFeedback.mediumImpact();
    // Open modal with Metronome tab (index 0)
    PracticeToolsModal.show(context, initialTab: 0);
  }

  void _onLongPress() {
    HapticFeedback.heavyImpact();
    // Open modal with Tuner tab (index 1)
    PracticeToolsModal.show(context, initialTab: 1);
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
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
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
