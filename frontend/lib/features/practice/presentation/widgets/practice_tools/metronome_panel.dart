import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../features/practice/domain/entities/metronome_settings.dart';
import '../../../../../features/practice/presentation/providers/metronome_provider.dart';
import '../metronome/cat_beat_indicator.dart';
import '../metronome/subdivision_picker.dart';
import '../metronome/time_signature_picker.dart';
import 'bpm_controls.dart';

/// Metronome panel content with tap tempo support.
class MetronomePanel extends ConsumerStatefulWidget {
  const MetronomePanel({super.key});

  @override
  ConsumerState<MetronomePanel> createState() => _MetronomePanelState();
}

class _MetronomePanelState extends ConsumerState<MetronomePanel>
    with SingleTickerProviderStateMixin {
  /// Tap timestamps for calculating tempo (last 4 taps).
  final List<int> _tapTimestamps = [];

  /// Maximum number of taps to track.
  static const int _maxTaps = 4;

  /// Timeout in ms - reset taps if no tap for this duration.
  static const int _tapTimeout = 2000;

  /// Animation controller for tap scale effect.
  late AnimationController _tapAnimationController;

  /// Scale animation.
  late Animation<double> _scaleAnimation;

  /// Whether cat is currently showing smile (after tap).
  bool _isSmiling = false;

  /// Whether speech bubble is temporarily hidden after "좋다냥".
  bool _isBubbleHidden = false;

  /// Timer for auto-start (can be cancelled if user keeps tapping).
  Timer? _autoStartTimer;

  /// Whether tempo explanation bubble is showing.
  bool _showTempoExplanation = false;

  /// Timer for hiding tempo explanation after 3 seconds.
  Timer? _tempoExplanationTimer;

  @override
  void initState() {
    super.initState();
    _tapAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.9), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 60),
    ]).animate(
      CurvedAnimation(parent: _tapAnimationController, curve: Curves.easeOut),
    );

    _tapAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Reset smile after animation completes
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() => _isSmiling = false);
          }
        });
      }
    });
  }

  /// Get tempo marking name based on BPM (Italian/English).
  String _getTempoMarking(int bpm) {
    if (bpm < 40) return 'Grave';
    if (bpm < 60) return 'Largo';
    if (bpm < 66) return 'Larghetto';
    if (bpm < 76) return 'Adagio';
    if (bpm < 108) return 'Andante';
    if (bpm < 120) return 'Moderato';
    if (bpm < 132) return 'Allegretto';
    if (bpm < 168) return 'Allegro';
    if (bpm < 176) return 'Vivace';
    if (bpm < 200) return 'Presto';
    return 'Prestissimo';
  }

  /// Get tempo explanation in Korean (transliteration + meaning).
  /// Returns a tuple: (한글 음역, 한글 의미)
  (String, String) _getTempoExplanation(int bpm) {
    if (bpm < 40) return ('그라베', '매우 느리고 장중하게');
    if (bpm < 60) return ('라르고', '느리고 폭넓게');
    if (bpm < 66) return ('라르게토', '조금 느리게');
    if (bpm < 76) return ('아다지오', '천천히 여유있게');
    if (bpm < 108) return ('안단테', '걷는 빠르기로');
    if (bpm < 120) return ('모데라토', '보통 빠르기로');
    if (bpm < 132) return ('알레그레토', '조금 빠르게');
    if (bpm < 168) return ('알레그로', '빠르고 경쾌하게');
    if (bpm < 176) return ('비바체', '활발하고 생기있게');
    if (bpm < 200) return ('프레스토', '매우 빠르게');
    return ('프레스티시모', '가장 빠르게');
  }

  /// Handle tap on tempo marking to show explanation.
  void _onTempoMarkingTap() {
    _tempoExplanationTimer?.cancel();
    setState(() {
      _showTempoExplanation = true;
      _isBubbleHidden = false; // Show bubble if it was hidden after playback
    });

    _tempoExplanationTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showTempoExplanation = false);
      }
    });
  }

  @override
  void dispose() {
    _tapAnimationController.dispose();
    _autoStartTimer?.cancel();
    _tempoExplanationTimer?.cancel();
    super.dispose();
  }

  /// Handle tap on cat for tap tempo.
  void _onCatTap() {
    final state = ref.read(metronomeProvider);

    // Only work when metronome is stopped
    if (state.isPlaying) return;

    // Cancel any pending auto-start (user is still tapping)
    _autoStartTimer?.cancel();
    _autoStartTimer = null;

    final now = DateTime.now().millisecondsSinceEpoch;

    // Show bubble immediately on tap
    if (_isBubbleHidden) {
      setState(() => _isBubbleHidden = false);
    }

    // Clear old taps if timeout
    if (_tapTimestamps.isNotEmpty && now - _tapTimestamps.last > _tapTimeout) {
      _tapTimestamps.clear();
    }

    _tapTimestamps.add(now);

    // Keep only last N taps
    if (_tapTimestamps.length > _maxTaps) {
      _tapTimestamps.removeAt(0);
    }

    // Animate, smile, and play sound
    setState(() => _isSmiling = true);
    _tapAnimationController.forward(from: 0);
    ref.read(metronomeProvider.notifier).playTapSound();

    // Calculate BPM if we have at least 2 taps
    if (_tapTimestamps.length >= 2) {
      final intervals = <int>[];
      for (int i = 1; i < _tapTimestamps.length; i++) {
        intervals.add(_tapTimestamps[i] - _tapTimestamps[i - 1]);
      }
      final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
      final bpm = (60000 / avgInterval).round();

      // Apply BPM (will be clamped in the provider)
      ref.read(metronomeProvider.notifier).setBpm(bpm);

      // After "좋다냥": auto-start metronome after 1.5s (cancellable)
      if (_tapTimestamps.length >= _maxTaps) {
        // Cancel any existing timer
        _autoStartTimer?.cancel();

        // Auto-start metronome after 1.5 seconds (can be cancelled by more taps)
        _autoStartTimer = Timer(const Duration(milliseconds: 1500), () {
          if (mounted) {
            // Start metronome automatically
            ref.read(metronomeProvider.notifier).start();

            setState(() {
              _isBubbleHidden = true;
              _tapTimestamps.clear();
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(metronomeProvider);

    // When not playing: eyes open (neutral), unless just tapped (smiling)
    // When playing: use the beat-based logic from CatBeatIndicator
    final showSmilingOverride = !state.isPlaying && _isSmiling;

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.space6),
      child: Column(
        children: [
          // Cat beat indicator with tap gesture and speech bubble
          SizedBox(
            height: 210, // Fixed height for cat + bubble area + paws
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Cat indicator
                GestureDetector(
                  onTap: _onCatTap,
                  child: AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: state.isPlaying ? 1.0 : _scaleAnimation.value,
                        child: child,
                      );
                    },
                    child: CatBeatIndicator(
                      currentBeat: state.currentBeat,
                      timeSignature: state.settings.timeSignature,
                      isPlaying: state.isPlaying,
                      accentPattern: state.settings.accentPattern,
                      bpm: state.settings.bpm,
                      size: 120, // Reduced from 140 to make room for bubble
                      forceSmile: showSmilingOverride,
                    ),
                  ),
                ),
                // Speech bubble (top left of cat)
                // Shows audio error, tempo explanation, or tap tempo message
                if (state.hasAudioError ||
                    (!state.isPlaying && !_isBubbleHidden))
                  Positioned(
                    left: 10,
                    top: 0,
                    child: TapTempoSpeechBubble(
                      tapCount: _tapTimestamps.length,
                      tempoExplanation:
                          _showTempoExplanation
                              ? _getTempoExplanation(state.settings.bpm)
                              : null,
                      audioError: state.audioError,
                    ),
                  ),
                // BPM display with tempo marking (bottom right of cat) - always visible
                Positioned(
                  right: 10,
                  bottom: 40,
                  child: GestureDetector(
                    onTap: _onTempoMarkingTap,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getTempoMarking(state.settings.bpm),
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.inkSecondary,
                          ),
                        ),
                        Text(
                          '${state.settings.bpm}',
                          style: AppTypography.displayLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.paperAccent,
                            fontSize: 40,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 44),

          // BPM controls with logarithmic slider
          LogarithmicBpmSlider(
            bpm: state.settings.bpm,
            onChanged: (value) {
              ref.read(metronomeProvider.notifier).setBpm(value);
              _onTempoMarkingTap(); // Show tempo explanation
            },
            onIncrement: (delta) {
              ref.read(metronomeProvider.notifier).incrementBpm(delta);
              _onTempoMarkingTap(); // Show tempo explanation
            },
          ),
          SizedBox(height: AppSpacing.space8),

          // Play/Pause button
          SizedBox(
            width: 80,
            height: 80,
            child: OutlinedButton(
              onPressed: () => ref.read(metronomeProvider.notifier).toggle(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.paperAccent,
                side: const BorderSide(color: AppColors.paperAccent, width: 3),
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
              ),
              child:
                  state.isPlaying && state.currentBeat > 0
                      ? Text(
                        '${state.currentBeat}',
                        style: AppTypography.displayLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.paperAccent,
                          fontSize: 36,
                        ),
                      )
                      : Icon(
                        state.isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 48,
                        color: AppColors.paperAccent,
                      ),
            ),
          ),
          SizedBox(height: AppSpacing.space8),

          // Time signature selector (tap to open picker)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '박자표',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpacing.space2),
              GestureDetector(
                onTap: () async {
                  final result = await TimeSignaturePicker.show(
                    context,
                    state.settings.timeSignature,
                  );
                  if (result != null) {
                    ref
                        .read(metronomeProvider.notifier)
                        .setTimeSignature(result);
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.space4,
                    vertical: AppSpacing.space3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    border: Border.all(color: AppColors.inkQuaternary),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildTimeSignatureDisplay(
                            state.settings.timeSignature,
                          ),
                          SizedBox(width: AppSpacing.space3),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.settings.timeSignature.isCompound
                                    ? '복합 박자'
                                    : '단순 박자',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.inkSecondary,
                                ),
                              ),
                              if (state.settings.timeSignature.isCompound)
                                Text(
                                  '큰박 ${state.settings.timeSignature.mainBeats}개',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.paperAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.inkSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.space6),

          // Subdivision selector (tap to open picker)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '서브디비전',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpacing.space2),
              GestureDetector(
                onTap: () async {
                  final result = await SubdivisionPicker.show(
                    context,
                    state.settings.subdivision,
                  );
                  if (result != null) {
                    ref.read(metronomeProvider.notifier).setSubdivision(result);
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.space4,
                    vertical: AppSpacing.space3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    border: Border.all(color: AppColors.inkQuaternary),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // Note symbol
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.paperAccentSoft,
                            ),
                            child: Center(
                              child: Text(
                                state.settings.subdivision.noteSymbol,
                                style: AppTypography.headingLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.paperAccent,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: AppSpacing.space3),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.settings.subdivision.label,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '패턴: ${state.settings.subdivision.visualPattern}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.inkSecondary,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.inkSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.space6),

          // Accent pattern selector
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '첫박 강조',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Switch(
                    value:
                        state.settings.accentPattern ==
                        AccentPattern.firstBeatOnly,
                    onChanged: (value) {
                      ref
                          .read(metronomeProvider.notifier)
                          .setAccentPattern(
                            value
                                ? AccentPattern.firstBeatOnly
                                : AccentPattern.uniform,
                          );
                    },
                    activeThumbColor: AppColors.paperAccent,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: AppSpacing.space8),
        ],
      ),
    );
  }

  /// Build time signature display widget (stacked numerator/denominator).
  Widget _buildTimeSignatureDisplay(TimeSignature ts) {
    final parts = ts.label.split('/');
    final numerator = parts[0];
    final denominator = parts[1];

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: AppColors.paperAccentSoft),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            numerator,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.paperAccent,
              height: 1.0,
            ),
          ),
          Container(width: 20, height: 1.5, color: AppColors.paperAccent),
          Text(
            denominator,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.paperAccent,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Speech bubble for tap tempo hint (cat language style).
/// Also used for tempo explanation when tempoExplanation is provided.
class TapTempoSpeechBubble extends StatelessWidget {
  const TapTempoSpeechBubble({
    super.key,
    required this.tapCount,
    this.tempoExplanation,
    this.audioError,
  });

  final int tapCount;

  /// If provided, shows tempo explanation instead of tap tempo message.
  /// Format: (한글 음역, 한글 의미)
  final (String, String)? tempoExplanation;

  /// If provided, shows audio error message (highest priority).
  final String? audioError;

  @override
  Widget build(BuildContext context) {
    final String message;
    final Color backgroundColor;
    final Color textColor;

    // Audio error has highest priority
    if (audioError != null) {
      message = '통화중이냥~';
      backgroundColor = AppColors.paperAccentSoft;
      textColor = AppColors.paperAccent;
    }
    // If tempo explanation is provided, show it (success style)
    else if (tempoExplanation != null) {
      final (koreanName, koreanMeaning) = tempoExplanation!;
      message = '$koreanName\n($koreanMeaning)';
      backgroundColor = AppColors.bubbleSuccessBackground;
      textColor = AppColors.bubbleSuccessText;
    } else if (tapCount == 0) {
      // Idle state - same as tuner "소리 감지 대기..."
      message = '탭하라냥~';
      backgroundColor = AppColors.bubbleIdleBackground;
      textColor = AppColors.bubbleIdleText;
    } else if (tapCount < 4) {
      // Progress state - warning style
      message = '${4 - tapCount}번 더냥~';
      backgroundColor = AppColors.bubbleWarningBackground;
      textColor = AppColors.bubbleWarningText;
    } else {
      // Success state
      message = '좋다냥! 🎵';
      backgroundColor = AppColors.bubbleSuccessBackground;
      textColor = AppColors.bubbleSuccessText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
