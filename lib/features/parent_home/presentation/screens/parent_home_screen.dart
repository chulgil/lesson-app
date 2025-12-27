import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/debug_role_switcher.dart';
import '../../../../models/parent_child_relation.dart';
import '../../../../providers/parent/parent_crud_provider.dart';
import '../widgets/child_card.dart';
import '../widgets/parent_notification_badge.dart';

/// Parent home screen with dashboard
class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return DebugWrapper(
      child: Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: _currentIndex,
            children: const [
              _ParentDashboardTab(),
              _ParentNotificationsTab(),
              _ParentSettingsTab(),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavigation(),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: '알림',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }
}

/// Parent Dashboard Tab
class _ParentDashboardTab extends ConsumerWidget {
  const _ParentDashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final dateFormat = DateFormat('M월 d일 EEEE', 'ko');

    // TODO: Replace with actual parent ID from auth
    const currentParentId = 'parent_1';

    final relationsAsync = ref.watch(relationsForParentProvider(currentParentId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '안녕하세요 👋',
                    style: AppTypography.headingLarge,
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    dateFormat.format(now),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              const ParentNotificationBadge(),
            ],
          ),

          const SizedBox(height: AppSpacing.space6),

          // Children Section
          Text('내 자녀', style: AppTypography.headingMedium),
          const SizedBox(height: AppSpacing.space3),

          relationsAsync.when(
            data: (relations) {
              if (relations.isEmpty) {
                return _buildEmptyChildState(context);
              }
              return Column(
                children: relations
                    .where((r) => r.status == RelationStatus.active)
                    .map((relation) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.space3),
                          child: ChildCard(relation: relation),
                        ))
                    .toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('자녀 정보를 불러올 수 없습니다'),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Quick Actions
          Text('바로가기', style: AppTypography.headingMedium),
          const SizedBox(height: AppSpacing.space3),

          _buildQuickActions(context),

          const SizedBox(height: AppSpacing.space6),

          // Weekly Summary
          Text('이번 주 요약', style: AppTypography.headingMedium),
          const SizedBox(height: AppSpacing.space3),

          _buildWeeklySummary(),

          const SizedBox(height: AppSpacing.space6),

          // Payment Summary
          Text('결제 현황', style: AppTypography.headingMedium),
          const SizedBox(height: AppSpacing.space3),

          _buildPaymentSummary(),
        ],
      ),
    );
  }

  Widget _buildEmptyChildState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space6),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(
            Icons.family_restroom,
            size: 48,
            color: AppColors.textTertiaryLight,
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            '연결된 자녀가 없습니다',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '초대 코드를 입력하여 자녀와 연결하세요',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.space4),
          FilledButton.icon(
            onPressed: () {
              // Navigate to invitation code screen
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const _InvitationCodeScreen(),
              ));
            },
            icon: const Icon(Icons.link, size: 18),
            label: const Text('초대 코드 입력'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.link,
            label: '초대 코드\n입력',
            color: AppColors.primary,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const _InvitationCodeScreen(),
              ));
            },
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.payment,
            label: '결제\n내역',
            color: AppColors.secondary,
            onTap: () {
              // TODO: Navigate to payment history
            },
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.bar_chart,
            label: '연습\n리포트',
            color: AppColors.practiceGood,
            onTap: () {
              // TODO: Navigate to practice report
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklySummary() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildSummaryItem('레슨', '2회', Icons.school),
              const SizedBox(width: AppSpacing.space4),
              _buildSummaryItem('연습', '5일', Icons.fitness_center),
              const SizedBox(width: AppSpacing.space4),
              _buildSummaryItem('과제', '80%', Icons.assignment_turned_in),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: AppSpacing.space2),
          Text(
            value,
            style: AppTypography.headingMedium.copyWith(
              color: AppColors.primary,
            ),
          ),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '이번 달 결제 예정',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              Text(
                '150,000원',
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          const Divider(),
          const SizedBox(height: AppSpacing.space3),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '결제 완료',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      '100,000원',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.practiceGood,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.borderLight,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '결제 대기',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      '50,000원',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Quick Action Card Widget
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: AppSpacing.space2),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Parent Notifications Tab (Placeholder)
class _ParentNotificationsTab extends StatelessWidget {
  const _ParentNotificationsTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: AppColors.textTertiaryLight,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            '새로운 알림이 없습니다',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// Parent Settings Tab (Placeholder)
class _ParentSettingsTab extends ConsumerWidget {
  const _ParentSettingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('설정', style: AppTypography.headingLarge),
          const SizedBox(height: AppSpacing.space6),

