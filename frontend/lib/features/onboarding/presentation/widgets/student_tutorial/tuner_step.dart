import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

class TunerStep extends StatefulWidget {
  final bool completed;
  final VoidCallback onComplete;

  const TunerStep({
    super.key,
    required this.completed,
    required this.onComplete,
  });

  @override
  State<TunerStep> createState() => _TunerStepState();
}

class _TunerStepState extends State<TunerStep> {
  late String? _selectedNote;
  bool _hasCalledOnComplete = false;

  @override
  void initState() {
    super.initState();
    // 기존 완료 상태면 기본값 A4로 설정
    _selectedNote = widget.completed ? 'A4' : null;
    _hasCalledOnComplete = widget.completed;
  }

  void _onSelect(String note) {
    setState(() {
      _selectedNote = note;
    });

    // 첫 선택에서만 onComplete() 호출
    if (!_hasCalledOnComplete) {
      _hasCalledOnComplete = true;
      widget.onComplete();
    }
  }

  String _getFrequency(String note) {
    return switch (note) {
      'A4' => '440 Hz',
      'C4' => '261.6 Hz',
      'E4' => '329.6 Hz',
      'G4' => '392.0 Hz',
      _ => '',
    };
  }

  String _getNoteName(String note) {
    return switch (note) {
      'A4' => '라',
      'C4' => '도',
      'E4' => '미',
      'G4' => '솔',
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    // 버그 B: 부모 _StudentTutorialPage 가 이미 SingleChildScrollView 이므로
    // 중첩 스크롤(중복 제스처 인식기) 제거 → Padding 단독.
    return Padding(
      padding: EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 안내 텍스트
          Text(
            '원하는 음을 선택하면 정확한 음높이를 확인할 수 있어요',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkTertiary,
            ),
          ),
          SizedBox(height: AppSpacing.space4),

          // 음 선택 칩들
          Wrap(
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            children: [
              _buildNoteChip('A4', '라'),
              _buildNoteChip('C4', '도'),
              _buildNoteChip('E4', '미'),
              _buildNoteChip('G4', '솔'),
            ],
          ),
          SizedBox(height: AppSpacing.space5),

          // 선택된 음 결과 카드
          if (_selectedNote != null) ...[
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.paperAccentSoft,
                border: Border.all(color: AppColors.paperAccent),
              ),
              padding: EdgeInsets.all(AppSpacing.space3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 음 이름 + 주파수
                  Text(
                    '${_selectedNote!} (${_getNoteName(_selectedNote!)})',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.ink,
                    ),
                  ),
                  SizedBox(height: AppSpacing.space2),

                  // 주파수 + 정확도
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppColors.paperOk,
                      ),
                      SizedBox(width: AppSpacing.space2),
                      Text(
                        '${_getFrequency(_selectedNote!)} · 정확히 맞췄어요!',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.paperOk,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoteChip(String note, String noteName) {
    final isSelected = _selectedNote == note;

    return ChoiceChip(
      key: ValueKey('student_tutorial_tuner_chip_$note'),
      label: Text('$note ($noteName)'),
      selected: isSelected,
      selectedColor: AppColors.paperAccentSoft,
      onSelected: (_) => _onSelect(note),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      side:
          isSelected
              ? BorderSide(color: AppColors.paperAccent, width: 1)
              : BorderSide.none,
    );
  }
}
