import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Grid pitch between candidate speckles, in logical pixels.
const double _grainCell = 24.0;

/// Ink alpha for a single speckle. Deliberately near the perception threshold.
const double _grainOpacity = 0.022;

/// Share of cells left empty, so the grain reads as sparse fibre.
const double _grainSparsity = 0.55;

/// Fixed seed — the speckle field must be identical on every paint.
const int _grainSeed = 0x5E4D;

/// Notebook x Score paper grain.
///
/// Draws sparse ink speckles that hint at paper fibre. Hyen standard H1
/// lightened the paper token to #FFFDF8, and the designer asked for texture
/// only if it stays subtle — so this must read as warmth, never as noise.
///
/// The speckle field is deterministic: [paint] reseeds its own generator, so
/// the same size always yields the same field.
///
/// Spec: `.harness/spec/2026-08-05-hyen-ux-standard.md` H1
class PaperGrainPainter extends CustomPainter {
  const PaperGrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final random = math.Random(_grainSeed);
    final paint = Paint()
      ..color = AppColors.ink.withValues(alpha: _grainOpacity);

    final columns = (size.width / _grainCell).ceil();
    final rows = (size.height / _grainCell).ceil();

    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        if (random.nextDouble() < _grainSparsity) continue;

        canvas.drawCircle(
          Offset(
            (column + random.nextDouble()) * _grainCell,
            (row + random.nextDouble()) * _grainCell,
          ),
          0.5 + random.nextDouble() * 0.5,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(PaperGrainPainter oldDelegate) => false;
}

/// Marks a subtree as already carrying grain.
class _PaperTextureScope extends InheritedWidget {
  const _PaperTextureScope({required super.child});

  @override
  bool updateShouldNotify(_PaperTextureScope oldWidget) => false;
}

/// Lays [PaperGrainPainter] behind [child] as a background decoration layer.
///
/// [CustomPaint] with a child is a proxy box: constraints and sizing pass
/// through untouched, so wrapping an existing body cannot shift layout.
///
/// Nesting is idempotent. Several screens put a [PaperScaffold] tab body
/// inside a paper [NotebookScreenScaffold]; stacking two grain layers would
/// double the alpha and push the texture above the intended ceiling, so an
/// inner [PaperTexture] defers to the outer one.
@immutable
class PaperTexture extends StatelessWidget {
  const PaperTexture({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final alreadyGrained =
        context.getInheritedWidgetOfExactType<_PaperTextureScope>() != null;
    if (alreadyGrained) return child;

    return _PaperTextureScope(
      child: CustomPaint(
        painter: const PaperGrainPainter(),
        isComplex: true,
        willChange: false,
        child: child,
      ),
    );
  }
}
