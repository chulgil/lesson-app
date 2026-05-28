import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_glyph.dart';

/// 학원 휴강 의견 윈도우 위젯 (G15 §5.2).
///
/// 학원장 휴강 결정 후 강사가 1시간 이내에 의견을 제출할 수 있다.
/// 윈도우 만료 시 자동 적용. 학원 관리자가 즉시 적용도 가능.
class ClosureCommentWidget extends StatefulWidget {
  /// 윈도우 만료까지 남은 분.
  final int minutesUntilAutoApply;

  /// 이미 제출된 의견. null = 미제출.
  final String? submittedComment;

  /// 윈도우 닫힘 (적용됨/만료됨).
  final bool isWindowClosed;

  /// 의견 제출 콜백.
  final ValueChanged<String> onSubmit;

  const ClosureCommentWidget({
    super.key,
    required this.minutesUntilAutoApply,
    required this.onSubmit,
    this.submittedComment,
    this.isWindowClosed = false,
  });

  @override
  State<ClosureCommentWidget> createState() => _ClosureCommentWidgetState();
}

class _ClosureCommentWidgetState extends State<ClosureCommentWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.submittedComment ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasSubmitted = widget.submittedComment != null;
    final disabled = widget.isWindowClosed || hasSubmitted;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.closureCommentTitle,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          TextField(
            controller: _controller,
            maxLines: 3,
            enabled: !disabled,
            decoration: InputDecoration(
              hintText: AppStrings.closureCommentHint,
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkTertiary,
              ),
              filled: true,
              fillColor:
                  disabled
                      ? AppColors.inkQuaternary.withValues(alpha: 0.1)
                      : AppColors.paper,
              border: OutlineInputBorder(
                borderSide: const BorderSide(color: AppColors.inkQuaternary),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AppColors.inkQuaternary),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AppColors.paperAccent),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: disabled ? null : _handleSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.paperAccent,
                minimumSize: const Size(0, AppSpacing.buttonHeight),
                shape: const RoundedRectangleBorder(),
              ),
              child: Text(
                hasSubmitted
                    ? AppStrings.closureCommentSubmitted
                    : AppStrings.closureCommentSend,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.paper,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          if (widget.isWindowClosed)
            _noticeLine(AppStrings.closureCommentWindowClosed)
          else ...[
            _noticeLine(
              AppStrings.closureCommentAutoApply(widget.minutesUntilAutoApply),
            ),
            _noticeLine(AppStrings.closureCommentImmediateApply),
          ],
        ],
      ),
    );
  }

  Widget _noticeLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            NotebookGlyph.referenceMark,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit(text);
  }
}
