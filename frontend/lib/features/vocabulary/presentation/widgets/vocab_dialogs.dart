import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_alert_dialog.dart';
import '../../domain/entities/vocab_card.dart';

/// The raw field values captured by [showVocabCardDialog] (#1124).
class VocabCardDraft {
  const VocabCardDraft({
    required this.front,
    required this.back,
    this.example,
    this.memo,
  });

  final String front;
  final String back;
  final String? example;
  final String? memo;
}

/// Prompt for a set title — create when [initialTitle] is null, else rename.
/// Resolves to the trimmed title, or null if cancelled (#1124).
Future<String?> showVocabSetNameDialog(
  BuildContext context, {
  String? initialTitle,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _SetNameDialog(initialTitle: initialTitle),
  );
}

/// Prompt for a card's fields — add when [initial] is null, else edit. Resolves
/// to a [VocabCardDraft], or null if cancelled (#1124).
Future<VocabCardDraft?> showVocabCardDialog(
  BuildContext context, {
  VocabCard? initial,
}) {
  return showDialog<VocabCardDraft>(
    context: context,
    builder: (_) => _CardDialog(initial: initial),
  );
}

class _SetNameDialog extends StatefulWidget {
  const _SetNameDialog({this.initialTitle});

  final String? initialTitle;

  @override
  State<_SetNameDialog> createState() => _SetNameDialogState();
}

class _SetNameDialogState extends State<_SetNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialTitle ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    Navigator.of(context).pop(title);
  }

  @override
  Widget build(BuildContext context) {
    return NotebookAlertDialog(
      title:
          widget.initialTitle == null
              ? AppStrings.vocabNewSetTitle
              : AppStrings.vocabRenameSetTitle,
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(
          hintText: AppStrings.vocabSetNameHint,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            AppStrings.cancel,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(
            AppStrings.save,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}

class _CardDialog extends StatefulWidget {
  const _CardDialog({this.initial});

  final VocabCard? initial;

  @override
  State<_CardDialog> createState() => _CardDialogState();
}

class _CardDialogState extends State<_CardDialog> {
  late final _front = TextEditingController(text: widget.initial?.front ?? '');
  late final _back = TextEditingController(text: widget.initial?.back ?? '');
  late final _example = TextEditingController(
    text: widget.initial?.example ?? '',
  );
  late final _memo = TextEditingController(text: widget.initial?.memo ?? '');
  bool _showError = false;

  @override
  void dispose() {
    _front.dispose();
    _back.dispose();
    _example.dispose();
    _memo.dispose();
    super.dispose();
  }

  void _submit() {
    final front = _front.text.trim();
    final back = _back.text.trim();
    if (front.isEmpty || back.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(context).pop(
      VocabCardDraft(
        front: front,
        back: back,
        example: _example.text,
        memo: _memo.text,
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String? hint, {
    bool autofocus = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.space3),
    child: TextField(
      controller: controller,
      autofocus: autofocus,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(labelText: label, hintText: hint),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return NotebookAlertDialog(
      title:
          widget.initial == null
              ? AppStrings.vocabNewCardTitle
              : AppStrings.vocabEditCardTitle,
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _field(
            _front,
            AppStrings.vocabCardFrontLabel,
            AppStrings.vocabCardFrontHint,
            autofocus: widget.initial == null,
          ),
          _field(
            _back,
            AppStrings.vocabCardBackLabel,
            AppStrings.vocabCardBackHint,
          ),
          _field(_example, AppStrings.vocabCardExampleLabel, null),
          _field(_memo, AppStrings.vocabCardMemoLabel, null),
          if (_showError)
            Text(
              AppStrings.vocabCardRequiredError,
              style: AppTypography.caption.copyWith(
                color: AppColors.paperAccent,
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            AppStrings.cancel,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(
            AppStrings.save,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}
