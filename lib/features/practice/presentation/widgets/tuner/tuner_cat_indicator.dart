import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/tuner_types.dart';
import '../../providers/tuner_combo_provider.dart';
import '../../providers/tuner_provider.dart';

/// Heart particle for perfect tuning celebration.
/// Starts from cat edge and expands outward radially to the circle.
class _HeartParticle {
  _HeartParticle({
    required this.center,
    required this.angle,
    required this.baseSize,
    required this.startRadius,
    required this.maxRadius,
    required this.rotation,
    this.progress = 0.0,
    this.speed = 1.0,
  });

  final Offset center; // Cat center position
  final double angle; // Direction angle (radians)
  final double baseSize; // Base size of heart
  final double startRadius; // Start from cat edge
  final double maxRadius; // End at circle edge
  double rotation; // Current rotation
  double progress; // 0.0 = at cat edge, 1.0 = at circle edge
  double speed; // Speed multiplier

  /// Current position based on progress
  Offset get position {
    final currentRadius = startRadius + progress * (maxRadius - startRadius);
    return Offset(
      center.dx + math.cos(angle) * currentRadius,
      center.dy + math.sin(angle) * currentRadius,
    );
  }

  /// Size grows as particle moves outward
  double get size {
    // Start small, grow to full size
    return baseSize * (0.5 + progress * 0.5);
  }

  /// Opacity: fade in quickly, stay visible until the very end
  double get opacity {
    if (progress < 0.1) {
      // Quick fade in
      return progress / 0.1;
    } else if (progress > 0.9) {
      // Very late fade out
      return (1.0 - progress) / 0.1;
    }
    return 1.0;
  }

  bool get isDead => progress >= 1.0;
}

/// Cat indicator for tuner with expressions and speech bubbles.
class TunerCatIndicator extends ConsumerStatefulWidget {
  const TunerCatIndicator({
    super.key,
    this.size = 120,
  });

  final double size;

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
  final List<_HeartParticle> _particles = [];
  final math.Random _random = math.Random();

  // Thresholds
  static const _scaleStartSeconds = 1.0; // Cat grows after 1 second
  static const _particleStartSeconds = 2.0; // 1 second after scale starts
  static const _starburstStartSeconds = 6.0; // 4 seconds after particles start
  static const _maxScale = 1.5;
  static const _maxParticles = 500;

