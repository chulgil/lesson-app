import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';

/// Shows a bottom sheet for entering a rejection message.
///
/// Returns the trimmed message, or null if dismissed without sending.
///
/// Shared by [SuggestAlternativeScreen] and [showSuggestAlternativeBottomSheet]
/// (its bottom-sheet counterpart) so the reject step stays identical across
/// both presentations.
Future<String?> showRejectMessageBottomSheet(BuildContext context) {
  return showNotebookBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    padding: EdgeInsets.zero,
    showHandle: false,
    builder: (context) => const _RejectMessageBottomSheet(),
  );
}

class _RejectMessageBottomSheet extends StatefulWidget {
  const _RejectMessageBottomSheet();

  @override
  State<_RejectMessageBottomSheet> createState() =>
      _RejectMessageBottomSheetState();
}

class _RejectMessageBottomSheetState extends State<_RejectMessageBottomSheet> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: AppStrings.declineDefaultMessage);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.paper),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.space3,
        AppSpacing.screenPadding,
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            AppSpacing.space4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          const Center(
            child: BottomSheetHandle(width: 36, margin: EdgeInsets.zero),
          ),
          const SizedBox(height: AppSpacing.space4),

          // Title
          // Notebook × Score: BottomSheetHandle 선행 커스텀 바텀시트 헤더는
          // Playfair appBarTitle 로 통일 (§7.27, 18/w700).
          Text(
            AppStrings.rejectBottomSheetTitle,
            style: NotebookTypography.appBarTitle,
          ),
          const SizedBox(height: AppSpacing.space2),

          // Guide text
          Text(
            AppStrings.rejectBottomSheetGuide,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),

          // Message input
          TextField(
            controller: _controller,
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: AppStrings.messageHint,
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space3,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space4),

          // Send button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final message = _controller.text.trim();
                if (message.isNotEmpty) {
                  Navigator.pop(context, message);
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(
                  AppSpacing.buttonHeightSmall,
                ),
                backgroundColor: AppColors.paperAccent,
                shape: RoundedRectangleBorder(),
              ),
              child: Text(
                AppStrings.rejectSendAndClose,
                style: AppTypography.buttonSmall.copyWith(
                  color: AppColors.paper,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
