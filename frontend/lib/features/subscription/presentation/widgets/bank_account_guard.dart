import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../search/search_facade.dart' show teacherFullProfileProvider;

/// #847 입금 계좌 미등록 시 수강권 발급/제안을 막고 계좌 등록을 유도한다.
///
/// 계좌가 없으면 학생이 보는 결제 정보가 "미등록 / - / -" 로 떠 결제 자체가
/// 불가능한 막다른 상태가 된다. 결제가 필요한 발급(선불 미확인)·제안 직전에
/// 호출하여 사전 차단한다.
///
/// 반환값:
/// - `true`  : 입금 계좌가 1개 이상 → 진행 가능
/// - `false` : 계좌 없음 → 안내 다이얼로그 노출, 호출자는 즉시 중단
Future<bool> ensureBankAccountRegistered({
  required BuildContext context,
  required WidgetRef ref,
  required String teacherId,
}) async {
  final profile = await ref.read(teacherFullProfileProvider(teacherId).future);
  final hasAccount = (profile?.bankAccounts ?? const []).isNotEmpty;
  if (hasAccount) return true;
  if (!context.mounted) return false;

  await showDialog<void>(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          title: const Text(AppStrings.bankAccountRequiredTitle),
          content: const Text(AppStrings.bankAccountRequiredBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(AppStrings.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.push(AppRoutes.bankAccountEdit);
              },
              child: Text(
                AppStrings.bankAccountRequiredCta,
                style: TextStyle(color: AppColors.paperAccent),
              ),
            ),
          ],
        ),
  );
  return false;
}
