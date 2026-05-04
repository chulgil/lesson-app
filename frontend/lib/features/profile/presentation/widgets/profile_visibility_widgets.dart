import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../features/profile/domain/entities/teacher_profile.dart';

/// Labels for visibility options
const Map<ProfileVisibility, String> visibilityLabels = {
  ProfileVisibility.public: '전체 공개',
  ProfileVisibility.students: '연결된 학생만',
  ProfileVisibility.private: '비공개',
};

/// Icons for visibility options
const Map<ProfileVisibility, IconData> visibilityIcons = {
  ProfileVisibility.public: Icons.public,
  ProfileVisibility.students: Icons.people,
  ProfileVisibility.private: Icons.lock,
};

/// Get color for visibility option
Color getVisibilityColor(ProfileVisibility visibility) {
  switch (visibility) {
    case ProfileVisibility.public:
      return AppColors.paperOk;
    case ProfileVisibility.students:
      return AppColors.ink;
    case ProfileVisibility.private:
      return AppColors.inkTertiary;
  }
}

/// Get icon for verification badge
IconData getBadgeIcon(VerificationBadge badge) {
  switch (badge) {
    case VerificationBadge.phoneVerified:
      return Icons.phone_android;
    case VerificationBadge.certified:
      return Icons.verified;
    case VerificationBadge.premium:
      return Icons.star;
  }
}

/// Get label for verification badge
String getBadgeLabel(VerificationBadge badge) {
  switch (badge) {
    case VerificationBadge.phoneVerified:
      return '본인인증';
    case VerificationBadge.certified:
      return '자격인증';
    case VerificationBadge.premium:
      return '프리미엄';
  }
}

/// Profile completion card widget
class ProfileCompletionCard extends StatelessWidget {
  final TeacherProfile profile;

  const ProfileCompletionCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final level = profile.completionLevel;
    final percentage = profile.completionPercentage;

    Color levelColor;
    String levelLabel;
    String levelDescription;

    switch (level) {
      case ProfileCompletionLevel.minimum:
        levelColor = AppColors.paperAccent;
        levelLabel = '최소';
        levelDescription = '검색 노출이 제한됩니다';
      case ProfileCompletionLevel.basic:
        levelColor = AppColors.paperAccent;
        levelLabel = '기본';
        levelDescription = '제한적으로 검색에 노출됩니다';
      case ProfileCompletionLevel.standard:
        levelColor = AppColors.ink;
        levelLabel = '표준';
        levelDescription = '검색에 정상 노출됩니다';
      case ProfileCompletionLevel.complete:
        levelColor = AppColors.paperOk;
        levelLabel = '완성';
        levelDescription = '프리미엄 노출 혜택을 받습니다';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: levelColor.withValues(alpha: 0.1),
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
                decoration: BoxDecoration(color: levelColor),
                child: Text(
                  levelLabel,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.paper,
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
            borderRadius: BorderRadius.zero,
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
            style: AppTypography.bodySmall.copyWith(color: levelColor),
          ),
        ],
      ),
    );
  }
}

/// Search toggle widget
class SearchToggle extends StatelessWidget {
  final bool isSearchable;
  final ValueChanged<bool> onChanged;

  const SearchToggle({
    super.key,
    required this.isSearchable,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: const BoxDecoration(color: AppColors.paperDark),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: isSearchable ? AppColors.paperAccent : AppColors.inkTertiary,
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
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isSearchable,
            onChanged: onChanged,
            activeThumbColor: AppColors.paperAccent,
          ),
        ],
      ),
    );
  }
}

/// Section title widget for visibility settings
class VisibilitySectionTitle extends StatelessWidget {
  final String title;

  const VisibilitySectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    // Notebook × Score: 공개 범위 설정 섹션 제목도 Playfair sectionTitle(17) 로 통일.
    return Text(title, style: NotebookTypography.sectionTitle);
  }
}

