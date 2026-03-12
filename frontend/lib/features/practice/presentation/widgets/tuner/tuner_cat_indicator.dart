import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/tuner_types.dart';
import '../../providers/tuner_combo_provider.dart';
import '../../providers/tuner_provider.dart';
import 'tuner_cat_painters.dart';
import 'tuner_cat_particle.dart';
import 'tuner_cat_widgets.dart';

/// Cat indicator for tuner with expressions and speech bubbles.
class TunerCatIndicator extends ConsumerStatefulWidget {
  const TunerCatIndicator({
    super.key,
    this.size = 120,
    this.showNote = true,
    this.showSpeechBubble = false, // Show speech bubble next to cat
  });

  final double size;
  final bool showNote; // Whether to show current note inside cat area
  final bool showSpeechBubble; // Whether to show speech bubble next to cat face

  @override
  ConsumerState<TunerCatIndicator> createState() => _TunerCatIndicatorState();
}

class _TunerCatIndicatorState extends ConsumerState<TunerCatIndicator>
    with TickerProviderStateMixin {
  late AnimationController _jumpController;
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _jumpAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  // Ticker for smooth particle animation
  Ticker? _particleTicker;
  Duration _lastTickTime = Duration.zero;

  ComboTier _lastTier = ComboTier.none;

  // Perfect duration tracking
  DateTime? _perfectStartTime;
  bool _isScaling = false;
  bool _showParticles = false;

  // Heart particles
  final List<HeartParticle> _particles = [];
  final math.Random _random = math.Random();

  // Animation timing thresholds (in seconds of perfect tuning)
  static const _scaleStartSeconds = 1.0; // Start scale after 1 second of perfect
  static const _particleStartSeconds = 2.0; // Start particles after 2 seconds
  static const _starburstStartSeconds = 6.0; // Start starburst after 6 seconds
  static const _maxScale = 1.25; // 1.04 * 1.2 = 1.248 ≈ 1.25
  static const _maxParticles = 500;

  // Starburst animation
  late AnimationController _starburstController;
  bool _showStarburst = false;
  DateTime? _starburstStartTime;

  // Reverse animation (3 seconds to revert all effects)
  static const _revertDurationSeconds = 3.0;
  bool _isReverting = false;
  DateTime? _revertStartTime;
  double _revertProgress = 0.0; // 0 = just started reverting, 1 = fully reverted

  // Counter for reactivation attempts (compared against difficulty.reactivationChances)
  int _reactivationCount = 0;

  // Ecstasy pulse animation (stronger pulse when particles appear)
  late AnimationController _ecstasyController;
  late Animation<double> _ecstasyAnimation;
  late Animation<double> _ecstasyYAnimation;

  @override
  void initState() {
    super.initState();

    _jumpController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);

    // Scale animation: 1.0 -> 1.5 over 3 seconds
    _scaleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: _maxScale).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );

    _jumpAnimation = Tween<double>(begin: 0, end: -15).animate(
      CurvedAnimation(parent: _jumpController, curve: Curves.easeOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Starburst rotation: one full rotation every 0.7 seconds (3x faster)
    _starburstController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    // Ecstasy bounce: slow bounce from below like floating up with joy
    _ecstasyController = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    );
    // Scale animation: gradually grow from 1.0 to 1.15 and back
    _ecstasyAnimation = TweenSequence<double>([
      // Slowly grow bigger
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 50,
      ),
      // Slowly shrink back
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 50,
      ),
    ]).animate(_ecstasyController);

    // Y translation for floating up effect
    _ecstasyYAnimation = TweenSequence<double>([
      // Float up from below
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -15.0)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 50,
      ),
      // Gentle float back down
      TweenSequenceItem(
        tween: Tween<double>(begin: -15.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 50,
      ),
    ]).animate(_ecstasyController);
  }

  @override
  void dispose() {
    _jumpController.dispose();
    _pulseController.dispose();
    _scaleController.dispose();
    _starburstController.dispose();
    _ecstasyController.dispose();
    _particleTicker?.dispose();
    super.dispose();
  }

  void _startParticleTicker() {
    _particleTicker?.dispose();
    _lastTickTime = Duration.zero;
    _particleTicker = createTicker(_onParticleTick);
    _particleTicker!.start();
  }

  void _stopParticleTicker() {
    _particleTicker?.stop();
    _particleTicker?.dispose();
    _particleTicker = null;
  }

  void _onParticleTick(Duration elapsed) {
    if ((!_showParticles && !_isReverting) || !mounted) {
      _stopParticleTicker();
      return;
    }

    // Calculate delta time for smooth animation
    final deltaMs = (elapsed - _lastTickTime).inMilliseconds;
    _lastTickTime = elapsed;

    // Skip if too long (app was in background)
    if (deltaMs > 100) return;

    final deltaProgress = deltaMs / 1000.0; // Convert to seconds

    // Handle reverting mode
    if (_isReverting) {
      setState(() {
        // Update revert progress
        if (_revertStartTime != null) {
          _revertProgress = DateTime.now()
              .difference(_revertStartTime!)
              .inMilliseconds / (_revertDurationSeconds * 1000);
          _revertProgress = _revertProgress.clamp(0.0, 1.0);
        }

        // Move particles back toward center (reverse direction)
        final revertSpeed = 1.0 / _revertDurationSeconds; // Complete in 3 seconds
        for (final particle in _particles) {
          particle.progress -= deltaProgress * revertSpeed * 1.5; // 1.5x speed to reach center
          particle.rotation -= deltaProgress * 0.1; // Slow reverse rotation
        }

        // Remove particles that reached center
        _particles.removeWhere((p) => p.progress <= 0);

        // Check if revert is complete
        if (_revertProgress >= 1.0 || _particles.isEmpty) {
          _completeRevert();
        }
      });
      return;
    }

    final perfectDuration = _getPerfectDuration();
    final timeSinceStart = perfectDuration - _particleStartSeconds;

    setState(() {
      // Speed increases over time: 0.3 at start, up to 2.1 at 30 seconds
      // Rate: 0.3 → 0.6 → 0.9 → 1.2 → 1.5 → 1.8 → 2.1
      final speedMultiplier = math.min(2.1, 0.3 + timeSinceStart * 0.06);

      // Update existing particles - move outward smoothly
      for (final particle in _particles) {
        particle.progress += deltaProgress * speedMultiplier * particle.speed;
        particle.rotation += deltaProgress * 0.2;
      }

      // Remove dead particles
      _particles.removeWhere((p) => p.isDead);

      // Add new particles - reach 500 by 30 seconds
      // Start with 80% fewer particles (20% of original), increase over time
      if (perfectDuration >= _particleStartSeconds &&
          _particles.length < _maxParticles) {
        // Spawn count: 0 at start, up to 12 at 30 seconds (80% fewer at start)
        final spawnCount = math.min(12, (timeSinceStart * 0.4).toInt());
        for (var i = 0; i < spawnCount; i++) {
          if (_particles.length < _maxParticles && _random.nextDouble() < 0.85) {
            _spawnParticle();
          }
        }
      }
    });
  }

  void _spawnParticle() {
    // Cat center position - Column is centered, cat is at top of Column
    // Approximate cat center: center of widget minus some offset for Column content
    final centerX = widget.size / 2;
    final catSize = widget.size * 0.6;
    // Cat is at top of centered Column, so offset from widget center
    final centerY = widget.size / 2 - catSize * 0.3;
    final center = Offset(centerX, centerY);

    // Cat radius (cat is scaled up to 1.5x)
    final catRadius = widget.size * 0.6 * 0.45 * _scaleAnimation.value;

    // Start from OUTSIDE cat face edge (110% of cat radius)
    // This ensures particles appear behind the semi-transparent cat face
    final startRadius = catRadius * 1.1;

    // Max radius (extends to curtain layer edge)
    final maxRadius = widget.size * 2.0; // Match curtain coverage

    // Random angle for radial direction
    final angle = _random.nextDouble() * math.pi * 2;

    _particles.add(HeartParticle(
      center: center,
      angle: angle,
      baseSize: 28 + _random.nextDouble() * 14, // 28-42px (slightly smaller)
      startRadius: startRadius,
      maxRadius: maxRadius,
      rotation: _random.nextDouble() * math.pi * 2,
      progress: 0.0,
      speed: 0.9 + _random.nextDouble() * 0.3, // 0.9-1.2x speed
    ));
  }

  double _getPerfectDuration() {
    if (_perfectStartTime == null) return 0;
    return DateTime.now().difference(_perfectStartTime!).inMilliseconds / 1000;
  }

  void _onPerfectStateChanged(bool isPerfect, NoteName? currentNoteName, TunerDifficulty difficulty) {
    if (isPerfect && currentNoteName != null) {
      // If we were reverting, check reactivation rules
      if (_isReverting) {
        final maxChances = difficulty.reactivationChances;
        // Check if reactivation chances exhausted
        if (_reactivationCount >= maxChances) {
          // No more chances - block and let revert continue
          return;
        }
        // Still have chances - allow reactivation
        _reactivationCount++;
        _cancelRevert();
      }

      // Note can change (A -> D -> G) - animation continues as long as isPerfect

      // Start tracking perfect duration
      _perfectStartTime ??= DateTime.now();

      final duration = _getPerfectDuration();

      // Start scaling after 2 seconds
      if (duration >= _scaleStartSeconds && !_isScaling) {
        _isScaling = true;
        _scaleController.forward();
      }

      // Start particles after 2 seconds (1 second after scale starts)
      if (duration >= _particleStartSeconds && !_showParticles) {
        _showParticles = true;
        _startParticleTicker();
        // Start ecstasy pulsing animation
        _ecstasyController.repeat();
      }

      // Start starburst after 10 seconds
      if (duration >= _starburstStartSeconds && !_showStarburst) {
        setState(() {
          _showStarburst = true;
          _starburstStartTime = DateTime.now();
        });
        _starburstController.repeat();
      }
    } else {
      // Start reverting animation instead of immediate reset
      if (!_isReverting && (_showParticles || _showStarburst || _isScaling)) {
        _startRevert();
      } else if (!_isReverting) {
        // No animations were active, just reset
        _resetAll();
      }
    }
  }

  /// Start the 3-second reverse animation
  void _startRevert() {
    setState(() {
      _isReverting = true;
      _revertStartTime = DateTime.now();
      _revertProgress = 0.0;
      _showParticles = false; // Stop spawning new particles
      // NOTE: Do NOT reset _hasReactivatedDuringRevert here!
      // Once reactivation is used, it stays used until full reset (_resetAll)
    });

    // Start scale reverse animation (3 seconds)
    _scaleController.animateTo(
      0.0,
      duration: Duration(milliseconds: (_revertDurationSeconds * 1000).toInt()),
      curve: Curves.easeInOutCubic,
    );

    // Keep particle ticker running for reverse animation
    if (_particleTicker == null || !_particleTicker!.isActive) {
      _startParticleTicker();
    }

    // Slow down ecstasy animation
    _ecstasyController.stop();
  }

  /// Cancel revert and resume normal animation
  void _cancelRevert() {
    setState(() {
      _isReverting = false;
      _revertStartTime = null;
      _revertProgress = 0.0;
    });

    // Resume forward animations from current position
    if (_scaleController.value < _maxScale) {
      _scaleController.forward();
    }

    // Resume ecstasy if particles are showing
    if (_particles.isNotEmpty) {
      _showParticles = true;
      _ecstasyController.repeat();
    }

    // Resume starburst if it was showing
    if (_showStarburst && !_starburstController.isAnimating) {
      _starburstController.repeat();
    }
  }

  /// Complete the revert and reset all state
  void _completeRevert() {
    _resetAll();
  }

  /// Reset all animation state
  void _resetAll() {
    setState(() {
      _perfectStartTime = null;
      _isScaling = false;
      _showParticles = false;
      _showStarburst = false;
      _starburstStartTime = null;
      _isReverting = false;
      _revertStartTime = null;
      _revertProgress = 0.0;
      _reactivationCount = 0; // Reset reactivation counter
      _particles.clear();
    });

    _stopParticleTicker();
    _scaleController.reset();
    _starburstController.stop();
    _starburstController.reset();
    _ecstasyController.stop();
    _ecstasyController.reset();
  }

  void _onComboChanged(ComboState comboState) {
    final newTier = comboState.tier;
    final judgement = comboState.lastJudgement;

    // Trigger jump animation on Perfect with combo milestone
    if (judgement == JudgementResult.perfect && newTier != _lastTier) {
      _jumpController.forward().then((_) => _jumpController.reverse());
    }

    _lastTier = newTier;
  }

  @override
  Widget build(BuildContext context) {
    final tunerState = ref.watch(tunerProvider);
    final comboState = ref.watch(tunerComboProvider);

    // Listen for combo changes
    ref.listen(tunerComboProvider, (_, next) => _onComboChanged(next));

    // Listen for perfect state changes
    ref.listen(tunerProvider, (previous, next) {
      final currentNoteName = next.currentNote?.name;
      final difficulty = next.settings.difficulty;
      if (previous?.isPerfect != next.isPerfect) {
        _onPerfectStateChanged(next.isPerfect, currentNoteName, difficulty);
      } else if (next.isPerfect) {
        // Still perfect, check duration thresholds
        _onPerfectStateChanged(true, currentNoteName, difficulty);
      }
    });

    final status = tunerState.status;
    final isPerfect = tunerState.isPerfect;
    final tier = comboState.tier;

    // Calculate sizes based on widget.size
    final catSize = widget.size * 0.6; // Cat takes 60% of space
    final showExtras = widget.size >= 100; // Only show extras if enough space

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        clipBehavior: Clip.none, // Allow speech bubble to overflow
        alignment: Alignment.center,
        children: [
          // Speech bubble above cat head (Layer 0 - behind starburst and hearts)
          if (widget.showSpeechBubble)
            Positioned(
              top: -catSize * 0.3, // Above cat head
              left: 0,
              right: 0,
              child: Center(
                child: CatSpeechBubble(
                  isListening: tunerState.isListening,
                  hasNote: tunerState.currentNote != null,
                  isPerfect: isPerfect,
                  comboTier: tier,
                  scale: (widget.size / 120) * 1.1 / 1.4, // 1.1x size
                  centDeviation: tunerState.centDeviation,
                  errorMessage: tunerState.error,
                ),
              ),
            ),

          // Rotating starburst (behind everything) - grows to cover screen
          if (_showStarburst || (_isReverting && _starburstStartTime != null))
            Positioned.fill(
              child: OverflowBox(
                maxWidth: widget.size * 4,
                maxHeight: widget.size * 4,
                child: AnimatedBuilder(
                  animation: _starburstController,
                  builder: (context, child) {
                    final starburstMs = _starburstStartTime != null
                        ? DateTime.now()
                            .difference(_starburstStartTime!)
                            .inMilliseconds
                        : 0;

                    // Size progress: 0 to 1 over 5 seconds (forward)
                    var sizeProgress = (starburstMs / 5000.0).clamp(0.0, 1.0);

                    // Color progress: 0 to 1.0 over 8 seconds (all yellow at 8s)
                    var colorProgress = (starburstMs / 8000.0).clamp(0.0, 1.0);

                    // Calculate revert progress (shrink back over 3 seconds)
                    double fadeOut = 0.0;
                    if (_isReverting && _revertStartTime != null) {
                      final revertMs = DateTime.now()
                          .difference(_revertStartTime!)
                          .inMilliseconds;
                      fadeOut = (revertMs / (_revertDurationSeconds * 1000)).clamp(0.0, 1.0);

                      // Reverse size and color during revert
                      sizeProgress = sizeProgress * (1.0 - fadeOut);
                      colorProgress = colorProgress * (1.0 - fadeOut);
                    }

                    // Hide when fully reverted
                    if (fadeOut >= 1.0) {
                      return const SizedBox.shrink();
                    }

                    return CustomPaint(
                      size: Size(widget.size * 4, widget.size * 4),
                      painter: StarburstPainter(
                        progress: sizeProgress,
                        colorProgress: colorProgress,
                        rotation: _starburstController.value * math.pi * 2,
                        fadeOut: fadeOut,
                      ),
                    );
                  },
                ),
              ),
            ),

          // Heart particles (behind cat) - Layer 2
          if (_showParticles || (_isReverting && _particles.isNotEmpty))
            Positioned.fill(
              child: CustomPaint(
                painter: HeartParticlePainter(particles: _particles),
              ),
            ),

          // Main content - Layer 3 (topmost)
          Positioned.fill(
            child: Center(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Cat face with animations
              AnimatedBuilder(
                animation: Listenable.merge([
                  _jumpAnimation,
                  _pulseAnimation,
                  _scaleAnimation,
                  _ecstasyAnimation,
                  _ecstasyYAnimation,
                ]),
                builder: (context, child) {
                  // Combine pulse, scale, and ecstasy animations
                  final baseScale = _scaleAnimation.value;
                  final pulseScale = isPerfect ? _pulseAnimation.value : 1.0;
                  // Apply ecstasy pulsing when particles are showing
                  final ecstasyScale = _showParticles ? _ecstasyAnimation.value : 1.0;
                  final totalScale = baseScale * pulseScale * ecstasyScale;

                  // Y offset: jump animation + ecstasy float from below
                  final ecstasyY = _showParticles ? _ecstasyYAnimation.value : 0.0;
                  final totalY = _jumpAnimation.value + ecstasyY;

                  return Transform.translate(
                    offset: Offset(0, totalY),
                    child: Transform.scale(
                      scale: totalScale,
                      child: child,
                    ),
                  );
                },
                child: CatFace(
                  size: catSize,
                  status: status,
                  isPerfect: isPerfect,
                  comboTier: tier,
                  isEcstatic: _showParticles,
                ),
              ),

              // Status message or current note display with cent
              if (showExtras && widget.showNote) ...[
                const SizedBox(height: 4),
                if (tunerState.currentNote != null)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: NoteWithCent(
                      note: tunerState.currentNote!,
                      isPerfect: isPerfect,
                    ),
                  )
                else
                  StatusBubble(
                    isListening: tunerState.isListening,
                    hasNote: false,
                    isPerfect: isPerfect,
                    errorMessage: tunerState.error,
                  ),
              ],
            ],
              ),
            ),
          ),

        ],
      ),
    );
  }
}