          // Notification Settings
          _buildSettingsSection(
            context,
            '알림 설정',
            [
              _buildSettingsTile(
                icon: Icons.notifications,
                title: '알림 설정',
                subtitle: '알림 종류별 수신 설정',
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ParentNotificationSettingsScreen(),
                  ));
                },
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          // Account Settings
          _buildSettingsSection(
            context,
            '계정',
            [
              _buildSettingsTile(
                icon: Icons.person,
                title: '프로필 수정',
                subtitle: '이름, 연락처 변경',
                onTap: () {
                  // TODO: Navigate to profile edit
                },
              ),
              _buildSettingsTile(
                icon: Icons.family_restroom,
                title: '자녀 관리',
                subtitle: '연결된 자녀 목록',
                onTap: () {
                  // TODO: Navigate to children management
                },
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          // Support
          _buildSettingsSection(
            context,
            '지원',
            [
              _buildSettingsTile(
                icon: Icons.help_outline,
                title: '도움말',
                subtitle: '자주 묻는 질문',
                onTap: () {},
              ),
              _buildSettingsTile(
                icon: Icons.logout,
                title: '로그아웃',
                subtitle: '',
                onTap: () {
                  // TODO: Logout
                },
                isDestructive: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    String title,
    List<Widget> tiles,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(children: tiles),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppColors.error : AppColors.textSecondaryLight,
      ),
      title: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(
          color: isDestructive ? AppColors.error : null,
        ),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiaryLight,
              ),
            )
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

/// Invitation Code Screen (Simple placeholder)
class _InvitationCodeScreen extends ConsumerStatefulWidget {
  const _InvitationCodeScreen();

  @override
  ConsumerState<_InvitationCodeScreen> createState() =>
      _InvitationCodeScreenState();
}

class _InvitationCodeScreenState extends ConsumerState<_InvitationCodeScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('초대 코드를 입력해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final invitation = await ref.read(invitationByCodeProvider(code).future);

      if (invitation == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('유효하지 않은 초대 코드입니다')),
          );
        }
        return;
      }

      if (!invitation.isValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('만료된 초대 코드입니다')),
          );
        }
        return;
      }

      // TODO: Complete the connection process
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('자녀와 연결되었습니다!')),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('초대 코드 입력')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.space6),
            Icon(
              Icons.link,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              '자녀 또는 선생님에게 받은\n초대 코드를 입력해주세요',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space6),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: '초대 코드',
                hintText: 'ABC123',
                prefixIcon: Icon(Icons.vpn_key),
              ),
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              style: AppTypography.headingMedium,
            ),
            const SizedBox(height: AppSpacing.space4),
            FilledButton(
              onPressed: _isLoading ? null : _submitCode,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('연결하기'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Parent Notification Settings Screen
class ParentNotificationSettingsScreen extends ConsumerStatefulWidget {
  const ParentNotificationSettingsScreen({super.key});

  @override
  ConsumerState<ParentNotificationSettingsScreen> createState() =>
      _ParentNotificationSettingsScreenState();
}

class _ParentNotificationSettingsScreenState
    extends ConsumerState<ParentNotificationSettingsScreen> {
  // Local state for toggle values
  bool _lessonReminder = true;
  bool _lessonComplete = true;
  bool _assignmentNew = true;
  bool _practiceReminder = true;
  bool _practiceComplete = false;
  bool _teacherMessage = true;
  bool _weeklyReport = true;
  bool _monthlyReport = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('알림 설정')),
      body: ListView(
        children: [
          // Payment notifications (required)
          _buildSection(
            '결제 알림',
            [
              _buildDisabledTile('결제 요청', '결제 요청 시 알림', true),
              _buildDisabledTile('결제 완료', '결제 완료 시 알림', true),
            ],
            hint: '결제 관련 알림은 필수로 수신됩니다',
          ),

          // Lesson notifications
          _buildSection(
            '레슨 알림',
            [
              _buildToggleTile(
                '레슨 리마인더',
                '레슨 1일 전, 1시간 전 알림',
                _lessonReminder,
                (v) => setState(() => _lessonReminder = v),
              ),
              _buildToggleTile(
                '레슨 완료',
                '레슨 완료 시 알림',
                _lessonComplete,
                (v) => setState(() => _lessonComplete = v),
              ),
            ],
          ),

          // Assignment notifications
          _buildSection(
            '과제 알림',
            [
              _buildToggleTile(
                '새 과제',
                '선생님이 새 과제를 등록했을 때',
                _assignmentNew,
                (v) => setState(() => _assignmentNew = v),
              ),
            ],
          ),

          // Practice notifications
          _buildSection(
            '연습 알림',
            [
              _buildToggleTile(
                '연습 리마인더',
                '연습 시간 알림',
                _practiceReminder,
                (v) => setState(() => _practiceReminder = v),
              ),
              _buildToggleTile(
                '연습 완료',
                '자녀가 연습을 완료했을 때',
                _practiceComplete,
                (v) => setState(() => _practiceComplete = v),
              ),
            ],
          ),

          // Communication
          _buildSection(
            '커뮤니케이션',
            [
              _buildToggleTile(
                '선생님 메시지',
                '선생님이 메시지를 보냈을 때',
                _teacherMessage,
                (v) => setState(() => _teacherMessage = v),
              ),
            ],
          ),

          // Reports
          _buildSection(
            '리포트',
            [
              _buildToggleTile(
                '주간 리포트',
                '매주 일요일 연습 현황 요약',
                _weeklyReport,
                (v) => setState(() => _weeklyReport = v),
              ),
              _buildToggleTile(
                '월간 리포트',
                '매월 말 상세 리포트',
                _monthlyReport,
                (v) => setState(() => _monthlyReport = v),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space6),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> tiles, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (hint != null) ...[
                const SizedBox(height: 4),
                Text(
                  hint,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ],
          ),
        ),
        ...tiles,
      ],
    );
  }

  Widget _buildToggleTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title, style: AppTypography.bodyMedium),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textTertiaryLight,
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildDisabledTile(String title, String subtitle, bool value) {
    return SwitchListTile(
      title: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondaryLight,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textTertiaryLight,
        ),
      ),
      value: value,
      onChanged: null, // Disabled
    );
  }
}
