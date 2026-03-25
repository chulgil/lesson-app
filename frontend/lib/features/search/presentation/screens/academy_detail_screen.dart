import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/profile/domain/entities/teacher_search.dart';
import '../../../../repositories/teacher_search_repository.dart';
import '../../../parent_home/presentation/providers/user_profile_provider.dart';
import '../providers/teacher_search_provider.dart';

/// Academy detail screen - shows academy info and teacher list
class AcademyDetailScreen extends ConsumerWidget {
  final String organizationId;

  const AcademyDetailScreen({
    super.key,
    required this.organizationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final academyAsync = ref.watch(academyInfoProvider(organizationId));
    final teachersAsync = ref.watch(academyTeachersProvider(organizationId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: academyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, '학원 정보를 불러올 수 없습니다'),
        data: (academy) {
          if (academy == null) {
            return _buildErrorState(context, '학원 정보를 찾을 수 없습니다');
          }
          return CustomScrollView(
            slivers: [
              _buildAppBar(context, academy),
              SliverToBoxAdapter(
                child: Padding(
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
              ),
              teachersAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => SliverToBoxAdapter(
                  child: Center(
                    child: Text(
                      '선생님 목록을 불러올 수 없습니다',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textSecondaryLight),
                    ),
                  ),
                ),
                data: (teachers) => _buildTeacherList(context, ref, teachers),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.space6),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.textSecondaryLight),
          const SizedBox(height: AppSpacing.space4),
          Text(
            message,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: AppSpacing.space4),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('돌아가기'),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, AcademyInfo academy) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.school,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    academy.name,
                    style: AppTypography.headingMedium
                        .copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAcademyInfoCard(AcademyInfo academy) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
            _buildInfoRow(
              icon: Icons.phone_outlined,
              text: academy.phone!,
            ),
            const SizedBox(height: AppSpacing.space3),
          ],
          // Instruments
          if (academy.instruments.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.music_note,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Wrap(
                    spacing: AppSpacing.space2,
                    runSpacing: AppSpacing.space1,
                    children: academy.instruments
                        .map((i) => Chip(
                              label: Text(i),
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              labelStyle: AppTypography.bodySmall
                                  .copyWith(color: AppColors.primary),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ))
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
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondaryLight),
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherListHeader(AcademyInfo academy) {
    return Row(
      children: [
        Icon(Icons.people_outline, size: 20, color: AppColors.primary),
        const SizedBox(width: AppSpacing.space2),
        Text(
          '소속 선생님',
          style: AppTypography.headingSmall,
        ),
        const SizedBox(width: AppSpacing.space2),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space2,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${academy.teacherCount}명',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  SliverList _buildTeacherList(
    BuildContext context,
    WidgetRef ref,
    List<TeacherPublicProfile> teachers,
  ) {
    if (teachers.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Center(
              child: Text(
                '소속 선생님이 없습니다',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondaryLight),
              ),
            ),
          ),
        ]),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final teacher = teachers[index];
          return _AcademyTeacherCard(
            teacher: teacher,
            onProfileTap: () {
              context.push(AppRoutes.teacherDetail.replaceFirst(':id', teacher.id));
            },
            onTrialTap: () {
              final userProfile = ref.read(currentUserProfileProvider);
              context.push(
                '/schedule/booking',
                extra: {
                  'teacherId': teacher.id,
                  'teacherName': teacher.name ?? '',
                  'instrument': teacher.instruments.isNotEmpty
                      ? teacher.instruments.first
                      : '악기',
                  'studentId': userProfile.userId,
                  'studentName': userProfile.userName,
                  'isTrialLesson': true,
                },
              );
            },
          );
        },
        childCount: teachers.length,
      ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onProfileTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Row(
            children: [
              // Profile image
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: teacher.profileImage != null
                    ? NetworkImage(teacher.profileImage!)
                    : null,
                child: teacher.profileImage == null
                    ? Icon(Icons.person, color: AppColors.primary, size: 28)
                    : null,
              ),
              const SizedBox(width: AppSpacing.space3),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teacher.name ?? '익명 선생님',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          teacher.instruments.join(' · '),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        if (teacher.experienceYears != null) ...[
                          Text(
                            ' | ${teacher.experienceYears}년 경력',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondaryLight,
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
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space3,
                    vertical: AppSpacing.space2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('체험 신청'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
