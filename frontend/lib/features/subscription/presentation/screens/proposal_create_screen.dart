import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/subscription_proposal.dart';
import '../../domain/entities/subscription_template.dart';
import '../providers/subscription_issue_flow_provider.dart';
import '../providers/subscription_proposal_providers.dart';
import '../providers/subscription_template_providers.dart';
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
    this.teacherName = AppStrings.teacher,
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
    final studentsAsync = ref.watch(subscriptionIssueStudentsProvider);
    final templatesAsync = ref.watch(
      activeTeacherTemplatesProvider(widget.teacherId),
    );

    return NotebookScreenScaffold(
      appBar: AppBar(
        title: const Text(AppStrings.proposalCreateAppBarTitle),
        centerTitle: true,
      ),
      body: studentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text('${AppStrings.errorOccurred}.')),
        data: (students) {
          if (students.isEmpty) {
            return _buildNoStudentsState();
          }

          return templatesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (_, __) => Center(child: Text('${AppStrings.errorOccurred}.')),
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
          Icon(Icons.people_outline, size: 64, color: AppColors.inkSecondary),
          const SizedBox(height: AppSpacing.space4),
          Text(
            AppStrings.proposalCreateNoStudentsTitle,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            AppStrings.proposalCreateNoStudentsBody,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkTertiary,
            ),
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
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: AppColors.inkSecondary,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            AppStrings.proposalCreateNoTemplatesTitle,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            AppStrings.proposalCreateNoTemplatesBody,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.space6),
          ElevatedButton.icon(
            onPressed: () {
              context.push(
                '${AppRoutes.subscriptionTemplates}?teacherId=${widget.teacherId}',
              );
            },
            icon: const Icon(Icons.add),
            label: const Text(AppStrings.proposalCreateTemplateButton),
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
          _buildStepHeader('1', AppStrings.proposalCreateStepStudent),
          const SizedBox(height: AppSpacing.space2),
          _buildStudentSelector(students),

          const SizedBox(height: AppSpacing.space6),

          // Step 2: Template Selection (Selectable Cards)
          _buildStepHeader(
            '2',
            AppStrings.proposalCreateStepTemplateMaxFormat(
              kMaxTemplateSelections,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          _buildTemplateCards(templates),

          const SizedBox(height: AppSpacing.space6),

          // Optional Message
          _buildSectionTitle(AppStrings.proposalCreateMessageOptional),
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
          decoration: BoxDecoration(color: AppColors.paperAccent),
          alignment: Alignment.center,
          child: Text(
            step,
            style: AppTypography.caption.copyWith(
              color: AppColors.paper,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        Text(
          title,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _buildStudentSelector(List students) {
    // Validate selected student exists in list
    final validStudentIds = students.map((s) => s.id as String).toSet();
    final effectiveSelection =
        (_selectedStudentId != null &&
                validStudentIds.contains(_selectedStudentId))
            ? _selectedStudentId
            : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: effectiveSelection,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
          border: InputBorder.none,
          hintText: AppStrings.proposalCreateStudentSelectHint,
        ),
        isExpanded: true,
        items:
            students.map<DropdownMenuItem<String>>((student) {
              return DropdownMenuItem<String>(
                value: student.id,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.paperAccentSoft,
                      child: Text(
                        student.name[0],
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.paperAccent,
                        ),
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
          _buildInfoBanner(AppStrings.proposalCreateTemplateInfoBanner),

        if (_selectedTemplateIds.length > 1)
          _buildInfoBanner(
            AppStrings.proposalCreateMultiSelectInfoFormat(
                  _selectedTemplateIds.length,
                ) +
                AppStrings.proposalCreateRecommendedHint,
          ),

        // Template cards
        ...templates.map((template) {
          final isSelected = _selectedTemplateIds.contains(template.id);
          final isRecommended = _recommendedTemplateId == template.id;
          final isDisabled = atMax && !isSelected;

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space2),
            child: GestureDetector(
              onLongPress:
                  isSelected && _selectedTemplateIds.length > 1
                      ? () {
                        setState(() {
                          _recommendedTemplateId = template.id;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppStrings.proposalCreateRecommendedDesignatedFormat(
                                template.name,
                              ),
                            ),
                            duration: const Duration(seconds: 1),
                            backgroundColor: AppColors.paperAccent,
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
              AppStrings.proposalCreateSelectedCountFormat(
                _selectedTemplateIds.length,
                kMaxTemplateSelections,
              ),
              style: AppTypography.caption.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoBanner(String text) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      decoration: BoxDecoration(color: AppColors.ink.withValues(alpha: 0.1)),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.ink),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              text,
              style: AppTypography.caption.copyWith(color: AppColors.ink),
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
              _selectedTemplateIds.isNotEmpty
                  ? _selectedTemplateIds.first
                  : null;
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
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: TextField(
        controller: _messageController,
        maxLines: 3,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.all(AppSpacing.space4),
          border: InputBorder.none,
          hintText: AppStrings.proposalCreateMessageHint,
        ),
      ),
    );
  }

  /// Action buttons with branching logic:
  /// - 1 template: [제안 보내기] + [즉시 발급]
  /// - 2-3 templates: [제안 보내기] only (student must choose)
  Widget _buildActionButtons() {
    final canSubmit =
        _selectedStudentId != null &&
        _selectedTemplateIds.isNotEmpty &&
        !_isSubmitting;
    final isSingleTemplate = _selectedTemplateIds.length == 1;

    return Column(
      children: [
        // Primary: Send proposal
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canSubmit ? () => _submit(ProposalType.proposal) : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
              shape: RoundedRectangleBorder(),
            ),
            child:
                _isSubmitting
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Text(
                      _selectedTemplateIds.length > 1
                          ? AppStrings.proposalCreateMultiTemplateSendFormat(
                            _selectedTemplateIds.length,
                          )
                          : AppStrings.proposalSend,
                    ),
          ),
        ),

        // Secondary: Direct issue (only for single template)
        if (isSingleTemplate) ...[
          const SizedBox(height: AppSpacing.space3),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed:
                  canSubmit ? () => _submit(ProposalType.directIssue) : null,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.space4,
                ),
                side: BorderSide(
                  color:
                      canSubmit
                          ? AppColors.paperAccent
                          : AppColors.inkQuaternary,
                ),
                shape: RoundedRectangleBorder(),
              ),
              child: const Text(AppStrings.proposalTypeDirectIssue),
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            AppStrings.proposalCreateImmediateIssueHelp,
            style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
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
      final templateName =
          templateAsync.valueOrNull?.name ?? AppStrings.subscription;

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
            content: Text(
              _selectedTemplateIds.length > 1
                  ? AppStrings.proposalCreateMultiSentMessageFormat(
                    _selectedTemplateIds.length,
                  )
                  : AppStrings.proposalCreateSentMessage,
            ),
            backgroundColor: AppColors.paperOk,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.proposalCreateFailMessage),
            backgroundColor: AppColors.paperAccent,
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
