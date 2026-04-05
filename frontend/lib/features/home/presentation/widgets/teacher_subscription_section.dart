import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../schedule/domain/entities/request_event.dart';
import '../../../schedule/presentation/providers/unified_lesson_request_providers.dart';
import '../../../students/presentation/providers/lesson_class_providers.dart';
import '../../../students/presentation/providers/membership_providers.dart';
import '../../../subscription/domain/entities/subscription.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../../../subscription/presentation/widgets/subscription_ticket_card.dart';

/// Home dashboard section showing teacher's issued subscriptions.
///
/// Pattern: same as LessonRequestSection — max 3 items + "더보기" button.
/// Hidden when 0 active subscriptions.
class TeacherSubscriptionSection extends ConsumerWidget {
  final String teacherId;

  const TeacherSubscriptionSection({
    super.key,
    required this.teacherId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(
      teacherStudentSubscriptionsProvider(teacherId),
    );

    return subscriptionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (subscriptions) {
        if (subscriptions.isEmpty) return const SizedBox.shrink();

        final active = subscriptions
            .where((s) =>
                s.status == SubscriptionStatus.active ||
                s.status == SubscriptionStatus.expiringSoon)
            .toList();

        if (active.isEmpty) return const SizedBox.shrink();

        final display = active.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, active.length),
            const SizedBox(height: AppSpacing.space1),
            _buildStatusStats(subscriptions),
            _buildPendingChangeBadge(context, ref),
            const SizedBox(height: AppSpacing.space2),

            // Subscription cards
            ...display.map((subscription) => _SubscriptionCardWithName(
                  subscription: subscription,
                  ref: ref,
                  onTap: () => context.push(
                    AppRoutes.subscriptionDetail
                        .replaceFirst(':id', subscription.id),
                    extra: {'viewerRole': 'teacher'},
                  ),
                )),

            // "더보기"
            if (active.length > 3) ...[
              const SizedBox(height: AppSpacing.space2),
              Center(
                child: TextButton(
                  onPressed: () => context.push(
                    AppRoutes.teacherSubscriptions,
                  ),
                  child: Text(
                    AppStrings.moreSubscriptions(active.length - 3),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.confirmation_number_outlined,
                  size: AppSpacing.iconSM,
                  color: AppColors.textSecondaryLight,
                ),
                const SizedBox(width: AppSpacing.space2),
                Text(AppStrings.subscription, style: AppTypography.headingMedium),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  '($count)',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          if (count > 3)
            TextButton.icon(
              onPressed: () => context.push(AppRoutes.teacherSubscriptions),
              icon: const Icon(Icons.list, size: AppSpacing.iconXS),
              label: Text(AppStrings.viewAll),
            ),
        ],
      ),
    );
  }

  Widget _buildPendingChangeBadge(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(
      pendingScheduleChangeRequestsProvider(teacherId),
    );

    return pendingAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (requests) {
        if (requests.isEmpty) return const SizedBox.shrink();

        final studentNames = ref.watch(studentNameMapProvider);

        return Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.screenPadding,
            right: AppSpacing.screenPadding,
            top: AppSpacing.space2,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppSpacing.space2),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: red dot + count label
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Text(
                      AppStrings.pendingChangeRequests(requests.length),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                // Mini rows for each request
                ...requests.take(3).map((event) => _buildChangeRequestRow(
                      context,
                      event,
                      studentNames,
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChangeRequestRow(
    BuildContext context,
    RequestEvent event,
    Map<String, String> studentNames,
  ) {
    final studentName = studentNames[event.actorId] ?? '';
    final sessionLabel = event.sessionNumber != null
        ? AppStrings.sessionNumberLabel(event.sessionNumber!)
        : '';
    final typeLabel = event.eventType == RequestEventType.scheduleChangeProposed
        ? AppStrings.sessionChangeRequest
        : AppStrings.sessionCancelRequest;
    final relativeTime = formatRelativeTime(event.createdAt);

    return GestureDetector(
      onTap: event.subscriptionId != null
          ? () => context.push(
                AppRoutes.subscriptionDetail
                    .replaceFirst(':id', event.subscriptionId!),
                extra: {'viewerRole': 'teacher'},
              )
          : null,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.space1),
        child: Text(
          '$studentName $sessionLabel $typeLabel · $relativeTime',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondaryLight,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildStatusStats(List<Subscription> all) {
    final activeCount = all.where((s) => s.status == SubscriptionStatus.active).length;
    final expiringCount = all.where((s) => s.status == SubscriptionStatus.expiringSoon || s.isExpiringSoon).length;
    final expiredCount = all.where((s) => s.status == SubscriptionStatus.expired).length;

    final parts = <String>[];
    if (activeCount > 0) parts.add('${AppStrings.statusActive} $activeCount');
    if (expiringCount > 0) parts.add('${AppStrings.statusExpiringSoon} $expiringCount');
    if (expiredCount > 0) parts.add('${AppStrings.statusExpired} $expiredCount');

    if (parts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.screenPadding + AppSpacing.space2),
      child: Text(
        parts.join(' · '),
        style: AppTypography.caption.copyWith(
          color: AppColors.textTertiaryLight,
        ),
      ),
    );
  }
}

/// Loads membership + class info to show student name on ticket card.
class _SubscriptionCardWithName extends StatelessWidget {
  final Subscription subscription;
  final WidgetRef ref;
  final VoidCallback? onTap;

  const _SubscriptionCardWithName({
    required this.subscription,
    required this.ref,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final membershipAsync = ref.watch(membershipProvider(subscription.membershipId));

    return membershipAsync.when(
      data: (membership) {
        if (membership == null) {
          return SubscriptionTicketCard(
            subscription: subscription,
            onTap: onTap,
          );
        }
        final lessonClassAsync = ref.watch(lessonClassProvider(membership.lessonClassId));
        final studentNames = ref.watch(studentNameMapProvider);
        final studentName = studentNames[subscription.studentId];

        return lessonClassAsync.when(
          data: (lessonClass) => SubscriptionTicketCard(
            subscription: subscription,
            className: lessonClass?.name,
            instrument: membership.instrument,
            personName: studentName,
            onTap: onTap,
          ),
          loading: () => SubscriptionTicketCard(
            subscription: subscription,
            instrument: membership.instrument,
            onTap: onTap,
          ),
          error: (_, __) => SubscriptionTicketCard(
            subscription: subscription,
            instrument: membership.instrument,
            onTap: onTap,
          ),
        );
      },
      loading: () => SubscriptionTicketCard(
        subscription: subscription,
        onTap: onTap,
      ),
      error: (_, __) => SubscriptionTicketCard(
        subscription: subscription,
        onTap: onTap,
      ),
    );
  }
}
