import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../features/profile/domain/entities/teacher_profile.dart';
import '../../../../features/profile/profile_facade.dart';
import '../widgets/extended_profile_widgets.dart';

/// Screen for managing education, career, and certificate information.
class ExtendedProfileScreen extends ConsumerWidget {
  const ExtendedProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(teacherExtendedProfileProvider);

    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(
        title: AppStrings.profileExtendedTitle,
      ),
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (_, __) =>
                const Center(child: Text(AppStrings.profileExtendedError)),
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Text(AppStrings.profileExtendedNotFound),
            );
          }
          return _CredentialsContent(profile: profile);
        },
      ),
    );
  }
}

class _CredentialsContent extends StatelessWidget {
  final TeacherProfile profile;

  const _CredentialsContent({required this.profile});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          // Notebook × Score: "Fine." 종지부
          const SizedBox(height: AppSpacing.space6),
          Center(child: Text('Fine.', style: NotebookTypography.fine)),

          SizedBox(
            height:
                AppSpacing.space8 + MediaQuery.of(context).padding.bottom + 32,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    // Notebook × Score: _buildSectionTitle 의 title 은 Playfair sectionTitle
    // 로 통일. 3개 호출부(학력/경력/자격증) 에 일괄 반영 (§7.17).
    return Text(title, style: NotebookTypography.sectionTitle);
  }

  Widget _buildEducationSection(BuildContext context) {
    final educations = profile.education ?? [];

    return Column(
      children: [
        if (educations.isEmpty)
          ProfileEmptyCard(
            icon: Icons.school_outlined,
            message: AppStrings.profileEducationEmpty,
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
            label: AppStrings.profileEducationAdd,
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
            message: AppStrings.profileCareerEmpty,
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
            label: AppStrings.profileCareerAdd,
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
            message: AppStrings.profileCertificateEmpty,
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
            label: AppStrings.profileCertificateAdd,
            onTap: () => context.push(AppRoutes.certificateEdit),
          ),
        ],
      ],
    );
  }
}
