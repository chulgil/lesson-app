import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/metronome_settings.dart';
import '../../../../providers/metronome/metronome_provider.dart';
import '../../domain/entities/tuner_settings.dart';
import '../../domain/entities/tuner_types.dart';
import '../providers/tuner_provider.dart';
import 'metronome/cat_beat_indicator.dart';
import 'tuner/circular_tuner_indicator.dart';
import 'tuner/clef_svgs.dart';
import 'tuner/tuner_cat_indicator.dart';
import 'tuner/tuner_settings_sheet.dart';

/// Practice tools modal with tab-based navigation between Metronome and Tuner.
class PracticeToolsModal extends ConsumerStatefulWidget {
  const PracticeToolsModal({super.key, this.initialTab = 0});

  /// Initial tab index (0 = Metronome, 1 = Tuner)
  final int initialTab;

  static Future<void> show(BuildContext context, {int initialTab = 0}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PracticeToolsModal(initialTab: initialTab),
    );
  }

  @override
  ConsumerState<PracticeToolsModal> createState() => _PracticeToolsModalState();
}

class _PracticeToolsModalState extends ConsumerState<PracticeToolsModal>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );

    // Listen for tab changes to manage tuner microphone
    _tabController.addListener(_onTabChanged);

    // Pre-warm both metronome and tuner engines
    Future.microtask(() {
      ref.read(metronomeProvider.notifier).warmUp();

      // Warm up tuner (starts microphone stream without processing)
      // This is done once when modal opens, so tab switching is instant
      ref.read(tunerProvider.notifier).warmUp().then((_) {
        if (!mounted) return;

        // If starting on tuner tab, enable processing after warm-up
        if (widget.initialTab == 1) {
          ref.read(tunerProvider.notifier).enableProcessing();
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    // Stop tuner completely when modal closes (including stream)
    ref.read(tunerProvider.notifier).stopCompletely();
    super.dispose();
  }

  /// Handle tab changes - toggle tuner processing (instant, no blocking)
  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;

    final tuner = ref.read(tunerProvider.notifier);
    if (_tabController.index == 1) {
      // Switching TO tuner tab - enable processing (instant!)
      // Stream is already active from warmUp, so no blocking occurs
      tuner.enableProcessing();
    } else {
      // Switching AWAY from tuner tab - disable processing
      // Stream stays active for instant re-enabling
      tuner.disableProcessing();
    }
  }

  /// Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final tuner = ref.read(tunerProvider.notifier);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // App going to background - stop tuner (not recording)
        tuner.onAppPaused();
        break;
      case AppLifecycleState.resumed:
        // App returning - only resume if on tuner tab
        if (_tabController.index == 1) {
          tuner.onAppResumed();
        }
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: AppSpacing.space2),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with tabs
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.space2,
              vertical: AppSpacing.space3,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  padding: EdgeInsets.zero,
                ),
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondaryLight,
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3,
                    labelPadding: EdgeInsets.zero,
                    labelStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                    ),
                    tabs: const [
                      Tab(text: '메트로놈'),
                      Tab(text: '튜너'),
                    ],
                  ),
                ),
                // Settings button for tuner
                AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, child) {
                    return _tabController.index == 1
                        ? IconButton(
                            icon: const Icon(Icons.settings_outlined),
                            onPressed: () => TunerSettingsSheet.show(context),
                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                            padding: EdgeInsets.zero,
                          )
                        : const SizedBox(width: 40);
                  },
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                _MetronomePanel(),
                _TunerPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Metronome panel content with tap tempo support.
class _MetronomePanel extends ConsumerStatefulWidget {
  const _MetronomePanel();

  @override
  ConsumerState<_MetronomePanel> createState() => _MetronomePanelState();
}

