import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../profile/domain/entities/teacher_profile.dart';
import '../../../search/presentation/providers/teacher_search_provider.dart';
import '../../domain/entities/subscription_proposal.dart';
import '../../domain/entities/subscription_template.dart';
import '../providers/subscription_proposal_providers.dart';
import '../providers/subscription_template_providers.dart';

/// Screen for students to view and respond to a subscription proposal.
class ProposalDetailScreen extends ConsumerStatefulWidget {
  final String proposalId;

  const ProposalDetailScreen({
    super.key,
    required this.proposalId,
  });

  @override
  ConsumerState<ProposalDetailScreen> createState() =>
      _ProposalDetailScreenState();
}

class _ProposalDetailScreenState extends ConsumerState<ProposalDetailScreen> {
  bool _isProcessing = false;
  // v4: Selected template for multi-choice proposals
  String? _selectedTemplateId;

  @override
  Widget build(BuildContext context) {
    final proposalAsync =
        ref.watch(subscriptionProposalProvider(widget.proposalId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('수강권 제안'),
        centerTitle: true,
      ),
      // 처리 중일 때는 provider 상태 변화로 인한 UI 깜빡임 방지
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : proposalAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('오류: $e')),
              data: (proposal) {
                if (proposal == null) {
                  return const Center(child: Text('제안을 찾을 수 없습니다'));
                }

                return _buildContent(proposal);
              },
            ),
      // Fixed bottom action bar
      bottomNavigationBar: proposalAsync.whenOrNull(
        data: (proposal) {
          if (proposal == null || !proposal.canRespond || _isProcessing) {
            return null;
          }
          return _buildBottomActionBar(proposal);
        },
      ),
    );
  }

  Widget _buildContent(SubscriptionProposal proposal) {
    // v4: Handle multi-choice proposals
    if (proposal.isMultiChoice) {
      return _buildMultiChoiceContent(proposal);
    }

    // Single template proposal (original flow)
    final templateAsync =
        ref.watch(subscriptionTemplateProvider(proposal.templateId));

    return templateAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('오류: $e')),
      data: (template) {
        if (template == null) {
          return const Center(child: Text('템플릿을 찾을 수 없습니다'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status banner (if not pending)
              if (proposal.status != ProposalStatus.pending)
                _buildStatusBanner(proposal),

              // Proposal header card
              _buildProposalCard(proposal, template),

              const SizedBox(height: AppSpacing.space6),

              // Proposal details
              _buildDetailsCard(template),

              // Teacher message
              if (proposal.message != null) ...[
                const SizedBox(height: AppSpacing.space6),
                _buildMessageCard(proposal.message!),
              ],

              // Discount info
              if (proposal.hasDiscount) ...[
                const SizedBox(height: AppSpacing.space6),
                _buildDiscountCard(proposal, template),
              ],

              // Payment info (only show for pending proposals)
              if (proposal.status == ProposalStatus.pending) ...[
                const SizedBox(height: AppSpacing.space6),
                _buildPaymentCard(proposal, template),
              ],

              // Waiting message (for paymentNotified status)
              if (proposal.status == ProposalStatus.paymentNotified) ...[
                const SizedBox(height: AppSpacing.space6),
                _buildWaitingCard(proposal),
              ],

              // Add bottom padding for fixed action bar
              if (proposal.canRespond)
                const SizedBox(height: AppSpacing.space8),
            ],
          ),
        );
      },
    );
  }

  /// v4: Multi-choice proposal content
  Widget _buildMultiChoiceContent(SubscriptionProposal proposal) {
    // Initialize selected template from proposal or use recommended
    _selectedTemplateId ??=
        proposal.selectedTemplateId ?? proposal.effectiveRecommendedTemplateId;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner (if not pending)
          if (proposal.status != ProposalStatus.pending)
            _buildStatusBanner(proposal),

          // Multi-choice header
          _buildMultiChoiceHeader(proposal),

          const SizedBox(height: AppSpacing.space6),

          // Teacher message
          if (proposal.message != null) ...[
            _buildMessageCard(proposal.message!),
            const SizedBox(height: AppSpacing.space6),
          ],

          // Template selection (only for pending)
          if (proposal.canRespond) ...[
            Text(
              '수강권을 선택하세요',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            _buildTemplateSelection(proposal),
            const SizedBox(height: AppSpacing.space6),
          ],

          // Selected template details
          _buildSelectedTemplateDetails(proposal),

          // Discount info
          if (proposal.hasDiscount) ...[
            const SizedBox(height: AppSpacing.space6),
            _buildMultiChoiceDiscountCard(proposal),
          ],

          // Payment info (only show for pending proposals)
          if (proposal.status == ProposalStatus.pending) ...[
            const SizedBox(height: AppSpacing.space6),
            _buildMultiChoicePaymentCard(proposal),
          ],

          // Waiting message (for paymentNotified status)
          if (proposal.status == ProposalStatus.paymentNotified) ...[
            const SizedBox(height: AppSpacing.space6),
            _buildWaitingCard(proposal),
          ],

          // Add bottom padding for fixed action bar
          if (proposal.canRespond)
            const SizedBox(height: AppSpacing.space8),
        ],
      ),
    );
  }

  Widget _buildMultiChoiceHeader(SubscriptionProposal proposal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          // Icon (smaller, rounded square)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.card_giftcard,
              size: 24,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.space3),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row with badge
                Row(
                  children: [
                    Text(
                      '수강권 제안',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (proposal.isAutoProposal) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '자동 발송',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.info,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.space1),

                // Subtitle: 선생님 제안 or 만료 정보
                if (proposal.status == ProposalStatus.pending)
                  Text(
                    proposal.formattedExpiration,
                    style: AppTypography.bodySmall.copyWith(
                      color: proposal.timeUntilExpiration.inDays < 2
                          ? AppColors.warning
                          : AppColors.textSecondaryLight,
                    ),
                  )
                else if (!proposal.isAutoProposal)
                  Text(
                    '선생님이 보낸 제안',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSelection(SubscriptionProposal proposal) {
    return Column(
      children: proposal.allTemplateIds.map((templateId) {
        final templateAsync =
            ref.watch(subscriptionTemplateProvider(templateId));
        final isSelected = _selectedTemplateId == templateId;
        final isRecommended = proposal.isRecommended(templateId);

        return templateAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => const SizedBox.shrink(),
          data: (template) {
            if (template == null) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedTemplateId = templateId;
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
                      color:
                          isSelected ? AppColors.primary : AppColors.borderLight,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Radio indicator
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.borderLight,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Center(
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary,
                                  ),
                                ),
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.warning.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('⭐',
                                            style: TextStyle(fontSize: 10)),
                                        const SizedBox(width: 2),
                                        Text(
                                          '추천',
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.warning,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
                          ],
                        ),
                      ),

                      // Price
                      Text(
                        template.formattedPrice,
                        style: AppTypography.headingSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildSelectedTemplateDetails(SubscriptionProposal proposal) {
    final effectiveTemplateId = _selectedTemplateId ?? proposal.effectiveTemplateId;
    final templateAsync =
        ref.watch(subscriptionTemplateProvider(effectiveTemplateId));

    return templateAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const SizedBox.shrink(),
      data: (template) {
        if (template == null) return const SizedBox.shrink();
        return _buildDetailsCard(template);
      },
    );
  }

  Widget _buildMultiChoiceDiscountCard(SubscriptionProposal proposal) {
    final effectiveTemplateId = _selectedTemplateId ?? proposal.effectiveTemplateId;
    final templateAsync =
        ref.watch(subscriptionTemplateProvider(effectiveTemplateId));

    return templateAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (template) {
        if (template == null) return const SizedBox.shrink();
        return _buildDiscountCard(proposal, template);
      },
    );
  }

  Widget _buildMultiChoicePaymentCard(SubscriptionProposal proposal) {
    final effectiveTemplateId = _selectedTemplateId ?? proposal.effectiveTemplateId;
    final templateAsync =
        ref.watch(subscriptionTemplateProvider(effectiveTemplateId));

    return templateAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (template) {
        if (template == null) return const SizedBox.shrink();
        return _buildPaymentCard(proposal, template);
      },
    );
  }

  Widget _buildStatusBanner(SubscriptionProposal proposal) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String message;

    switch (proposal.status) {
      case ProposalStatus.paymentNotified:
        backgroundColor = AppColors.info.withValues(alpha: 0.1);
        textColor = AppColors.info;
        icon = Icons.schedule;
        message = '입금 확인을 기다리고 있습니다';
        break;
      case ProposalStatus.confirmed:
        backgroundColor = AppColors.success.withValues(alpha: 0.1);
        textColor = AppColors.success;
        icon = Icons.check_circle;
        message = '수강권이 발급되었습니다!';
        break;
      case ProposalStatus.rejected:
        backgroundColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
        icon = Icons.cancel;
        message = '스킵한 제안입니다';
        break;
      case ProposalStatus.expired:
        backgroundColor = AppColors.textTertiaryLight.withValues(alpha: 0.1);
        textColor = AppColors.textTertiaryLight;
        icon = Icons.timer_off;
        message = '제안이 만료되었습니다';
        break;
      case ProposalStatus.cancelled:
        backgroundColor = AppColors.textTertiaryLight.withValues(alpha: 0.1);
        textColor = AppColors.textTertiaryLight;
        icon = Icons.block;
        message = '선생님이 제안을 취소했습니다';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyMedium.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProposalCard(
      SubscriptionProposal proposal, SubscriptionTemplate template) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.card_giftcard,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),

          // Template name
          Text(
            template.name,
            style: AppTypography.headingMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),

          // Teacher name placeholder
          Text(
            '선생님 제안',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondaryLight),
          ),

          // Expiration info
          if (proposal.status == ProposalStatus.pending) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              proposal.formattedExpiration,
              style: AppTypography.caption.copyWith(
                color: proposal.timeUntilExpiration.inDays < 2
                    ? AppColors.warning
                    : AppColors.textTertiaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsCard(SubscriptionTemplate template) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          _buildDetailRow('금액', template.formattedPrice),
          const Divider(height: 24),
          _buildDetailRow('횟수', '${template.totalLessons}회'),
          const Divider(height: 24),
          _buildDetailRow('레슨시간', '${template.lessonDurationMinutes}분'),
          const Divider(height: 24),
          _buildDetailRow('유효기간', '결제일로부터 ${template.formattedValidity}'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.space1),
              Text(
                '선생님 메시지',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            message,
            style: AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountCard(
      SubscriptionProposal proposal, SubscriptionTemplate template) {
    final originalPrice = template.price;
    final discountedPrice = originalPrice - (proposal.discountAmount ?? 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer, size: 18, color: AppColors.warning),
              const SizedBox(width: AppSpacing.space1),
              Text(
                proposal.discountReason ?? '할인 적용',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '정가',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondaryLight),
              ),
              Text(
                template.formattedPrice,
                style: AppTypography.bodySmall.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '할인',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondaryLight),
              ),
              Text(
                '-${_formatPrice(proposal.discountAmount ?? 0)}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '결제가',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _formatPrice(discountedPrice),
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(
      SubscriptionProposal proposal, SubscriptionTemplate template) {
    // Get teacher profile for bank account info
    final teacherProfileAsync = ref.watch(teacherFullProfileProvider(proposal.teacherId));

    return teacherProfileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _buildPaymentCardWithInfo(null),
      data: (profile) => _buildPaymentCardWithInfo(profile?.bankAccount),
    );
  }

  Widget _buildPaymentCardWithInfo(BankAccount? bankAccount) {
    // Fallback for no bank account
    final bankName = bankAccount?.bankName ?? '계좌 미등록';
    final accountNumber = bankAccount?.accountNumber ?? '-';
    final accountHolder = bankAccount?.accountHolder ?? '-';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.space1),
              Text(
                '결제 정보',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),
          _buildPaymentInfoRow('은행', bankName),
          const SizedBox(height: AppSpacing.space2),
          _buildPaymentInfoRow('계좌번호', accountNumber,
              copyable: true, copyValue: accountNumber),
          const SizedBox(height: AppSpacing.space2),
          _buildPaymentInfoRow('예금주', accountHolder),
        ],
      ),
    );
  }

  Widget _buildPaymentInfoRow(String label, String value,
      {bool copyable = false, String? copyValue}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium
              .copyWith(color: AppColors.textSecondaryLight),
        ),
        Row(
          children: [
            Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (copyable) ...[
              const SizedBox(width: AppSpacing.space2),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: copyValue ?? value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('계좌번호가 복사되었습니다'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '복사',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildWaitingCard(SubscriptionProposal proposal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.hourglass_empty, size: 48, color: AppColors.info),
          const SizedBox(height: AppSpacing.space4),
          Text(
            '입금 확인 대기중',
            style: AppTypography.headingSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '선생님이 입금을 확인하면 수강권이 발급됩니다.\n입금 확인까지 1~2일 정도 소요될 수 있습니다.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          OutlinedButton.icon(
            onPressed: () => _showContactOptions(proposal),
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: const Text('선생님께 문의하기'),
          ),
        ],
      ),
    );
  }

  /// Show contact options dialog (call/message)
  void _showContactOptions(SubscriptionProposal proposal) {
    // Get teacher profile for contact info
    final teacherProfileAsync = ref.read(teacherFullProfileProvider(proposal.teacherId));

    teacherProfileAsync.whenOrNull(
      data: (profile) {
        if (profile == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('선생님 정보를 찾을 수 없습니다')),
          );
          return;
        }

        final phoneNumber = profile.verification.phoneNumber;
        if (phoneNumber == null || phoneNumber.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('선생님 연락처 정보가 없습니다')),
          );
          return;
        }

        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${profile.name} 선생님께 연락하기',
                    style: AppTypography.headingSmall,
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.success,
                      child: Icon(Icons.call, color: Colors.white),
                    ),
                    title: const Text('전화하기'),
                    subtitle: Text(phoneNumber),
                    onTap: () {
                      Navigator.pop(context);
                      _launchPhone(phoneNumber);
                    },
                  ),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.info,
                      child: const Icon(Icons.message, color: Colors.white),
                    ),
                    title: const Text('문자 보내기'),
                    subtitle: Text(phoneNumber),
                    onTap: () {
                      Navigator.pop(context);
                      _launchSms(phoneNumber);
                    },
                  ),
                  const SizedBox(height: AppSpacing.space4),
                ],
              ),
            ),
          ),
        );
      },
    );

    // If data is not available, show loading or error
    if (teacherProfileAsync is AsyncLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선생님 정보를 불러오는 중...')),
      );
    } else if (teacherProfileAsync is AsyncError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선생님 정보를 불러올 수 없습니다')),
      );
    }
  }

  void _launchPhone(String phoneNumber) async {
    // Copy to clipboard (url_launcher can be added later for actual call)
    await Clipboard.setData(ClipboardData(text: phoneNumber));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('전화번호가 복사되었습니다: $phoneNumber'),
          action: SnackBarAction(
            label: '확인',
            onPressed: () {},
          ),
        ),
      );
    }
  }

  void _launchSms(String phoneNumber) async {
    // Copy to clipboard (url_launcher can be added later for actual SMS)
    await Clipboard.setData(ClipboardData(text: phoneNumber));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('전화번호가 복사되었습니다: $phoneNumber'),
          action: SnackBarAction(
            label: '확인',
            onPressed: () {},
          ),
        ),
      );
    }
  }

  /// Fixed bottom action bar for proposal response
  Widget _buildBottomActionBar(SubscriptionProposal proposal) {
    // For multi-choice proposals, check if template is selected
    final bool canProceed = !proposal.isMultiChoice || _selectedTemplateId != null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selection hint for multi-choice
            if (proposal.isMultiChoice && _selectedTemplateId == null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space3,
                  vertical: AppSpacing.space2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                    const SizedBox(width: AppSpacing.space2),
                    Text(
                      '수강권을 선택해주세요',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
            ],

            // Payment complete button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_isProcessing || !canProceed)
                    ? null
                    : () => _notifyPayment(proposal),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.payment),
                label: const Text('입금 완료했어요'),
              ),
            ),

            const SizedBox(height: AppSpacing.space2),

            // Reject button
            TextButton(
              onPressed: _isProcessing ? null : () => _showRejectDialog(proposal),
              child: Text(
                '이번엔 스킵할게요',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _notifyPayment(SubscriptionProposal proposal) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final notifier = ref.read(subscriptionProposalNotifierProvider.notifier);

      // For multi-choice proposals, save selected template first
      if (proposal.isMultiChoice && _selectedTemplateId != null) {
        await notifier.selectTemplate(proposal.id, _selectedTemplateId!);
      }

      await notifier.notifyPayment(proposal.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('입금 알림을 보냈습니다'),
            backgroundColor: AppColors.success,
          ),
        );
        // Refresh the page
        ref.invalidate(subscriptionProposalProvider(proposal.id));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: $e'),
            backgroundColor: AppColors.error,
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

  Future<void> _showRejectDialog(SubscriptionProposal proposal) async {
    // 다이얼로그가 String?을 반환 (null = 취소, non-null = 스킵 + 사유)
    final reason = await showDialog<String?>(
      context: context,
      builder: (dialogContext) => _SkipReasonDialog(),
    );

    // reason이 null이 아니면 스킵 진행 (빈 문자열도 스킵 의도)
    if (reason != null && mounted) {
      await _rejectProposal(proposal, reason.isEmpty ? null : reason);
    }
  }

  Future<void> _rejectProposal(
      SubscriptionProposal proposal, String? reason) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final notifier = ref.read(subscriptionProposalNotifierProvider.notifier);
      await notifier.reject(proposal.id, reason);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('이번 제안을 스킵했습니다'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: $e'),
            backgroundColor: AppColors.error,
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

  String _formatPrice(int price) {
    if (price >= 10000) {
      final man = price ~/ 10000;
      final remainder = price % 10000;
      if (remainder == 0) {
        return '$man만원';
      }
      return '$man만 $remainder원';
    }
    return '$price원';
  }
}

/// 스킵 사유 입력 다이얼로그
/// TextEditingController 생명주기를 자체적으로 관리하여
/// 부모 위젯 rebuild로 인한 controller disposed 에러 방지
class _SkipReasonDialog extends StatefulWidget {
  @override
  State<_SkipReasonDialog> createState() => _SkipReasonDialogState();
}

class _SkipReasonDialogState extends State<_SkipReasonDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('이번엔 스킵'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('이번 제안을 스킵하시겠습니까?\n나중에 다시 제안받을 수 있어요.'),
          const SizedBox(height: AppSpacing.space4),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: '사유 (선택)',
              hintText: '선생님께 전달할 메시지',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('스킵하기'),
        ),
      ],
    );
  }
}
