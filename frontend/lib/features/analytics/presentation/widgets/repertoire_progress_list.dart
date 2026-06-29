// Repertoire progress list widget.
// Spec: docs/specs/analytics/student_progress_dashboard_spec.md §2.2 Tab 2

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/analytics_models.dart';

// ignore: widget-smoke-test
/// Displays a list of repertoire pieces with completion status.
class RepertoireProgressList extends StatelessWidget {
  const RepertoireProgressList({super.key, required this.pieces});

  final List<RepertoirePiece> pieces;

  @override
  Widget build(BuildContext context) {
    if (pieces.isEmpty) return const SizedBox.shrink();

    // Group by book
    final bookGroups = <String, List<RepertoirePiece>>{};
    for (final p in pieces) {
      final book = p.bookTitle ?? AppStrings.analyticsRepertoireBookOther;
      (bookGroups[book] ??= []).add(p);
    }

    return Column(
      children: bookGroups.entries.map((e) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              e.key,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            ...e.value.map((p) => _PieceRow(piece: p)),
            const SizedBox(height: AppSpacing.space3),
          ],
        );
      }).toList(),
    );
  }
}

class _PieceRow extends StatelessWidget {
  const _PieceRow({required this.piece});

  final RepertoirePiece piece;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (piece.status) {
      RepertoireStatus.completed => (Icons.check_circle, AppColors.paperOk, AppStrings.analyticsRepertoireStatusCompleted),
      RepertoireStatus.inProgress => (Icons.play_circle_outline, AppColors.paperAccent, AppStrings.analyticsRepertoireStatusInProgress),
      RepertoireStatus.planned => (Icons.radio_button_unchecked, AppColors.inkQuaternary, AppStrings.analyticsRepertoireStatusPlanned),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              piece.title,
              style: AppTypography.bodySmall.copyWith(
                color: piece.status == RepertoireStatus.planned
                    ? AppColors.inkTertiary
                    : AppColors.ink,
              ),
            ),
          ),
          Text(
            label,
            style: AppTypography.captionSmall.copyWith(color: color),
          ),
          if (piece.masteryPercent != null) ...[
            const SizedBox(width: AppSpacing.space2),
            SizedBox(
              width: 48,
              child: LinearProgressIndicator(
                value: piece.masteryPercent! / 100,
                backgroundColor: AppColors.inkQuaternary,
                color: color,
                minHeight: 3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
