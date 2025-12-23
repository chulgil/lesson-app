import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth/user_role_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Debug FAB for switching between teacher and student roles
/// Only visible in debug mode (kDebugMode)
class DebugRoleSwitcher extends ConsumerWidget {
  const DebugRoleSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only show in debug mode
    if (!kDebugMode) return const SizedBox.shrink();

    final currentRole = ref.watch(currentUserRoleProvider);

    return Positioned(
      right: AppSpacing.space4,
      bottom: 100, // Above bottom navigation
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Role indicator badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: AppSpacing.space1,
            ),
            decoration: BoxDecoration(
              color: currentRole == UserRole.teacher
                  ? AppColors.primary
                  : AppColors.secondary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '${currentRole.emoji} ${currentRole.label}',
              style: AppTypography.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space2),

          // Switch FAB
          GestureDetector(
            onTap: () => _switchRole(context, ref),
            onLongPress: () => _showDetailedOptions(context, ref),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: currentRole == UserRole.teacher
                      ? [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)]
                      : [AppColors.secondary, AppColors.secondary.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (currentRole == UserRole.teacher
                            ? AppColors.primary
                            : AppColors.secondary)
                        .withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.swap_horiz,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _switchRole(BuildContext context, WidgetRef ref) {
    final currentRole = ref.read(currentUserRoleProvider);
    final newRole =
        currentRole == UserRole.teacher ? UserRole.student : UserRole.teacher;

    ref.read(currentUserRoleProvider.notifier).state = newRole;

    // Show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${newRole.emoji} ${newRole.label} 모드로 전환'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            newRole == UserRole.teacher ? AppColors.primary : AppColors.secondary,
      ),
    );

    // Navigate to appropriate home
    context.go(newRole.homeRoute);
  }

  void _showDetailedOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _DebugOptionsSheet(),
    );
  }
}

/// Detailed debug options bottom sheet
class _DebugOptionsSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRole = ref.watch(currentUserRoleProvider);
    final mockStudents = ref.watch(mockStudentsProvider);
    final selectedStudent = ref.watch(selectedMockStudentProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.space2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: const Icon(Icons.bug_report, color: AppColors.warning),
              ),
              const SizedBox(width: AppSpacing.space3),
              Text('개발자 옵션', style: AppTypography.headingMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),

          // Role Selection
          Text(
            '역할 선택',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Row(
            children: UserRole.values.map((role) {
              final isSelected = role == currentRole;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: role == UserRole.teacher ? AppSpacing.space2 : 0,
                    left: role == UserRole.student ? AppSpacing.space2 : 0,
                  ),
                  child: InkWell(
                    onTap: () {
                      ref.read(currentUserRoleProvider.notifier).state = role;
                      context.go(role.homeRoute);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.space3),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (role == UserRole.teacher
                                    ? AppColors.primary
                                    : AppColors.secondary)
                                .withValues(alpha: 0.1)
                            : AppColors.surfaceSecondaryLight,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMedium),
                        border: Border.all(
                          color: isSelected
                              ? (role == UserRole.teacher
                                  ? AppColors.primary
                                  : AppColors.secondary)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            role.emoji,
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(height: AppSpacing.space1),
                          Text(
                            role.label,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected
                                  ? (role == UserRole.teacher
                                      ? AppColors.primary
                                      : AppColors.secondary)
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // Student Selection (only when student role)
          if (currentRole == UserRole.student) ...[
            const SizedBox(height: AppSpacing.space4),
            Text(
              '테스트 학생 선택',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Wrap(
              spacing: AppSpacing.space2,
              runSpacing: AppSpacing.space2,
              children: mockStudents.map((student) {
                final isSelected = student.id == selectedStudent.id;
                return ChoiceChip(
                  label: Text(student.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(selectedMockStudentProvider.notifier).state =
                          student;
                    }
                  },
                  selectedColor: AppColors.secondary.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppColors.secondary
                        : AppColors.textSecondaryLight,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: AppSpacing.space4),

          // Additional debug actions
          const Divider(),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '추가 기능',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('모든 데이터 새로고침'),
            dense: true,
            onTap: () {
              // Invalidate common providers
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('데이터를 새로고침합니다'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('앱 정보'),
            dense: true,
            onTap: () {
              Navigator.pop(context);
              showAboutDialog(
                context: context,
                applicationName: 'Lesson App',
                applicationVersion: '0.1.0 (Debug)',
                children: [
                  const Text('음악 레슨 관리 앱'),
                  const SizedBox(height: 8),
                  Text(
                    '현재 역할: ${currentRole.label}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: AppSpacing.space4),
        ],
      ),
    );
  }
}

/// Wrapper widget that adds debug FAB overlay to any screen
class DebugWrapper extends StatelessWidget {
  final Widget child;

  const DebugWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return child;

    return Stack(
      children: [
        child,
        const DebugRoleSwitcher(),
      ],
    );
  }
}
