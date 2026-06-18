import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/repository_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../features/auth/auth_facade.dart';
import '../../../../features/profile/profile_facade.dart';

/// Student invite code input screen
/// Students enter an invite code from the teacher to connect with their teacher
class StudentInviteCodeScreen extends ConsumerStatefulWidget {
  const StudentInviteCodeScreen({super.key});

  @override
  ConsumerState<StudentInviteCodeScreen> createState() =>
      _StudentInviteCodeScreenState();
}

class _StudentInviteCodeScreenState
    extends ConsumerState<StudentInviteCodeScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
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

                      // Student emoji icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.paperAccentSoft,
                        ),
                        child: Center(
                          child: Text(
                            '🎵',
                            style: AppTypography.displayLarge.copyWith(
                              fontSize: 40,
                            ),
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
                        '선생님으로부터 받은\n초대 코드를 입력해주세요',
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

                      // Invite code input
                      Form(
                        key: _formKey,
                        child: TextFormField(
                          controller: _codeController,
                          textAlign: TextAlign.center,
                          style: AppTypography.headingMedium.copyWith(
                            letterSpacing: 4,
                          ),
                          decoration: InputDecoration(
                            hintText: AppStrings.authInviteCodeHint,
                            hintStyle: AppTypography.bodyLarge.copyWith(
                              color: AppColors.inkTertiary,
                            ),
                            filled: true,
                            fillColor: AppColors.paperDark,
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.paperAccent,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.paperAccent,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.space4,
                              vertical: AppSpacing.space4,
                            ),
                          ),
                          textCapitalization: TextCapitalization.characters,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '초대 코드를 입력해주세요';
                            }
                            return null;
                          },
                          onChanged: (_) {
                            if (_errorMessage != null) {
                              setState(() => _errorMessage = null);
                            }
                          },
                        ),
                      ),

                      // Error message
                      if (_errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.space2),
                        Text(
                          _errorMessage!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.paperAccent,
                          ),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.space4),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: AppSpacing.buttonHeight,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmitCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.paperAccent,
                            // Notebook × Score §7.50: Vermillion CTA foreground = paper.
                            foregroundColor: AppColors.paper,
                            shape: RoundedRectangleBorder(),
                          ),
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      // Notebook × Score §7.50: Vermillion CTA spinner = paper.
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.paper,
                                      ),
                                    ),
                                  )
                                  : Text(
                                    '코드 확인하기',
                                    style: AppTypography.button,
                                  ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.space6),

                      // Info box
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.space4),
                        decoration: BoxDecoration(
                          color: AppColors.ink.withValues(alpha: 0.1),
                        ),
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
                                '초대 코드는 선생님이 학생 등록 후 제공합니다.\n아직 코드가 없다면 아래에서 바로 시작할 수 있어요.',
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
                          onPressed: _handleStartWithoutCode,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.inkSecondary,
                            side: BorderSide(color: AppColors.inkQuaternary),
                            shape: RoundedRectangleBorder(),
                          ),
                          child: Text(
                            '코드 없이 시작하기',
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
    // 만 14세 미만 차단 안전망 (phone_verification_policy.md §2.2).
    //
    // 정식 연령 검증은 통신사 본인인증(PASS) 으로 자동 처리될 예정이나, PASS
    // 통합 전까지 코드 없이 진입하는 학생에 대한 최소 게이트로 자가신고 확인을
    // 둔다. PASS 연동 시 이 다이얼로그는 본인인증 플로우로 대체한다.
    final isOverFourteen = await _confirmAgeGate();
    if (isOverFourteen != true) return;

    if (!mounted) return;
    // Set role to student and go directly to profile setup
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

  Future<void> _handleSubmitCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final code = _codeController.text.trim().toUpperCase();

      if (ref.read(mockDataModeProvider)) {
        // Mock: accept any 6+ character code
        await Future.delayed(const Duration(seconds: 1));
        if (code.length < 6) {
          setState(() => _errorMessage = '올바르지 않은 초대 코드입니다');
          return;
        }
      } else {
        // Remote: send connection request via invite code
        final apiClient = ref.read(apiClientProvider);
        try {
          await apiClient.post(
            '/invites/connection-requests',
            data: {
              'target_id': '', // Will be resolved by invite_code on server
              'method': 'inviteCode',
              'invite_code': code,
            },
          );
        } catch (e) {
          setState(() => _errorMessage = '올바르지 않은 초대 코드입니다');
          return;
        }
      }

      ref.read(currentUserRoleProvider.notifier).state = UserRole.student;
      ref.invalidate(mySentRequestsProvider);
      ref.invalidate(myConnectionsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.authTeacherConnectionRequested),
            backgroundColor: AppColors.paperOk,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go(AppRoutes.studentProfileSetup);
      }
    } catch (e) {
      setState(() => _errorMessage = '코드 확인 중 오류가 발생했습니다');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
