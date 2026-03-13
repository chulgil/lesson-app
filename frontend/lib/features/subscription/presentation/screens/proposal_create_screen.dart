import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../students/presentation/providers/student_crud_provider.dart';
import '../../domain/entities/subscription_proposal.dart';
import '../../domain/entities/subscription_template.dart';
import '../providers/subscription_template_providers.dart';
import '../providers/subscription_proposal_providers.dart';
import '../widgets/selectable_template_card.dart';

/// Screen for teachers to create a subscription proposal.
///
/// Template-First 3-Step UX:
/// 1. Student selection (dropdown)
/// 2. Template selection (SelectableTemplateCard, max 3)
/// 3. Action branch: propose (async) or direct issue (immediate)
class ProposalCreateScreen extends ConsumerStatefulWidget {
  final String teacherId;
  final String teacherName;
  final String? preselectedStudentId;

  const ProposalCreateScreen({
    super.key,
    required this.teacherId,
    this.teacherName = '선생님',
    this.preselectedStudentId,
  });

  @override
  ConsumerState<ProposalCreateScreen> createState() =>
      _ProposalCreateScreenState();
}

class _ProposalCreateScreenState extends ConsumerState<ProposalCreateScreen> {
  String? _selectedStudentId;
  final Set<String> _selectedTemplateIds = {};
  String? _recommendedTemplateId;
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

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
                  '${AppRoutes.subscriptionTemplates}?teacherId=${widget.teacherId}');
            },
            icon: const Icon(Icons.add),
            label: const Text('템플릿 만들기'),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(List students, List<SubscriptionTemplate> templates) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step 1: Student Selection
          _buildStepHeader('1', '학생 선택'),
          const SizedBox(height: AppSpacing.space2),
          _buildStudentSelector(students),

          const SizedBox(height: AppSpacing.space6),

          // Step 2: Template Selection (Selectable Cards)
          _buildStepHeader('2', '수강권 선택 (최대 $kMaxTemplateSelections개)'),
          const SizedBox(height: AppSpacing.space2),
          _buildTemplateCards(templates),

          const SizedBox(height: AppSpacing.space6),

          // Optional Message
          _buildSectionTitle('메시지 (선택)'),
          const SizedBox(height: AppSpacing.space2),
          _buildMessageInput(),

          const SizedBox(height: AppSpacing.space8),

          // Step 3: Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildStepHeader(String step, String title) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: AppTypography.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        Text(
          title,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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

  Widget _buildTemplateCards(List<SubscriptionTemplate> templates) {
    final atMax = _selectedTemplateIds.length >= kMaxTemplateSelections;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Help text
        if (_selectedTemplateIds.isEmpty)
          _buildInfoBanner('수강권을 선택하세요. 복수 선택 시 학생이 하나를 선택합니다.'),

        if (_selectedTemplateIds.length > 1)
          _buildInfoBanner(
            '${_selectedTemplateIds.length}개 선택됨 — 학생이 하나를 선택합니다. '
            '추천 지정: 카드를 길게 누르세요.',
          ),

        // Template cards
        ...templates.map((template) {
          final isSelected = _selectedTemplateIds.contains(template.id);
          final isRecommended = _recommendedTemplateId == template.id;
          final isDisabled = atMax && !isSelected;

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space2),
            child: GestureDetector(
              onLongPress: isSelected && _selectedTemplateIds.length > 1
                  ? () {
                      setState(() {
                        _recommendedTemplateId = template.id;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${template.name}을 추천으로 지정했습니다'),
                          duration: const Duration(seconds: 1),
                          backgroundColor: AppColors.secondary,
                        ),
                      );
                    }
                  : null,
              child: SelectableTemplateCard(
                template: template,
                isSelected: isSelected,
                isRecommended: isRecommended,
                isDisabled: isDisabled,
                onTap: () => _toggleTemplate(template.id),
              ),
            ),
          );
        }),

        // Selected count
        if (_selectedTemplateIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.space1),
            child: Text(
              '${_selectedTemplateIds.length}/$kMaxTemplateSelections개 선택',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoBanner(String text) {
    return Container(
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
              text,
              style: AppTypography.caption.copyWith(color: AppColors.info),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleTemplate(String templateId) {
    setState(() {
      if (_selectedTemplateIds.contains(templateId)) {
        _selectedTemplateIds.remove(templateId);
        if (_recommendedTemplateId == templateId) {
          _recommendedTemplateId =
              _selectedTemplateIds.isNotEmpty ? _selectedTemplateIds.first : null;
        }
      } else {
        if (_selectedTemplateIds.length < kMaxTemplateSelections) {
          _selectedTemplateIds.add(templateId);
          // Auto-set first selection as recommended
          _recommendedTemplateId ??= templateId;
        }
      }
    });
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

  /// Action buttons with branching logic:
  /// - 1 template: [제안 보내기] + [즉시 발급]
  /// - 2-3 templates: [제안 보내기] only (student must choose)
  Widget _buildActionButtons() {
    final canSubmit = _selectedStudentId != null &&
        _selectedTemplateIds.isNotEmpty &&
        !_isSubmitting;
    final isSingleTemplate = _selectedTemplateIds.length == 1;

    return Column(
      children: [
        // Primary: Send proposal
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canSubmit
                ? () => _submit(ProposalType.proposal)
                : null,
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
        ),

        // Secondary: Direct issue (only for single template)
        if (isSingleTemplate) ...[
          const SizedBox(height: AppSpacing.space3),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: canSubmit
                  ? () => _submit(ProposalType.directIssue)
                  : null,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: canSubmit ? AppColors.primary : AppColors.borderLight,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('즉시 발급'),
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '즉시 발급: 학생 확인 없이 바로 수강권을 발급합니다',
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Future<void> _submit(ProposalType proposalType) async {
    if (_selectedStudentId == null || _selectedTemplateIds.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (proposalType == ProposalType.directIssue) {
        // Direct issue: navigate to issue subscription screen
        final templateId = _selectedTemplateIds.first;
        if (mounted) {
          context.push(
            '${AppRoutes.issueSubscription}?studentId=$_selectedStudentId&templateId=$templateId',
          );
        }
        return;
      }

      // Proposal flow: create multi-choice proposal
      final notifier = ref.read(subscriptionProposalNotifierProvider.notifier);

      final templateId = _selectedTemplateIds.first;
      final templateAsync = ref.read(subscriptionTemplateProvider(templateId));
      final templateName = templateAsync.valueOrNull?.name ?? '수강권';

      await notifier.createMultiChoiceProposal(
        teacherId: widget.teacherId,
        studentId: _selectedStudentId!,
        templateIds: _selectedTemplateIds.toList(),
        recommendedTemplateId:
            _selectedTemplateIds.length > 1 ? _recommendedTemplateId : null,
        message:
            _messageController.text.isEmpty ? null : _messageController.text,
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
