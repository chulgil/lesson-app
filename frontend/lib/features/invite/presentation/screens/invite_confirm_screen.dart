import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:lessonaza/core/widgets/notebook/thin_rule.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../features/profile/domain/entities/invite.dart';
import '../../../auth/auth_facade.dart';
import '../../../parent_home/parent_home_facade.dart';
import '../../../profile/presentation/extensions/profile_domain_visuals.dart';
import '../../../profile/profile_facade.dart';
import '../extensions/invite_target_role_routing.dart';

/// Screen for confirming connection request from an invite
class InviteConfirmScreen extends ConsumerStatefulWidget {
  final Invite invite;

  /// Overrides the post-connection destination instead of deriving
  /// `userRole.homeRoute`. Used by the onboarding invite-code flow so a
  /// still-onboarding student lands on profile setup — `homeRoute` would be
  /// redirected back to role-select by the auth guard mid-onboarding. When
  /// set, the two-choice "book a lesson now" success offer is also
  /// suppressed since the student hasn't finished onboarding yet.
  final String? successRedirectRoute;

  const InviteConfirmScreen({
    super.key,
    required this.invite,
    this.successRedirectRoute,
  });

  @override
  ConsumerState<InviteConfirmScreen> createState() =>
      _InviteConfirmScreenState();
}

class _InviteConfirmScreenState extends ConsumerState<InviteConfirmScreen> {
  final _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserRole = ref.watch(currentInviteUserRoleProvider);
    final inviteCreatorRole = widget.invite.creatorRole;

    // #1267 — 대상 역할이 지정된 초대는 스캔한 계정의 실제 역할(교사/학생/학부모)
    // 이 대상과 일치해야 한다. currentInviteUserRoleProvider 는 학부모를
    // student 로 접어버려 학부모의 학생용 QR 대리 스캔을 못 걸러내므로, 전체
    // 3종 UserRole 을 별도로 비교한다.
    final actualUserRole = ref.watch(currentUserRoleProvider);
    final targetRole = widget.invite.targetRole;
    final targetMismatch =
        targetRole != null && actualUserRole != targetRole.asUserRole;

