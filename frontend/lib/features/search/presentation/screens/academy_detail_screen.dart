import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../features/inbox/inbox_ui_facade.dart';
import '../../../../features/profile/domain/entities/teacher_search.dart';
import '../../domain/repositories/teacher_search_repository.dart';
import '../../../parent_home/parent_home_facade.dart';
import '../../search_facade.dart';

/// Academy detail screen - shows academy info and teacher list
class AcademyDetailScreen extends ConsumerWidget {
  final String organizationId;

  const AcademyDetailScreen({super.key, required this.organizationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final academyAsync = ref.watch(academyInfoProvider(organizationId));
    final teachersAsync = ref.watch(academyTeachersProvider(organizationId));

    return NotebookScreenScaffold(
      backgroundColor: AppColors.paperDark,
      appBar: NotebookDetailAppBar(
        title:
            academyAsync.valueOrNull != null
                ? '${academyAsync.valueOrNull!.name} (학원)'
                : AppStrings.searchTabAcademy,
      ),
      body: academyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, AppStrings.searchAcademyLoadError),
        data: (academy) {
          if (academy == null) {
            return _buildErrorState(context, AppStrings.searchAcademyNotFound);
          }
          return _buildScrollBody(context, ref, academy, teachersAsync);
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.inkSecondary),
          const SizedBox(height: AppSpacing.space4),
          Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text(AppStrings.goBack),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollBody(
    BuildContext context,
    WidgetRef ref,
    AcademyInfo academy,
    AsyncValue<List<TeacherPublicProfile>> teachersAsync,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Academy header (previously in SliverAppBar flexibleSpace)
          Container(
            width: double.infinity,
            color: AppColors.paperAccent,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.space6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(color: AppColors.paper),
                  child: Icon(
                    Icons.school,
                    size: 36,
                    color: AppColors.paperAccent,
                  ),
                ),
                const SizedBox(height: AppSpacing.space3),
                Text(
                  academy.name,
                  style: AppTypography.headingMedium.copyWith(
                    color: AppColors.paper,
                  ),
                ),
              ],
            ),
          ),

          // Academy info + teacher list
          Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAcademyInfoCard(academy),
                const SizedBox(height: AppSpacing.space6),
                _buildTeacherListHeader(academy),
                const SizedBox(height: AppSpacing.space3),
              ],
            ),
          ),

          // Teachers
          teachersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (error, stack) => Center(
                  child: Text(
                    AppStrings.searchAcademyTeacherListError,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ),
            data: (teachers) => _buildTeacherList(context, ref, teachers),
          ),

          // G20/#401 — 문의하기 폼
          const SizedBox(height: AppSpacing.space6),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.space4),
              decoration: BoxDecoration(color: AppColors.paper),
              child: AcademyInquiryFormWidget(academyId: organizationId),
            ),
          ),

          // Notebook × Score: "Fine." 종지부
          const SizedBox(height: AppSpacing.space6),
          Center(child: Text('Fine.', style: NotebookTypography.fine)),
          const SizedBox(height: AppSpacing.space8),
        ],
      ),
    );
  }

  Widget _buildAcademyInfoCard(AcademyInfo academy) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(color: AppColors.paper),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Address
          if (academy.address != null) ...[
            _buildInfoRow(
              icon: Icons.location_on_outlined,
              text: academy.address!,
            ),
            const SizedBox(height: AppSpacing.space3),
          ],
          // Phone
          if (academy.phone != null) ...[
            _buildInfoRow(icon: Icons.phone_outlined, text: academy.phone!),
            const SizedBox(height: AppSpacing.space3),
          ],
          // Instruments
          if (academy.instruments.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.music_note, size: 20, color: AppColors.paperAccent),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Wrap(
                    spacing: AppSpacing.space2,
                    runSpacing: AppSpacing.space1,
                    children:
                        academy.instruments
                            .map(
                              (i) => Chip(
                                label: Text(i),
                                backgroundColor: AppColors.paperAccent
                                    .withValues(alpha: 0.1),
                                labelStyle: AppTypography.bodySmall.copyWith(
                                  color: AppColors.paperAccent,
                                ),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.paperAccent),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherListHeader(AcademyInfo academy) {
    return Row(
      children: [
        Icon(Icons.people_outline, size: 20, color: AppColors.paperAccent),
        const SizedBox(width: AppSpacing.space2),
        // Notebook × Score: 카테고리 섹션 제목은 Playfair sectionTitle
        // (§7.17). '소속 선생님' 은 정적 그룹 헤더.
        Text(
          AppStrings.searchAffiliatedTeachers,
          style: NotebookTypography.sectionTitle,
        ),
        const SizedBox(width: AppSpacing.space2),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space2,
            vertical: 2,
          ),
          decoration: BoxDecoration(color: AppColors.paperAccentSoft),
          child: Text(
            '${academy.teacherCount}명',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.paperAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherList(
    BuildContext context,
    WidgetRef ref,
    List<TeacherPublicProfile> teachers,
  ) {
    // G5/W3: 학원 공개 페이지 노출 동의(publicPageConsent=true)한 강사만 표시.
    final publicTeachers = teachers.where((t) => t.publicPageConsent).toList();

    if (publicTeachers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Center(
          child: Text(
            AppStrings.searchAcademyNoPublicTeachers,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ),
      );
    }

    return Column(
      children:
          publicTeachers.map((teacher) {
            return _AcademyTeacherCard(
              teacher: teacher,
              onProfileTap: () {
                context.push(
                  AppRoutes.teacherDetail.replaceFirst(':id', teacher.id),
                );
              },
              onTrialTap: () {
                final userProfile = ref.read(currentUserProfileProvider);
                context.push(
                  AppRoutes.lessonBooking,
                  extra: {
                    'teacherId': teacher.id,
                    'teacherName': teacher.name ?? '',
                    'instrument':
                        teacher.instruments.isNotEmpty
                            ? teacher.instruments.first
                            : AppStrings.instrumentLabel,
                    'studentId': userProfile.userId,
                    'studentName': userProfile.userName,
                    'isTrialLesson': true,
                  },
                );
              },
            );
          }).toList(),
    );
  }
}

/// Teacher card widget for academy detail screen
class _AcademyTeacherCard extends StatelessWidget {
  final TeacherPublicProfile teacher;
  final VoidCallback onProfileTap;
  final VoidCallback onTrialTap;

  const _AcademyTeacherCard({
    required this.teacher,
    required this.onProfileTap,
    required this.onTrialTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(color: AppColors.paper),
      child: InkWell(
        onTap: onProfileTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Row(
            children: [
              // Profile image
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.paperAccentSoft,
                backgroundImage:
                    teacher.profileImage != null
                        ? NetworkImage(teacher.profileImage!)
                        : null,
                child:
                    teacher.profileImage == null
                        ? Icon(
                          Icons.person,
                          color: AppColors.paperAccent,
                          size: 28,
                        )
                        : null,
              ),
              const SizedBox(width: AppSpacing.space3),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teacher.name ?? AppStrings.searchAnonymousTeacher,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Row(
                      children: [
                        Text(
                          teacher.instruments.join(' · '),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.inkSecondary,
                          ),
                        ),
                        if (teacher.experienceYears != null) ...[
                          Text(
                            ' | ${teacher.experienceYears}년 경력',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.inkSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Action button
              ElevatedButton(
                onPressed: onTrialTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.paperAccent,
                  foregroundColor: AppColors.paper,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space3,
                    vertical: AppSpacing.space2,
                  ),
                  shape: const RoundedRectangleBorder(),
                ),
                child: const Text(AppStrings.searchTrialApply),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
