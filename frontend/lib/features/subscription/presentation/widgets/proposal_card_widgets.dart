import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../profile/domain/entities/teacher_profile.dart';
import '../../domain/entities/subscription_proposal.dart';
import '../../domain/entities/subscription_template.dart';

/// Status banner showing proposal status (paymentNotified, confirmed, rejected, expired, cancelled)
class ProposalStatusBanner extends StatelessWidget {
  final SubscriptionProposal proposal;

  const ProposalStatusBanner({super.key, required this.proposal});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String message;

    switch (proposal.status) {
      case ProposalStatus.paymentNotified:
        backgroundColor = AppColors.ink.withValues(alpha: 0.1);
        textColor = AppColors.ink;
        icon = Icons.schedule;
        message = '입금 확인을 기다리고 있습니다';
        break;
      case ProposalStatus.confirmed:
        backgroundColor = AppColors.paperOk.withValues(alpha: 0.1);
        textColor = AppColors.paperOk;
        icon = Icons.check_circle;
        message = '수강권이 발급되었습니다!';
        break;
      case ProposalStatus.rejected:
        backgroundColor = AppColors.paperAccent.withValues(alpha: 0.1);
        textColor = AppColors.paperAccent;
        icon = Icons.cancel;
        message = '스킵한 제안입니다';
        break;
      case ProposalStatus.expired:
        backgroundColor = AppColors.inkTertiary.withValues(alpha: 0.1);
        textColor = AppColors.inkTertiary;
        icon = Icons.timer_off;
        message = '제안이 만료되었습니다';
        break;
      case ProposalStatus.cancelled:
        backgroundColor = AppColors.inkTertiary.withValues(alpha: 0.1);
        textColor = AppColors.inkTertiary;
        icon = Icons.block;
        message = '선생님이 제안을 취소했습니다';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space4),
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: backgroundColor,
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
}

/// Header card with icon, template name, and expiration info
class ProposalHeaderCard extends StatelessWidget {
  final SubscriptionProposal proposal;
  final SubscriptionTemplate template;

