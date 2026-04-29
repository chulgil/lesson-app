import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../students/presentation/providers/student_crud_provider.dart';
import '../../domain/entities/subscription.dart';
import '../providers/subscription_providers.dart';
import '../widgets/subscription_card.dart';

/// Teacher-facing screen showing students with expiring subscriptions.
///
/// Navigated from the dashboard "수강권 임박 N명" urgent action.
/// Groups subscriptions by student and shows renewal actions.
class ExpiringSubscriptionsScreen extends ConsumerWidget {
  const ExpiringSubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expiringSoonAsync = ref.watch(expiringSoonSubscriptionsProvider);
    final expiredAsync = ref.watch(expiredSubscriptionsProvider);
    final studentsAsync = ref.watch(studentsProvider);

    return Scaffold(
      backgroundColor: AppColors.paperDark,
      appBar: AppBar(
        backgroundColor: AppColors.paperDark,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: expiringSoonAsync.when(
          loading: () => const Text(AppStrings.subscriptionViewAction),
          error: (_, __) => const Text(AppStrings.subscriptionViewAction),
          data: (subscriptions) {
            final expiredSubs = expiredAsync.valueOrNull ?? [];
            final allStudents = {
              ...subscriptions.map((s) => s.studentId),
              ...expiredSubs.map((s) => s.studentId),
            };
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.subscriptionViewAction),
                if (allStudents.isNotEmpty)
                  Text(
                    AppStrings.studentsCountSubtitle(allStudents.length),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.paperAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      body: expiringSoonAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text(AppStrings.errorTryAgain)),
        data: (subscriptions) {
          final expiredSubs = expiredAsync.valueOrNull ?? [];
          final allSubscriptions = [...subscriptions, ...expiredSubs];

          if (allSubscriptions.isEmpty) {
            return _buildEmptyState();
          }

          // Group subscriptions by studentId
          final grouped = <String, List<Subscription>>{};
          for (final sub in allSubscriptions) {
            grouped.putIfAbsent(sub.studentId, () => []).add(sub);
          }

          // Sort by most urgent first (least remaining lessons or days)
          final sortedEntries =
              grouped.entries.toList()..sort((a, b) {
                final aMin = _getUrgency(a.value);
                final bMin = _getUrgency(b.value);
                return aMin.compareTo(bMin);
              });

          return studentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _buildSubscriptionList(sortedEntries, {}),
            data: (students) {
              final studentMap = {for (final s in students) s.id: s.name};
              return _buildSubscriptionList(sortedEntries, studentMap);
            },
          );
        },
      ),
    );
  }

  /// Returns urgency score (lower = more urgent).
  /// Expired subscriptions get score -1 (most urgent).
  int _getUrgency(List<Subscription> subs) {
    int minUrgency = 999;
    for (final sub in subs) {
      if (sub.status == SubscriptionStatus.expired) return -1;
      final remaining = sub.remainingLessons ?? 999;
      final days = sub.daysUntilExpiration ?? 999;
      final urgency = remaining < days ? remaining : days;
      if (urgency < minUrgency) minUrgency = urgency;
    }
    return minUrgency;
  }

  Widget _buildSubscriptionList(
    List<MapEntry<String, List<Subscription>>> sortedEntries,
    Map<String, String> studentNames,
  ) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      itemCount: sortedEntries.length,
      itemBuilder: (context, index) {
        final entry = sortedEntries[index];
        final studentId = entry.key;
        final subs = entry.value;
        final studentName =
            studentNames[studentId] ??
            AppStrings.studentNameFallback(
              studentId.replaceAll('student_', '#'),
            );

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.space4),
          child: _buildStudentSection(context, studentId, studentName, subs),
        );
      },
    );
  }

  Widget _buildStudentSection(
    BuildContext context,
    String studentId,
    String studentName,
    List<Subscription> subscriptions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Student header
        GestureDetector(
          onTap:
              () => context.push(
                AppRoutes.studentDetail.replaceFirst(':id', studentId),
              ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.paperAccent,
                  child: Text(
                    studentName.isNotEmpty ? studentName[0] : 'S',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.paper,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Text(
                    studentName,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.inkSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space2),

        // One-tap renewal button
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed:
                () => context.push(
                  '${AppRoutes.issueSubscription}?studentId=$studentId',
                ),
            icon: const Icon(Icons.autorenew, size: 18),
            label: const Text(AppStrings.issueSubscriptionButton),
          ),
        ),
        const SizedBox(height: AppSpacing.space3),

        // Subscription cards
        ...subscriptions.map(
          (sub) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space3),
            child: SubscriptionCard(
              subscription: sub,
              className: sub.typeLabel,
              onTap:
                  () => context.push(
                    AppRoutes.subscriptionDetail.replaceFirst(':id', sub.id),
                  ),
              onRenewalTap:
                  () => context.push(
                    '${AppRoutes.issueSubscription}?studentId=$studentId',
                  ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(color: AppColors.paperDark),
            child: Icon(
              Icons.check_circle_outline,
              size: 48,
              color: AppColors.paperOk,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            AppStrings.expiringEmptyTitle,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            AppStrings.expiringEmptyBody,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
