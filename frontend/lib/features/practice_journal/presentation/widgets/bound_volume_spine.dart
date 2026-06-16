import 'package:flutter/material.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/core/theme/app_spacing.dart';
import 'package:lessonaza/core/theme/app_typography.dart';
import 'package:lessonaza/core/theme/notebook_typography.dart';

/// 책등(spine) — 완성본은 실선 + 로마숫자(VOL.), 연습중은 점선.
///
/// 책장(`BoundShelfScreen`)에서 완성본/연습중을 시각적으로 구분한다.
class BoundVolumeSpine extends StatelessWidget {
  /// 권 번호(1부터). null 이면 연습중(미완성 — 점선).
  final int? volumeNo;
  final String title;

  const BoundVolumeSpine({super.key, required this.title, this.volumeNo});

  bool get _bound => volumeNo != null;

  @override
  Widget build(BuildContext context) {
    final roman = _bound ? romanOf(volumeNo! - 1) : null;

    final inner = SizedBox(
      width: 68,
      height: 152,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space2,
          vertical: AppSpacing.space3,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _bound ? 'VOL.' : AppStrings.boundShelfInProgress,
              style: AppTypography.caption.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            if (roman != null)
              Text(
                roman,
                style: NotebookTypography.roman.copyWith(fontSize: 22),
              ),
            const Spacer(),
            Text(
              title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: AppColors.ink),
            ),
          ],
        ),
      ),
    );

    if (_bound) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.paperDark,
          border: Border.all(color: AppColors.ink, width: 1.2),
        ),
        child: inner,
      );
    }
    return CustomPaint(
      foregroundPainter: const _DashedBorderPainter(
        color: AppColors.inkSecondary,
      ),
      child: ColoredBox(color: AppColors.paper, child: inner),
    );
  }
}

/// 사각형 둘레를 점선으로 그리는 painter (연습중 책등).
class _DashedBorderPainter extends CustomPainter {
  final Color color;

  const _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
    final source = Path()..addRect(Offset.zero & size);
    const dash = 4.0;
    const gap = 3.0;
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0.0, metric.length)),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