    final isValidConnection =
        !targetMismatch && currentUserRole != inviteCreatorRole;

    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(
        title: AppStrings.inviteConnectionRequest,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: isValidConnection
              ? _buildValidContent(inviteCreatorRole)
              : _buildInvalidContent(
                  currentUserRole,
                  mismatchTargetRole: targetMismatch ? targetRole : null,
                ),
        ),
      ),
    );
  }

  Widget _buildInvalidContent(
    InviteUserRole currentUserRole, {
    InviteTargetRole? mismatchTargetRole,
  }) {
    final String body;
    if (mismatchTargetRole != null) {
      body = AppStrings.inviteTargetRoleMismatchBodyFormat(
        mismatchTargetRole.label,
      );
    } else {
      body = currentUserRole == InviteUserRole.teacher
          ? AppStrings.inviteSelfCodeTeacher
          : AppStrings.inviteSelfCodeStudent;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.paperAccentSoft,
              borderRadius: BorderRadius.zero,
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              size: 40,
              color: AppColors.paperAccent,
            ),
          ),
          const SizedBox(height: AppSpacing.space6),
          // Notebook × Score: 연결 실패 상태 헤드라인 Playfair sectionTitle (§7.89).
          Text(
            mismatchTargetRole != null
                ? AppStrings.inviteTargetRoleMismatchTitle
                : AppStrings.inviteCannotConnect,
            style: NotebookTypography.sectionTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            body,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.space6),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text(AppStrings.goBack),
          ),
        ],
      ),
    );
  }

  Widget _buildValidContent(InviteUserRole creatorRole) {
    final creatorRoleLabel = creatorRole.label;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: AppSpacing.space4),

          // Success icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.paperOkSoft,
              borderRadius: BorderRadius.zero,
            ),
            child: Icon(Icons.link, size: 48, color: AppColors.paperOk),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Title — Notebook × Score: 고정 구조 섹션 헤더는 Playfair sectionTitle
          // (§7.17 / §7.87-h). creatorRoleLabel은 enum 라벨(선생님/학생)로
          // 유한 집합이므로 §7.30 예외 아님.
          Text(
            AppStrings.inviteConnectWithRoleFormat(creatorRoleLabel),
            style: NotebookTypography.sectionTitle,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.space2),

          Text(
            AppStrings.inviteConnectRequestPrompt,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.space6),

          // Invite info card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.zero,
              border: Border.all(color: AppColors.inkQuaternary),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  icon: Icons.person,
                  label: AppStrings.inviteInviter,
                  value: creatorRoleLabel,
                ),
                const SizedBox(height: AppSpacing.space2),
                const ThinRule(),
                const SizedBox(height: AppSpacing.space2),
                _buildInfoRow(
                  icon: Icons.confirmation_number,
                  label: AppStrings.inviteCode,
                  value: widget.invite.inviteCode,
                ),
                const SizedBox(height: AppSpacing.space2),
                const ThinRule(),
                const SizedBox(height: AppSpacing.space2),
                _buildInfoRow(
                  icon: Icons.access_time,
                  label: AppStrings.inviteValidPeriod,
                  value: widget.invite.formattedExpiry,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Optional message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.zero,
              border: Border.all(color: AppColors.inkQuaternary),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.proposalCreateMessageOptional,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                TextField(
                  controller: _messageController,
                  maxLines: 3,
                  maxLength: 200,
                  decoration: InputDecoration(
                    hintText: AppStrings.inviteMessageHint,
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: AppColors.inkQuaternary),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: AppColors.inkQuaternary),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: AppColors.paperAccent),
                    ),
                    contentPadding: const EdgeInsets.all(AppSpacing.space3),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.paperAccent,
                foregroundColor: AppColors.paper,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.space4,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.paper,
                      ),
                    )
                  : const Text(AppStrings.inviteSendConnectionRequest),
            ),
          ),

          const SizedBox(height: AppSpacing.space3),

          // Cancel button
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              AppStrings.cancel,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.space4),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.inkSecondary),
        const SizedBox(width: AppSpacing.space3),
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Future<void> _sendRequest() async {
    setState(() => _isLoading = true);

    try {
      // Determine who is teacher and who is student
      final invite = widget.invite;
      final creatorRole = invite.creatorRole;

      final request = await ref
          .read(connectionRequesterProvider.notifier)
          .requestConnection(
            targetId: invite.creatorId,
            targetRole: creatorRole,
            method: InviteMethod.inviteCode,
            inviteId: invite.id,
            message: _messageController.text.isEmpty
                ? null
                : _messageController.text,
          );

      if (mounted) {
        if (request != null) {
          _showSuccessDialog(creatorRole.label);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(AppStrings.inviteConnectionFailed),
              backgroundColor: AppColors.paperAccent,
            ),
          );
        }
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      // 409 means the relationship already exists — treat as success.
      if (e.statusCode == 409) {
        _showAlreadyConnectedDialog(widget.invite.creatorRole.label);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.inviteConnectionFailed),
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppStrings.inviteConnectionFailed),
          backgroundColor: AppColors.paperAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAlreadyConnectedDialog(String targetRoleLabel) {
    final userRole = ref.read(currentUserRoleProvider);
    final homeRoute = widget.successRedirectRoute ?? userRole.homeRoute;

    showNotebookDialog(
      context: context,
      barrierDismissible: false,
      titleWidget: const SizedBox.shrink(),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.space4),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.inkSoft,
              borderRadius: BorderRadius.zero,
            ),
            child: Icon(Icons.link, size: 48, color: AppColors.ink),
          ),
          const SizedBox(height: AppSpacing.space4),
          // Notebook × Score: 중복 연결 다이얼로그 헤드라인 Playfair sectionTitle (§7.89).
          Text(
            AppStrings.inviteAlreadyConnected,
            style: NotebookTypography.sectionTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            AppStrings.inviteAlreadyConnectedBodyFormat(targetRoleLabel),
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.space4),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go(homeRoute);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.paperAccent,
              foregroundColor: AppColors.paper,
            ),
            child: const Text(AppStrings.confirm),
          ),
        ),
      ],
    );
  }

  void _showSuccessDialog(String targetRoleLabel) {
    // Get home route based on current user role
    final userRole = ref.read(currentUserRoleProvider);
    final homeRoute = widget.successRedirectRoute ?? userRole.homeRoute;
    final invite = widget.invite;

    // successRedirectRoute means we're mid-onboarding (see the field doc) —
    // suppress the optional "book a lesson now" / "go to student list"
    // offers and always land on the single deterministic destination.
    final isOnboarding = widget.successRedirectRoute != null;

    // Check if student connected to teacher - offer booking option
    final isStudentConnectingToTeacher =
        !isOnboarding &&
        userRole == UserRole.student &&
        invite.creatorRole == InviteUserRole.teacher;
    // Check if teacher received student invite - offer going to student list
    final isTeacherConnectingToStudent =
        !isOnboarding && userRole == UserRole.teacher;

    showNotebookDialog(
      context: context,
      barrierDismissible: false,
      titleWidget: const SizedBox.shrink(),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.space4),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.paperOkSoft,
              borderRadius: BorderRadius.zero,
            ),
            child: Icon(Icons.check_circle, size: 48, color: AppColors.paperOk),
          ),
          const SizedBox(height: AppSpacing.space4),
          // Notebook × Score: 연결 성공 다이얼로그 헤드라인 Playfair sectionTitle (§7.89).
          Text(
            AppStrings.inviteRequestSent,
            style: NotebookTypography.sectionTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            AppStrings.inviteRequestSentBodyFormat(targetRoleLabel),
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (isStudentConnectingToTeacher) ...[
            const SizedBox(height: AppSpacing.space3),
            Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: AppColors.inkSoft,
                borderRadius: BorderRadius.zero,
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 20, color: AppColors.ink),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      AppStrings.inviteTrialBookingHint,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.space4),
        ],
      ),
      actions: [
        if (isStudentConnectingToTeacher) ...[
          // Two buttons: Go home or Book lesson
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go(homeRoute);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.inkSecondary,
                  ),
                  child: const Text(AppStrings.inviteGoHome),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Navigate to booking screen with teacher info
                    final userProfile = ref.read(currentUserProfileProvider);
                    context.push(
                      AppRoutes.lessonBooking,
                      extra: {
                        'teacherId': invite.creatorId,
                        'teacherName': invite.creatorName ?? AppStrings.teacher,
                        'instrument': AppStrings
                            .instrumentFallback, // Will be selected in booking screen
                        'studentId': userProfile.userId,
                        'studentName': userProfile.userName,
                        'isTrialLesson': true,
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.paperAccent,
                    foregroundColor: AppColors.paper,
                  ),
                  child: const Text(AppStrings.inviteLessonBooking),
                ),
              ),
            ],
          ),
        ] else if (isTeacherConnectingToStudent) ...[
          // Teacher: offer going to student list
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go(homeRoute);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.inkSecondary,
                  ),
                  child: const Text(AppStrings.inviteGoHome),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go(homeRoute);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.paperAccent,
                    foregroundColor: AppColors.paper,
                  ),
                  child: const Text(AppStrings.inviteStudentList),
                ),
              ),
            ],
          ),
        ] else ...[
          // Single button: Go home
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go(homeRoute);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.paperAccent,
                foregroundColor: AppColors.paper,
              ),
              child: const Text(AppStrings.confirm),
            ),
          ),
        ],
      ],
    );
  }
}
