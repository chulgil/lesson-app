import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/lessons/domain/entities/payment.dart';
import '../../../lessons/presentation/providers/payment_providers.dart';
import '../widgets/payment_management/payment_management_widgets.dart';

/// Payment management screen - overview of all payments.
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
            onPressed: _showMonthPicker,
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
            // Summary section
            SliverToBoxAdapter(
              child: summaryAsync.when(
                data: (summary) => PaymentSummarySection(
                  summary: summary,
                  onViewOverdue: () => _tabController.animateTo(1),
                ),
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
              data: (payments) => SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPaymentList(payments),
                    _buildPaymentList(
                      payments.where((p) => p.status == PaymentStatus.pending).toList(),
                    ),
                    _buildPaymentList(
                      payments.where((p) => p.status == PaymentStatus.confirmed).toList(),
                    ),
                  ],
                ),
              ),
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SliverFillRemaining(
                child: _buildErrorState(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPaymentDialog,
        icon: const Icon(Icons.add),
        label: const Text('결제 추가'),
      ),
    );
  }

  Widget _buildPaymentList(List<Payment> payments) {
    if (payments.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: payments.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.space3),
      itemBuilder: (context, index) {
        final payment = payments[index];
        return PaymentCard(
          payment: payment,
          onTap: () => _showPaymentDetail(payment),
          onConfirm: () => _confirmPayment(payment),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: AppColors.textTertiaryLight),
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

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: AppSpacing.space3),
          Text('데이터를 불러오는데 실패했습니다', style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.space4),
          OutlinedButton(
            onPressed: () => ref.invalidate(paymentsNotifierProvider),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  void _showMonthPicker() {
    // TODO: Implement month picker
  }

  void _showPaymentDetail(Payment payment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentDetailSheet(payment: payment),
    );
  }

  /// Confirm payment as teacher (step 2 or direct confirmation).
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
      builder: (context) => const AddPaymentSheet(),
    );
  }
}

/// Tab bar delegate for sliver persistent header.
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.backgroundLight,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}
