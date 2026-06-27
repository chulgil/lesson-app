import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';

/// 3-2-1 count-in overlay shown above the YouTube canvas.
///
/// Spec: docs/specs/practice/youtube_loop_practice_spec.md §4.4
/// Tokens: Playfair Display 60-72pt w700, paperAccent, paper 60% opacity.
///
/// On mount the overlay starts a 3-2-1 sequence (1 sec per number). When the
/// sequence finishes it calls [onCompleted]. While each digit shows,
/// [onTick] fires once (callers use this to trigger a metronome click).
class CountInOverlay extends StatefulWidget {
  /// How many beats to count down (default 3).
  final int beats;

  /// Per-beat duration in milliseconds. Default 1000.
  final int beatDurationMs;

  /// Fires once per visible digit (use to play a metronome click).
  final void Function(int currentBeat)? onTick;

  /// Fires when the entire countdown finishes.
  final VoidCallback onCompleted;

  const CountInOverlay({
    super.key,
    this.beats = 3,
    this.beatDurationMs = 1000,
    this.onTick,
    required this.onCompleted,
  });

  @override
  State<CountInOverlay> createState() => _CountInOverlayState();
}

class _CountInOverlayState extends State<CountInOverlay> {
  late int _current; // counts down from widget.beats to 0
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _current = widget.beats;
    // First tick fires immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onTick?.call(_current);
    });
    _timer = Timer.periodic(Duration(milliseconds: widget.beatDurationMs), (_) {
      if (!mounted) return;
      setState(() {
        _current -= 1;
      });
      if (_current <= 0) {
        _timer?.cancel();
        widget.onCompleted();
      } else {
        widget.onTick?.call(_current);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_current <= 0) return const SizedBox.shrink();
    return Center(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.paper.withValues(alpha: 0.60), // paper 60% opacity
            borderRadius: BorderRadius.zero,
          ),
          child: Text(
            '$_current',
            style: GoogleFonts.playfairDisplay(
              fontSize: 72,
              fontWeight: FontWeight.w700,
              color: AppColors.paperAccent,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
