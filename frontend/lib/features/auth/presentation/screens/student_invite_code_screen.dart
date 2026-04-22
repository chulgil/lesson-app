import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/auth/presentation/providers/user_role_provider.dart';

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
    return Scaffold(
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
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusXLarge),
                        ),
                        child: const Center(
                          child: Text('🎵', style: TextStyle(fontSize: 40)),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space4),

                      // Title
                      Text(
                        '학생 등록',
                        style: AppTypography.headingLarge,
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
                            hintText: '초대 코드 입력',
                            hintStyle: AppTypography.bodyLarge.copyWith(
                              color: AppColors.inkTertiary,
                            ),
                            filled: true,
                            fillColor: AppColors.paperDark,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMedium),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMedium),
                              borderSide: BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMedium),
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
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusLarge),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
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
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMedium),
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
                            side: BorderSide(
                              color: AppColors.inkQuaternary,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusLarge),
                            ),
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

  void _handleStartWithoutCode() {
    // Set role to student and go directly to profile setup
    ref.read(currentUserRoleProvider.notifier).state = UserRole.student;
    context.go(AppRoutes.studentProfileSetup);
  }

  Future<void> _handleSubmitCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final code = _codeController.text.trim().toUpperCase();

      if (EnvironmentConfig.useMockData) {
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('선생님과 성공적으로 연결되었습니다!'),
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