  // Starburst animation
  late AnimationController _starburstController;
  bool _showStarburst = false;
  DateTime? _starburstStartTime;
  DateTime? _starburstFadeStartTime; // When pitch became inaccurate

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
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    );
    // Scale animation for subtle size change
    _ecstasyAnimation = TweenSequence<double>([
      // Slowly rise with subtle scale
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 50,
      ),
      // Gentle settle back
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 50,
      ),
    ]).animate(_ecstasyController);

    // Y translation for floating up effect
    _ecstasyYAnimation = TweenSequence<double>([
      // Float up from below
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -12.0)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 50,
      ),
      // Gentle bounce back down
      TweenSequenceItem(
        tween: Tween<double>(begin: -12.0, end: 0.0)
            .chain(CurveTween(curve: Curves.bounceOut)),
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
    if (!_showParticles || !mounted) {
      _stopParticleTicker();
      return;
    }

    // Calculate delta time for smooth animation
    final deltaMs = (elapsed - _lastTickTime).inMilliseconds;
    _lastTickTime = elapsed;

    // Skip if too long (app was in background)
    if (deltaMs > 100) return;

    final deltaProgress = deltaMs / 1000.0; // Convert to seconds

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

    // Max radius (well beyond the circular tuner edge)
    final maxRadius = widget.size * 1.2; // Far past the circle edge

    // Random angle for radial direction
    final angle = _random.nextDouble() * math.pi * 2;

    _particles.add(_HeartParticle(
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

  void _onPerfectStateChanged(bool isPerfect) {
    if (isPerfect) {
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
      // Reset everything
      _perfectStartTime = null;
      _isScaling = false;
      _showParticles = false;
      _showStarburst = false;
      _starburstStartTime = null;
      _stopParticleTicker();
      _particles.clear();
      _scaleController.reverse();
      _starburstController.stop();
      _starburstController.reset();
      _ecstasyController.stop();
      _ecstasyController.reset();
    }
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
      if (previous?.isPerfect != next.isPerfect) {
        _onPerfectStateChanged(next.isPerfect);
      } else if (next.isPerfect) {
        // Still perfect, check duration thresholds
        _onPerfectStateChanged(true);
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
        alignment: Alignment.center,
        children: [
          // Rotating starburst (behind everything) - grows to cover screen
          if (_showStarburst)
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

                    // Size progress: 0 to 1 over 5 seconds
                    final sizeProgress = (starburstMs / 5000.0).clamp(0.0, 1.0);

                    // Color progress: 0 to 0.9 over 8 seconds (all yellow at 8s)
                    // Phase 1 (0-2.7s): pattern with transparent
                    // Phase 2 (2.7-5.3s): transparent disappears
                    // Phase 3 (5.3-8s): white becomes yellow
                    // Stays yellow while pitch is accurate
                    final colorProgress = ((starburstMs / 8000.0) * 0.9).clamp(0.0, 0.9);

                    // Track fade out when pitch becomes inaccurate
                    if (!isPerfect && _showStarburst) {
                      _starburstFadeStartTime ??= DateTime.now();
                    } else if (isPerfect) {
                      _starburstFadeStartTime = null;
                    }

                    // Calculate fade out progress (0 to 1 over 1 second)
                    final fadeOutMs = _starburstFadeStartTime != null
                        ? DateTime.now()
                            .difference(_starburstFadeStartTime!)
                            .inMilliseconds
                        : 0;
                    final fadeOut = (fadeOutMs / 1000.0).clamp(0.0, 1.0);

                    // Hide when fully faded out
                    if (fadeOut >= 1.0) {
                      return const SizedBox.shrink();
                    }

                    return CustomPaint(
                      size: Size(widget.size * 4, widget.size * 4),
                      painter: _StarburstPainter(
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
          if (_showParticles)
            Positioned.fill(
              child: CustomPaint(
                painter: _HeartParticlePainter(particles: _particles),
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
                child: _CatFace(
                  size: catSize,
                  status: status,
                  isPerfect: isPerfect,
                  comboTier: tier,
                  isEcstatic: _showParticles,
                ),
              ),

              // Status message speech bubble
              if (showExtras) ...[
                const SizedBox(height: 8),
                _StatusBubble(
                  isListening: tunerState.isListening,
                  hasNote: tunerState.currentNote != null,
                  isPerfect: isPerfect,
                ),
              ],

              // Cent display - only if enough space
              if (tunerState.currentNote != null && showExtras) ...[
                const SizedBox(height: 4),
                _CentDisplay(
                  centDeviation: tunerState.centDeviation,
                  isPerfect: isPerfect,
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

/// Painter for rotating spiral/screw starburst effect.
/// Color progression:
/// Curtain effect with quadrant-based pattern
/// Each quadrant: T25%, W45%, Y30% (40 beams per quadrant, 160 total)
/// Phase 1 (0-0.3): Pattern with transparent
/// Phase 2 (0.3-0.6): Transparent disappears, white + yellow
/// Phase 3 (0.6-0.9): White becomes yellow
/// Phase 4: All yellow (stays while pitch accurate), fade out when inaccurate
class _StarburstPainter extends CustomPainter {
  _StarburstPainter({
    this.progress = 0.0,
    this.colorProgress = 0.0,
    this.rotation = 0.0,
    this.fadeOut = 0.0,
  });

  // 32 beams total: 8 per quadrant × 4 quadrants (80% reduction)
  // Per quadrant: T=2 (25%), W=4 (50%), Y=2 (25%)
  static const int beamCount = 32;
  static const int beamsPerQuadrant = 8;

  final double progress; // Size growth progress
  final double colorProgress; // Color transition progress (0-0.9, stays at yellow)
  final double rotation; // Rotation angle in radians
  final double fadeOut; // Fade out progress when pitch becomes inaccurate (0-1)

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Radius grows from 10% to 100% based on progress
    final maxRadius = size.width / 2;
    final radius = maxRadius * (0.1 + progress * 0.9);

    // Only fade out when pitch becomes inaccurate
    final overallOpacity = (1.0 - fadeOut).clamp(0.0, 1.0);

    // Per quadrant pattern: T=2 (0-1), W=4 (2-5), Y=2 (6-7)
    // T25%, W50%, Y25% of 8 beams
    Color getPatternColor(int index, double opacity) {
      final i = index % beamsPerQuadrant;
      if (i < 2) {
        return Colors.transparent; // T: 0-1 (2 beams = 25%)
      } else if (i < 6) {
        return Colors.white.withValues(alpha: opacity); // W: 2-5 (4 beams = 50%)
      } else {
        return Colors.yellow.withValues(alpha: opacity); // Y: 6-7 (2 beams = 25%)
      }
    }

    bool isTransparentPosition(int index) => (index % beamsPerQuadrant) < 2;
    bool isWhitePosition(int index) {
      final i = index % beamsPerQuadrant;
      return i >= 2 && i < 6;
    }

    List<Color> colors;

    if (colorProgress < 0.3) {
      // Phase 1: Initial pattern T25%, W45%, Y30% per quadrant
      colors = List.generate(beamCount, (i) => getPatternColor(i, overallOpacity));
    } else if (colorProgress < 0.6) {
      // Phase 2: Transparent disappears, filled with white/yellow
      final t = ((colorProgress - 0.3) / 0.3).clamp(0.0, 1.0);
      colors = List.generate(beamCount, (i) {
        if (isTransparentPosition(i)) {
          // Transparent becomes yellow gradually
          return Colors.yellow.withValues(alpha: overallOpacity * t);
        } else if (isWhitePosition(i)) {
          return Colors.white.withValues(alpha: overallOpacity);
        } else {
          return Colors.yellow.withValues(alpha: overallOpacity);
        }
      });
    } else if (colorProgress < 0.9) {
      // Phase 3: White becomes yellow - all fills with yellow
      final t = ((colorProgress - 0.6) / 0.3).clamp(0.0, 1.0);
      colors = List.generate(beamCount, (i) {
        if (isWhitePosition(i)) {
          // Blend from white to yellow
          return Color.lerp(Colors.white, Colors.yellow, t)!.withValues(alpha: overallOpacity);
        } else {
          return Colors.yellow.withValues(alpha: overallOpacity);
        }
      });
    } else {
      // Phase 4: All yellow (stays until pitch becomes inaccurate)
      colors = List.generate(
        beamCount,
        (_) => Colors.yellow.withValues(alpha: overallOpacity),
      );
    }

    final anglePerBeam = math.pi * 2 / beamCount;

    for (var i = 0; i < beamCount; i++) {
      final baseAngle = i * anglePerBeam + rotation;
      final color = colors[i % colors.length];

      // Skip transparent beams
      if (color == Colors.transparent || color.a < 0.01) continue;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      // Draw straight triangular beam
      final path = Path();
      path.moveTo(center.dx, center.dy);

      final angle1 = baseAngle;
      final angle2 = baseAngle + anglePerBeam * 0.85;

      path.lineTo(
        center.dx + math.cos(angle1) * radius,
        center.dy + math.sin(angle1) * radius,
      );
      path.lineTo(
        center.dx + math.cos(angle2) * radius,
        center.dy + math.sin(angle2) * radius,
      );
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarburstPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.colorProgress != colorProgress ||
      oldDelegate.rotation != rotation ||
      oldDelegate.fadeOut != fadeOut;
}

/// Painter for heart particles.
class _HeartParticlePainter extends CustomPainter {
  _HeartParticlePainter({required this.particles});

  final List<_HeartParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    // Light purple color like cat face
    final baseColor = AppColors.primary.withValues(alpha: 0.3);

    for (final particle in particles) {
      final opacity = particle.opacity * 0.8; // Max 80% opacity
      if (opacity <= 0.01) continue;

      final paint = Paint()
        ..color = baseColor.withValues(alpha: opacity * 0.4)
        ..style = PaintingStyle.fill;

      final pos = particle.position;
      final particleSize = particle.size;

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(particle.rotation);

      // Draw heart shape
      _drawHeart(canvas, particleSize, paint);

      canvas.restore();
    }
  }

  void _drawHeart(Canvas canvas, double size, Paint paint) {
    final path = Path();
    final s = size / 2;

    // Heart shape using bezier curves - centered
    path.moveTo(0, s * 0.3);

    // Left half
    path.cubicTo(
      -s * 0.8, -s * 0.5,
      -s * 0.8, s * 0.3,
      0, s,
    );

    // Right half
    path.moveTo(0, s * 0.3);
    path.cubicTo(
      s * 0.8, -s * 0.5,
      s * 0.8, s * 0.3,
      0, s,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeartParticlePainter oldDelegate) => true;
}

/// Status message bubble for tuner.
class _StatusBubble extends StatelessWidget {
  const _StatusBubble({
    required this.isListening,
    required this.hasNote,
    required this.isPerfect,
  });

  final bool isListening;
  final bool hasNote;
  final bool isPerfect;

  @override
  Widget build(BuildContext context) {
    String message;
    Color backgroundColor;
    Color textColor;

    if (!isListening) {
      message = '마이크를 켜주세요';
      backgroundColor = Colors.grey[200]!;
      textColor = Colors.grey[600]!;
    } else if (!hasNote) {
      message = '소리 감지 대기...';
      backgroundColor = Colors.blue[50]!;
      textColor = Colors.blue[700]!;
    } else if (isPerfect) {
      message = '완벽해요! 🎵';
      backgroundColor = Colors.green[100]!;
      textColor = Colors.green[800]!;
    } else {
      message = '소리 감지중';
      backgroundColor = Colors.orange[50]!;
      textColor = Colors.orange[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
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
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

/// Cat face with expression based on tuning status.
class _CatFace extends StatelessWidget {
  const _CatFace({
    required this.size,
    required this.status,
    required this.isPerfect,
    required this.comboTier,
    this.isEcstatic = false,
  });

  final double size;
  final TuningStatus status;
  final bool isPerfect;
  final ComboTier comboTier;
  final bool isEcstatic;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CatFacePainter(
        status: status,
        isPerfect: isPerfect,
        comboTier: comboTier,
        isEcstatic: isEcstatic,
      ),
    );
  }
}

/// Cat face painter matching metronome style.
class _CatFacePainter extends CustomPainter {
  _CatFacePainter({
    required this.status,
    required this.isPerfect,
    required this.comboTier,
    this.isEcstatic = false,
  });

  final TuningStatus status;
  final bool isPerfect;
  final ComboTier comboTier;
  final bool isEcstatic;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.45);
    final radius = size.height * 0.4;

    // Use metronome style colors
    // Light purple opaque color (same visual as 0.2 alpha on white background)
    final faceColor = Color.lerp(Colors.white, AppColors.primary, 0.2)!;
    final featureColor = AppColors.primary;

    final facePaint = Paint()
      ..color = faceColor
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = featureColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final featurePaint = Paint()
      ..color = featureColor
      ..style = PaintingStyle.fill;

    // Face circle
    canvas.drawCircle(center, radius, facePaint);

    // Ears (metronome style with outline)
    _drawEars(canvas, center, radius, facePaint, linePaint);

    // Eyes based on status
    final eyeY = center.dy - radius * 0.1;
    final eyeRadius = radius * 0.22;
    final leftEyeX = center.dx - radius * 0.38;
    final rightEyeX = center.dx + radius * 0.38;

    final shouldCloseEyes = isPerfect || status == TuningStatus.tuned;

    if (isEcstatic) {
      // Ecstatic expression: extra happy curved eyes with sparkle
      _drawEcstaticEye(canvas, Offset(leftEyeX, eyeY), eyeRadius, linePaint);
      _drawEcstaticEye(canvas, Offset(rightEyeX, eyeY), eyeRadius, linePaint);
      // Draw blush marks on cheeks
      _drawBlush(canvas, center, radius);
    } else if (shouldCloseEyes) {
      _drawSmilingEye(canvas, Offset(leftEyeX, eyeY), eyeRadius, linePaint);
      _drawSmilingEye(canvas, Offset(rightEyeX, eyeY), eyeRadius, linePaint);
    } else {
      canvas.drawCircle(Offset(leftEyeX, eyeY), eyeRadius, featurePaint);
      canvas.drawCircle(Offset(rightEyeX, eyeY), eyeRadius, featurePaint);
    }

    // Nose (metronome style triangle)
    final nosePath = Path();
    nosePath.moveTo(center.dx, center.dy + radius * 0.15);
    nosePath.lineTo(center.dx - radius * 0.1, center.dy + radius * 0.28);
    nosePath.lineTo(center.dx + radius * 0.1, center.dy + radius * 0.28);
    nosePath.close();
    canvas.drawPath(nosePath, featurePaint);

    // Mouth (metronome style ω shape)
    final mouthPath = Path();
    mouthPath.moveTo(center.dx, center.dy + radius * 0.28);
    mouthPath.lineTo(center.dx, center.dy + radius * 0.4);
    canvas.drawPath(mouthPath, linePaint);

    mouthPath.reset();
    mouthPath.moveTo(center.dx, center.dy + radius * 0.4);
    mouthPath.quadraticBezierTo(center.dx - radius * 0.15,
        center.dy + radius * 0.5, center.dx - radius * 0.22, center.dy + radius * 0.4);
    canvas.drawPath(mouthPath, linePaint);

    mouthPath.reset();
    mouthPath.moveTo(center.dx, center.dy + radius * 0.4);
    mouthPath.quadraticBezierTo(center.dx + radius * 0.15,
        center.dy + radius * 0.5, center.dx + radius * 0.22, center.dy + radius * 0.4);
    canvas.drawPath(mouthPath, linePaint);

    // Whiskers (metronome style)
    _drawWhiskers(canvas, center, radius, linePaint);
  }

  void _drawEars(Canvas canvas, Offset center, double radius, Paint facePaint,
      Paint linePaint) {
    final earPath = Path();
    earPath.moveTo(center.dx - radius * 0.7, center.dy - radius * 0.5);
    earPath.lineTo(center.dx - radius * 0.9, center.dy - radius * 1.1);
    earPath.lineTo(center.dx - radius * 0.3, center.dy - radius * 0.7);
    earPath.close();
    earPath.moveTo(center.dx + radius * 0.7, center.dy - radius * 0.5);
    earPath.lineTo(center.dx + radius * 0.9, center.dy - radius * 1.1);
    earPath.lineTo(center.dx + radius * 0.3, center.dy - radius * 0.7);
    earPath.close();
    canvas.drawPath(earPath, facePaint);
    canvas.drawPath(earPath, linePaint);
  }

  void _drawSmilingEye(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    path.moveTo(center.dx - radius, center.dy);
    path.quadraticBezierTo(
        center.dx, center.dy - radius * 0.8, center.dx + radius, center.dy);
    canvas.drawPath(path, paint);
  }

  void _drawEcstaticEye(Canvas canvas, Offset center, double radius, Paint paint) {
    // Ecstatic eyes: tighter curve (more squeezed happy look)
    final thickerPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(center.dx - radius, center.dy);
    // Higher curve for more intense happiness
    path.quadraticBezierTo(
        center.dx, center.dy - radius * 1.1, center.dx + radius, center.dy);
    canvas.drawPath(path, thickerPaint);
  }

  void _drawBlush(Canvas canvas, Offset center, double radius) {
    // Pink blush circles on both cheeks
    final blushPaint = Paint()
      ..color = Colors.pink.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    // Left cheek blush
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - radius * 0.55, center.dy + radius * 0.25),
        width: radius * 0.35,
        height: radius * 0.22,
      ),
      blushPaint,
    );

    // Right cheek blush
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + radius * 0.55, center.dy + radius * 0.25),
        width: radius * 0.35,
        height: radius * 0.22,
      ),
      blushPaint,
    );
  }

  void _drawWhiskers(Canvas canvas, Offset center, double radius, Paint paint) {
    final whiskerPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx - radius * 0.35, center.dy + radius * 0.35),
      Offset(center.dx - radius * 0.85, center.dy + radius * 0.25),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(center.dx - radius * 0.35, center.dy + radius * 0.4),
      Offset(center.dx - radius * 0.85, center.dy + radius * 0.45),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(center.dx + radius * 0.35, center.dy + radius * 0.35),
      Offset(center.dx + radius * 0.85, center.dy + radius * 0.25),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(center.dx + radius * 0.35, center.dy + radius * 0.4),
      Offset(center.dx + radius * 0.85, center.dy + radius * 0.45),
      whiskerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CatFacePainter oldDelegate) {
    return oldDelegate.status != status ||
        oldDelegate.isPerfect != isPerfect ||
        oldDelegate.comboTier != comboTier ||
        oldDelegate.isEcstatic != isEcstatic;
  }
}

/// Speech bubble for cat feedback.
class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({
    required this.judgement,
    required this.comboTier,
  });

  final JudgementResult judgement;
  final ComboTier comboTier;

  @override
  Widget build(BuildContext context) {
    // Use combo message if available, otherwise judgement message
    final message =
        comboTier != ComboTier.none ? comboTier.message : judgement.message;

    final color = switch (judgement) {
      JudgementResult.perfect => Colors.green[100],
      JudgementResult.good => Colors.yellow[100],
      JudgementResult.miss => Colors.grey[200],
    };

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
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
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Cent deviation display.
class _CentDisplay extends StatelessWidget {
  const _CentDisplay({
    required this.centDeviation,
    required this.isPerfect,
  });

  final double centDeviation;
  final bool isPerfect;

  @override
  Widget build(BuildContext context) {
    final color = isPerfect
        ? Colors.green
        : (centDeviation < 0 ? Colors.red : Colors.orange);

    final arrow = centDeviation > 3
        ? '↓'
        : (centDeviation < -3 ? '↑' : '');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (arrow.isNotEmpty)
          Text(
            arrow,
            style: TextStyle(
              fontSize: 18,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        Text(
          '${centDeviation >= 0 ? '+' : ''}${centDeviation.toStringAsFixed(1)}¢',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Combo counter display.
class _ComboCounter extends StatelessWidget {
  const _ComboCounter({
    required this.count,
    required this.tier,
  });

  final int count;
  final ComboTier tier;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Stars based on tier
        for (var i = 0; i < tier.stars; i++)
          Icon(
            Icons.star,
            size: 16,
            color: tier.isGolden ? Colors.amber : Colors.yellow[700],
          ),

        const SizedBox(width: 4),

        Text(
          'COMBO $count',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: tier.isGolden ? Colors.amber[800] : AppColors.primary,
          ),
        ),
      ],
    );
  }
}
