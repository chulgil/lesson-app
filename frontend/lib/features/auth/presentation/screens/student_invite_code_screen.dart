import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_state.dart';
import '../../../../core/deep_link/pending_invite_code_provider.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../features/auth/auth_facade.dart';
import '../../../../features/profile/domain/entities/invite.dart';
import '../../../invite/invite_facade.dart';

/// Student invite code input screen
/// Students enter an invite code from the teacher to connect with their teacher
class StudentInviteCodeScreen extends ConsumerStatefulWidget {
  const StudentInviteCodeScreen({super.key, this.initialCode});

  /// #1267 — QR 스캔으로 온 신규 사용자는 코드를 이미 알고 있으므로 수동 입력을
  /// 건너뛴다 (CodeInputScreen 의 deep-link initialCode 패턴과 동일).
  final String? initialCode;

  @override
  ConsumerState<StudentInviteCodeScreen> createState() =>
      _StudentInviteCodeScreenState();
}

class _StudentInviteCodeScreenState
    extends ConsumerState<StudentInviteCodeScreen> {
  bool _isSkipping = false; // #104: skip 경로 전용 가드 (제출 스피너와 분리)

  /// UXB-2 #1289 — 초대 딥링크가 남긴 코드. non-null 이면 이 화면은 역할 선택을
  /// 건너뛰고 도착한 것이므로 그 사실을 배너로 밝히고 탈출구를 제공한다.
  ///
  /// 진입 시점에 한 번만 읽는다 (watch 아님): 코드 소진 후 provider 를 비워도
  /// 입력 중인 화면이 다시 그려지며 배너가 사라지는 깜빡임이 없다.
  String? _pendingInviteCode;

  @override
  void initState() {
    super.initState();
    _pendingInviteCode = ref.read(pendingInviteCodeProvider);
  }

  /// 역할 선택 화면으로 돌아간다 — 초대를 받았지만 실제로는 선생님/학부모인 경우.
  /// 코드를 비워야 auth 가드가 다시 이 화면으로 튕겨보내지 않는다.
  void _switchRole() {
    ref.read(pendingInviteCodeProvider.notifier).state = null;
    context.go(AppRoutes.roleSelect);
  }

  @override
  Widget build(BuildContext context) {
    return NotebookScreenScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.login),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.space4),

                      // UXB-2 #1289 — 역할 선택을 건너뛰고 도착한 경우에만.
                      if (_pendingInviteCode != null) ...[
                        _buildRoleSkipBanner(),
                        const SizedBox(height: AppSpacing.space4),
                      ],

                      // Student icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.paperAccentSoft,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.music_note,
                            size: 40,
                            color: AppColors.paperAccent,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space4),

                      // Notebook × Score §7.17: 화면 진입 타이틀 Playfair.
                      Text(
                        AppStrings.authStudentRegister,
                        style: NotebookTypography.sectionTitle,
                      ),
                      const SizedBox(height: AppSpacing.space2),

                      // Description
                      Text(
                        AppStrings.inviteCodeScreenDesc,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppSpacing.space2),
                      Text(
                        AppStrings.inviteStudentCodeValidityHint,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.inkTertiary,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppSpacing.space6),

                      // 6-box invite code input — shared with the
                      // post-onboarding invite flow (CodeInputScreen) so both
                      // entry points look up the same way and confirm via the
                      // same teacher-info step before creating a connection.
                      InviteCodeDigitInput(
                        // 딥링크 코드는 redirect 로 넘어오므로 route extra 가
                        // 없다 — provider 에 보관된 값을 prefill 로 쓴다.
                        initialCode: widget.initialCode ?? _pendingInviteCode,
                        onInviteResolved: _handleInviteResolved,
                      ),

                      const SizedBox(height: AppSpacing.space6),

                      // Info box
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.space4),
                        decoration: BoxDecoration(color: AppColors.inkSoft),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.ink,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.space3),
                            Expanded(
                              child: Text(
                                AppStrings.inviteCodeHelpInfo,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.space4),

                      // Skip invite code - start without teacher
                      SizedBox(
                        width: double.infinity,
                        height: AppSpacing.buttonHeight,
                        child: OutlinedButton(
                          onPressed:
                              _isSkipping ? null : _handleStartWithoutCode,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.inkSecondary,
                            side: BorderSide(color: AppColors.inkQuaternary),
                            shape: RoundedRectangleBorder(),
                          ),
                          child: Text(
                            AppStrings.inviteCodeSkipButton,
                            style: AppTypography.button.copyWith(
                              color: AppColors.inkSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleStartWithoutCode() async {
    // #104: skip 더블탭 가드 — 진행 중이면 재진입 무시 (age-gate 중복·navigation 중복 방지).
    if (_isSkipping) return;
    setState(() => _isSkipping = true);
    // 만 14세 미만 차단 안전망 (phone_verification_policy.md §2.2).
    //
    // 정식 연령 검증은 통신사 본인인증(PASS) 으로 자동 처리될 예정이나, PASS
    // 통합 전까지 코드 없이 진입하는 학생에 대한 최소 게이트로 자가신고 확인을
    // 둔다. PASS 연동 시 이 다이얼로그는 본인인증 플로우로 대체한다.
    final isOverFourteen = await _confirmAgeGate();
    if (isOverFourteen != true) {
      if (mounted) setState(() => _isSkipping = false);
      return;
    }
    if (!mounted) return;
    // Set role to student and go directly to profile setup
    // #608 — remote 는 auth state 파생이 SSOT(user_role_provider.build).
    // 이 수동 set 은 mock 모드(디버그 역할 전환) 전용 메커니즘으로만 유효.
    ref.read(currentUserRoleProvider.notifier).state = UserRole.student;
    context.go(AppRoutes.studentProfileSetup);
  }

  /// Returns ``true`` when the user self-reports being 만 14세 이상.
  /// Shows a blocking message and returns ``false`` otherwise.
  Future<bool?> _confirmAgeGate() {
    return showNotebookDialog<bool>(
      context: context,
      title: AppStrings.authAgeGateTitle,
      message: AppStrings.authAgeGateBody,
      confirmLabel: AppStrings.authAgeGateConfirm,
      cancelLabel: AppStrings.authAgeGateCancel,
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () {
        Navigator.of(context).pop(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.authAgeGateBlocked),
            backgroundColor: AppColors.paperAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  /// UXB-2 #1289 — 역할 선택을 건너뛰고 왔다는 사실을 한 줄로 밝히고,
  /// 실제로는 선생님/학부모인 사용자를 위한 보조 링크를 함께 둔다.
  Widget _buildRoleSkipBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: const BoxDecoration(color: AppColors.paperAccentSoft),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.mark_email_read_outlined,
                size: 20,
                color: AppColors.paperAccent,
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Text(
                  AppStrings.inviteDeepLinkStudentBanner,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.ink),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _switchRole,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.inkSecondary,
                minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space2,
                ),
                shape: const RoundedRectangleBorder(),
              ),
              child: Text(
                AppStrings.inviteDeepLinkRoleSwitch,
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkSecondary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A valid invite code was resolved — establish the student role (mock
  /// mode SSOT parity, see #608 above) before showing the teacher-info
  /// confirm step, then push the shared [InviteConfirmScreen] directly so
  /// the actual connection request is only created on explicit confirm.
  ///
  /// UXB-2 #1289 — 딥링크 role-skip 으로 온 사용자는 아직 역할이 없다
  /// ([AuthNeedsRole]). 코드가 유효한 것으로 확인된 지금 학생 역할을 확정한다
  /// (#1267 QR 스캔이 스캐너에서 setRole 하는 것과 같은 지점 — 무효·만료 코드는
  /// 여기 도달하지 못하므로 역할이 잘못 확정되지 않는다).
  Future<void> _handleInviteResolved(Invite invite) async {
    if (ref.read(authNotifierProvider) is AuthNeedsRole) {
      try {
        await ref.read(authNotifierProvider.notifier).setRole(UserRole.student);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.inviteDeepLinkRoleSetFailed),
            backgroundColor: AppColors.paperAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (!mounted) return;
      // 역할이 확정됐으므로 코드는 라우팅 목적을 다했다.
      ref.read(pendingInviteCodeProvider.notifier).state = null;
    }
    ref.read(currentUserRoleProvider.notifier).state = UserRole.student;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => InviteConfirmScreen(
              invite: invite,
              // Onboarding isn't complete yet — routing to `homeRoute` would be
              // redirected back to role-select by the auth guard. Land on
              // profile setup instead (preserves the pre-unification behavior).
              successRedirectRoute: AppRoutes.studentProfileSetup,
            ),
      ),
    );
  }
}
