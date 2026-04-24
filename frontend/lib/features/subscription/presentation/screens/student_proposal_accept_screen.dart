import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../search/presentation/providers/teacher_search_provider.dart';
import '../../domain/entities/subscription_proposal.dart';
import '../providers/subscription_proposal_providers.dart';
import '../providers/subscription_template_providers.dart';
import '../widgets/template_choice_card.dart';

/// Screen where a student views and accepts a teacher's subscription proposal.
///
/// Displays up to 3 template choices with a recommended badge,
/// per-lesson price, duration estimates, and bank account info for payment.
class StudentProposalAcceptScreen extends ConsumerStatefulWidget {
  final String proposalId;

  const StudentProposalAcceptScreen({super.key, required this.proposalId});

  @override
  ConsumerState<StudentProposalAcceptScreen> createState() =>
      _StudentProposalAcceptScreenState();
}

class _StudentProposalAcceptScreenState
    extends ConsumerState<StudentProposalAcceptScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final proposalAsync = ref.watch(
      subscriptionProposalProvider(widget.proposalId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('수강권 선택'), centerTitle: true),
      body:
          _isProcessing
              ? const Center(child: CircularProgressIndicator())
              : proposalAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('오류가 발생했습니다.')),
                data: (proposal) {
                  if (proposal == null) {
                    return const Center(child: Text('제안을 찾을 수 없습니다'));
                  }
                  return _buildBody(proposal);
                },
              ),
    );
  }

  Widget _buildBody(SubscriptionProposal proposal) {
    final teacherAsync = ref.watch(
      teacherFullProfileProvider(proposal.teacherId),
    );
    final teacherName =
        teacherAsync.whenOrNull(data: (profile) => profile?.name) ?? '선생님';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          _buildHeader(teacherName),
          if (proposal.message != null && proposal.message!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space4),
            _buildMessageBubble(proposal.message!),
          ],
          const SizedBox(height: AppSpacing.space6),
          _buildTemplateCards(proposal),
          const SizedBox(height: AppSpacing.space4),
          _buildDeclineButton(proposal),
          const SizedBox(height: AppSpacing.space6),
          _buildBankAccountSection(proposal),
          const SizedBox(height: AppSpacing.space8),
        ],
      ),
    );
  }

  Widget _buildHeader(String teacherName) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.space4),
        Text(
          '$teacherName 선생님',
          style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          '수강권을 제안했어요',
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
      ],
    );
  }

  Widget _buildMessageBubble(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: AppColors.paperAccent.withValues(alpha: 0.06),
      ),
      child: Text(
        '"$message"',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.paperAccent,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTemplateCards(SubscriptionProposal proposal) {
    final templateIds = proposal.allTemplateIds;

    return Column(
      children:
          templateIds.map((templateId) {
            final templateAsync = ref.watch(
              subscriptionTemplateProvider(templateId),
            );
            final isRecommended = proposal.isRecommended(templateId);

            return templateAsync.when(
              loading:
                  () => const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.space3),
                    child: SizedBox(
                      height: 140,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              error: (_, __) => const SizedBox.shrink(),
              data: (template) {
                if (template == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                  child: TemplateChoiceCard(
                    template: template,
                    isRecommended: isRecommended,
                    isProcessing: _isProcessing,
                    onAccept: () => _handleAccept(proposal, templateId),
                  ),
                );
              },
            );
          }).toList(),
    );
  }

  Widget _buildDeclineButton(SubscriptionProposal proposal) {
    return TextButton(
      onPressed: _isProcessing ? null : () => _handleReject(proposal),
      child: Text(
        '다음에 할게요',
        style: AppTypography.bodyMedium.copyWith(color: AppColors.inkSecondary),
      ),
    );
  }

  Widget _buildBankAccountSection(SubscriptionProposal proposal) {
    final teacherProfileAsync = ref.watch(
      teacherFullProfileProvider(proposal.teacherId),
    );

    return teacherProfileAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (profile) {
        final bankAccount = profile?.defaultBankAccount;
        if (bankAccount == null) return const SizedBox.shrink();

        final accountText =
            '${bankAccount.bankName} ${bankAccount.accountNumber} (${bankAccount.accountHolder})';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionDivider('결제 안내'),
            const SizedBox(height: AppSpacing.space3),
            _buildAccountRow(accountText),
            const SizedBox(height: AppSpacing.space2),
            Text(
              '선택 후 위 계좌로 입금해 주세요',
              style: AppTypography.caption.copyWith(
                color: AppColors.inkTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionDivider(String label) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.inkQuaternary)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3),
          child: Text(
            label,
            style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.inkQuaternary)),
      ],
    );
  }

  Widget _buildAccountRow(String accountText) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => _copyToClipboard(accountText),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space2,
                vertical: AppSpacing.space1,
              ),
              decoration: BoxDecoration(
                color: AppColors.paperAccent.withValues(alpha: 0.1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.copy,
                    size: AppSpacing.iconXS,
                    color: AppColors.paperAccent,
                  ),
                  const SizedBox(width: AppSpacing.space1),
                  Text(
                    '복사',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.paperAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Text(
              accountText,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Actions
  // ------------------------------------------------------------------

  Future<void> _handleAccept(
    SubscriptionProposal proposal,
    String templateId,
  ) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final notifier = ref.read(subscriptionProposalNotifierProvider.notifier);

      // For multi-choice proposals, save selected template first
      if (proposal.isMultiChoice) {
        await notifier.selectTemplate(proposal.id, templateId);
      }

      // Notify payment (student selected and will pay)
      await notifier.notifyPayment(proposal.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('수강권을 선택했습니다'),
            backgroundColor: AppColors.paperOk,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('오류가 발생했습니다. 다시 시도해주세요.'),
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleReject(SubscriptionProposal proposal) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final notifier = ref.read(subscriptionProposalNotifierProvider.notifier);
      await notifier.reject(proposal.id, null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('다음에 다시 제안 받을 수 있어요'),
            backgroundColor: AppColors.ink,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('오류가 발생했습니다. 다시 시도해주세요.'),
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('계좌번호가 복사되었습니다'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
}