/// Visibility tile widget
class VisibilityTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final ProfileVisibility value;
  final ValueChanged<ProfileVisibility> onChanged;

  const VisibilityTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space2),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.inkSecondary),
        title: Text(title, style: AppTypography.bodyMedium),
        subtitle: Text(
          subtitle,
          style: AppTypography.caption.copyWith(color: AppColors.inkSecondary),
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
              color: getVisibilityColor(value).withValues(alpha: 0.1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  visibilityIcons[value],
                  size: 16,
                  color: getVisibilityColor(value),
                ),
                const SizedBox(width: AppSpacing.space1),
                Text(
                  visibilityLabels[value]!,
                  style: AppTypography.caption.copyWith(
                    color: getVisibilityColor(value),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: AppSpacing.space1),
                Icon(
                  Icons.arrow_drop_down,
                  size: 20,
                  color: getVisibilityColor(value),
                ),
              ],
            ),
          ),
          itemBuilder:
              (context) =>
                  ProfileVisibility.values.map((v) {
                    return PopupMenuItem(
                      value: v,
                      child: Row(
                        children: [
                          Icon(
                            visibilityIcons[v],
                            size: 20,
                            color: getVisibilityColor(v),
                          ),
                          const SizedBox(width: AppSpacing.space2),
                          Text(visibilityLabels[v]!),
                          if (v == value) ...[
                            const Spacer(),
                            Icon(
                              Icons.check,
                              size: 20,
                              color: AppColors.paperAccent,
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
        ),
      ),
    );
  }
}

/// Info card for visibility settings
class VisibilityInfoCard extends StatelessWidget {
  const VisibilityInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(color: AppColors.ink.withValues(alpha: 0.1)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: AppColors.ink),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '공개 범위 안내',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  '• 전체 공개: 누구나 볼 수 있습니다\n'
                  '• 연결된 학생만: 연결된 학생/학부모만 볼 수 있습니다\n'
                  '• 비공개: 아무에게도 표시되지 않습니다',
                  style: AppTypography.caption.copyWith(color: AppColors.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Preview section widget for profile preview
class PreviewSection extends StatelessWidget {
  final String title;
  final bool isVisible;
  final Widget child;

  const PreviewSection({
    super.key,
    required this.title,
    required this.isVisible,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color:
            isVisible
                ? AppColors.paperDark
                : AppColors.paperDark.withValues(alpha: 0.5),
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
                const SizedBox(width: AppSpacing.space2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.inkTertiary.withValues(alpha: 0.2),
                  ),
                  child: Text(
                    '비공개',
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.inkTertiary,
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
                color: AppColors.inkTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}

/// Badge chip widget for profile preview
class BadgeChip extends StatelessWidget {
  final VerificationBadge badge;

  const BadgeChip({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: AppColors.paperAccentSoft),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(getBadgeIcon(badge), size: 16, color: AppColors.paperAccent),
          const SizedBox(width: AppSpacing.space1),
          Text(
            getBadgeLabel(badge),
            style: AppTypography.caption.copyWith(
              color: AppColors.paperAccent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Show profile preview bottom sheet
void showProfilePreviewSheet({
  required BuildContext context,
  required TeacherProfile profile,
  required ProfileVisibilitySettings settings,
}) {
  showNotebookModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder:
        (context) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder:
              (context, scrollController) => Container(
                decoration: const BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.zero,
                ),
                child: Column(
                  children: [
                    // Handle bar
                    const BottomSheetHandle(
                      margin: EdgeInsets.symmetric(vertical: AppSpacing.space3),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space4,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.visibility, size: 20),
                          const SizedBox(width: AppSpacing.space2),
                          // Notebook × Score: BottomSheetHandle + 상단 제목 조합은 §7.27
                          // 패턴. Playfair appBarTitle 로 통일.
                          Text(
                            '공개 프로필 미리보기',
                            style: NotebookTypography.appBarTitle,
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
                        padding: const EdgeInsets.all(AppSpacing.space4),
                        children: [
                          ProfilePreviewContent(
                            profile: profile,
                            settings: settings,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        ),
  );
}

/// Profile preview content widget
class ProfilePreviewContent extends StatelessWidget {
  final TeacherProfile profile;
  final ProfileVisibilitySettings settings;

  const ProfilePreviewContent({
    super.key,
    required this.profile,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile header
        Center(
          child: Column(
            children: [
              if (settings.photoVisibility == ProfileVisibility.public)
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.paperDark,
                  backgroundImage:
                      profile.profileImage != null
                          ? NetworkImage(profile.profileImage!)
                          : null,
                  child:
                      profile.profileImage == null
                          ? Icon(
                            Icons.person,
                            size: 50,
                            color: AppColors.inkSecondary,
                          )
                          : null,
                )
              else
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.paperDark,
                  child: Icon(
                    Icons.visibility_off,
                    size: 30,
                    color: AppColors.inkTertiary,
                  ),
                ),
              const SizedBox(height: AppSpacing.space3),
              if (settings.nameVisibility == ProfileVisibility.public)
                Text(profile.name, style: AppTypography.headingLarge)
              else
                Text(
                  '비공개',
                  style: AppTypography.headingLarge.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                ),
              const SizedBox(height: AppSpacing.space1),
              if (profile.instruments.isNotEmpty)
                Text(
                  profile.instruments.join(' · '),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.inkSecondary,
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
            children:
                profile.allBadges
                    .map((badge) => BadgeChip(badge: badge))
                    .toList(),
          ),
          const SizedBox(height: AppSpacing.space4),
        ],

        // Introduction
        PreviewSection(
          title: AppStrings.profileVisibilitySectionIntro,
          isVisible: true,
          child: Text(profile.introduction, style: AppTypography.bodyMedium),
        ),

        // Fee
        if (profile.feeRange != null)
          PreviewSection(
            title: AppStrings.profileVisibilitySectionFee,
            isVisible: settings.feeVisibility == ProfileVisibility.public,
            child: Text(
              profile.feeRange!.formatted,
              style: AppTypography.bodyMedium,
            ),
          ),

        // Career & Education
        if ((profile.career != null && profile.career!.isNotEmpty) ||
            (profile.education != null && profile.education!.isNotEmpty))
          PreviewSection(
            title: AppStrings.profileVisibilitySectionCareerEdu,
            isVisible: settings.careerVisibility == ProfileVisibility.public,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (profile.education != null)
                  ...profile.education!.map(
                    (edu) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.space1),
                      child: Text(
                        '${edu.school} ${edu.major} (${edu.degree})',
                        style: AppTypography.bodySmall,
                      ),
                    ),
                  ),
                if (profile.career != null)
                  ...profile.career!.map(
                    (career) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.space1),
                      child: Text(
                        '${career.organization} - ${career.position} (${career.period})',
                        style: AppTypography.bodySmall,
                      ),
                    ),
                  ),
              ],
            ),
          ),

        // Certificates
        if (profile.verification.certificates.isNotEmpty)
          PreviewSection(
            title: AppStrings.profileVisibilitySectionCertificate,
            isVisible:
                settings.certificateVisibility == ProfileVisibility.public,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  profile.verification.certificates
                      .where((c) => c.isApproved)
                      .map(
                        (cert) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.space1,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.verified,
                                size: 16,
                                color: AppColors.paperOk,
                              ),
                              const SizedBox(width: AppSpacing.space1),
                              Expanded(
                                child: Text(
                                  cert.name,
                                  style: AppTypography.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),

        // Contact
        PreviewSection(
          title: AppStrings.profileVisibilitySectionContact,
          isVisible: settings.contactVisibility == ProfileVisibility.public,
          child: Text(
            profile.verification.phoneNumber ?? '등록된 연락처 없음',
            style: AppTypography.bodyMedium,
          ),
        ),
      ],
    );
  }
}
