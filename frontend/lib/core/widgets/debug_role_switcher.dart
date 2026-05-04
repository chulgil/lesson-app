import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/providers/user_role_provider.dart';
import '../config/environment.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'notebook/notebook_surfaces.dart';
import 'recording_diagnostic_screen.dart';

/// Get color for user role
Color _getRoleColor(UserRole role) {
  switch (role) {
    case UserRole.teacher:
      return AppColors.paperAccent;
    case UserRole.student:
      return AppColors.paperOk;
    case UserRole.parent:
      return AppColors.ink;
  }
}

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
              color: _getRoleColor(currentRole),
              borderRadius: BorderRadius.zero,
            ),
            child: Text(
              '${currentRole.emoji} ${currentRole.label}',
              style: AppTypography.caption.copyWith(
                color: AppColors.paper,
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
                  colors: [
                    _getRoleColor(currentRole),
                    _getRoleColor(currentRole).withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.swap_horiz,
                color: AppColors.paper,
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
    // Cycle through: teacher -> student -> parent -> teacher
    final UserRole newRole;
    switch (currentRole) {
      case UserRole.teacher:
        newRole = UserRole.student;
      case UserRole.student:
        newRole = UserRole.parent;
      case UserRole.parent:
        newRole = UserRole.teacher;
    }

    if (!EnvironmentConfig.useMockData) {
      // Remote mode: use devLogin for actual account switch
      _devLoginAs(context, ref, newRole);
      return;
    }

    ref.read(currentUserRoleProvider.notifier).state = newRole;

    // Show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${newRole.emoji} ${newRole.label} 모드로 전환'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _getRoleColor(newRole),
      ),
    );

    // Navigate to appropriate home
    context.go(newRole.homeRoute);
  }

  Future<void> _devLoginAs(
    BuildContext context,
    WidgetRef ref,
    UserRole role,
  ) async {
    final accounts = {
      UserRole.teacher: ('minyeon@example.com', 'teacher', '박미연'),
      UserRole.student: ('soyeon@example.com', 'student', '김소연'),
      UserRole.parent: ('parent@example.com', 'parent', '김정수'),
    };
    final (email, roleStr, name) = accounts[role]!;

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .devLogin(email: email, role: roleStr, name: name);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${role.emoji} ${role.label} 모드로 전환'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            backgroundColor: _getRoleColor(role),
          ),
        );
        context.go(role.homeRoute);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('계정 전환 실패: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    }
  }

  void _showDetailedOptions(BuildContext context, WidgetRef ref) {
    showNotebookModalBottomSheet<void>(
      context: context,
      builder: (context) => _DebugOptionsSheet(),
    );
  }
}

/// Detailed debug options bottom sheet
class _DebugOptionsSheet extends ConsumerWidget {
  Future<void> _devLoginAsFromSheet(
    BuildContext context,
    WidgetRef ref,
    UserRole role,
  ) async {
    final accounts = {
      UserRole.teacher: ('minyeon@example.com', 'teacher', '박미연'),
      UserRole.student: ('soyeon@example.com', 'student', '김소연'),
      UserRole.parent: ('parent@example.com', 'parent', '김정수'),
    };
    final (email, roleStr, name) = accounts[role]!;

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .devLogin(email: email, role: roleStr, name: name);
      if (context.mounted) {
        context.go(role.homeRoute);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('계정 전환 실패: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRole = ref.watch(currentUserRoleProvider);
    final mockStudents = ref.watch(mockStudentsProvider);
    final selectedStudent = ref.watch(selectedMockStudentProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: SingleChildScrollView(
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
                    color: AppColors.paperAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: const Icon(
                    Icons.bug_report,
                    color: AppColors.paperAccent,
                  ),
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
              children:
                  UserRole.values.asMap().entries.map((entry) {
                    final index = entry.key;
                    final role = entry.value;
                    final isSelected = role == currentRole;
                    final roleColor = _getRoleColor(role);
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right:
                              index < UserRole.values.length - 1
                                  ? AppSpacing.space1
                                  : 0,
                          left: index > 0 ? AppSpacing.space1 : 0,
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            if (!EnvironmentConfig.useMockData) {
                              _devLoginAsFromSheet(context, ref, role);
                            } else {
                              ref.read(currentUserRoleProvider.notifier).state =
                                  role;
                              context.go(role.homeRoute);
                            }
                          },
                          borderRadius: BorderRadius.zero,
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.space2),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? roleColor.withValues(alpha: 0.1)
                                      : AppColors.paperDark,
                              borderRadius: BorderRadius.zero,
                              border: Border.all(
                                color:
                                    isSelected ? roleColor : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  role.emoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(height: AppSpacing.space1),
                                Text(
                                  role.label,
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                    color:
                                        isSelected
                                            ? roleColor
                                            : AppColors.inkSecondary,
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
                children:
                    mockStudents.map((student) {
                      final isSelected = student.id == selectedStudent.id;
                      return ChoiceChip(
                        label: Text(student.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            ref
                                .read(selectedMockStudentProvider.notifier)
                                .state = student;
                          }
                        },
                        selectedColor: AppColors.paperOk.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color:
                              isSelected
                                  ? AppColors.paperOk
                                  : AppColors.inkSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
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
                  applicationName: 'Lessonaza',
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
            ListTile(
              leading: const Icon(
                Icons.audio_file,
                color: AppColors.paperAccent,
              ),
              title: const Text('녹음 파일 진단'),
              subtitle: const Text('녹음 파일과 DB 매칭 상태 확인'),
              dense: true,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RecordingDiagnosticScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.space4),
          ],
        ),
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

    return Stack(children: [child, const DebugRoleSwitcher()]);
  }
}
