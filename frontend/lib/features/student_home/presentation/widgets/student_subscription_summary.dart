import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../subscription/subscription_ui_facade.dart';
import '../providers/student_home_subscription_summary_provider.dart';

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
    final summariesAsync = ref.watch(
      studentHomeSubscriptionSummariesProvider(studentId),
    );

    return summariesAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return _buildEmptyState(context);
        }

        return _buildContent(context, items);
      },
      loading: () => _buildLoadingState(),
      error: (_, __) => _buildErrorState(),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<StudentHomeSubscriptionSummaryItem> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.studentHomeMySubscriptions,
              style: NotebookTypography.sectionTitle,
            ),
            if (onViewAll != null)
              TextButton(
                onPressed: onViewAll,
                // H6 — 버튼처럼 눌리는 텍스트 액션은 밑줄로 affordance 를 준다.
                child: const Text(
                  AppStrings.viewAll,
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),

        // Subscription cards
        ...items.map((item) {
          final subscription = item.subscription;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space3),
            child: SubscriptionMembershipCard(
              subscription: subscription,
              classNameAsync: AsyncData(item.className),
              instrument: item.instrument,
              onTap:
                  subscription.id.isNotEmpty
                      ? () {
                        context.push(
                          AppRoutes.subscriptionDetail.replaceFirst(
                            ':id',
                            subscription.id,
                          ),
                          extra: {'viewerRole': 'student'},
                        );
                      }
                      : null,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      // 빈 수강권 카드도 채워진 카드와 동일하게 전폭 — width 미지정 시 Column 이
      // intrinsic 폭으로 줄어 좌측 정사각형으로 렌더됨(#631).
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: SizedBox(
        height: 220,
        child: EmptyStateWidget(
          icon: Icons.confirmation_number_outlined,
          title: AppStrings.noSubscriptionsRegisteredTitle,
          subtitle: AppStrings.noSubscriptionsRegisteredHint,
          actionLabel: AppStrings.subscriptionEmptyRequestLessonCta,
          // #621 — 학생 빈 수강권 "레슨 신청" 은 교사 전용 lessonRequests 가
          // 아니라 학생 진입점인 선생님 선택(레슨 신청 funnel)으로 라우팅한다.
          onAction: () => context.push(AppRoutes.selectTeacher),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      // #635 — 로딩→빈/콘텐츠 전환 시 테두리 pop-in 방지(동일 전폭+테두리).
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(color: AppColors.paper),
      child: Text(
        '수강권 정보를 불러올 수 없습니다',
        style: AppTypography.bodyMedium.copyWith(color: AppColors.inkSecondary),
      ),
    );
  }
}
