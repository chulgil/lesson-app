import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/payment.dart';
import '../../../../providers/providers.dart';

/// Payment management screen - overview of all payments
class PaymentManagementScreen extends ConsumerStatefulWidget {
  const PaymentManagementScreen({super.key});

  @override
  ConsumerState<PaymentManagementScreen> createState() =>
      _PaymentManagementScreenState();
}

class _PaymentManagementScreenState
    extends ConsumerState<PaymentManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(paymentSummaryProvider);
    final paymentsAsync = ref.watch(paymentsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('수강료 관리'),
        actions: [
          IconButton(
            onPressed: () => _showMonthPicker(),
            icon: const Icon(Icons.calendar_month),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(paymentSummaryProvider);
          ref.invalidate(paymentsNotifierProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Summary cards
            SliverToBoxAdapter(
              child: summaryAsync.when(
                data: (summary) => _buildSummarySection(summary),
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.space6),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            // Tab bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: '전체'),
                    Tab(text: '미납'),
                    Tab(text: '완료'),
                  ],
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondaryLight,
                  indicatorColor: AppColors.primary,
                ),
              ),
            ),

            // Payment list
            paymentsAsync.when(
              data: (payments) {
                return SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPaymentList(payments),
                      _buildPaymentList(payments
                          .where((p) => p.status == PaymentStatus.pending)
                          .toList()),
                      _buildPaymentList(payments
                          .where((p) => p.status == PaymentStatus.confirmed)
                          .toList()),
                    ],
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: AppColors.error),
                      const SizedBox(height: AppSpacing.space3),
                      Text('데이터를 불러오는데 실패했습니다',
                          style: AppTypography.bodyMedium),
                      const SizedBox(height: AppSpacing.space4),
                      OutlinedButton(
                        onPressed: () =>
                            ref.invalidate(paymentsNotifierProvider),
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPaymentDialog(),
        icon: const Icon(Icons.add),
        label: const Text('결제 추가'),
      ),
    );
  }

  Widget _buildSummarySection(PaymentSummary summary) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${DateTime.now().month}월 수강료 현황',
            style: AppTypography.headingMedium,
          ),
          const SizedBox(height: AppSpacing.space4),

          // Main stats row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: '수납 완료',
                  value: summary.formattedTotalReceived,
                  subtitle: '${summary.paidStudents}명',
                  color: AppColors.practiceGood,
                  icon: Icons.check_circle,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: _buildStatCard(
                  title: '미납',
                  value: summary.formattedTotalPending,
                  subtitle: '${summary.unpaidStudents}명',
                  color: summary.overdueStudents > 0
                      ? AppColors.error
                      : AppColors.warning,
                  icon: Icons.pending,
                ),
              ),
            ],
          ),

          // Overdue warning
          if (summary.overdueStudents > 0) ...[
            const SizedBox(height: AppSpacing.space3),
            Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: AppColors.error, size: 20),
                  const SizedBox(width: AppSpacing.space2),
                  Text(
                    '연체 ${summary.overdueStudents}명',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      _tabController.animateTo(1); // Go to pending tab
                    },
                    child: const Text('확인하기'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSpacing.space2),
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            value,
            style: AppTypography.headingMedium.copyWith(
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: AppTypography.caption.copyWith(
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentList(List<Payment> payments) {
    if (payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long,
                size: 64, color: AppColors.textTertiaryLight),
            const SizedBox(height: AppSpacing.space4),
            Text(
              '결제 내역이 없습니다',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: payments.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.space3),
      itemBuilder: (context, index) {
        final payment = payments[index];
        return _buildPaymentCard(payment);
      },
    );
  }

  Widget _buildPaymentCard(Payment payment) {
    final isOverdue = payment.isOverdue;
    final statusColor = _getStatusColor(payment.status, isOverdue);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color: isOverdue
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPaymentDetail(payment),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: payment.type == PaymentType.trial
                          ? AppColors.info
                          : AppColors.primaryLight,
                      child: Text(
                        payment.studentName.isNotEmpty
                            ? payment.studentName[0]
                            : '?',
                        style: AppTypography.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                payment.studentName,
                                style: AppTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.space2),
                              _buildTypeBadge(payment.type),
                            ],
                          ),
                          Text(
                            payment.periodDisplay,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(payment),
                  ],
                ),

                const SizedBox(height: AppSpacing.space3),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.space3),

                // Amount and method row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment.formattedAmount,
                          style: AppTypography.headingMedium.copyWith(
                            color: statusColor,
                          ),
                        ),
                        Text(
                          payment.method.label,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    if (payment.status == PaymentStatus.pending)
                      Flexible(child: _buildPaymentActionButton(payment)),
                  ],
                ),

                // Overdue warning
                if (isOverdue) ...[
                  const SizedBox(height: AppSpacing.space3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space3,
                      vertical: AppSpacing.space2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSmall),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber,
                            size: 14, color: AppColors.error),
                        const SizedBox(width: AppSpacing.space1),
                        Text(
                          '연체 ${DateTime.now().difference(payment.dueDate!).inDays}일',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build action button based on payment status
  /// Step 1: Student clicks "입금완료" to notify teacher
  /// Step 2: Teacher clicks "입금확인" to confirm payment
  Widget _buildPaymentActionButton(Payment payment) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Show notification indicator if student confirmed
        if (payment.isAwaitingTeacherConfirmation) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space2,
              vertical: AppSpacing.space1,
            ),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.notifications_active,
                  size: 14,
                  color: AppColors.info,
                ),
                const SizedBox(width: 4),
                Text(
                  '입금알림',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
        // Confirm button
        FilledButton.icon(
          onPressed: () => _confirmPayment(payment),
          icon: const Icon(Icons.check, size: 16),
          label: const Text('입금확인'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.practiceGood,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeBadge(PaymentType type) {
    final isTrial = type == PaymentType.trial;
    final color = isTrial ? AppColors.info : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type.label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Payment payment) {
    Color color;
    final label = payment.displayStatus;

    if (payment.isOverdue) {
      color = AppColors.error;
    } else if (payment.isAwaitingTeacherConfirmation) {
      color = AppColors.info;
    } else {
      switch (payment.status) {
        case PaymentStatus.pending:
          color = AppColors.warning;
        case PaymentStatus.paid:
          color = AppColors.info;
        case PaymentStatus.confirmed:
        // ignore: deprecated_member_use_from_same_package
        case PaymentStatus.completed:
          color = AppColors.practiceGood;
        case PaymentStatus.overdue:
          color = AppColors.error;
        case PaymentStatus.cancelled:
          color = AppColors.textTertiaryLight;
        case PaymentStatus.refunded:
          color = AppColors.info;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (payment.isAwaitingTeacherConfirmation) ...[
            Icon(Icons.notifications_active, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(PaymentStatus status, bool isOverdue) {
    if (isOverdue) return AppColors.error;
    switch (status) {
      case PaymentStatus.pending:
        return AppColors.warning;
      case PaymentStatus.paid:
        return AppColors.info;
      case PaymentStatus.confirmed:
      // ignore: deprecated_member_use_from_same_package
      case PaymentStatus.completed:
        return AppColors.practiceGood;
      case PaymentStatus.overdue:
        return AppColors.error;
      case PaymentStatus.cancelled:
        return AppColors.textTertiaryLight;
      case PaymentStatus.refunded:
        return AppColors.info;
    }
  }

  void _showMonthPicker() {
    // TODO: Implement month picker
  }

  void _showPaymentDetail(Payment payment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PaymentDetailSheet(payment: payment),
    );
  }

  /// Confirm payment as teacher (step 2 or direct confirmation)
  Future<void> _confirmPayment(Payment payment) async {
    final isStep2 = payment.isAwaitingTeacherConfirmation;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('입금 확인'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${payment.studentName}님의 ${payment.formattedAmount} 입금을 확인하시겠습니까?'),
            if (isStep2) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.practiceGood.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 18, color: AppColors.practiceGood),
                    const SizedBox(width: 8),
                    Text(
                      '학생이 입금완료를 알렸습니다',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.practiceGood,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(paymentsNotifierProvider.notifier).markAsCompleted(payment.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${payment.studentName}님 입금이 확인되었습니다'),
            backgroundColor: AppColors.practiceGood,
          ),
        );
      }
    }
  }

  void _showAddPaymentDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddPaymentSheet(),
    );
  }
}

/// Tab bar delegate for sliver persistent header
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.backgroundLight,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}

/// Payment detail bottom sheet
class _PaymentDetailSheet extends ConsumerWidget {
  final Payment payment;

  const _PaymentDetailSheet({required this.payment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        payment.studentName.isNotEmpty
                            ? payment.studentName[0]
                            : '?',
                        style: AppTypography.headingSmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(payment.studentName,
                              style: AppTypography.headingMedium),
                          Text(
                            payment.periodDisplay,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.space6),

                // Details
                _buildDetailRow('금액', payment.formattedAmount),
                _buildDetailRow('상태', payment.displayStatus),
                _buildDetailRow('결제수단', payment.method.label),
                _buildDetailRow('레슨 횟수', '${payment.lessonCount}회'),
                if (payment.dueDate != null)
                  _buildDetailRow(
                    '납부기한',
                    '${payment.dueDate!.month}월 ${payment.dueDate!.day}일',
                  ),
                if (payment.studentConfirmed && payment.studentConfirmedAt != null)
                  _buildDetailRow(
                    '학생 입금완료',
                    '${payment.studentConfirmedAt!.month}/${payment.studentConfirmedAt!.day} ${payment.studentConfirmedAt!.hour}:${payment.studentConfirmedAt!.minute.toString().padLeft(2, '0')}',
                  ),
                if (payment.description != null)
                  _buildDetailRow('메모', payment.description!),

                const SizedBox(height: AppSpacing.space6),

                // Actions
                if (payment.status == PaymentStatus.pending) ...[
                  // Student confirmed indicator
                  if (payment.isAwaitingTeacherConfirmation) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.notifications_active, size: 20, color: AppColors.info),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '학생이 입금완료를 알렸습니다',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.info,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '계좌 확인 후 입금확인을 눌러주세요',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.info.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await ref
                            .read(paymentsNotifierProvider.notifier)
                            .markAsCompleted(payment.id);
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('입금 확인'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.practiceGood,
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.space4),
                      ),
                    ),
                  ),
                  // Student confirm button (if not already confirmed)
                  if (!payment.studentConfirmed) ...[
                    const SizedBox(height: AppSpacing.space2),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await ref
                              .read(paymentsNotifierProvider.notifier)
                              .markStudentConfirmed(payment.id);
                        },
                        icon: Icon(Icons.notifications, color: AppColors.info),
                        label: Text('학생 입금완료 알림', style: TextStyle(color: AppColors.info)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.info),
                          padding:
                              const EdgeInsets.symmetric(vertical: AppSpacing.space4),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.space3),
                ],

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // TODO: Edit payment
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('수정'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('결제 삭제'),
                              content: const Text('이 결제 내역을 삭제하시겠습니까?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('취소'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.error,
                                  ),
                                  child: const Text('삭제'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await ref
                                .read(paymentsNotifierProvider.notifier)
                                .deletePayment(payment.id);
                          }
                        },
                        icon: Icon(Icons.delete, color: AppColors.error),
                        label: Text('삭제',
                            style: TextStyle(color: AppColors.error)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.error),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: Row(
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
      ),
    );
  }
}

