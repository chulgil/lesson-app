import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_screen_scaffold.dart';

/// 💰 수강권·정산 카테고리 화면 (#765 — BottomSheet → 정식 라우트 승격).
///
/// 기존 `showSubscriptionBillingSheet` 의 항목을 그대로 옮긴 화면. 시트와 달리
/// 정식 라우트라, 하위 상세 화면에서 뒤로가기 시 이 메뉴로 정상 복귀한다.
class SubscriptionBillingCategoryScreen extends StatelessWidget {
  final String teacherId;

  const SubscriptionBillingCategoryScreen({super.key, required this.teacherId});

  @override
  Widget build(BuildContext context) {
    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(
        title: AppStrings.categorySheetSubscriptionBillingTitle,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.card_membership),
            title: const Text(AppStrings.profileSubscriptionTemplateLabel),
            subtitle: const Text(
              AppStrings.profileSubscriptionTemplateSubtitle,
            ),
            onTap: () => context.push(AppRoutes.subscriptionTemplates),
          ),
          ListTile(
            leading: const Icon(Icons.warning_amber_outlined),
            title: const Text(AppStrings.profileOutstandingPaymentsLabel),
            subtitle: const Text(AppStrings.profileOutstandingPaymentsSubtitle),
            onTap: () => context.push(AppRoutes.outstandingPayments),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_outlined),
            title: const Text(AppStrings.profileBankAccountLabel),
            subtitle: const Text(AppStrings.profileBankAccountSubtitle),
            onTap: () => context.push(AppRoutes.bankAccountEdit),
          ),
          // 가격표 분리 화면 (#785 — 수강권 상품과 별개 명시).
          ListTile(
            leading: const Icon(Icons.attach_money_outlined),
            title: const Text(AppStrings.priceTableSection),
            subtitle: const Text(AppStrings.priceListRoleSubtitle),
            onTap: () => context.push(AppRoutes.priceTable),
          ),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text(AppStrings.profileCancelPolicyLabel),
            subtitle: const Text(AppStrings.profileCancelPolicySubtitle),
            onTap: () =>
                context.push('${AppRoutes.lessonPolicy}?teacherId=$teacherId'),
          ),
          ListTile(
            leading: const Icon(Icons.event_busy_outlined),
            title: const Text(AppStrings.profileCancellationDefaultsLabel),
            subtitle: const Text(
              AppStrings.profileCancellationDefaultsSubtitle,
            ),
            onTap: () => context.push(AppRoutes.cancellationDefaults),
          ),
        ],
      ),
    );
  }
}
