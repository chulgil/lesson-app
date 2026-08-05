// Journey sticker catalog section (P3b Daily Satisfaction — doc 46 §5).
//
// Achieved = filled sticker (Notebook accent). Unachieved = dashed outline +
// progress bar + current/target label (ESL-style visual grammar, adapted to
// the Notebook ink palette — see journey_sticker_visuals.dart for the C8
// color-budget rationale).

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_glyph.dart';
import '../../domain/entities/journey_sticker.dart';
import '../extensions/journey_sticker_visuals.dart';

/// Renders the full journey sticker catalog grouped by [StickerFamily].
class JourneyStickerSection extends StatelessWidget {
  const JourneyStickerSection({super.key, required this.catalog});

  final JourneyStickerCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final byFamily = catalog.byFamily;
    if (byFamily.isEmpty) return const SizedBox.shrink();

    return Column(
      key: const ValueKey('journey_sticker_section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.journeyStickerSectionTitle,
          style: NotebookTypography.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.space3),
        for (final family in StickerFamily.values)
          if (byFamily[family]?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space4),
              child: _JourneyStickerFamilyGroup(stickers: byFamily[family]!),
            ),
      ],
    );
  }
}

class _JourneyStickerFamilyGroup extends StatelessWidget {
  const _JourneyStickerFamilyGroup({required this.stickers});

  final List<JourneySticker> stickers;

  @override
  Widget build(BuildContext context) {
    final first = stickers.first;
    final achievedCount = stickers.where((s) => s.achieved).length;

    // Sub-group by metric so ladders with different units (예: practice의
    // 누적시간 vs 연습일수) don't mix inside one row.
    final byMetric = <String, List<JourneySticker>>{};
    for (final sticker in stickers) {
      byMetric.putIfAbsent(sticker.metric, () => []).add(sticker);
    }

    return Column(
      key: ValueKey('journey_sticker_family_${first.family.name}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            NotebookGlyph(first.glyph, size: 16, color: AppColors.ink),
            const SizedBox(width: AppSpacing.space2),
            Text(
              first.familyLabel,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            Text(
              '($achievedCount/${stickers.length})',
              style: AppTypography.caption.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),
        for (final metricStickers in byMetric.values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space2),
            child: Wrap(
              spacing: AppSpacing.space3,
              runSpacing: AppSpacing.space3,
              children: [
                for (final sticker in metricStickers)
                  _JourneyStickerTile(sticker: sticker),
              ],
            ),
          ),
      ],
    );
  }
}

class _JourneyStickerTile extends StatelessWidget {
  const _JourneyStickerTile({required this.sticker});

  final JourneySticker sticker;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey('journey_sticker_tile_${sticker.key}'),
      width: 88,
      child: Column(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CustomPaint(
              painter:
                  sticker.achieved
                      ? null
                      : _DashedCirclePainter(color: sticker.tierInkColor),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      sticker.achieved
                          ? AppColors.paperAccentSoft
                          : Colors.transparent,
                ),
                alignment: Alignment.center,
                child: NotebookGlyph(
                  sticker.glyph,
                  size: 22,
                  color: sticker.displayColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: LinearProgressIndicator(
              value: sticker.progress,
              minHeight: 4,
              backgroundColor: AppColors.paperDark,
              valueColor: AlwaysStoppedAnimation<Color>(sticker.displayColor),
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            sticker.progressLabel,
            style: AppTypography.captionSmall.copyWith(
              color:
                  sticker.achieved
                      ? AppColors.paperAccent
                      : AppColors.inkTertiary,
              fontWeight: sticker.achieved ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

/// Minimal dashed-circle outline for unachieved stickers (no dashed-border
/// package in deps — simplicity-ladder step 7: smallest new implementation).
class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 1;
    const dashCount = 16;
    const gapFraction = 0.5;
    final sweepPerDash = (2 * 3.141592653589793) / dashCount;
    for (var i = 0; i < dashCount; i++) {
      final start = i * sweepPerDash;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweepPerDash * (1 - gapFraction),
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}