/// Add payment bottom sheet
class _AddPaymentSheet extends ConsumerStatefulWidget {
  const _AddPaymentSheet();

  @override
  ConsumerState<_AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends ConsumerState<_AddPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedStudentId;
  String? _selectedStudentName;
  PaymentType _paymentType = PaymentType.regular;
  int _amount = 200000;
  PaymentMethod _method = PaymentMethod.bankTransfer;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  int _weekStart = 1;
  int _weekEnd = 4;
  int _lessonCount = 4;
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController(text: '200000');

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _updateAmount() {
    if (_paymentType == PaymentType.trial) {
      _amount = 30000; // Default trial fee
      _amountController.text = '30000';
      _lessonCount = 1;
      _weekStart = _weekEnd; // Single week for trial
    } else {
      // Calculate based on weeks
      final weeks = _weekEnd - _weekStart + 1;
      _lessonCount = weeks;
      // Adjust amount proportionally if not full month
      if (weeks < 4) {
        _amount = (200000 / 4 * weeks).round();
        _amountController.text = _amount.toString();
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('결제 추가', style: AppTypography.headingMedium),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Payment Type Selector
                        Text('결제 유형', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: AppSpacing.space2),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTypeCard(
                                type: PaymentType.regular,
                                icon: Icons.event_repeat,
                                description: '월별 정기 레슨',
                              ),
                            ),
                            const SizedBox(width: AppSpacing.space3),
                            Expanded(
                              child: _buildTypeCard(
                                type: PaymentType.trial,
                                icon: Icons.music_note,
                                description: '1회 체험 레슨',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.space5),

                        // Student selector
                        Text('학생 선택', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: AppSpacing.space2),
                        studentsAsync.when(
                          data: (students) => DropdownButtonFormField<String>(
                            value: _selectedStudentId,
                            decoration: const InputDecoration(
                              hintText: '학생을 선택하세요',
                              border: OutlineInputBorder(),
                            ),
                            items: students.map((s) {
                              return DropdownMenuItem(
                                value: s.id,
                                child: Text('${s.name} (${s.level.label})'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              final student = students.firstWhere((s) => s.id == value);
                              setState(() {
                                _selectedStudentId = value;
                                _selectedStudentName = student.name;
                                if (_paymentType == PaymentType.regular) {
                                  _amount = student.monthlyFee;
                                  _amountController.text = _amount.toString();
                                }
                              });
                            },
                            validator: (value) {
                              if (value == null) return '학생을 선택하세요';
                              return null;
                            },
                          ),
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (_, __) => const Text('학생 목록을 불러올 수 없습니다'),
                        ),

                        const SizedBox(height: AppSpacing.space5),

                        // Month and Week selector (for regular only)
                        if (_paymentType == PaymentType.regular) ...[
                          Text('기간 선택', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: AppSpacing.space2),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _showMonthSelector(),
                                  icon: const Icon(Icons.calendar_month),
                                  label: Text('${_selectedMonth.year}년 ${_selectedMonth.month}월'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.space3),
                          Text('주차 범위', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight)),
                          const SizedBox(height: AppSpacing.space2),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: _weekStart,
                                  decoration: const InputDecoration(
                                    labelText: '시작',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  items: List.generate(5, (i) => i + 1).map((week) {
                                    return DropdownMenuItem(value: week, child: Text('$week주'));
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _weekStart = value;
                                        if (_weekEnd < value) _weekEnd = value;
                                      });
                                      _updateAmount();
                                    }
                                  },
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text('~'),
                              ),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: _weekEnd,
                                  decoration: const InputDecoration(
                                    labelText: '종료',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  items: List.generate(5, (i) => i + 1)
                                      .where((w) => w >= _weekStart)
                                      .map((week) {
                                    return DropdownMenuItem(value: week, child: Text('$week주'));
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _weekEnd = value);
                                      _updateAmount();
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.space2),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.space3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                                const SizedBox(width: AppSpacing.space2),
                                Text(
                                  '${_weekEnd - _weekStart + 1}주 · $_lessonCount회 레슨',
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.space5),
                        ],

                        // Trial date selector
                        if (_paymentType == PaymentType.trial) ...[
                          Text('체험 일자', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: AppSpacing.space2),
                          OutlinedButton.icon(
                            onPressed: () => _showDatePicker(),
                            icon: const Icon(Icons.event),
                            label: Text('${_selectedMonth.month}월 ${_selectedMonth.day}일'),
                          ),
                          const SizedBox(height: AppSpacing.space5),
                        ],

                        // Amount
                        Text('금액', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: AppSpacing.space2),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: '금액을 입력하세요',
                            suffixText: '원',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            _amount = int.tryParse(value) ?? 0;
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '금액을 입력하세요';
                            }
                            if (int.tryParse(value) == null) {
                              return '올바른 금액을 입력하세요';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: AppSpacing.space5),

                        // Payment method
                        Text('결제 수단', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: AppSpacing.space2),
                        Wrap(
                          spacing: AppSpacing.space2,
                          children: PaymentMethod.values.map((method) {
                            final isSelected = _method == method;
                            return ChoiceChip(
                              label: Text(method.label),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _method = method);
                                }
                              },
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: AppSpacing.space5),

                        // Description
                        Text('메모 (선택)', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: AppSpacing.space2),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText: '메모를 입력하세요',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.space6),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _submit,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.space4),
                            ),
                            child: Text(_paymentType == PaymentType.trial
                                ? '체험 레슨 결제 추가'
                                : '정규 레슨 결제 추가'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTypeCard({
    required PaymentType type,
    required IconData icon,
    required String description,
  }) {
    final isSelected = _paymentType == type;
    final color = type == PaymentType.trial ? AppColors.info : AppColors.primary;

    return GestureDetector(
      onTap: () {
        setState(() {
          _paymentType = type;
          _updateAmount();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: isSelected ? color : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : AppColors.textSecondaryLight, size: 28),
            const SizedBox(height: AppSpacing.space2),
            Text(
              type.label,
              style: AppTypography.bodyMedium.copyWith(
                color: isSelected ? color : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              description,
              style: AppTypography.caption.copyWith(
                color: isSelected ? color.withValues(alpha: 0.8) : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMonthSelector() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(now.year - 1, 1),
      lastDate: DateTime(now.year + 1, 12),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (selected != null) {
      setState(() {
        _selectedMonth = DateTime(selected.year, selected.month, 1);
      });
    }
  }

  Future<void> _showDatePicker() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(now.year - 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (selected != null) {
      setState(() {
        _selectedMonth = selected;
        // Calculate week of month
        final firstDay = DateTime(selected.year, selected.month, 1);
        _weekStart = ((selected.day + firstDay.weekday - 1) / 7).ceil();
        _weekEnd = _weekStart;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudentId == null) return;

    DateTime periodStart;
    DateTime periodEnd;

    if (_paymentType == PaymentType.trial) {
      periodStart = _selectedMonth;
      periodEnd = _selectedMonth;
    } else {
      // Calculate period based on weeks
      final weekStartDay = ((_weekStart - 1) * 7) + 1;
      final weekEndDay = (_weekEnd * 7).clamp(1, 31);
      periodStart = DateTime(_selectedMonth.year, _selectedMonth.month, weekStartDay);
      periodEnd = DateTime(_selectedMonth.year, _selectedMonth.month, weekEndDay);
    }

    final payment = Payment(
      id: '',
      studentId: _selectedStudentId!,
      studentName: _selectedStudentName ?? '',
      type: _paymentType,
      amount: _amount,
      status: PaymentStatus.pending,
      method: _method,
      paymentDate: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 7)),
      lessonCount: _lessonCount,
      periodStart: periodStart,
      periodEnd: periodEnd,
      weekStart: _weekStart,
      weekEnd: _weekEnd,
      description: _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : null,
      createdAt: DateTime.now(),
    );

    await ref.read(paymentsNotifierProvider.notifier).addPayment(payment);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_paymentType == PaymentType.trial
              ? '체험 레슨 결제가 추가되었습니다'
              : '정규 레슨 결제가 추가되었습니다'),
        ),
      );
    }
  }
}
