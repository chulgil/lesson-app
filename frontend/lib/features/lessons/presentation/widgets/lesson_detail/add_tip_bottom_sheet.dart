// Add tip bottom sheet widget

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/notebook_typography.dart';
import '../../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../domain/entities/tip_template.dart';
import '../tip_template_bottom_sheet.dart';

/// Bottom sheet for adding tips with template support
class AddTipBottomSheet extends ConsumerStatefulWidget {
  final String title;
  final String? instrument;
  final TipCategory? initialCategory;
  final Function(String content) onSubmit;

  const AddTipBottomSheet({
    super.key,
    required this.title,
    this.instrument,
    this.initialCategory,
    required this.onSubmit,
  });

  @override
  ConsumerState<AddTipBottomSheet> createState() => _AddTipBottomSheetState();
}

class _AddTipBottomSheetState extends ConsumerState<AddTipBottomSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.zero,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              const Center(
                child: BottomSheetHandle(
                  margin: EdgeInsets.only(bottom: AppSpacing.space4),
                ),
              ),

              // Header
              Row(
                children: [
                  // Notebook × Score §7.27: 바텀시트 제목 Playfair (동적 title 이지만 헤더 포지션).
                  Text(widget.title, style: NotebookTypography.sectionTitle),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      showTipTemplateBottomSheet(
                        context: context,
                        instrument: widget.instrument,
                        initialCategory: widget.initialCategory,
                        onSelect: widget.onSubmit,
                      );
                    },
                    icon: const Icon(Icons.library_books_outlined, size: 18),
                    label: const Text('템플릿에서'),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.space4),

              // Text input
              TextField(
                controller: _controller,
                maxLines: 4,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '직접 입력하세요...',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: AppSpacing.space4),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final content = _controller.text.trim();
                    if (content.isNotEmpty) {
                      Navigator.pop(context);
                      widget.onSubmit(content);
                    }
                  },
                  child: const Text('추가'),
                ),
              ),

              const SizedBox(height: AppSpacing.space4),
            ],
          ),
        ),
      ),
    );
  }
}
