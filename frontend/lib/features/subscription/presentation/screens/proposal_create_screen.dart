import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../students/presentation/providers/student_crud_provider.dart';
import '../../domain/entities/subscription_template.dart';
import '../providers/subscription_template_providers.dart';
import '../providers/subscription_proposal_providers.dart';

/// Screen for teachers to create a subscription proposal.
class ProposalCreateScreen extends ConsumerStatefulWidget {
  final String teacherId;
  final String teacherName; // 🆕 For notification
  final String? preselectedStudentId;

  const ProposalCreateScreen({
    super.key,
    required this.teacherId,
    this.teacherName = '선생님', // 🆕 Default value
    this.preselectedStudentId,
  });

  @override
  ConsumerState<ProposalCreateScreen> createState() =>
      _ProposalCreateScreenState();
}

class _ProposalCreateScreenState extends ConsumerState<ProposalCreateScreen> {
  String? _selectedStudentId;
  // v4: Multi-select with checkboxes - default to all selected
  final Set<String> _selectedTemplateIds = {};
  String? _recommendedTemplateId;
  final _messageController = TextEditingController();
  bool _isSubmitting = false;
  bool _hasInitializedTemplates = false;

  @override
  void initState() {
    super.initState();
    _selectedStudentId = widget.preselectedStudentId;
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);
    final templatesAsync =
        ref.watch(activeTeacherTemplatesProvider(widget.teacherId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('수강권 제안'),
        centerTitle: true,
      ),
      body: studentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('오류가 발생했습니다.')),
        data: (students) {
          if (students.isEmpty) {
            return _buildNoStudentsState();
          }

          return templatesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('오류가 발생했습니다.')),
            data: (templates) {
              if (templates.isEmpty) {
                return _buildNoTemplatesState();
              }

              return _buildForm(students, templates);
            },
          );
        },
      ),
    );
  }

  Widget _buildNoStudentsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline,
              size: 64, color: AppColors.textSecondaryLight),
          const SizedBox(height: AppSpacing.space4),
          Text(
            '등록된 학생이 없습니다',
            style: AppTypography.bodyLarge
                .copyWith(color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '학생을 먼저 추가해주세요',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textTertiaryLight),
          ),
        ],
      ),
    );
  }

  Widget _buildNoTemplatesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 64, color: AppColors.textSecondaryLight),
          const SizedBox(height: AppSpacing.space4),
          Text(
            '수강권 템플릿이 없습니다',
            style: AppTypography.bodyLarge
                .copyWith(color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '먼저 수강권 템플릿을 생성해주세요',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textTertiaryLight),
          ),
          const SizedBox(height: AppSpacing.space6),
          ElevatedButton.icon(
            onPressed: () {
              context.push(
                  '/subscriptions/templates?teacherId=${widget.teacherId}');
            },
            icon: const Icon(Icons.add),
            label: const Text('템플릿 만들기'),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(List students, List<SubscriptionTemplate> templates) {
    // Initialize all templates as selected by default (once)
    if (!_hasInitializedTemplates && templates.isNotEmpty) {
      _hasInitializedTemplates = true;
      // Select all templates by default
      for (final template in templates) {
        _selectedTemplateIds.add(template.id);
      }
      // Set first template as recommended
      _recommendedTemplateId = templates.first.id;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student Selection
          _buildSectionTitle('학생 선택'),
          const SizedBox(height: AppSpacing.space2),
          _buildStudentSelector(students),

          const SizedBox(height: AppSpacing.space6),

          // Template Selection
          _buildSectionTitle('수강권 선택'),
          const SizedBox(height: AppSpacing.space2),
          _buildTemplateSelector(templates),

          const SizedBox(height: AppSpacing.space6),

          // Optional Message
          _buildSectionTitle('메시지 (선택)'),
          const SizedBox(height: AppSpacing.space2),
          _buildMessageInput(),

          const SizedBox(height: AppSpacing.space8),

          // Submit Button
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.bodyMedium.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildStudentSelector(List students) {
    // Validate selected student exists in list
    final validStudentIds = students.map((s) => s.id as String).toSet();
    final effectiveSelection = (_selectedStudentId != null &&
            validStudentIds.contains(_selectedStudentId))
        ? _selectedStudentId
        : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: DropdownButtonFormField<String>(
        value: effectiveSelection,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
          hintText: '학생을 선택하세요',
        ),
        isExpanded: true,
        items: students.map<DropdownMenuItem<String>>((student) {
          return DropdownMenuItem<String>(
            value: student.id,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    student.name[0],
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
                Flexible(
                  child: Text(
                    student.name,
                    style: AppTypography.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedStudentId = value;
          });
        },
      ),
    );
  }

  Widget _buildTemplateSelector(List<SubscriptionTemplate> templates) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Help text for multi-select
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: AppColors.info),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '전체 선택됨. 제외할 수강권을 해제하세요. 학생이 하나를 선택합니다.',
                  style: AppTypography.caption.copyWith(color: AppColors.info),
                ),
              ),
            ],
          ),
        ),

        // Template list with checkboxes
        ...templates.map((template) {
          final isSelected = _selectedTemplateIds.contains(template.id);
          final isRecommended = _recommendedTemplateId == template.id;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedTemplateIds.remove(template.id);
                    // Remove recommended if unchecked
                    if (_recommendedTemplateId == template.id) {
                      _recommendedTemplateId = null;
                    }
                  } else {
                    _selectedTemplateIds.add(template.id);
                    // Auto-set first selection as recommended
                    _recommendedTemplateId ??= template.id;
                  }
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.05)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.borderLight,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Checkbox indicator
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.borderLight,
                          width: 2,
                        ),
                        color: isSelected ? AppColors.primary : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.space3),

                    // Template info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                template.name,
                                style: AppTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (isRecommended) ...[
                                const SizedBox(width: 4),
                                const Text('⭐', style: TextStyle(fontSize: 14)),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppSpacing.space1),
                          Text(
                            template.summaryText,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                          if (template.description != null) ...[
                            const SizedBox(height: AppSpacing.space1),
                            Text(
                              template.description!,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textTertiaryLight,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Price + recommend star button
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          template.formattedPrice,
                          style: AppTypography.headingSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (isSelected && _selectedTemplateIds.length > 1) ...[
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _recommendedTemplateId = template.id;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isRecommended
                                    ? AppColors.warning.withValues(alpha: 0.2)
                                    : AppColors.surfaceSecondaryLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isRecommended ? '추천 ⭐' : '추천 지정',
                                style: AppTypography.caption.copyWith(
                                  color: isRecommended
                                      ? AppColors.warning
                                      : AppColors.textSecondaryLight,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        // Selected count indicator
        if (_selectedTemplateIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${_selectedTemplateIds.length}개 선택됨${_selectedTemplateIds.length > 1 ? ' (학생이 1개 선택)' : ''}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: TextField(
        controller: _messageController,
        maxLines: 3,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.all(16),
          border: InputBorder.none,
          hintText: '학생에게 전달할 메시지를 입력하세요',
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit = _selectedStudentId != null &&
        _selectedTemplateIds.isNotEmpty &&
        !_isSubmitting;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canSubmit ? _submitProposal : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(_selectedTemplateIds.length > 1
                ? '${_selectedTemplateIds.length}개 수강권 제안 보내기'
                : '제안 보내기'),
      ),
    );
  }

  Future<void> _submitProposal() async {
    if (_selectedStudentId == null || _selectedTemplateIds.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final notifier = ref.read(subscriptionProposalNotifierProvider.notifier);

      // 🆕 Get template name for notification
      final templateId = _selectedTemplateIds.first;
      final templateAsync = ref.read(subscriptionTemplateProvider(templateId));
      final templateName = templateAsync.valueOrNull?.name ?? '수강권';

      // v4: Use multi-choice proposal
      await notifier.createMultiChoiceProposal(
        teacherId: widget.teacherId,
        studentId: _selectedStudentId!,
        templateIds: _selectedTemplateIds.toList(),
        recommendedTemplateId:
            _selectedTemplateIds.length > 1 ? _recommendedTemplateId : null,
        message:
            _messageController.text.isEmpty ? null : _messageController.text,
        // 🆕 For notification
        teacherName: widget.teacherName,
        templateName: templateName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_selectedTemplateIds.length > 1
                ? '${_selectedTemplateIds.length}개 수강권 제안을 보냈습니다'
                : '수강권 제안을 보냈습니다'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('제안 실패. 다시 시도해주세요.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
