import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/notebook/notebook_screen_scaffold.dart';
import '../../../auth/auth_facade.dart' show currentUserIdProvider;
import '../../../schedule/schedule_facade.dart' show studentNameMapProvider;
import '../../domain/entities/refund_request.dart';
import '../providers/refund_request_providers.dart';
import '../widgets/refund_status_badge.dart';

/// Teacher-side surface for pending refund requests (#1271) — mirrors
/// [PaymentPendingListScreen]'s read-only-list-then-navigate pattern. The
/// single actionable place stays the subscription detail's
/// [RefundActionBox] — this screen is a visibility surface only.
class RefundPendingListScreen extends ConsumerWidget {
  const RefundPendingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacherId = ref.watch(currentUserIdProvider);
    final pendingAsync = ref.watch(
      teacherPendingRefundRequestsProvider(teacherId),
    );
    final studentNames = ref.watch(studentNameMapProvider);

    return NotebookScreenScaffold(
      appBarTitle: AppStrings.refundPendingListTitle,
      body: pendingAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.account_balance_outlined,
              title: AppStrings.refundPendingEmpty,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
            itemCount: items.length,
            itemBuilder:
                (context, index) => _Row(
                  item: items[index],
                  studentName:
                      studentNames[items[index].studentId] ??
                      AppStrings.student,
                ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (_, __) => const EmptyStateWidget(
              icon: Icons.account_balance_outlined,
              title: AppStrings.refundPendingEmpty,
            ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final RefundRequest item;
  final String studentName;

  const _Row({required this.item, required this.studentName});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:
          () => context.push(
            AppRoutes.subscriptionDetail.replaceFirst(
              ':id',
              item.subscriptionId,
            ),
            extra: {'viewerRole': 'teacher'},
          ),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space2,
        ),
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: AppColors.paperDark,
          border: Border.all(color: AppColors.inkQuaternary),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentName,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    '${item.bankName} ${item.accountNumber}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            RefundStatusBadge(request: item),
            const SizedBox(width: AppSpacing.space2),
            const Icon(Icons.chevron_right, color: AppColors.inkSecondary),
          ],
        ),
      ),
    );
  }
}