class _MetronomePanelState extends ConsumerState<_MetronomePanel>
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
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.9),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.9, end: 1.0),
        weight: 60,
      ),
    ]).animate(CurvedAnimation(
      parent: _tapAnimationController,
      curve: Curves.easeOut,
    ));

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
                // Shows tempo explanation when tapped, otherwise tap tempo message
                if (!state.isPlaying && !_isBubbleHidden)
                  Positioned(
                    left: 10,
                    top: 0,
                    child: _TapTempoSpeechBubble(
                      tapCount: _tapTimestamps.length,
                      tempoExplanation: _showTempoExplanation
                          ? _getTempoExplanation(state.settings.bpm)
                          : null,
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
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        Text(
                          '${state.settings.bpm}',
                          style: AppTypography.displayLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
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
          _LogarithmicBpmSlider(
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
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 3),
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
              ),
              child: state.isPlaying && state.currentBeat > 0
                  ? Text(
                      '${state.currentBeat}',
                      style: AppTypography.displayLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 36,
                      ),
                    )
                  : Icon(
                      state.isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 48,
                      color: AppColors.primary,
                    ),
            ),
          ),
          SizedBox(height: AppSpacing.space8),

          // Time signature selector
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
              Row(
                children: TimeSignature.values.map((ts) {
                  final isSelected = ts == state.settings.timeSignature;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(ts.label),
                        selected: isSelected,
                        onSelected: (_) =>
                            ref.read(metronomeProvider.notifier).setTimeSignature(ts),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimaryLight,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.space6),

          // Subdivision selector
          _SubdivisionSelector(
            selected: state.settings.subdivision,
            onChanged: (sub) =>
                ref.read(metronomeProvider.notifier).setSubdivision(sub),
          ),
          SizedBox(height: AppSpacing.space6),

          // Accent pattern selector
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '박자 패턴',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpacing.space2),
              Wrap(
                spacing: AppSpacing.space2,
                runSpacing: AppSpacing.space2,
                children: AccentPattern.values.map((pattern) {
                  final isSelected = pattern == state.settings.accentPattern;
                  return ChoiceChip(
                    label: Text(pattern.label),
                    selected: isSelected,
                    onSelected: (_) =>
                        ref.read(metronomeProvider.notifier).setAccentPattern(pattern),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimaryLight,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: AppSpacing.space1),
              Text(
                state.settings.accentPattern.description,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.space8),
        ],
      ),
    );
  }
}

/// Speech bubble for tap tempo hint (cat language style).
/// Also used for tempo explanation when tempoExplanation is provided.
class _TapTempoSpeechBubble extends StatelessWidget {
  const _TapTempoSpeechBubble({
    required this.tapCount,
    this.tempoExplanation,
  });

  final int tapCount;
  /// If provided, shows tempo explanation instead of tap tempo message.
  /// Format: (한글 음역, 한글 의미)
  final (String, String)? tempoExplanation;

