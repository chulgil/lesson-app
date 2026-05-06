import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_state.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../domain/entities/user_role.dart';
import '../extensions/user_role_visuals.dart';
import '../providers/auth_provider.dart';

/// Role selection screen shown after first OAuth signup when role is null.
class RoleSelectScreen extends ConsumerStatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  ConsumerState<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends ConsumerState<RoleSelectScreen> {
  bool _isLoading = false;

  Future<void> _selectRole(UserRole role) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(authNotifierProvider.notifier).setRole(role);

      if (!mounted) return;
      final authState = ref.read(authNotifierProvider);
      if (authState is AuthAuthenticated) {
        // Students go through onboarding first (invite code → profile → tutorial)
        if (role == UserRole.student) {
          context.go(AppRoutes.studentInviteCode);
        } else {
          context.go(authState.role.homeRoute);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.authRoleSetupFailed),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final userName = authState is AuthNeedsRole ? authState.name : '';

    return NotebookScreenScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Notebook × Score §7.113: 웰컴 아이콘만 BoxShape.circle 예외 (의례 모먼트).
              // 인사 제스처의 원형 바탕 ≠ 카드 모서리. 각진 카드와 대비로 시선 집중.
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.paperAccentSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.waving_hand_rounded,
                  size: 40,
                  color: AppColors.paperAccent,
                ),
              ),
              const SizedBox(height: AppSpacing.space4),

              // Notebook × Score §7.17: 환영 타이틀 Playfair (의례적 진입 모먼트).
              Text(
                '$userName님, 환영합니다!',
                style: NotebookTypography.sectionTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                '레슨 앱에서 어떤 역할로 사용하시나요?',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.inkSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Teacher option
              _RoleCard(
                icon: Icons.school_rounded,
                title: '선생님',
                description: '학생 관리, 레슨 일정, 피드백 작성',
                color: AppColors.paperAccent,
                isLoading: _isLoading,
                onTap: () => _selectRole(UserRole.teacher),
              ),
              const SizedBox(height: AppSpacing.space3),

              // Student option
              _RoleCard(
                icon: Icons.music_note_rounded,
                title: '학생',
                description: '레슨 확인, 연습 기록, 피드백 확인',
                color: AppColors.paperAccent,
                isLoading: _isLoading,
                onTap: () => _selectRole(UserRole.student),
              ),
              const SizedBox(height: AppSpacing.space3),

              // Parent option
              _RoleCard(
                icon: Icons.family_restroom_rounded,
                title: '학부모',
                description: '자녀의 레슨과 연습을 확인',
                color: AppColors.ink,
                isLoading: _isLoading,
                onTap: () => _selectRole(UserRole.parent),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Notebook × Score §7.113: 역할 카드는 BorderRadius.zero (악보·종이 직선 기하).
    return InkWell(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          color: color.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              // Notebook × Score §7.113: 아이콘 bg 도 각진 (카드 내부 컨테이너 규칙).
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppSpacing.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            else
              Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}
