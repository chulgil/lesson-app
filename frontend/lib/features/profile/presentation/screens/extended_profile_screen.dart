import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/teacher_profile.dart';
import '../../../../providers/profile/teacher_extended_profile_provider.dart';
import '../widgets/extended_profile_dialogs.dart';
import '../widgets/extended_profile_widgets.dart';

/// Extended profile screen for managing detailed teacher information
class ExtendedProfileScreen extends ConsumerWidget {
  const ExtendedProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(teacherExtendedProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('상세 프로필'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility_outlined),
            tooltip: '공개 설정',
            onPressed: () => context.push(AppRoutes.profileVisibility),
          ),
        ],
      ),
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('프로필을 찾을 수 없습니다'));
          }
          return _ProfileContent(profile: profile);
        },
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  final TeacherProfile profile;

  const _ProfileContent({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile completion card
          ProfileCompletionCard(profile: profile),

          const SizedBox(height: AppSpacing.space6),

          // Lesson content management shortcuts
          _buildSectionTitle('레슨 콘텐츠'),
          const SizedBox(height: AppSpacing.space3),
          _buildQuickLinkRow(context),

          const SizedBox(height: AppSpacing.space6),

          // Experience & Fee section
          _buildSectionTitle('기본 정보'),
          const SizedBox(height: AppSpacing.space3),
          _buildExperienceCard(context, ref),
          const SizedBox(height: AppSpacing.space3),
          _buildFeeCard(context, ref),
          const SizedBox(height: AppSpacing.space3),
          _buildLessonTypesCard(context, ref),
          const SizedBox(height: AppSpacing.space3),
          _buildLessonAreasCard(context, ref),

          const SizedBox(height: AppSpacing.space6),

          // Education section
          _buildSectionTitle('학력'),
          const SizedBox(height: AppSpacing.space3),
          _buildEducationSection(context),

          const SizedBox(height: AppSpacing.space6),

          // Career section
          _buildSectionTitle('경력'),
          const SizedBox(height: AppSpacing.space3),
          _buildCareerSection(context),

          const SizedBox(height: AppSpacing.space6),

          // Certificate section
          _buildSectionTitle('자격증'),
          const SizedBox(height: AppSpacing.space3),
          _buildCertificateSection(context),

          const SizedBox(height: AppSpacing.space8),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.headingSmall,
    );
  }

  Widget _buildQuickLinkRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickLinkCard(
            icon: Icons.music_note,
            label: '악기 관리',
            onTap: () => context.push(AppRoutes.instrumentManagement),
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: _QuickLinkCard(
            icon: Icons.library_music,
            label: '레퍼토리 관리',
            onTap: () => context.push(AppRoutes.repertoireManagement),
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceCard(BuildContext context, WidgetRef ref) {
    return ProfileInfoCard(
      icon: Icons.work_history_outlined,
      title: '교육 경력',
      value: profile.experienceYears != null
          ? '${profile.experienceYears}년'
          : '미입력',
      isEmpty: profile.experienceYears == null,
      onTap: () => showExperienceDialog(context, ref, profile),
    );
  }

  Widget _buildFeeCard(BuildContext context, WidgetRef ref) {
    return ProfileInfoCard(
      icon: Icons.payments_outlined,
      title: '레슨료',
      value: profile.feeRange?.formatted ?? '미입력',
      isEmpty: profile.feeRange == null,
      onTap: () => showFeeDialog(context, ref, profile),
    );
  }

  Widget _buildLessonTypesCard(BuildContext context, WidgetRef ref) {
    final types = profile.lessonTypes ?? [];
    final typeLabels = types.map(getLessonTypeLabel).join(', ');

    return ProfileInfoCard(
      icon: Icons.school_outlined,
      title: '레슨 방식',
      value: types.isNotEmpty ? typeLabels : '미입력',
      isEmpty: types.isEmpty,
      onTap: () => showLessonTypesDialog(context, ref, profile),
    );
  }

  Widget _buildLessonAreasCard(BuildContext context, WidgetRef ref) {
    final areas = profile.lessonAreas ?? [];

    return ProfileInfoCard(
      icon: Icons.location_on_outlined,
      title: '레슨 가능 지역',
      value: areas.isNotEmpty ? areas.join(', ') : '미입력',
      isEmpty: areas.isEmpty,
      onTap: () => showAreasDialog(context, ref, profile),
    );
  }

  Widget _buildEducationSection(BuildContext context) {
    final educations = profile.education ?? [];

    return Column(
      children: [
        if (educations.isEmpty)
          ProfileEmptyCard(
            icon: Icons.school_outlined,
            message: '학력 정보가 없습니다',
            buttonText: '학력 추가',
            onTap: () => context.push(AppRoutes.educationEdit),
          )
        else ...[
          ...educations.asMap().entries.map((entry) {
            final index = entry.key;
            final edu = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < educations.length - 1 ? AppSpacing.space3 : 0,
              ),
              child: EducationCard(education: edu, index: index),
            );
          }),
          const SizedBox(height: AppSpacing.space3),
          ProfileAddButton(
            label: '학력 추가',
            onTap: () => context.push(AppRoutes.educationEdit),
          ),
        ],
      ],
    );
  }

  Widget _buildCareerSection(BuildContext context) {
    final careers = profile.career ?? [];

    return Column(
      children: [
        if (careers.isEmpty)
          ProfileEmptyCard(
            icon: Icons.work_outline,
            message: '경력 정보가 없습니다',
            buttonText: '경력 추가',
            onTap: () => context.push(AppRoutes.careerEdit),
          )
        else ...[
          ...careers.asMap().entries.map((entry) {
            final index = entry.key;
            final career = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < careers.length - 1 ? AppSpacing.space3 : 0,
              ),
              child: CareerCard(career: career, index: index),
            );
          }),
          const SizedBox(height: AppSpacing.space3),
          ProfileAddButton(
            label: '경력 추가',
            onTap: () => context.push(AppRoutes.careerEdit),
          ),
        ],
      ],
    );
  }

  Widget _buildCertificateSection(BuildContext context) {
    final certificates = profile.verification.certificates;

    return Column(
      children: [
        if (certificates.isEmpty)
          ProfileEmptyCard(
            icon: Icons.verified_outlined,
            message: '등록된 자격증이 없습니다',
            buttonText: '자격증 추가',
            onTap: () => context.push(AppRoutes.certificateEdit),
          )
        else ...[
          ...certificates.map((cert) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: certificates.last != cert ? AppSpacing.space3 : 0,
              ),
              child: CertificateCard(certificate: cert),
            );
          }),
          const SizedBox(height: AppSpacing.space3),
          ProfileAddButton(
            label: '자격증 추가',
            onTap: () => context.push(AppRoutes.certificateEdit),
          ),
        ],
      ],
    );
  }
}

class _QuickLinkCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickLinkCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: AppSpacing.space2),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
