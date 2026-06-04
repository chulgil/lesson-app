import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Second-stage feedback dialog — shown when user picks 아쉬워요.
///
/// Returns:
/// - `String` (non-empty) — feedback text submitted (의견 보내기)
/// - `null` — user dismissed via 나중에 or barrier
///
/// Spec: `docs/specs/settings/app_rating_prompt_spec.md` §9.
class AppRatingFeedbackDialog extends StatefulWidget {
  const AppRatingFeedbackDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AppRatingFeedbackDialog(),
    );
  }

  @override
  State<AppRatingFeedbackDialog> createState() =>
      _AppRatingFeedbackDialogState();
}

class _AppRatingFeedbackDialogState extends State<AppRatingFeedbackDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.ratingFeedbackTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.ratingFeedbackBody, style: AppTypography.bodySmall),
          const SizedBox(height: AppSpacing.space3),
          TextField(
            controller: _controller,
            maxLines: 4,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text(AppStrings.ratingFeedbackLater),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, AppSpacing.buttonHeight),
          ),
          onPressed: () {
            final text = _controller.text.trim();
            Navigator.of(context).pop(text.isEmpty ? null : text);
          },
          child: const Text(AppStrings.ratingFeedbackSend),
        ),
      ],
    );
  }
}
