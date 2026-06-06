import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../auth/auth_facade.dart';

/// #430 G1 B1 — 학생 직접 가입 임시 안전망 화면.
///
/// 정책: `docs/specs/user/phone_verification_policy.md §3.2` — 학생 직접
/// 가입은 만 14세 검증을 위해 통신사 본인인증(PASS) 이 필요하다. PASS
/// 통합이 완료될 때까지 학생 직접 가입은 본 화면으로 안내되며, 만 14세
/// 미만 자녀의 활동은 학부모 계정의 자녀 프로필로 진행한다.
///
/// PASS 인증 통합 시 본 화면은 학생용 전화인증 화면으로 교체된다.
class StudentSignupBlockedScreen extends ConsumerWidget {
  const StudentSignupBlockedScreen({super.key});

  Future<void> _switchToParentSignup(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // 학생 역할 선택을 되돌리고 RoleSelectScreen 으로 복귀시켜 학부모를
    // 다시 고를 수 있게 한다. 약관 동의 상태는 그대로 유지된다.
    await ref.read(authNotifierProvider.notifier).clearRole();
    if (!context.mounted) return;
    context.go(AppRoutes.roleSelect);
  }

  void _goToStudentInviteCode(BuildContext context) {
    context.go(AppRoutes.studentInviteCode);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NotebookScreenScaffold(
      backgroundColor: AppColors.paperDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.paperAccentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.family_restroom_rounded,
                    size: 40,
                    color: AppColors.paperAccent,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.space5),

              Text(
                AppStrings.studentSignupBlockedTitle,
                style: NotebookTypography.sectionTitle,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.space3),

              Text(
                AppStrings.studentSignupBlockedBody,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.space2),

              Text(
                AppStrings.studentSignupBlockedHelper,
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkTertiary,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              FilledButton(
                onPressed: () => _switchToParentSignup(context, ref),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.paperAccent,
                  minimumSize: const Size(0, AppSpacing.buttonHeight),
                  shape: const RoundedRectangleBorder(),
                ),
                child: Text(
                  AppStrings.studentSignupBlockedParentCta,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.paper,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.space3),

              OutlinedButton(
                onPressed: () => _goToStudentInviteCode(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.paperAccent,
                  minimumSize: const Size(0, AppSpacing.buttonHeight),
                  side: const BorderSide(color: AppColors.paperAccent),
                  shape: const RoundedRectangleBorder(),
                ),
                child: Text(
                  AppStrings.studentSignupBlockedInviteCta,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.paperAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.space4),
            ],
          ),
        ),
      ),
    );
  }
}
