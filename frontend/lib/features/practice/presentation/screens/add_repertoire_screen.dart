import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../providers/practice_repertoire/practice_repertoire_crud_provider.dart';
import '../../../../shared/widgets/app_date_picker.dart';
import '../widgets/section_form/date_range_section.dart';

/// Screen for adding a new repertoire
class AddRepertoireScreen extends ConsumerStatefulWidget {
  final String studentId;

  const AddRepertoireScreen({super.key, required this.studentId});

  @override
  ConsumerState<AddRepertoireScreen> createState() =>
      _AddRepertoireScreenState();
}

class _AddRepertoireScreenState extends ConsumerState<AddRepertoireScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _nameFocusNode = FocusNode();
  bool _isLoading = false;
  bool _isNameFocused = false;

  // Date fields
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  // Predefined repertoire suggestions
  final List<_RepertoireSuggestion> _suggestions = [
    _RepertoireSuggestion('스즈키 1권', '스즈키 바이올린 교본 1권'),
    _RepertoireSuggestion('스즈키 2권', '스즈키 바이올린 교본 2권'),
    _RepertoireSuggestion('스즈키 3권', '스즈키 바이올린 교본 3권'),
    _RepertoireSuggestion('스즈키 4권', '스즈키 바이올린 교본 4권'),
    _RepertoireSuggestion('스즈키 5권', '스즈키 바이올린 교본 5권'),
    _RepertoireSuggestion('스즈키 6권', '스즈키 바이올린 교본 6권'),
    _RepertoireSuggestion('크로이처 에튀드', 'Kreutzer 42 Etudes'),
    _RepertoireSuggestion('세브시크', 'Sevcik Violin Studies'),
    _RepertoireSuggestion('바흐 파르티타', 'Bach Partitas for Solo Violin'),
    _RepertoireSuggestion('바흐 소나타', 'Bach Sonatas for Solo Violin'),
    _RepertoireSuggestion('스케일/아르페지오', '스케일 및 아르페지오 연습'),
  ];

  @override
  void initState() {
    super.initState();
    _nameFocusNode.addListener(() {
      setState(() => _isNameFocused = _nameFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit({bool addSectionAfter = false}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repertoire = await ref
          .read(repertoireCrudProvider.notifier)
          .createRepertoire(
            studentId: widget.studentId,
            name: _nameController.text.trim(),
            description:
                _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
            startDate: _startDate,
            endDate: _endDate,
          );

      if (mounted) {
        if (addSectionAfter) {
          // Navigate to add section screen with the newly created repertoire
          context.pop(true);
          context.push(
            '${AppRoutes.addSection}?repertoireId=${repertoire.id}&studentId=${widget.studentId}',
          );
        } else {
          context.pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('레퍼토리 추가에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await AppDatePicker.show(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: '시작일 선택',
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // If end date is before start date, clear it
        if (_endDate != null && _endDate!.isBefore(_startDate)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await AppDatePicker.show(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime(2030),
      helpText: '종료일 선택',
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  void _clearEndDate() {
    setState(() => _endDate = null);
  }

  void _selectSuggestion(_RepertoireSuggestion suggestion) {
    _nameController.text = suggestion.name;
    _descriptionController.text = suggestion.description;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('레퍼토리 추가')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name field
              TextFormField(
                controller: _nameController,
                focusNode: _nameFocusNode,
                decoration: const InputDecoration(
                  labelText: '레퍼토리 이름 *',
                  hintText: '예: 스즈키 6권, 바흐 협주곡',
                  prefixIcon: Icon(Icons.library_music),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '레퍼토리 이름을 입력해주세요';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.space4),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '설명 (선택)',
                  hintText: '예: Bach Violin Concerto in A minor',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
                textInputAction: TextInputAction.done,
              ),

              // Suggestions section (only visible when name field is focused)
              if (_isNameFocused) ...[
                const SizedBox(height: AppSpacing.space3),

                // Suggestion chips
                Wrap(
                  spacing: AppSpacing.space2,
                  runSpacing: AppSpacing.space2,
                  children:
                      _suggestions.map((suggestion) {
                        return ActionChip(
                          label: Text(suggestion.name),
                          onPressed: () => _selectSuggestion(suggestion),
                          avatar: const Icon(Icons.add, size: 18),
                        );
                      }).toList(),
                ),
              ],

              const SizedBox(height: AppSpacing.space6),

              // Period section using DateRangeSection
              DateRangeSection(
                startDate: _startDate,
                endDate: _endDate,
                onStartDateTap: _selectStartDate,
                onEndDateTap: _selectEndDate,
                onEndDateClear: _clearEndDate,
                endDatePlaceholder: '설정 안함 (매일 반복)',
                showHintMessage: true,
              ),

              const SizedBox(height: AppSpacing.space8),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : () => _submit(),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text('레퍼토리 추가'),
                ),
              ),

              const SizedBox(height: AppSpacing.space3),

              // Add section after save button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed:
                      _isLoading ? null : () => _submit(addSectionAfter: true),
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('저장 후 섹션 추가하기'),
                ),
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(
                '💡 레퍼토리 저장 후 섹션 추가 화면으로 이동합니다',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RepertoireSuggestion {
  final String name;
  final String description;

  _RepertoireSuggestion(this.name, this.description);
}