  @override
  Widget build(BuildContext context) {
    final String message;
    final Color backgroundColor;
    final Color textColor;

    // If tempo explanation is provided, show it (success style)
    if (tempoExplanation != null) {
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
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
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // Soft ivory text color (not pure white, easier on eyes)
    const softIvory = Color(0xFFFFFAF0);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: softIvory,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hybrid BPM slider: 10-200 linear (75%), 200-400 compressed (25%).
/// Includes +1/-1 buttons for fine-tuning.
class _LogarithmicBpmSlider extends StatelessWidget {
  const _LogarithmicBpmSlider({
    required this.bpm,
    required this.onChanged,
    required this.onIncrement,
  });

  final int bpm;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onIncrement;

  static const double _minBpm = 30;
  static const double _midBpm = 120; // Transition point
  static const double _maxBpm = 208;
  static const double _midPosition = 0.6; // 120 BPM at 60% of slider

  /// Convert BPM to slider position (0-1) using hybrid scale.
  /// 10-200: linear in 0-0.75 range
  /// 200-400: compressed in 0.75-1.0 range
  double _bpmToSlider(int bpm) {
    final clampedBpm = bpm.clamp(_minBpm.toInt(), _maxBpm.toInt()).toDouble();

    if (clampedBpm <= _midBpm) {
      // Linear: 10-200 maps to 0-0.75
      return ((clampedBpm - _minBpm) / (_midBpm - _minBpm) * _midPosition)
          .clamp(0.0, _midPosition);
    } else {
      // Compressed: 200-400 maps to 0.75-1.0
      return (_midPosition +
              (clampedBpm - _midBpm) /
                  (_maxBpm - _midBpm) *
                  (1.0 - _midPosition))
          .clamp(_midPosition, 1.0);
    }
  }

  /// Convert slider position (0-1) to BPM using hybrid scale.
  int _sliderToBpm(double position) {
    if (position <= _midPosition) {
      // Linear: 0-0.75 maps to 10-200
      final bpm = _minBpm + (position / _midPosition) * (_midBpm - _minBpm);
      return bpm.round().clamp(_minBpm.toInt(), _midBpm.toInt());
    } else {
      // Compressed: 0.75-1.0 maps to 200-400
      final bpm = _midBpm +
          ((position - _midPosition) / (1.0 - _midPosition)) *
              (_maxBpm - _midBpm);
      return bpm.round().clamp(_midBpm.toInt(), _maxBpm.toInt());
    }
  }

  /// Get color based on BPM intensity (darker = faster).
  Color _getSliderColor(int bpm) {
    final intensity = ((bpm - _minBpm) / (_maxBpm - _minBpm)).clamp(0.0, 1.0);
    return Color.lerp(
      AppColors.primaryLight,
      AppColors.primary,
      intensity,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    final sliderColor = _getSliderColor(bpm);

    return Column(
      children: [
        // Main slider with +5/-5 buttons
        Row(
          children: [
            _CircleButton(
              label: '-5',
              onPressed: () => onIncrement(-5),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: sliderColor,
                  inactiveTrackColor:
                      AppColors.primaryLight.withValues(alpha: 0.3),
                  thumbColor: sliderColor,
                  overlayColor: sliderColor.withValues(alpha: 0.2),
                  trackHeight: 6,
                ),
                child: Slider(
                  value: _bpmToSlider(bpm),
                  min: 0,
                  max: 1,
                  onChanged: (value) => onChanged(_sliderToBpm(value)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _CircleButton(
              label: '+5',
              onPressed: () => onIncrement(5),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Fine-tuning +1/-1 buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SmallButton(
              label: '-1',
              onPressed: () => onIncrement(-1),
            ),
            const SizedBox(width: 16),
            _SmallButton(
              label: '+1',
              onPressed: () => onIncrement(1),
            ),
          ],
        ),
      ],
    );
  }
}

/// Small button for fine BPM adjustment.
class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 32,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Tuner panel content.
class _TunerPanel extends ConsumerStatefulWidget {
  const _TunerPanel();

  @override
  ConsumerState<_TunerPanel> createState() => _TunerPanelState();
}

class _TunerPanelState extends ConsumerState<_TunerPanel> {
  // Note: Tuner start/stop is now managed by PracticeToolsModal
  // to properly handle tab changes and app lifecycle

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main tuner area - responsive to screen size
        Expanded(
          child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;
                final availableHeight = constraints.maxHeight;

                // Use the smaller dimension with padding
                final availableSize = (availableWidth < availableHeight
                    ? availableWidth
                    : availableHeight) - 32; // 16px padding each side

                // Circle size fills available space (indicators are inside)
                final circleSize = availableSize * 1.1; // 110% for circle (bigger for font 72)
                final catSize = circleSize * 0.40; // Cat is 40% of circle (smaller)

                return Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    // Circle with cat (positioned 0px from top)
                    Positioned(
                      top: 0,
                      child: CircularTunerIndicator(
                        size: circleSize,
                        centerChild: TunerCatIndicator(
                          size: catSize,
                          showNote: false, // Don't show note inside cat
                          showSpeechBubble: true, // Show speech bubble next to cat
                        ),
                      ),
                    ),
                    // Current note display (below circle, moved up more)
                    Positioned(
                      top: circleSize - circleSize * 0.15 - 100,
                      child: _CurrentNoteDisplay(scale: (circleSize / 280) / 1.1), // 1.1x smaller
                    ),
                  ],
                );
              },
            ),
        ),

        SizedBox(height: AppSpacing.space4),

        // Bottom controls: Staff (left) + Info bar (right) - 1.5x bigger, at bottom
        Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.space4,
            right: AppSpacing.space4,
            bottom: AppSpacing.space6,
          ),
          child: Transform.translate(
            offset: const Offset(0, -20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Staff display (1.24x size)
                const _TunerStaff(width: 132, height: 99),
                // Info bar (1.24x size)
                Transform.scale(
                  scale: 1.24,
                  child: const TunerInfoBar(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Current note display widget (fixed position outside circle).
class _CurrentNoteDisplay extends ConsumerWidget {
  const _CurrentNoteDisplay({this.scale = 1.0});

  final double scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tunerState = ref.watch(tunerProvider);
    final currentNote = tunerState.currentNote;
    final isPerfect = tunerState.isPerfect;

    // Apply 1.1x size reduction and scale
    final adjustedScale = scale / 1.1;

    // Base font sizes (will be scaled)
    final noteFontSize = 72 * adjustedScale;
    final octaveFontSize = 42 * adjustedScale;

    if (currentNote == null) {
      // No note detected - show nothing (removed arrows)
      return const SizedBox.shrink();
    }

    // Green when perfect, primary color otherwise (80% opacity)
    final noteColor = isPerfect
        ? Colors.green.withValues(alpha: 0.9)
        : AppColors.primary.withValues(alpha: 0.8);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        // Note name
        Text(
          currentNote.name.sharpName,
          style: TextStyle(
            fontSize: noteFontSize,
            fontWeight: FontWeight.bold,
            color: noteColor,
          ),
        ),
        // Octave
        Text(
          '${currentNote.octave}',
          style: TextStyle(
            fontSize: octaveFontSize,
            fontWeight: FontWeight.w600,
            color: noteColor.withValues(alpha: 0.7),
          ),
        ),
        // Cent display removed - shown in TunerInfoBar below
      ],
    );
  }
}

/// Musical staff with note display for tuner.
/// Shows the current note on a 5-line staff when pitch is within beginner threshold.
/// Uses SVG for accurate clef rendering.
class _TunerStaff extends ConsumerWidget {
  const _TunerStaff({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tunerState = ref.watch(tunerProvider);
    final currentNote = tunerState.currentNote;
    final clefType = tunerState.settings.clefType;
    final autoSwitchClef = tunerState.settings.autoSwitchClef;

    // Use beginner-level threshold (±20 cents) for staff display
    final isWithinBeginnerThreshold = currentNote != null &&
        currentNote.centDeviation.abs() <= TunerDifficulty.beginner.perfectCent;

    final displayNote = isWithinBeginnerThreshold ? currentNote : null;

    // Determine effective clef (auto-switch only if enabled in settings)
    final effectiveClef = displayNote != null
        ? _getEffectiveClef(displayNote, clefType, autoSwitchClef)
        : clefType;

    // Get SVG for the clef
    final clefSvg = switch (effectiveClef) {
      ClefType.treble => trebleClefSvg,
      ClefType.bass => bassClefSvg,
      ClefType.alto => altoClefSvg,
    };

    // Calculate proportions
    final lineSpacing = height / 6;

    // Clef-specific height (treble clef needs to be 1.5x bigger)
    final clefHeight = switch (effectiveClef) {
      ClefType.treble => height * 0.85 * 1.5,
      ClefType.bass => height * 0.85,
      ClefType.alto => height * 0.85,
    };

    // Clef-specific left offset (treble clef needs to be more to the left)
    final clefLeftOffset = switch (effectiveClef) {
      ClefType.treble => -30.0,
      ClefType.bass => 2.0,
      ClefType.alto => 2.0,
    };

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Layer 1: Staff lines
          CustomPaint(
            size: Size(width, height),
            painter: _StaffLinesPainter(),
          ),

          // Layer 2: Clef SVG (only set height, let width auto-calculate to preserve aspect ratio)
          Positioned(
            left: clefLeftOffset,
            top: (height - clefHeight) / 2,
            child: SvgPicture.string(
              clefSvg,
              height: clefHeight,
              colorFilter: ColorFilter.mode(
                Colors.grey[600]!,
                BlendMode.srcIn,
              ),
            ),
          ),

          // Layer 3: Note
          if (displayNote != null)
            CustomPaint(
              size: Size(width, height),
              painter: _NotePainter(
                note: displayNote,
                effectiveClef: effectiveClef,
                lineSpacing: lineSpacing,
              ),
            ),
        ],
      ),
    );
  }

  /// Get effective clef for displaying a note.
  /// Automatically switches to bass clef for low notes (C3 and below in treble)
  /// to avoid notes going too far below the staff.
  ClefType _getEffectiveClef(TunerNote note, ClefType preferredClef, bool autoSwitch) {
    final naturalName = note.name.sharpName.replaceAll('#', '');
    final noteKey = '$naturalName${note.octave}';

    // Always auto-switch for very low/high notes to keep them on staff
    // For treble clef: switch to bass for notes below E3
    if (preferredClef == ClefType.treble && note.octave <= 3) {
      if (note.octave < 3 || (note.octave == 3 && 'CDEF'.contains(naturalName))) {
        return ClefType.bass;
      }
    }

    // For bass clef: switch to treble for notes above A3
    if (preferredClef == ClefType.bass && note.octave >= 4) {
      return ClefType.treble;
    }

    // If auto-switch is disabled, use preferred clef for mid-range notes
    if (!autoSwitch) {
      return preferredClef;
    }

    // Auto-switch mode: check if note is in preferred clef range first
    final preferredPositions = _getPositionsForClef(preferredClef);
    if (preferredPositions.containsKey(noteKey)) {
      return preferredClef;
    }

    // Try other clefs if note is outside preferred clef range
    for (final clef in ClefType.values) {
      if (clef == preferredClef) continue;
      final positions = _getPositionsForClef(clef);
      if (positions.containsKey(noteKey)) {
        return clef;
      }
    }

    return preferredClef; // Fallback
  }

  static Map<String, double> _getPositionsForClef(ClefType clef) {
    switch (clef) {
      case ClefType.treble:
        return {
          'C3': 9.5, 'D3': 9.0, 'E3': 8.5, 'F3': 8.0, 'G3': 7.5, 'A3': 7.0, 'B3': 6.5,
          'C4': 6.0, 'D4': 5.5, 'E4': 5.0, 'F4': 4.5, 'G4': 4.0, 'A4': 3.5, 'B4': 3.0,
          'C5': 2.5, 'D5': 2.0, 'E5': 1.5, 'F5': 1.0, 'G5': 0.5, 'A5': 0.0, 'B5': -0.5,
          'C6': -1.0, 'D6': -1.5, 'E6': -2.0, 'F6': -2.5, 'G6': -3.0, 'A6': -3.5, 'B6': -4.0,
        };
      case ClefType.bass:
        // Bass clef: G2 on line 1 (bottom=5.0), D3 on line 3 (middle=3.0), A3 on line 5 (top=1.0)
        return {
          'E1': 9.5, 'F1': 9.0, 'G1': 8.5, 'A1': 8.0, 'B1': 7.5,
          'C2': 7.0, 'D2': 6.5, 'E2': 6.0, 'F2': 5.5, 'G2': 5.0, 'A2': 4.5, 'B2': 4.0,
          'C3': 3.5, 'D3': 3.0, 'E3': 2.5, 'F3': 2.0, 'G3': 1.5, 'A3': 1.0, 'B3': 0.5,
          'C4': 0.0, 'D4': -0.5, 'E4': -1.0, 'F4': -1.5, 'G4': -2.0, 'A4': -2.5, 'B4': -3.0,
        };
      case ClefType.alto:
        // Alto clef: F3 on line 1 (bottom), C4 on line 3 (middle), G4 on line 5 (top)
        return {
          'C2': 10.0, 'D2': 9.5, 'E2': 9.0, 'F2': 8.5, 'G2': 8.0, 'A2': 7.5, 'B2': 7.0,
          'C3': 6.5, 'D3': 6.0, 'E3': 5.5, 'F3': 5.0, 'G3': 4.5, 'A3': 4.0, 'B3': 3.5,
          'C4': 3.0, 'D4': 2.5, 'E4': 2.0, 'F4': 1.5, 'G4': 1.0, 'A4': 0.5, 'B4': 0.0,
          'C5': -0.5, 'D5': -1.0, 'E5': -1.5, 'F5': -2.0, 'G5': -2.5, 'A5': -3.0, 'B5': -3.5,
        };
    }
  }
}

/// Painter for staff lines only.
class _StaffLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final lineSpacing = size.height / 6;
    final startX = 0.0;
    final endX = size.width;

    for (var i = 1; i <= 5; i++) {
      final y = i * lineSpacing;
      canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter for note only.
class _NotePainter extends CustomPainter {
  _NotePainter({
    required this.note,
    required this.effectiveClef,
    required this.lineSpacing,
  });

  final TunerNote note;
  final ClefType effectiveClef;
  final double lineSpacing;

  /// Calculate position for any note, even if outside predefined range.
  double _getPositionForNote(String naturalName, int octave) {
    final positions = _TunerStaff._getPositionsForClef(effectiveClef);
    final noteKey = '$naturalName$octave';

    // If note is in predefined range, use it directly
    if (positions.containsKey(noteKey)) {
      return positions[noteKey]!;
    }

    // Find a reference note in the same pitch class but different octave
    for (int refOctave = 1; refOctave <= 7; refOctave++) {
      final refKey = '$naturalName$refOctave';
      if (positions.containsKey(refKey)) {
        final refPosition = positions[refKey]!;
        // Each octave is 7 diatonic steps = 3.5 position units
        final octaveDiff = octave - refOctave;
        return refPosition - (octaveDiff * 3.5);
      }
    }

    return 3.0; // Fallback to middle line
  }

  @override
  void paint(Canvas canvas, Size size) {
    final naturalName = note.name.sharpName.replaceAll('#', '');
    final position = _getPositionForNote(naturalName, note.octave);

    final y = position * lineSpacing;
    final x = size.width * 0.7; // Note in right portion
    final noteRadius = lineSpacing * 0.55;

    // Draw note head
    final notePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(-0.3);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: noteRadius * 2.2,
        height: noteRadius * 1.6,
      ),
      notePaint,
    );
    canvas.restore();

    // Draw stem
    final stemPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final stemUp = position >= 3.0;
    final stemLength = lineSpacing * 3.5;

    if (stemUp) {
      final stemX = x + noteRadius * 0.9;
      canvas.drawLine(
        Offset(stemX, y),
        Offset(stemX, y - stemLength),
        stemPaint,
      );
    } else {
      final stemX = x - noteRadius * 0.9;
      canvas.drawLine(
        Offset(stemX, y),
        Offset(stemX, y + stemLength),
        stemPaint,
      );
    }

    // Draw ledger lines if needed
    final ledgerPaint = Paint()
      ..color = Colors.grey[500]!
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final ledgerWidth = noteRadius * 2.5;

    if (position > 5) {
      for (var i = 6.0; i <= position; i += 1.0) {
        final ledgerY = i * lineSpacing;
        canvas.drawLine(
          Offset(x - ledgerWidth, ledgerY),
          Offset(x + ledgerWidth, ledgerY),
          ledgerPaint,
        );
      }
    }

    if (position < 1) {
      for (var i = 0.0; i >= position; i -= 1.0) {
        final ledgerY = i * lineSpacing;
        canvas.drawLine(
          Offset(x - ledgerWidth, ledgerY),
          Offset(x + ledgerWidth, ledgerY),
          ledgerPaint,
        );
      }
    }

    // Draw sharp symbol if accidental
    if (note.name.isAccidental) {
      final accidentalPaint = Paint()
        ..color = AppColors.primary
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      final accidentalX = x - noteRadius * 2.5;
      final accidentalSize = lineSpacing * 0.5;

      // Sharp symbol (#)
      canvas.drawLine(
        Offset(accidentalX - accidentalSize * 0.3, y - accidentalSize),
        Offset(accidentalX - accidentalSize * 0.3, y + accidentalSize),
        accidentalPaint,
      );
      canvas.drawLine(
        Offset(accidentalX + accidentalSize * 0.3, y - accidentalSize),
        Offset(accidentalX + accidentalSize * 0.3, y + accidentalSize),
        accidentalPaint,
      );
      canvas.drawLine(
        Offset(accidentalX - accidentalSize * 0.6, y - accidentalSize * 0.3),
        Offset(accidentalX + accidentalSize * 0.6, y - accidentalSize * 0.5),
        accidentalPaint,
      );
      canvas.drawLine(
        Offset(accidentalX - accidentalSize * 0.6, y + accidentalSize * 0.3),
        Offset(accidentalX + accidentalSize * 0.6, y + accidentalSize * 0.1),
        accidentalPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NotePainter oldDelegate) {
    return oldDelegate.note != note || oldDelegate.effectiveClef != effectiveClef;
  }
}

/// Subdivision selector for metronome.
class _SubdivisionSelector extends StatelessWidget {
  const _SubdivisionSelector({
    required this.selected,
    required this.onChanged,
  });

  final Subdivision selected;
  final ValueChanged<Subdivision> onChanged;

  @override
  Widget build(BuildContext context) {
    // Show basic subdivisions (quarter, eighth, triplet, sixteenth) in main row
    // Show advanced subdivisions in expandable section
    final basicSubdivisions =
        Subdivision.values.where((s) => s.isBasic).toList();
    final advancedSubdivisions =
        Subdivision.values.where((s) => !s.isBasic).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '서브디비전',
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppSpacing.space2),
        // Basic subdivisions row
        Row(
          children: basicSubdivisions.map((sub) {
            final isSelected = sub == selected;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _SubdivisionChip(
                  subdivision: sub,
                  isSelected: isSelected,
                  onSelected: () => onChanged(sub),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: AppSpacing.space2),
        // Advanced subdivisions (5, 6 연음)
        if (advancedSubdivisions.isNotEmpty) ...[
          Wrap(
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            children: advancedSubdivisions.map((sub) {
              final isSelected = sub == selected;
              return ChoiceChip(
                label: Text(sub.label),
                selected: isSelected,
                onSelected: (_) => onChanged(sub),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimaryLight,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          SizedBox(height: AppSpacing.space2),
        ],
        // Visual pattern display
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space2,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                selected.visualPattern,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              SizedBox(width: AppSpacing.space4),
              Text(
                '(${selected.englishName})',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Subdivision chip widget.
class _SubdivisionChip extends StatelessWidget {
  const _SubdivisionChip({
    required this.subdivision,
    required this.isSelected,
    required this.onSelected,
  });

  final Subdivision subdivision;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.space2,
          vertical: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              subdivision.visualPattern,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : AppColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subdivision.label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.9)
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
