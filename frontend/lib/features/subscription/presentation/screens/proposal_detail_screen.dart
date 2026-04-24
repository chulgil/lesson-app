import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../search/presentation/providers/teacher_search_provider.dart';
import '../../domain/entities/subscription_proposal.dart';
import '../../domain/entities/subscription_template.dart';
import '../providers/subscription_proposal_providers.dart';
import '../providers/subscription_template_providers.dart';
import '../widgets/proposal_card_widgets.dart';
import '../widgets/skip_reason_dialog.dart';

/// Screen for students to view and respond to a subscription proposal.
class ProposalDetailScreen extends ConsumerStatefulWidget {
  final String proposalId;

  const ProposalDetailScreen({super.key, required this.proposalId});

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
    final proposalAsync = ref.watch(
      subscriptionProposalProvider(widget.proposalId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('수강권 제안'), centerTitle: true),
      // 처리 중일 때는 provider 상태 변화로 인한 UI 깜빡임 방지
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
    final templateAsync = ref.watch(
      subscriptionTemplateProvider(proposal.templateId),
    );

    return templateAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('오류가 발생했습니다.')),
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
                ProposalStatusBanner(proposal: proposal),

              // Proposal header card
              ProposalHeaderCard(proposal: proposal, template: template),

              const SizedBox(height: AppSpacing.space6),

              // Proposal details
              ProposalDetailsCard(template: template),

              // Teacher message
              if (proposal.message != null) ...[
                const SizedBox(height: AppSpacing.space6),
                ProposalMessageCard(message: proposal.message!),
              ],

              // Discount info
              if (proposal.hasDiscount) ...[
                const SizedBox(height: AppSpacing.space6),
                ProposalDiscountCard(proposal: proposal, template: template),
              ],

              // Payment info (only show for pending proposals)
              if (proposal.status == ProposalStatus.pending) ...[
                const SizedBox(height: AppSpacing.space6),
                _buildPaymentCard(proposal, template),
              ],

