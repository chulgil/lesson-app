import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../data/services/ai_notes_service.dart';

/// Bottom sheet showing AI-generated lesson notes with edit/save capability.
class AiNotesResultSheet extends StatefulWidget {
  final AiNoteResult result;
  final VoidCallback? onSave;

  const AiNotesResultSheet({super.key, required this.result, this.onSave});

  @override
  State<AiNotesResultSheet> createState() => _AiNotesResultSheetState();
}

class _AiNotesResultSheetState extends State<AiNotesResultSheet> {
  late TextEditingController _feedbackController;
  late TextEditingController _tipsController;

  @override
  void initState() {
    super.initState();
    _feedbackController = TextEditingController(
      text: widget.result.feedback ?? '',
    );
    _tipsController = TextEditingController(
      text: widget.result.practiceTips ?? '',
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _tipsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            // Notebook × Score: 바텀시트 배경은 Notebook paper (§7.50 팔레트 일관성).
            color: AppColors.paper,
          ),
          child: Column(
            children: [
              // Handle bar
              BottomSheetHandle(
                margin: const EdgeInsets.only(top: AppSpacing.space3),
                color: AppColors.inkQuaternary,
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: AppColors.paperAccent,
                          size: 24,
                        ),
                        const SizedBox(width: AppSpacing.space2),
                        // Notebook × Score: 바텀시트 커스텀 헤더 제목도 Playfair appBarTitle 로 통일 (§7.27 패턴).
                        Text('AI 레슨 노트', style: NotebookTypography.appBarTitle),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        widget.onSave?.call();
                        Navigator.pop(context);
                      },
                      child: const Text(AppStrings.save),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  children: [
                    // Feedback section
                    _buildSectionHeader('피드백', Icons.chat_bubble_outline),
                    const SizedBox(height: AppSpacing.space2),
                    TextField(
                      controller: _feedbackController,
                      maxLines: null,
                      decoration: _inputDecoration(),
                      style: AppTypography.bodyMedium,
                    ),

                    const SizedBox(height: AppSpacing.space6),

                    // Key points section
                    _buildSectionHeader('핵심 포인트', Icons.flag_outlined),
                    const SizedBox(height: AppSpacing.space2),
                    ...widget.result.keyPoints.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppColors.paperAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: AppTypography.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.space6),

                    // Practice tips section
                    _buildSectionHeader('연습 팁', Icons.lightbulb_outline),
                    const SizedBox(height: AppSpacing.space2),
                    TextField(
                      controller: _tipsController,
                      maxLines: null,
                      decoration: _inputDecoration(),
                      style: AppTypography.bodyMedium,
                    ),

                    if (widget.result.suggestedAssignments.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.space6),

                      // Suggested assignments
                      _buildSectionHeader('과제 제안', Icons.assignment_outlined),
                      const SizedBox(height: AppSpacing.space2),
                      ...widget.result.suggestedAssignments.map(
                        (a) => Card(
                          margin: const EdgeInsets.only(
                            bottom: AppSpacing.space2,
                          ),
                          elevation: 0,
                          color: AppColors.paperDark,
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.space3),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.title,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.space1),
                                Text(
                                  a.description,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.inkSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.space8),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.paperAccent),
        const SizedBox(width: 6),
        Text(
          title,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.paperAccent,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.paperDark,
      border: const OutlineInputBorder(borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.all(AppSpacing.space3),
    );
  }
}