  const ProposalHeaderCard({
    super.key,
    required this.proposal,
    required this.template,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space5),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.paperAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.card_giftcard,
              size: 32,
              color: AppColors.paperAccent,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            template.name,
            style: AppTypography.headingMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            '선생님 제안',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          if (proposal.status == ProposalStatus.pending) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              proposal.formattedExpiration,
              style: AppTypography.caption.copyWith(
                color:
                    proposal.timeUntilExpiration.inDays < 2
                        ? AppColors.paperAccent
                        : AppColors.inkTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Details card showing lesson count, duration, validity
class ProposalDetailsCard extends StatelessWidget {
  final SubscriptionTemplate template;

  const ProposalDetailsCard({super.key, required this.template});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
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
            color: AppColors.inkSecondary,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Teacher message card
class ProposalMessageCard extends StatelessWidget {
  final String message;

  const ProposalMessageCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paperAccent.withValues(alpha: 0.05),
        border: Border.all(color: AppColors.paperAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline,
                size: 18,
                color: AppColors.paperAccent,
              ),
              const SizedBox(width: AppSpacing.space1),
              Text(
                '선생님 메시지',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.paperAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(message, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }
}

/// Discount card showing original/discounted price
class ProposalDiscountCard extends StatelessWidget {
  final SubscriptionProposal proposal;
  final SubscriptionTemplate template;

  const ProposalDiscountCard({
    super.key,
    required this.proposal,
    required this.template,
  });

  @override
  Widget build(BuildContext context) {
    final originalPrice = template.price;
    final discountedPrice = originalPrice - (proposal.discountAmount ?? 0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paperAccent.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.paperAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_offer,
                size: 18,
                color: AppColors.paperAccent,
              ),
              const SizedBox(width: AppSpacing.space1),
              Text(
                proposal.discountReason ?? '할인 적용',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.paperAccent,
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
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
              Text(
                template.formattedPrice,
                style: AppTypography.bodySmall.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: AppColors.inkSecondary,
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
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
              Text(
                '-${_formatPrice(proposal.discountAmount ?? 0)}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.paperAccent,
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
                  color: AppColors.paperAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

/// Payment info card with bank account details.
/// When multiple accounts exist, shows a dropdown to select which account to display.
class ProposalPaymentInfoCard extends StatefulWidget {
  final BankAccount? bankAccount;
  final List<BankAccount> bankAccounts;

  const ProposalPaymentInfoCard({
    super.key,
    this.bankAccount,
    this.bankAccounts = const [],
  });

  @override
  State<ProposalPaymentInfoCard> createState() =>
      _ProposalPaymentInfoCardState();
}

class _ProposalPaymentInfoCardState extends State<ProposalPaymentInfoCard> {
  BankAccount? _selectedAccount;

  @override
  void initState() {
    super.initState();
    _selectedAccount = widget.bankAccount;
  }

  @override
  Widget build(BuildContext context) {
    final account = _selectedAccount;
    final bankName = account?.bankName ?? '계좌 미등록';
    final accountNumber = account?.accountNumber ?? '-';
    final accountHolder = account?.accountHolder ?? '-';
    final hasMultiple = widget.bankAccounts.length > 1;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance,
                size: 18,
                color: AppColors.paperAccent,
              ),
              const SizedBox(width: AppSpacing.space1),
              Text(
                '결제 정보',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (hasMultiple) ...[const Spacer(), _buildAccountSelector()],
            ],
          ),
          const SizedBox(height: AppSpacing.space4),
          _PaymentInfoRow(label: '은행', value: bankName),
          const SizedBox(height: AppSpacing.space2),
          _PaymentInfoRow(label: '계좌번호', value: accountNumber, copyable: true),
          const SizedBox(height: AppSpacing.space2),
          _PaymentInfoRow(label: '예금주', value: accountHolder),
        ],
      ),
    );
  }

  Widget _buildAccountSelector() {
    return PopupMenuButton<BankAccount>(
      onSelected: (account) => setState(() => _selectedAccount = account),
      itemBuilder:
          (context) =>
              widget.bankAccounts
                  .map(
                    (account) => PopupMenuItem<BankAccount>(
                      value: account,
                      child: Row(
                        children: [
                          if (account.id == _selectedAccount?.id)
                            Icon(
                              Icons.check,
                              size: 16,
                              color: AppColors.paperAccent,
                            )
                          else
                            const SizedBox(width: AppSpacing.space4),
                          const SizedBox(width: AppSpacing.space2),
                          Text('${account.bankName} ${account.accountNumber}'),
                        ],
                      ),
                    ),
                  )
                  .toList(),
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
            Text(
              '계좌 변경',
              style: AppTypography.caption.copyWith(
                color: AppColors.paperAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 16, color: AppColors.paperAccent),
          ],
        ),
      ),
    );
  }
}

class _PaymentInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;

  const _PaymentInfoRow({
    required this.label,
    required this.value,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.inkSecondary,
          ),
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
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('계좌번호가 복사되었습니다'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.paperAccent.withValues(alpha: 0.1),
                  ),
                  child: Text(
                    '복사',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.paperAccent,
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
}

/// Waiting card for payment confirmation status
class ProposalWaitingCard extends StatelessWidget {
  final VoidCallback onContactTapped;

  const ProposalWaitingCard({super.key, required this.onContactTapped});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.05),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.hourglass_empty, size: 48, color: AppColors.ink),
          const SizedBox(height: AppSpacing.space4),
          // Notebook × Score: 대기 상태 헤드라인 3축 통과 (§7.89 변형) — Playfair 승격.
          Text(
            '입금 확인 대기중',
            style: NotebookTypography.sectionTitle.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '선생님이 입금을 확인하면 수강권이 발급됩니다.\n입금 확인까지 1~2일 정도 소요될 수 있습니다.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          OutlinedButton.icon(
            onPressed: onContactTapped,
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: const Text('선생님께 문의하기'),
          ),
        ],
      ),
    );
  }
}
