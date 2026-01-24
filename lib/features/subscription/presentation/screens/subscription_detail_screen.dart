import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../students/domain/entities/lesson_class.dart';
import '../../../students/presentation/providers/lesson_class_providers.dart';
import '../../../students/presentation/providers/membership_providers.dart';
import '../../domain/entities/subscription.dart';
import '../providers/subscription_providers.dart';

/// Screen showing subscription detail information.
class SubscriptionDetailScreen extends ConsumerWidget {
  final String subscriptionId;

  const SubscriptionDetailScreen({
    super.key,
    required this.subscriptionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionAsync = ref.watch(subscriptionProvider(subscriptionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('수강권 상세'),
        centerTitle: true,
      ),
      body: subscriptionAsync.when(
        data: (subscription) {
          if (subscription == null) {
            return _buildNotFoundState();
          }
          return _SubscriptionDetailContent(subscription: subscription);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textTertiaryLight,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            '수강권을 찾을 수 없습니다',
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.space3),
            Text(
              '오류가 발생했습니다',
              style: AppTypography.headingSmall,
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              error,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Detail content widget.
class _SubscriptionDetailContent extends ConsumerWidget {
  final Subscription subscription;

  const _SubscriptionDetailContent({required this.subscription});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membershipAsync = ref.watch(membershipProvider(subscription.membershipId));

    return membershipAsync.when(
      data: (membership) {
        if (membership == null) {
          return _buildMembershipNotFound();
        }

        final lessonClassAsync = ref.watch(lessonClassProvider(membership.lessonClassId));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status card
              _buildStatusCard(),

              const SizedBox(height: AppSpacing.space6),

              // Lesson info
              lessonClassAsync.when(
                data: (lessonClass) => _buildLessonInfoCard(lessonClass, membership.instrument),
                loading: () => _buildInfoCardPlaceholder(),
                error: (_, __) => _buildLessonInfoCard(null, membership.instrument),
              ),

              const SizedBox(height: AppSpacing.space4),

              // Subscription details
              _buildDetailsCard(),

              const SizedBox(height: AppSpacing.space4),

              // Usage info (for package type)
              if (subscription.type == SubscriptionType.package) ...[
                _buildUsageCard(),
                const SizedBox(height: AppSpacing.space4),
              ],

              // Period info (for monthly type)
              if (subscription.type == SubscriptionType.monthly) ...[
                _buildPeriodCard(),
                const SizedBox(height: AppSpacing.space4),
              ],

              // History section
              _buildHistorySection(),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildMembershipNotFound(),
    );
  }

  Widget _buildMembershipNotFound() {
    return Center(
      child: Text(
        '레슨 정보를 찾을 수 없습니다',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondaryLight,
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;
    String statusMessage;

    switch (subscription.status) {
      case SubscriptionStatus.active:
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        statusMessage = '수강권이 활성화되어 있습니다';
        break;
      case SubscriptionStatus.expiringSoon:
        statusColor = AppColors.warning;
        statusIcon = Icons.warning_amber;
        statusMessage = '수강권이 곧 만료됩니다. 갱신을 권장합니다.';
        break;
      case SubscriptionStatus.expired:
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        statusMessage = '수강권이 만료되었습니다';
        break;
      case SubscriptionStatus.paused:
        statusColor = AppColors.textTertiaryLight;
        statusIcon = Icons.pause_circle;
        statusMessage = '수강권이 일시정지 상태입니다';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 32),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subscription.statusLabel,
                  style: AppTypography.headingSmall.copyWith(
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusMessage,
                  style: AppTypography.bodySmall.copyWith(
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonInfoCard(LessonClass? lessonClass, String instrument) {
    final isAcademy = lessonClass?.type == LessonClassType.academy;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: (isAcademy ? AppColors.info : AppColors.primary)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Center(
              child: Text(
                isAcademy ? '🏫' : '👤',
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lessonClass?.name ?? '개인레슨',
                  style: AppTypography.headingSmall,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.music_note,
                      size: 16,
                      color: AppColors.textSecondaryLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      instrument,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCardPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildDetailsCard() {
    final dateFormat = DateFormat('yyyy년 M월 d일');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('수강권 정보', style: AppTypography.headingSmall),
          const SizedBox(height: AppSpacing.space4),
          _buildDetailRow('유형', subscription.typeLabel),
          const Divider(),
          _buildDetailRow(
            '금액',
            '${NumberFormat('#,###').format(subscription.amount)}원',
          ),
          const Divider(),
          _buildDetailRow(
            '등록일',
            dateFormat.format(subscription.createdAt),
          ),
          if (subscription.startDate != null) ...[
            const Divider(),
            _buildDetailRow(
              '시작일',
              dateFormat.format(subscription.startDate!),
            ),
          ],
          if (subscription.endDate != null) ...[
            const Divider(),
            _buildDetailRow(
              '만료일',
              dateFormat.format(subscription.endDate!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUsageCard() {
    final remaining = subscription.remainingLessons ?? 0;
    final total = subscription.totalLessons ?? 0;
    final used = subscription.usedLessons;
    final percentage = subscription.usagePercentage ?? 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('이용 현황', style: AppTypography.headingSmall),
          const SizedBox(height: AppSpacing.space4),

          // Big number display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    '$remaining',
                    style: AppTypography.displayLarge.copyWith(
                      color: subscription.isExpiringSoon
                          ? AppColors.warning
                          : AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '남은 횟수',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space6),
                child: Text(
                  '/',
                  style: AppTypography.headingLarge.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    '$total',
                    style: AppTypography.headingLarge.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  Text(
                    '전체 횟수',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 12,
              backgroundColor: AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                subscription.isExpiringSoon ? AppColors.warning : AppColors.primary,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.space3),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '사용: $used회',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              Text(
                '${percentage.toInt()}% 사용',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodCard() {
    final days = subscription.daysUntilExpiration ?? 0;
    final isExpired = days <= 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('이용 기간', style: AppTypography.headingSmall),
          const SizedBox(height: AppSpacing.space4),

          // D-day display
          Center(
            child: Column(
              children: [
                Text(
                  isExpired ? '만료됨' : 'D-$days',
                  style: AppTypography.displayLarge.copyWith(
                    color: isExpired
                        ? AppColors.error
                        : subscription.isExpiringSoon
                            ? AppColors.warning
                            : AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isExpired ? '수강권이 만료되었습니다' : '남은 일수',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),

          if (!isExpired && subscription.endDate != null) ...[
            const SizedBox(height: AppSpacing.space4),
            const Divider(),
            const SizedBox(height: AppSpacing.space3),
            Text(
              '${DateFormat('yyyy년 M월 d일').format(subscription.endDate!)}에 만료됩니다',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    // Placeholder for usage history
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('이용 내역', style: AppTypography.headingSmall),
              TextButton(
                onPressed: () {
                  // TODO: Show full history
                },
                child: const Text('전체 보기'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          // Placeholder message
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Column(
                children: [
                  Icon(
                    Icons.history,
                    size: 40,
                    color: AppColors.textTertiaryLight,
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    '이용 내역이 없습니다',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
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
