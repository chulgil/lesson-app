import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
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

/// Screen for confirming connection request from an invite
class InviteConfirmScreen extends ConsumerStatefulWidget {
  final Invite invite;

  const InviteConfirmScreen({super.key, required this.invite});

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
    final isValidConnection = currentUserRole != inviteCreatorRole;

    return NotebookScreenScaffold(
      backgroundColor: AppColors.paperDark,
      appBar: AppBar(
        title: const Text(AppStrings.inviteConnectionRequest),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child:
              isValidConnection
                  ? _buildValidContent(inviteCreatorRole)
                  : _buildInvalidContent(currentUserRole),
        ),
      ),
    );
  }

  Widget _buildInvalidContent(InviteUserRole currentUserRole) {
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
            '연결할 수 없습니다',
            style: NotebookTypography.sectionTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            currentUserRole == InviteUserRole.teacher
                ? '선생님은 선생님의 초대 코드를 사용할 수 없습니다.\n학생의 초대 코드를 사용해주세요.'
                : '학생은 학생의 초대 코드를 사용할 수 없습니다.\n선생님의 초대 코드를 사용해주세요.',
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
              color: AppColors.paperOk.withValues(alpha: 0.1),
              borderRadius: BorderRadius.zero,
            ),
            child: Icon(Icons.link, size: 48, color: AppColors.paperOk),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Title — Notebook × Score: 고정 구조 섹션 헤더는 Playfair sectionTitle
          // (§7.17 / §7.87-h). creatorRoleLabel은 enum 라벨(선생님/학생)로
          // 유한 집합이므로 §7.30 예외 아님.
          Text(
            '$creatorRoleLabel과 연결하기',
            style: NotebookTypography.sectionTitle,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.space2),

          Text(
            '연결 요청을 보내시겠습니까?',
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
                const Divider(height: AppSpacing.space4),
                _buildInfoRow(
                  icon: Icons.confirmation_number,
                  label: AppStrings.inviteCode,
                  value: widget.invite.inviteCode,
                ),
                const Divider(height: AppSpacing.space4),
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
                  '메시지 (선택)',
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
              child:
                  _isLoading
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
              '취소',
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
            message:
                _messageController.text.isEmpty
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
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString();
        // Already connected is a success case
        if (errorMessage.contains('이미 연결')) {
          _showAlreadyConnectedDialog(widget.invite.creatorRole.label);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppColors.paperAccent,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAlreadyConnectedDialog(String targetRoleLabel) {
    final userRole = ref.read(currentUserRoleProvider);
    final homeRoute = userRole.homeRoute;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => NotebookAlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: AppSpacing.space4),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.ink.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Icon(Icons.link, size: 48, color: AppColors.ink),
                ),
                const SizedBox(height: AppSpacing.space4),
                // Notebook × Score: 중복 연결 다이얼로그 헤드라인 Playfair sectionTitle (§7.89).
                Text(
                  '이미 연결되어 있습니다',
                  style: NotebookTypography.sectionTitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  '해당 $targetRoleLabel과 이미\n연결되어 있습니다.',
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
                    Navigator.of(dialogContext).pop();
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
          ),
    );
  }

  void _showSuccessDialog(String targetRoleLabel) {
    // Get home route based on current user role
    final userRole = ref.read(currentUserRoleProvider);
    final homeRoute = userRole.homeRoute;
    final invite = widget.invite;

    // Check if student connected to teacher - offer booking option
    final isStudentConnectingToTeacher =
        userRole == UserRole.student &&
        invite.creatorRole == InviteUserRole.teacher;
    // Check if teacher received student invite - offer going to student list
    final isTeacherConnectingToStudent = userRole == UserRole.teacher;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => NotebookAlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: AppSpacing.space4),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.paperOk.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 48,
                    color: AppColors.paperOk,
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                // Notebook × Score: 연결 성공 다이얼로그 헤드라인 Playfair sectionTitle (§7.89).
                Text(
                  '연결 요청이 전송되었습니다!',
                  style: NotebookTypography.sectionTitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  '$targetRoleLabel이 요청을 수락하면\n연결이 완료됩니다.',
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
                      color: AppColors.ink.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 20,
                          color: AppColors.ink,
                        ),
                        const SizedBox(width: AppSpacing.space2),
                        Expanded(
                          child: Text(
                            '지금 바로 체험레슨을 예약할 수 있어요!',
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
                          Navigator.of(dialogContext).pop();
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
                          Navigator.of(dialogContext).pop();
                          // Navigate to booking screen with teacher info
                          final userProfile = ref.read(
                            currentUserProfileProvider,
                          );
                          context.push(
                            AppRoutes.lessonBooking,
                            extra: {
                              'teacherId': invite.creatorId,
                              'teacherName': invite.creatorName ?? '선생님',
                              'instrument':
                                  '악기', // Will be selected in booking screen
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
                          Navigator.of(dialogContext).pop();
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
                          Navigator.of(dialogContext).pop();
                          context.go(homeRoute);
                          // Navigate to students tab
                          context.push(AppRoutes.students);
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
                      Navigator.of(dialogContext).pop();
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
          ),
    );
  }
}
