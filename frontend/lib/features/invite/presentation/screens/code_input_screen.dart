import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../features/profile/domain/entities/invite.dart';
import '../../../profile/profile_facade.dart';
import '../widgets/invite_code_digit_input.dart';

/// Screen for entering a 6-digit invite code
class CodeInputScreen extends ConsumerStatefulWidget {
  const CodeInputScreen({super.key, this.initialCode});

  /// Pre-filled 6-digit code from a deep link (lessonapp://invite/{code}).
  /// When valid, the field auto-fills and submission runs automatically.
  final String? initialCode;

  @override
  ConsumerState<CodeInputScreen> createState() => _CodeInputScreenState();
}

class _CodeInputScreenState extends ConsumerState<CodeInputScreen> {
  @override
  Widget build(BuildContext context) {
    final userRole = ref.watch(currentInviteUserRoleProvider);
    final targetRole =
        userRole == InviteUserRole.teacher
            ? AppStrings.student
            : AppStrings.teacher;

    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(
        title: AppStrings.inviteCodeAppBarTitle,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.paperAccentSoft,
                  borderRadius: BorderRadius.zero,
                ),
                child: Icon(
                  Icons.dialpad,
                  size: 40,
                  color: AppColors.paperAccent,
                ),
              ),

              const SizedBox(height: AppSpacing.space6),

              // Title
              // Notebook × Score: 초대 코드 입력 제목도 Playfair appBarTitle 로 통일 (§7.27 패턴).
              Text(
                AppStrings.inviteCodeInputPromptFormat(targetRole),
                style: NotebookTypography.appBarTitle,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.space2),

              // Subtitle
              Text(
                AppStrings.inviteCodeInputSubtitle,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.space8),

              // 6-box invite code input — shared with the onboarding invite
              // flow (StudentInviteCodeScreen) so both entry points look up
              // and confirm the same way before creating a connection.
              InviteCodeDigitInput(
                initialCode: widget.initialCode,
                onInviteResolved: (invite) {
                  // Navigate to confirmation screen
                  context.push(AppRoutes.inviteConfirm, extra: invite);
                },
              ),

              const Spacer(),

              // QR scan alternative
              TextButton.icon(
                onPressed: () {
                  context.pop();
                  context.push(AppRoutes.inviteScan);
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text(AppStrings.inviteCodeQrScan),
              ),

              const SizedBox(height: AppSpacing.space4),
            ],
          ),
        ),
      ),
    );
  }
}
