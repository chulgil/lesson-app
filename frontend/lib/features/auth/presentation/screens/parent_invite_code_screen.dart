import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:lessonaza/core/widgets/notebook/thin_rule.dart';
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
import '../../../profile/profile_facade.dart';

/// Parent invite code input screen
/// Parents enter an invite code from the teacher to connect with their child
class ParentInviteCodeScreen extends ConsumerStatefulWidget {
  const ParentInviteCodeScreen({super.key});

  @override
  ConsumerState<ParentInviteCodeScreen> createState() =>
      _ParentInviteCodeScreenState();
}

class _ParentInviteCodeScreenState
    extends ConsumerState<ParentInviteCodeScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSkipping = false; // #103: skip 경로 전용 가드 (제출 스피너와 분리)
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

                      // Parent icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.ink.withValues(alpha: 0.1),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.family_restroom,
                            size: 40,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space4),

                      // Notebook × Score §7.17: 화면 진입 타이틀 Playfair.
                      Text(
                        AppStrings.authParentRegister,
                        style: NotebookTypography.sectionTitle,
                      ),
                      const SizedBox(height: AppSpacing.space2),

                      // Description
                      Text(
                        AppStrings.authParentInviteCodeDesc,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppSpacing.space2),
                      Text(
                        AppStrings.inviteParentCodeValidityHint,
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
                                color: AppColors.ink,
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
                              return AppStrings.inviteCodeValidationEmpty;
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
                            backgroundColor: AppColors.ink,
                            foregroundColor: AppColors.paper,
                            shape: RoundedRectangleBorder(),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.paper,
                                    ),
                                  ),
                                )
                              : Text(
                                  AppStrings.inviteCodeSubmitButton,
                                  style: AppTypography.button,
                                ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.space6),

                      // Divider
                      Row(
                        children: [
                          Expanded(child: ThinRule()),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.space3,
                            ),
                            child: Text(
                              AppStrings.authInviteOrDivider,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.inkTertiary,
                              ),
                            ),
                          ),
                          Expanded(child: ThinRule()),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.space4),

                      // Skip option
                      GestureDetector(
                        onTap: _isSkipping ? null : _handleSkip,
                        child: Column(
                          children: [
                            Text(
                              AppStrings.authParentSkipTitle,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.space1),
                            Text(
                              AppStrings.authParentSkipSubtitle,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.inkTertiary,
                              ),
                            ),
                          ],
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

  Future<void> _handleSubmitCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final code = _codeController.text.trim().toUpperCase();

      if (ref.read(mockDataModeProvider)) {
        // Mock: validate code shape via the invite repository.
        final repo = ref.read(inviteRepositoryProvider);
        final invite = await repo.getInviteByCode(code);
        if (!mounted) return;
        if (invite == null) {
          setState(() => _errorMessage = AppStrings.authInviteCodeInvalid);
          return;
        }
        if (!invite.isValid) {
          setState(() => _errorMessage = AppStrings.authInviteCodeExpired);
          return;
        }
      } else {
        // Remote: create the connection request (mirror student flow). The
        // server resolves the target from the invite code. Without this the
        // "child connected" toast was a no-op (#583).
        final apiClient = ref.read(apiClientProvider);
        try {
          await apiClient.post(
            '/invites/connection-requests',
            data: {
              'target_id': '',
              'method': 'inviteCode',
              'invite_code': code,
            },
          );
        } catch (_) {
          if (mounted) {
            setState(() => _errorMessage = AppStrings.authInviteCodeInvalid);
          }
          return;
        }
      }

      // Set role + complete onboarding so the auth gate lets /parent-home
      // through (otherwise AuthNeedsOnboarding bounces to roleSelect, #582).
      // #608 — remote 는 auth state 파생이 SSOT(user_role_provider.build).
      // 이 수동 set 은 mock 모드(디버그 역할 전환) 전용 메커니즘으로만 유효.
      ref.read(currentUserRoleProvider.notifier).state = UserRole.parent;
      await _completeParentOnboarding();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppStrings.authChildConnected),
          backgroundColor: AppColors.paperOk,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go(AppRoutes.parentHome);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AppStrings.authInviteCodeError;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSkip() async {
    // #103: skip 더블탭 가드 — 진행 중이면 재진입 무시 (PATCH·navigation 중복 방지).
    if (_isSkipping) return;
    setState(() => _isSkipping = true);
    // Set role to parent and navigate to empty home.
    // #608 — remote 는 auth state 파생이 SSOT(user_role_provider.build).
    // 이 수동 set 은 mock 모드(디버그 역할 전환) 전용 메커니즘으로만 유효.
    ref.read(currentUserRoleProvider.notifier).state = UserRole.parent;
    try {
      await _completeParentOnboarding();
    } catch (_) {
      if (mounted) setState(() => _isSkipping = false);
      return;
    }
    if (!mounted) return;
    context.go(AppRoutes.parentHome);
  }

  /// Mark onboarding complete so the auth gate lets /parent-home through.
  /// Mock/dev mode already authenticates via dev-login, so skip the call.
  Future<void> _completeParentOnboarding() async {
    if (ref.read(mockDataModeProvider)) return;
    await ref.read(authNotifierProvider.notifier).completeOnboarding();
  }
}
