import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/teacher_profile.dart';
import '../../../../providers/profile/teacher_extended_profile_provider.dart';

/// Screen for managing profile visibility settings
class ProfileVisibilityScreen extends ConsumerStatefulWidget {
  const ProfileVisibilityScreen({super.key});

  @override
  ConsumerState<ProfileVisibilityScreen> createState() =>
      _ProfileVisibilityScreenState();
}

class _ProfileVisibilityScreenState
    extends ConsumerState<ProfileVisibilityScreen> {
  bool _isLoading = false;
  late ProfileVisibilitySettings _settings;
  bool _hasChanges = false;

  final Map<ProfileVisibility, String> _visibilityLabels = {
    ProfileVisibility.public: '전체 공개',
    ProfileVisibility.students: '연결된 학생만',
    ProfileVisibility.private: '비공개',
  };

  final Map<ProfileVisibility, IconData> _visibilityIcons = {
    ProfileVisibility.public: Icons.public,
    ProfileVisibility.students: Icons.people,
    ProfileVisibility.private: Icons.lock,
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final profile = ref.read(teacherExtendedProfileProvider).valueOrNull;
    _settings = profile?.visibilitySettings ?? const ProfileVisibilitySettings();
  }

  void _updateSettings(ProfileVisibilitySettings newSettings) {
    setState(() {
      _settings = newSettings;
      _hasChanges = true;
    });
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    try {
      await ref
          .read(teacherExtendedProfileProvider.notifier)
          .updateVisibilitySettings(_settings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('설정이 저장되었습니다')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(teacherExtendedProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('공개 프로필 설정'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('저장'),
            ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('프로필을 찾을 수 없습니다'));
          }
          return _buildContent(context, profile);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, TeacherProfile profile) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        // Profile completion info
        _buildCompletionCard(profile),
        const SizedBox(height: AppSpacing.space4),

        // Search visibility toggle
        _buildSearchToggle(),
        const SizedBox(height: AppSpacing.space4),

        // Section visibility settings
        _buildSectionTitle('항목별 공개 범위'),
        const SizedBox(height: AppSpacing.space3),

        _buildVisibilityTile(
          title: '이름',
          subtitle: '프로필에 표시되는 이름',
          icon: Icons.person,
          value: _settings.nameVisibility,
          onChanged: (v) => _updateSettings(_settings.copyWith(nameVisibility: v)),
        ),

        _buildVisibilityTile(
          title: '프로필 사진',
          subtitle: '프로필 이미지',
          icon: Icons.photo_camera,
          value: _settings.photoVisibility,
          onChanged: (v) => _updateSettings(_settings.copyWith(photoVisibility: v)),
        ),

        _buildVisibilityTile(
          title: '연락처',
          subtitle: '전화번호, 이메일 등',
          icon: Icons.phone,
          value: _settings.contactVisibility,
          onChanged: (v) => _updateSettings(_settings.copyWith(contactVisibility: v)),
        ),

        _buildVisibilityTile(
          title: '레슨료',
          subtitle: '레슨 가격 정보',
          icon: Icons.payments,
          value: _settings.feeVisibility,
          onChanged: (v) => _updateSettings(_settings.copyWith(feeVisibility: v)),
        ),

        _buildVisibilityTile(
          title: '경력',
          subtitle: '학력 및 경력 정보',
          icon: Icons.work,
          value: _settings.careerVisibility,
          onChanged: (v) => _updateSettings(_settings.copyWith(careerVisibility: v)),
        ),

        _buildVisibilityTile(
          title: '자격증',
          subtitle: '인증된 자격증 정보',
          icon: Icons.verified,
          value: _settings.certificateVisibility,
          onChanged: (v) => _updateSettings(_settings.copyWith(certificateVisibility: v)),
        ),

        const SizedBox(height: AppSpacing.space4),

        // Info card
        _buildInfoCard(),

        const SizedBox(height: AppSpacing.space6),

        // Preview button
        SizedBox(
          width: double.infinity,
          height: AppSpacing.buttonHeight,
          child: OutlinedButton.icon(
            onPressed: () => _showProfilePreview(context, profile),
            icon: const Icon(Icons.preview),
            label: const Text('공개 프로필 미리보기'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionCard(TeacherProfile profile) {
    final level = profile.completionLevel;
    final percentage = profile.completionPercentage;

    Color levelColor;
    String levelLabel;
    String levelDescription;

    switch (level) {
      case ProfileCompletionLevel.minimum:
        levelColor = AppColors.error;
        levelLabel = '최소';
        levelDescription = '검색 노출이 제한됩니다';
      case ProfileCompletionLevel.basic:
        levelColor = AppColors.warning;
        levelLabel = '기본';
        levelDescription = '제한적으로 검색에 노출됩니다';
      case ProfileCompletionLevel.standard:
        levelColor = AppColors.info;
        levelLabel = '표준';
        levelDescription = '검색에 정상 노출됩니다';
      case ProfileCompletionLevel.complete:
        levelColor = AppColors.success;
        levelLabel = '완성';
        levelDescription = '프리미엄 노출 혜택을 받습니다';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: levelColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: levelColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space2,
                  vertical: AppSpacing.space1,
                ),
                decoration: BoxDecoration(
                  color: levelColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Text(
                  levelLabel,
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '프로필 완성도 $percentage%',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: levelColor.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(levelColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            levelDescription,
            style: AppTypography.bodySmall.copyWith(
              color: levelColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchToggle() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: _settings.isSearchable ? AppColors.primary : AppColors.textTertiaryLight,
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '검색 노출 허용',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '학생/학부모가 선생님을 검색할 수 있습니다',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _settings.isSearchable,
            onChanged: (value) {
              _updateSettings(_settings.copyWith(isSearchable: value));
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.headingSmall.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildVisibilityTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required ProfileVisibility value,
    required ValueChanged<ProfileVisibility> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space2),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textSecondaryLight),
        title: Text(title, style: AppTypography.bodyMedium),
        subtitle: Text(
          subtitle,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        trailing: PopupMenuButton<ProfileVisibility>(
          initialValue: value,
          onSelected: onChanged,
          offset: const Offset(0, 40),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space2,
              vertical: AppSpacing.space1,
            ),
            decoration: BoxDecoration(
              color: _getVisibilityColor(value).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _visibilityIcons[value],
                  size: 16,
                  color: _getVisibilityColor(value),
                ),
                const SizedBox(width: 4),
                Text(
                  _visibilityLabels[value]!,
                  style: AppTypography.caption.copyWith(
                    color: _getVisibilityColor(value),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  size: 20,
                  color: _getVisibilityColor(value),
                ),
              ],
            ),
          ),
          itemBuilder: (context) => ProfileVisibility.values.map((v) {
            return PopupMenuItem(
              value: v,
              child: Row(
                children: [
                  Icon(
                    _visibilityIcons[v],
                    size: 20,
                    color: _getVisibilityColor(v),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Text(_visibilityLabels[v]!),
                  if (v == value) ...[
                    const Spacer(),
                    Icon(Icons.check, size: 20, color: AppColors.primary),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getVisibilityColor(ProfileVisibility visibility) {
    switch (visibility) {
      case ProfileVisibility.public:
        return AppColors.success;
      case ProfileVisibility.students:
        return AppColors.info;
      case ProfileVisibility.private:
        return AppColors.textTertiaryLight;
    }
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: AppColors.info),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '공개 범위 안내',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  '• 전체 공개: 누구나 볼 수 있습니다\n'
                  '• 연결된 학생만: 연결된 학생/학부모만 볼 수 있습니다\n'
                  '• 비공개: 아무에게도 표시되지 않습니다',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showProfilePreview(BuildContext context, TeacherProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.visibility, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '공개 프로필 미리보기',
                      style: AppTypography.headingSmall,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildPreviewContent(profile),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewContent(TeacherProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile header
        Center(
          child: Column(
            children: [
              if (_settings.photoVisibility == ProfileVisibility.public)
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.surfaceSecondaryLight,
                  backgroundImage: profile.profileImage != null
                      ? NetworkImage(profile.profileImage!)
                      : null,
                  child: profile.profileImage == null
                      ? Icon(Icons.person, size: 50, color: AppColors.textSecondaryLight)
                      : null,
                )
              else
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.surfaceSecondaryLight,
                  child: Icon(
                    Icons.visibility_off,
                    size: 30,
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              const SizedBox(height: AppSpacing.space3),
              if (_settings.nameVisibility == ProfileVisibility.public)
                Text(
                  profile.name,
                  style: AppTypography.headingLarge,
                )
              else
                Text(
                  '비공개',
                  style: AppTypography.headingLarge.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              const SizedBox(height: AppSpacing.space1),
              if (profile.instruments.isNotEmpty)
                Text(
                  profile.instruments.join(' · '),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.space4),

        // Badges
        if (profile.allBadges.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: profile.allBadges.map((badge) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getBadgeIcon(badge),
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getBadgeLabel(badge),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.space4),
        ],

        // Introduction
        _buildPreviewSection(
          title: '소개',
          isVisible: true,
          child: Text(
            profile.introduction,
            style: AppTypography.bodyMedium,
          ),
        ),

        // Fee
        if (profile.feeRange != null)
          _buildPreviewSection(
            title: '레슨료',
            isVisible: _settings.feeVisibility == ProfileVisibility.public,
            child: Text(
              profile.feeRange!.formatted,
              style: AppTypography.bodyMedium,
            ),
          ),

        // Career & Education
        if ((profile.career != null && profile.career!.isNotEmpty) ||
            (profile.education != null && profile.education!.isNotEmpty))
          _buildPreviewSection(
            title: '경력 및 학력',
            isVisible: _settings.careerVisibility == ProfileVisibility.public,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (profile.education != null)
                  ...profile.education!.map((edu) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${edu.school} ${edu.major} (${edu.degree})',
                          style: AppTypography.bodySmall,
                        ),
                      )),
                if (profile.career != null)
                  ...profile.career!.map((career) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${career.organization} - ${career.position} (${career.period})',
                          style: AppTypography.bodySmall,
                        ),
                      )),
              ],
            ),
          ),

        // Certificates
        if (profile.verification.certificates.isNotEmpty)
          _buildPreviewSection(
            title: '자격증',
            isVisible: _settings.certificateVisibility == ProfileVisibility.public,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: profile.verification.certificates
                  .where((c) => c.isApproved)
                  .map((cert) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.verified,
                              size: 16,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                cert.name,
                                style: AppTypography.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),

        // Contact
        _buildPreviewSection(
          title: '연락처',
          isVisible: _settings.contactVisibility == ProfileVisibility.public,
          child: Text(
            profile.verification.phoneNumber ?? '등록된 연락처 없음',
            style: AppTypography.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewSection({
    required String title,
    required bool isVisible,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: isVisible
            ? AppColors.surfaceSecondaryLight
            : AppColors.surfaceSecondaryLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!isVisible) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.textTertiaryLight.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '비공개',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiaryLight,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          if (isVisible)
            child
          else
            Text(
              '이 정보는 공개되지 않습니다',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiaryLight,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  IconData _getBadgeIcon(VerificationBadge badge) {
    switch (badge) {
      case VerificationBadge.phoneVerified:
        return Icons.phone_android;
      case VerificationBadge.certified:
        return Icons.verified;
      case VerificationBadge.premium:
        return Icons.star;
    }
  }

  String _getBadgeLabel(VerificationBadge badge) {
    switch (badge) {
      case VerificationBadge.phoneVerified:
        return '본인인증';
      case VerificationBadge.certified:
        return '자격인증';
      case VerificationBadge.premium:
        return '프리미엄';
    }
  }
}
