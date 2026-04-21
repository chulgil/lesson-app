import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../students/domain/entities/class_membership.dart';
import '../../../students/presentation/providers/lesson_class_providers.dart';
import '../../../students/presentation/providers/membership_providers.dart';
import '../../../subscription/subscription_facade.dart';

/// Widget showing student's subscription summary on dashboard.
class StudentSubscriptionSummary extends ConsumerWidget {
  final String studentId;
  final VoidCallback? onViewAll;

  const StudentSubscriptionSummary({
    super.key,
    required this.studentId,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membershipsAsync = ref.watch(
      activeStudentMembershipsProvider(studentId),
    );
    final subscriptionsAsync = ref.watch(
      activeStudentSubscriptionsProvider(studentId),
    );

    return membershipsAsync.when(
      data: (memberships) {
        if (memberships.isEmpty) {
          return _buildEmptyState(context);
        }

        return subscriptionsAsync.when(
          data:
              (subscriptions) =>
                  _buildContent(context, ref, memberships, subscriptions),
          loading: () => _buildLoadingState(),
          error: (_, __) => _buildErrorState(),
        );
      },
      loading: () => _buildLoadingState(),
      error: (_, __) => _buildErrorState(),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<ClassMembership> memberships,
    List<Subscription> subscriptions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('내 수강권', style: AppTypography.headingMedium),
            if (onViewAll != null)
              TextButton(onPressed: onViewAll, child: const Text('전체 보기')),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),

        // Subscription cards
        ...memberships.map((membership) {
          final subscription = subscriptions.firstWhere(
            (s) => s.membershipId == membership.id,
            orElse: () => _createEmptySubscription(membership),
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space3),
            child: _SubscriptionMiniCard(
              membership: membership,
              subscription: subscription,
              onTap:
                  subscription.id.isNotEmpty
                      ? () {
                        context.push(
                          AppRoutes.subscriptionDetail.replaceFirst(
                            ':id',
                            subscription.id,
                          ),
                        );
                      }
                      : null,
            ),
          );
        }),
      ],
    );
  }

  Subscription _createEmptySubscription(ClassMembership membership) {
    return Subscription(
      id: '',
      studentId: studentId,
      membershipId: membership.id,
      type: SubscriptionType.monthly,
      amount: 0,
      status: SubscriptionStatus.expired,
      createdAt: DateTime.now(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 48,
            color: AppColors.inkTertiary,
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '등록된 수강권이 없습니다',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            '선생님에게 수강권 발급을 요청하세요',
            style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Text(
        '수강권 정보를 불러올 수 없습니다',
        style: AppTypography.bodyMedium.copyWith(color: AppColors.inkSecondary),
      ),
    );
  }
}

/// Enhanced card showing subscription info with progress bar, session count,
/// and quick schedule-change action. Toss card pattern: biggest info first.
class _SubscriptionMiniCard extends ConsumerWidget {
  final ClassMembership membership;
  final Subscription subscription;
  final VoidCallback? onTap;

  const _SubscriptionMiniCard({
    required this.membership,
    required this.subscription,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonClassAsync = ref.watch(
      lessonClassProvider(membership.lessonClassId),
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          border: Border.all(
            color:
                subscription.isExpiringSoon
                    ? AppColors.paperAccent
                    : AppColors.inkQuaternary,
            width: subscription.isExpiringSoon ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Badge + Name + Instrument
            Row(
              children: [
                _buildStatusBadge(),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: lessonClassAsync.when(
                    data:
                        (lessonClass) => Text(
                          '${lessonClass?.name ?? '개인레슨'} · ${membership.instrument}',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    loading: () => const Text('...'),
                    error: (_, __) => Text(membership.instrument),
                  ),
                ),
                if (_daysRemaining != null)
                  Text(
                    'D-$_daysRemaining',
                    style: AppTypography.caption.copyWith(
                      color:
                          _daysRemaining! <= 7
                              ? AppColors.paperAccent
                              : AppColors.inkTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.space3),

            // Row 2: Progress bar + Session count (big number)
            if (_totalSessions > 0) ...[
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusSmall,
                      ),
                      child: LinearProgressIndicator(
                        value: _progressValue,
                        minHeight: 6,
                        backgroundColor: AppColors.inkQuaternary,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _progressColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Text(
                    '${subscription.usedLessons}/$_totalSessions',
                    style: AppTypography.headingSmall.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    AppStrings.sessionUnit,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inkTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space3),
            ],

            // Row 3: Detail link only (schedule change is in subscription detail)
            if (subscription.id.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onTap != null)
                    TextButton(
                      onPressed: onTap,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppStrings.viewDetail,
                            style: AppTypography.buttonSmall.copyWith(
                              color: AppColors.paperAccent,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: AppColors.paperAccent,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  int get _totalSessions => subscription.totalLessonsForDisplay ?? 0;

  double get _progressValue {
    if (_totalSessions == 0) return 0;
    return (subscription.usedLessons / _totalSessions).clamp(0.0, 1.0);
  }

  Color get _progressColor {
    if (subscription.isExpiringSoon) return AppColors.paperAccent;
    if (_progressValue >= 0.9) return AppColors.paperAccent;
    return AppColors.ink;
  }

  int? get _daysRemaining {
    if (subscription.endDate == null) return null;
    final days = subscription.endDate!.difference(DateTime.now()).inDays;
    return days >= 0 ? days : null;
  }

  Widget _buildStatusBadge() {
    if (subscription.id.isEmpty) {
      return _badge(AppStrings.unregistered, AppColors.inkTertiary);
    }
    if (subscription.status == SubscriptionStatus.expired) {
      return _badge(AppStrings.expired, AppColors.paperAccent);
    }
    if (subscription.isExpiringSoon) {
      return _badge(AppStrings.expiringSoon, AppColors.paperAccent);
    }
    return _badge(AppStrings.active, AppColors.paperOk);
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
