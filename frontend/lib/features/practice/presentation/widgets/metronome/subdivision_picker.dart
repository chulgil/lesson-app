import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/notebook_typography.dart';
import '../../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../domain/entities/metronome_settings.dart';

/// Bottom sheet picker for selecting subdivision.
class SubdivisionPicker extends StatefulWidget {
  const SubdivisionPicker({super.key, required this.current});

  final Subdivision current;

  /// Show the subdivision picker as a bottom sheet.
  static Future<Subdivision?> show(BuildContext context, Subdivision current) {
    return showModalBottomSheet<Subdivision>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SubdivisionPicker(current: current),
    );
  }

  @override
  State<SubdivisionPicker> createState() => _SubdivisionPickerState();
}

class _SubdivisionPickerState extends State<SubdivisionPicker> {
  late Subdivision _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.75),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.zero,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            const BottomSheetHandle(),
            // Title
            Padding(
              padding: EdgeInsets.all(AppSpacing.space4),
              // Notebook × Score: 바텀시트 헤더 (§7.27) — Playfair sectionTitle.
              child: Text('서브디비전 선택', style: NotebookTypography.sectionTitle),
            ),
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic subdivisions section
                    _buildSection(
                      title: '기본 패턴',
                      subdivisions:
                          Subdivision.values.where((s) => s.isBasic).toList(),
                    ),
                    SizedBox(height: AppSpacing.space4),
                    // Variations section
                    _buildSection(
                      title: '베리에이션 (쉼표 포함)',
                      subdivisions:
                          Subdivision.values.where((s) => !s.isBasic).toList(),
                    ),
                    SizedBox(height: AppSpacing.space4),
                  ],
                ),
              ),
            ),
            // Visual pattern display for current selection
            Container(
              margin: EdgeInsets.symmetric(horizontal: AppSpacing.space4),
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.space4,
                vertical: AppSpacing.space3,
              ),
              decoration: BoxDecoration(
                color: AppColors.paperAccent.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppColors.paperAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_note,
                    size: 20,
                    color: AppColors.paperAccent,
                  ),
                  SizedBox(width: AppSpacing.space2),
                  Text(
                    '패턴: ${_selected.visualPattern}',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(width: AppSpacing.space3),
                  Text(
                    '(${_selected.label})',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.space4),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Subdivision> subdivisions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppSpacing.space2),
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children:
              subdivisions.map((sub) {
                final isSelected = sub == _selected;
                return _SubdivisionChip(
                  subdivision: sub,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() => _selected = sub);
                    Navigator.of(context).pop(sub);
                  },
                );
              }).toList(),
        ),
      ],
    );
  }
}

class _SubdivisionChip extends StatelessWidget {
  const _SubdivisionChip({
    required this.subdivision,
    required this.isSelected,
    required this.onTap,
  });

  final Subdivision subdivision;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.paperAccent : AppColors.paper,
          border: Border.all(
            color: isSelected ? AppColors.paperAccent : AppColors.inkQuaternary,
            width: isSelected ? 2 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: AppColors.paperAccent.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Visual pattern
            Text(
              subdivision.visualPattern,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.ink,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: AppSpacing.space1),
            // Korean label
            Text(
              subdivision.label,
              style: AppTypography.caption.copyWith(
                color: isSelected ? Colors.white : AppColors.inkSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
