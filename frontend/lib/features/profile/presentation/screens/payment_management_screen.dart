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
  DateTime _selectedMonth = DateTime.now();

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
        title: Text('수강료 관리 · ${_selectedMonth.year}.${_selectedMonth.month.toString().padLeft(2, '0')}'),
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

            // Payment list (filtered by selected month)
            paymentsAsync.when(
              data: (payments) {
                final filtered = payments.where((p) {
                  return p.createdAt.year == _selectedMonth.year &&
                      p.createdAt.month == _selectedMonth.month;
                }).toList();
                return SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPaymentList(filtered),
                      _buildPaymentList(
                        filtered.where((p) => p.status == PaymentStatus.pending).toList(),
                      ),
                      _buildPaymentList(
                        filtered.where((p) => p.status == PaymentStatus.confirmed).toList(),
                      ),
                    ],
                  ),
                );
              },
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
    final now = DateTime.now();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        int selectedYear = _selectedMonth.year;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final months = List.generate(12, (i) => i + 1);

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Year selector
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space4,
                      vertical: AppSpacing.space3,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            setSheetState(() => selectedYear--);
                          },
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text(
                          '$selectedYear년',
                          style: AppTypography.headingSmall,
                        ),
                        IconButton(
                          onPressed: selectedYear < now.year
                              ? () {
                                  setSheetState(() => selectedYear++);
                                }
                              : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Month grid
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.space4),
                    child: GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      mainAxisSpacing: AppSpacing.space2,
                      crossAxisSpacing: AppSpacing.space2,
                      childAspectRatio: 2,
                      children: months.map((month) {
                        final isSelected =
                            selectedYear == _selectedMonth.year &&
                                month == _selectedMonth.month;
                        final isFuture = selectedYear > now.year ||
                            (selectedYear == now.year && month > now.month);

                        return GestureDetector(
                          onTap: isFuture
                              ? null
                              : () {
                                  setState(() {
                                    _selectedMonth =
                                        DateTime(selectedYear, month);
                                  });
                                  Navigator.pop(context);
                                },
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMedium),
                              border: isSelected
                                  ? null
                                  : Border.all(
                                      color: isFuture
                                          ? AppColors.borderLight
                                              .withValues(alpha: 0.3)
                                          : AppColors.borderLight,
                                    ),
                            ),
                            child: Text(
                              '$month월',
                              style: AppTypography.bodyMedium.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : isFuture
                                        ? AppColors.textTertiaryLight
                                        : AppColors.textPrimaryLight,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
