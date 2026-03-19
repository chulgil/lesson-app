import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/teacher_profile.dart';
import '../../../../providers/profile/teacher_extended_profile_provider.dart';

/// Preview screen showing the teacher's public profile as students would see it
class ProfilePreviewScreen extends ConsumerWidget {
  const ProfilePreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(teacherExtendedProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 미리보기'),
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('프로필을 찾을 수 없습니다'));
          }
          return _buildPreview(context, profile);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('오류가 발생했습니다')),
      ),
    );
  }

  Widget _buildPreview(BuildContext context, TeacherProfile profile) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner with gradient + avatar + name
          _buildBanner(profile),

          // Introduction section
          if (profile.introduction.isNotEmpty)
            _buildSection(
              title: '소개',
              child: Text(
                profile.introduction,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimaryLight,
                  height: 1.6,
                ),
              ),
            ),

          // Info chips: instruments, experience, lesson areas
          _buildInfoChips(profile),

          // Teaching style section
          if (profile.teachingStyle != null &&
              profile.teachingStyle!.isNotEmpty)
            _buildSection(
              title: '교수 스타일',
              child: Text(
                profile.teachingStyle!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimaryLight,
                  height: 1.6,
                ),
              ),
            ),

          // Specialties chips
          if (profile.specialties != null && profile.specialties!.isNotEmpty)
            _buildSection(
              title: '전문 분야',
              child: Wrap(
                spacing: AppSpacing.space2,
                runSpacing: AppSpacing.space2,
                children: profile.specialties!.map((specialty) {
                  return Chip(
                    label: Text(specialty),
                    labelStyle: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.08),
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusRound),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Education list
          if (profile.education != null && profile.education!.isNotEmpty)
            _buildSection(
              title: '학력',
              child: Column(
                children: profile.education!.map((edu) {
                  return _buildListItem(
                    icon: Icons.school_outlined,
                    title: '${edu.school} ${edu.major}',
                    subtitle:
                        '${edu.degree}${edu.graduationYear != null ? ' · ${edu.graduationYear}' : ''}',
                  );
                }).toList(),
              ),
            ),

          // Certificates list
          if (profile.verification.certificates.isNotEmpty)
            _buildSection(
              title: '자격증',
              child: Column(
                children: profile.verification.certificates
                    .where((c) => c.isApproved)
                    .map((cert) {
                  return _buildListItem(
                    icon: Icons.verified_outlined,
                    title: cert.name,
                    subtitle: cert.issuingBody,
                  );
                }).toList(),
              ),
            ),

          // Bottom CTA
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeight,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.push(AppRoutes.extendedProfile);
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('프로필 수정하기'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusLarge),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.space8),
        ],
      ),
    );
  }

  Widget _buildBanner(TeacherProfile profile) {
    final initial = profile.name.isNotEmpty ? profile.name[0] : '?';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: AppSpacing.space8,
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  initial,
                  style: AppTypography.displayLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                profile.name,
                style: AppTypography.headingLarge.copyWith(
                  color: Colors.white,
                ),
              ),
              if (profile.instruments.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.space2),
                Text(
                  profile.instruments.join(' · '),
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChips(TeacherProfile profile) {
    final chips = <_InfoChipData>[];

    if (profile.instruments.isNotEmpty) {
      for (final instrument in profile.instruments) {
        chips.add(_InfoChipData(
          icon: Icons.music_note_outlined,
          label: instrument,
        ));
      }
    }

    if (profile.experienceYears != null) {
      chips.add(_InfoChipData(
        icon: Icons.work_outline,
        label: '경력 ${profile.experienceYears}년',
      ));
    }

    if (profile.lessonAreas != null && profile.lessonAreas!.isNotEmpty) {
      for (final area in profile.lessonAreas!.take(3)) {
        chips.add(_InfoChipData(
          icon: Icons.location_on_outlined,
          label: area,
        ));
      }
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space4,
      ),
      child: Wrap(
        spacing: AppSpacing.space2,
        runSpacing: AppSpacing.space2,
        children: chips.map((chip) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: AppSpacing.space2,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondaryLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  chip.icon,
                  size: 16,
                  color: AppColors.textSecondaryLight,
                ),
                const SizedBox(width: AppSpacing.space1),
                Text(
                  chip.label,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.space6),
          Text(
            title,
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          child,
        ],
      ),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChipData {
  final IconData icon;
  final String label;

  const _InfoChipData({required this.icon, required this.label});
}