              // Waiting message (for paymentNotified status)
              if (proposal.status == ProposalStatus.paymentNotified) ...[
                const SizedBox(height: AppSpacing.space6),
                ProposalWaitingCard(
                  onContactTapped: () => _showContactOptions(proposal),
                ),
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
            ProposalStatusBanner(proposal: proposal),

          // Multi-choice header
          _buildMultiChoiceHeader(proposal),

          const SizedBox(height: AppSpacing.space6),

          // Teacher message
          if (proposal.message != null) ...[
            ProposalMessageCard(message: proposal.message!),
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
            ProposalWaitingCard(
              onContactTapped: () => _showContactOptions(proposal),
            ),
          ],

          // Add bottom padding for fixed action bar
          if (proposal.canRespond) const SizedBox(height: AppSpacing.space8),
        ],
      ),
    );
  }

  Widget _buildMultiChoiceHeader(SubscriptionProposal proposal) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Row(
        children: [
          // Icon (smaller, rounded square)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.paperAccent.withValues(alpha: 0.1),
            ),
            child: const Icon(
              Icons.card_giftcard,
              size: 24,
              color: AppColors.paperAccent,
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
                      const SizedBox(width: AppSpacing.space2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.ink.withValues(alpha: 0.1),
                        ),
                        child: Text(
                          '자동 발송',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w500,
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
                      color:
                          proposal.timeUntilExpiration.inDays < 2
                              ? AppColors.paperAccent
                              : AppColors.inkSecondary,
                    ),
                  )
                else if (!proposal.isAutoProposal)
                  Text(
                    '선생님이 보낸 제안',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkSecondary,
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
      children:
          proposal.allTemplateIds.map((templateId) {
            final templateAsync = ref.watch(
              subscriptionTemplateProvider(templateId),
            );
            final isSelected = _selectedTemplateId == templateId;
            final isRecommended = proposal.isRecommended(templateId);

            return templateAsync.when(
              loading:
                  () => const Padding(
                    padding: EdgeInsets.all(AppSpacing.space4),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              error: (e, _) => const SizedBox.shrink(),
              data: (template) {
                if (template == null) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTemplateId = templateId;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.space4),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? AppColors.paperAccent.withValues(alpha: 0.05)
                                : AppColors.paper,
                        border: Border.all(
                          color:
                              isSelected
                                  ? AppColors.paperAccent
                                  : AppColors.inkQuaternary,
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
                                color:
                                    isSelected
                                        ? AppColors.paperAccent
                                        : AppColors.inkQuaternary,
                                width: 2,
                              ),
                            ),
                            child:
                                isSelected
                                    ? Center(
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.paperAccent,
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
                                      const SizedBox(width: AppSpacing.space1),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.paperAccent
                                              .withValues(alpha: 0.2),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '⭐',
                                              style: AppTypography.caption,
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              '추천',
                                              style: AppTypography.caption
                                                  .copyWith(
                                                    color:
                                                        AppColors.paperAccent,
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
                                    color: AppColors.inkSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Price
                          Text(
                            template.formattedPrice,
                            style: AppTypography.headingSmall.copyWith(
                              color: AppColors.paperAccent,
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
    final effectiveTemplateId =
        _selectedTemplateId ?? proposal.effectiveTemplateId;
    final templateAsync = ref.watch(
      subscriptionTemplateProvider(effectiveTemplateId),
    );

    return templateAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const SizedBox.shrink(),
      data: (template) {
        if (template == null) return const SizedBox.shrink();
        return ProposalDetailsCard(template: template);
      },
    );
  }

  Widget _buildMultiChoiceDiscountCard(SubscriptionProposal proposal) {
    final effectiveTemplateId =
        _selectedTemplateId ?? proposal.effectiveTemplateId;
    final templateAsync = ref.watch(
      subscriptionTemplateProvider(effectiveTemplateId),
    );

    return templateAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (template) {
        if (template == null) return const SizedBox.shrink();
        return ProposalDiscountCard(proposal: proposal, template: template);
      },
    );
  }

  Widget _buildMultiChoicePaymentCard(SubscriptionProposal proposal) {
    final effectiveTemplateId =
        _selectedTemplateId ?? proposal.effectiveTemplateId;
    final templateAsync = ref.watch(
      subscriptionTemplateProvider(effectiveTemplateId),
    );

    return templateAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (template) {
        if (template == null) return const SizedBox.shrink();
        return _buildPaymentCard(proposal, template);
      },
    );
  }

  Widget _buildPaymentCard(
    SubscriptionProposal proposal,
    SubscriptionTemplate template,
  ) {
    // Get teacher profile for bank account info
    final teacherProfileAsync = ref.watch(
      teacherFullProfileProvider(proposal.teacherId),
    );

    return teacherProfileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const ProposalPaymentInfoCard(),
      data:
          (profile) => ProposalPaymentInfoCard(
            bankAccount: profile?.defaultBankAccount,
            bankAccounts: profile?.bankAccounts ?? [],
          ),
    );
  }

  /// Show contact options dialog (call/message)
  void _showContactOptions(SubscriptionProposal proposal) {
    // Get teacher profile for contact info
    final teacherProfileAsync = ref.read(
      teacherFullProfileProvider(proposal.teacherId),
    );

    teacherProfileAsync.whenOrNull(
      data: (profile) {
        if (profile == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('선생님 정보를 찾을 수 없습니다')));
          return;
        }

        final phoneNumber = profile.verification.phoneNumber;
        if (phoneNumber == null || phoneNumber.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('선생님 연락처 정보가 없습니다')));
          return;
        }

        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          builder:
              (context) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Notebook × Score: 모달 시트 상단 제목 블록은
                      // Playfair appBarTitle 로 통일 (§7.27). profile.name 은
                      // 동적이지만 구조적 역할은 동일.
                      Text(
                        '${profile.name} 선생님께 연락하기',
                        style: NotebookTypography.appBarTitle,
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.paperOk,
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
                          backgroundColor: AppColors.ink,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('선생님 정보를 불러오는 중...')));
    } else if (teacherProfileAsync is AsyncError) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('선생님 정보를 불러올 수 없습니다')));
    }
  }

  void _launchPhone(String phoneNumber) async {
    // Copy to clipboard (url_launcher can be added later for actual call)
    await Clipboard.setData(ClipboardData(text: phoneNumber));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('전화번호가 복사되었습니다: $phoneNumber')));
    }
  }

  void _launchSms(String phoneNumber) async {
    // Copy to clipboard (url_launcher can be added later for actual SMS)
    await Clipboard.setData(ClipboardData(text: phoneNumber));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('전화번호가 복사되었습니다: $phoneNumber')));
    }
  }

  /// Fixed bottom action bar for proposal response
  Widget _buildBottomActionBar(SubscriptionProposal proposal) {
    // For multi-choice proposals, check if template is selected
    final bool canProceed =
        !proposal.isMultiChoice || _selectedTemplateId != null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
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
                  color: AppColors.paperAccent.withValues(alpha: 0.1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.paperAccent,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Text(
                      '수강권을 선택해주세요',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.paperAccent,
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
                onPressed:
                    (_isProcessing || !canProceed)
                        ? null
                        : () => _notifyPayment(proposal),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.space4,
                  ),
                  shape: const RoundedRectangleBorder(),
                ),
                icon:
                    _isProcessing
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
              onPressed:
                  _isProcessing ? null : () => _showRejectDialog(proposal),
              child: Text(
                '이번엔 스킵할게요',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
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
            backgroundColor: AppColors.paperOk,
          ),
        );
        // Refresh the page
        ref.invalidate(subscriptionProposalProvider(proposal.id));
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

  Future<void> _showRejectDialog(SubscriptionProposal proposal) async {
    // 다이얼로그가 String?을 반환 (null = 취소, non-null = 스킵 + 사유)
    final reason = await showDialog<String?>(
      context: context,
      builder: (dialogContext) => const SkipReasonDialog(),
    );

    // reason이 null이 아니면 스킵 진행 (빈 문자열도 스킵 의도)
    if (reason != null && mounted) {
      await _rejectProposal(proposal, reason.isEmpty ? null : reason);
    }
  }

  Future<void> _rejectProposal(
    SubscriptionProposal proposal,
    String? reason,
  ) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final notifier = ref.read(subscriptionProposalNotifierProvider.notifier);
      await notifier.reject(proposal.id, reason);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('이번 제안을 스킵했습니다')));
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
}
