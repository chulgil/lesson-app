import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_bottom_sheet.dart';
import '../../../../core/widgets/notebook/notebook_glyph.dart';

/// Shows the quest unlock celebration sheet when Q6 (first student invite)
/// completes and Q7~Q10 transition from locked to active.
///
/// Spec: `docs/specs/_audits/2026-06-10-teacher-flow-ux-audit.md` §4.5 B3.
Future<void> showQuestUnlockCelebrationSheet(BuildContext context) {
  return showNotebookModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => const QuestUnlockCelebrationSheet(),
  );
}

/// Sheet content widget — exposed for widget smoke testing.
///
/// Animation: ScaleTransition(0.8 → 1.0) + Opacity(0 → 1) 400ms per audit
/// §4.5 B3 — reuses the celebration pattern from
/// `FirstAvailabilityCelebrationSheet`.
class QuestUnlockCelebrationSheet extends StatefulWidget {
  const QuestUnlockCelebrationSheet({super.key});

  @override
  State<QuestUnlockCelebrationSheet> createState() =>
      _QuestUnlockCelebrationSheetState();
}

class _QuestUnlockCelebrationSheetState
    extends State<QuestUnlockCelebrationSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scale = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: FadeTransition(
          opacity: _opacity,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: NotebookGlyph(
                    NotebookGlyph.starFilled,
                    size: 32,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.space3),
                Text(
                  AppStrings.questUnlockCelebrationTitle,
                  style: NotebookTypography.pieceTitle.copyWith(
                    fontSize: 18,
                    color: AppColors.ink,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.space3),
                Text(
                  AppStrings.questUnlockCelebrationMessage,
                  style: NotebookTypography.handMedium.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.space6),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, AppSpacing.buttonHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusMedium,
                      ),
                    ),
                  ),
                  child: const Text(AppStrings.questUnlockCelebrationAction),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
