import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/teacher_profile.dart';
import '../../../../providers/profile/teacher_extended_profile_provider.dart';

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
          return _buildContent(context, ref, profile);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    TeacherProfile profile,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile completion card
          _buildCompletionCard(profile),

          const SizedBox(height: AppSpacing.space6),

          // Experience & Fee section
          _buildSectionTitle('기본 정보'),
          const SizedBox(height: AppSpacing.space3),
          _buildExperienceCard(context, ref, profile),
          const SizedBox(height: AppSpacing.space3),
          _buildFeeCard(context, ref, profile),
          const SizedBox(height: AppSpacing.space3),
          _buildLessonTypesCard(context, ref, profile),
          const SizedBox(height: AppSpacing.space3),
          _buildLessonAreasCard(context, ref, profile),

          const SizedBox(height: AppSpacing.space6),

          // Education section
          _buildSectionTitle('학력'),
          const SizedBox(height: AppSpacing.space3),
          _buildEducationSection(context, ref, profile),

          const SizedBox(height: AppSpacing.space6),

          // Career section
          _buildSectionTitle('경력'),
          const SizedBox(height: AppSpacing.space3),
          _buildCareerSection(context, ref, profile),

          const SizedBox(height: AppSpacing.space6),

          // Certificate section
          _buildSectionTitle('자격증'),
          const SizedBox(height: AppSpacing.space3),
          _buildCertificateSection(context, ref, profile),

          const SizedBox(height: AppSpacing.space8),
        ],
      ),
    );
  }

  Widget _buildCompletionCard(TeacherProfile profile) {
    final percentage = profile.completionPercentage;
    final level = profile.completionLevel;
    final levelColor = _getCompletionLevelColor(level);
    final levelLabel = _getCompletionLevelLabel(level);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [levelColor, levelColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '프로필 완성도',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  levelLabel,
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          Row(
            children: [
              Text(
                '$percentage%',
                style: AppTypography.headingLarge.copyWith(
                  color: Colors.white,
                  fontSize: 36,
                ),
              ),
              const SizedBox(width: AppSpacing.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    if (profile.nextSteps.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.space2),
                      Text(
                        '다음 단계: ${profile.nextSteps.join(", ")}',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
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

  Widget _buildExperienceCard(
    BuildContext context,
    WidgetRef ref,
    TeacherProfile profile,
  ) {
    return _buildInfoCard(
      icon: Icons.work_history_outlined,
      title: '교육 경력',
      value: profile.experienceYears != null
          ? '${profile.experienceYears}년'
          : '미입력',
      isEmpty: profile.experienceYears == null,
      onTap: () => _showExperienceDialog(context, ref, profile),
    );
  }

  Widget _buildFeeCard(
    BuildContext context,
    WidgetRef ref,
    TeacherProfile profile,
  ) {
    return _buildInfoCard(
      icon: Icons.payments_outlined,
      title: '레슨료',
      value: profile.feeRange?.formatted ?? '미입력',
      isEmpty: profile.feeRange == null,
      onTap: () => _showFeeDialog(context, ref, profile),
    );
  }

  Widget _buildLessonTypesCard(
    BuildContext context,
    WidgetRef ref,
    TeacherProfile profile,
  ) {
    final types = profile.lessonTypes ?? [];
    final typeLabels = types.map(_getLessonTypeLabel).join(', ');

    return _buildInfoCard(
      icon: Icons.school_outlined,
      title: '레슨 방식',
      value: types.isNotEmpty ? typeLabels : '미입력',
      isEmpty: types.isEmpty,
      onTap: () => _showLessonTypesDialog(context, ref, profile),
    );
  }

  Widget _buildLessonAreasCard(
    BuildContext context,
    WidgetRef ref,
    TeacherProfile profile,
  ) {
    final areas = profile.lessonAreas ?? [];

    return _buildInfoCard(
      icon: Icons.location_on_outlined,
      title: '레슨 가능 지역',
      value: areas.isNotEmpty ? areas.join(', ') : '미입력',
      isEmpty: areas.isEmpty,
      onTap: () => _showAreasDialog(context, ref, profile),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required bool isEmpty,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: isEmpty ? AppColors.warning.withValues(alpha: 0.3) : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTypography.bodyLarge.copyWith(
                      color: isEmpty
                          ? AppColors.textTertiaryLight
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textTertiaryLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationSection(
    BuildContext context,
    WidgetRef ref,
    TeacherProfile profile,
  ) {
    final educations = profile.education ?? [];

    return Column(
      children: [
        if (educations.isEmpty)
          _buildEmptyCard(
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
              child: _buildEducationCard(context, ref, edu, index),
            );
          }),
          const SizedBox(height: AppSpacing.space3),
          _buildAddButton(
            label: '학력 추가',
            onTap: () => context.push(AppRoutes.educationEdit),
          ),
        ],
      ],
    );
  }

  Widget _buildEducationCard(
    BuildContext context,
    WidgetRef ref,
    Education edu,
    int index,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.school,
              color: AppColors.success,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  edu.school,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${edu.major} · ${edu.degree}${edu.graduationYear != null ? ' · ${edu.graduationYear}년 졸업' : ''}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: AppColors.textTertiaryLight,
            ),
            onSelected: (value) {
              if (value == 'edit') {
                context.push('${AppRoutes.educationEdit}?index=$index');
              } else if (value == 'delete') {
                _showDeleteConfirmDialog(
                  context,
                  '학력',
                  () => ref.read(teacherExtendedProfileProvider.notifier).removeEducation(index),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('수정')),
              const PopupMenuItem(value: 'delete', child: Text('삭제')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCareerSection(
    BuildContext context,
    WidgetRef ref,
    TeacherProfile profile,
  ) {
    final careers = profile.career ?? [];

    return Column(
      children: [
        if (careers.isEmpty)
          _buildEmptyCard(
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
              child: _buildCareerCard(context, ref, career, index),
            );
          }),
          const SizedBox(height: AppSpacing.space3),
          _buildAddButton(
            label: '경력 추가',
            onTap: () => context.push(AppRoutes.careerEdit),
          ),
        ],
      ],
    );
  }

  Widget _buildCareerCard(
    BuildContext context,
    WidgetRef ref,
    Career career,
    int index,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.work,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        career.organization,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (career.isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '재직중',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${career.position} · ${career.period}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                if (career.description != null && career.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    career.description!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: AppColors.textTertiaryLight,
            ),
            onSelected: (value) {
              if (value == 'edit') {
                context.push('${AppRoutes.careerEdit}?index=$index');
              } else if (value == 'delete') {
                _showDeleteConfirmDialog(
                  context,
                  '경력',
                  () => ref.read(teacherExtendedProfileProvider.notifier).removeCareer(index),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('수정')),
              const PopupMenuItem(value: 'delete', child: Text('삭제')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateSection(
    BuildContext context,
    WidgetRef ref,
    TeacherProfile profile,
  ) {
    final certificates = profile.verification.certificates;

    return Column(
      children: [
        if (certificates.isEmpty)
          _buildEmptyCard(
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
              child: _buildCertificateCard(context, ref, cert),
            );
          }),
          const SizedBox(height: AppSpacing.space3),
          _buildAddButton(
            label: '자격증 추가',
            onTap: () => context.push(AppRoutes.certificateEdit),
          ),
        ],
      ],
    );
  }

  Widget _buildCertificateCard(
    BuildContext context,
    WidgetRef ref,
    Certificate cert,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: _getCertificateStatusColor(cert.status).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getCertificateStatusColor(cert.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getCertificateStatusIcon(cert.status),
              color: _getCertificateStatusColor(cert.status),
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        cert.name,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getCertificateStatusColor(cert.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getCertificateStatusLabel(cert.status),
                        style: AppTypography.caption.copyWith(
                          color: _getCertificateStatusColor(cert.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${_getCertificateTypeLabel(cert.type)} · ${cert.issuingBody}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${cert.issueDate.year}년 ${cert.issueDate.month}월 발급',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
                if (cert.isRejected && cert.rejectionReason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '반려 사유: ${cert.rejectionReason}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: AppColors.textTertiaryLight,
            ),
            onSelected: (value) {
              if (value == 'edit') {
                context.push('${AppRoutes.certificateEdit}?id=${cert.id}');
              } else if (value == 'delete') {
                _showDeleteConfirmDialog(
                  context,
                  '자격증',
                  () => ref.read(teacherExtendedProfileProvider.notifier).removeCertificate(cert.id),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('수정')),
              const PopupMenuItem(value: 'delete', child: Text('삭제')),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCertificateStatusColor(CertificateStatus status) {
    switch (status) {
      case CertificateStatus.pending:
        return AppColors.warning;
      case CertificateStatus.approved:
        return AppColors.success;
      case CertificateStatus.rejected:
        return AppColors.error;
    }
  }

  IconData _getCertificateStatusIcon(CertificateStatus status) {
    switch (status) {
      case CertificateStatus.pending:
        return Icons.hourglass_empty;
      case CertificateStatus.approved:
        return Icons.verified;
      case CertificateStatus.rejected:
        return Icons.cancel_outlined;
    }
  }

  String _getCertificateStatusLabel(CertificateStatus status) {
    switch (status) {
      case CertificateStatus.pending:
        return '심사중';
      case CertificateStatus.approved:
        return '승인됨';
      case CertificateStatus.rejected:
        return '반려됨';
    }
  }

  String _getCertificateTypeLabel(CertificateType type) {
    switch (type) {
      case CertificateType.musicTeacher:
        return '음악 교원';
      case CertificateType.cultureArtsEducator:
        return '문화예술교육사';
      case CertificateType.schoolTeacher:
        return '학교 교원';
      case CertificateType.conservatory:
        return '음악원 수료';
      case CertificateType.degree:
        return '음악 학위';
      case CertificateType.performance:
        return '연주 자격';
      case CertificateType.other:
        return '기타';
    }
  }

  Widget _buildEmptyCard({
    required IconData icon,
    required String message,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space6),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: AppColors.borderLight,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: AppColors.textTertiaryLight,
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.add),
            label: Text(buttonText),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // Dialog methods
  void _showExperienceDialog(
    BuildContext context,
    WidgetRef ref,
    TeacherProfile profile,
  ) {
    int years = profile.experienceYears ?? 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('교육 경력'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$years년',
                style: AppTypography.headingLarge,
              ),
              const SizedBox(height: AppSpacing.space4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: years > 0
                        ? () => setState(() => years--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    iconSize: 32,
                  ),
                  Slider(
                    value: years.toDouble(),
                    min: 0,
                    max: 50,
                    divisions: 50,
                    onChanged: (value) => setState(() => years = value.round()),
                  ),
                  IconButton(
                    onPressed: years < 50
                        ? () => setState(() => years++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                    iconSize: 32,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                ref.read(teacherExtendedProfileProvider.notifier)
                    .updateExperienceYears(years);
                Navigator.pop(context);
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeeDialog(
    BuildContext context,
    WidgetRef ref,
    TeacherProfile profile,
  ) {
    int minFee = profile.feeRange?.minFee ?? 30000;
    int maxFee = profile.feeRange?.maxFee ?? 50000;
    int duration = profile.feeRange?.duration ?? 60;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('레슨료 설정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('레슨 시간', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.space2),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 30, label: Text('30분')),
                  ButtonSegment(value: 45, label: Text('45분')),
                  ButtonSegment(value: 60, label: Text('60분')),
                ],
                selected: {duration},
                onSelectionChanged: (value) {
                  setState(() => duration = value.first);
                },
              ),
              const SizedBox(height: AppSpacing.space4),
              Text('최소 레슨료', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              Slider(
                value: minFee.toDouble(),
                min: 10000,
                max: 200000,
                divisions: 38,
                label: '${minFee ~/ 10000}만원',
                onChanged: (value) {
                  setState(() {
                    minFee = value.round();
                    if (maxFee < minFee) maxFee = minFee;
                  });
                },
              ),
              Text('최대 레슨료', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              Slider(
                value: maxFee.toDouble(),
                min: minFee.toDouble(),
                max: 300000,
                divisions: 58,
                label: '${maxFee ~/ 10000}만원',
                onChanged: (value) => setState(() => maxFee = value.round()),
              ),
              const SizedBox(height: AppSpacing.space2),
              Center(
                child: Text(
                  FeeRange(minFee: minFee, maxFee: maxFee, duration: duration).formatted,
                  style: AppTypography.headingSmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                ref.read(teacherExtendedProfileProvider.notifier).updateFeeRange(
                  FeeRange(minFee: minFee, maxFee: maxFee, duration: duration),
                );
                Navigator.pop(context);
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLessonTypesDialog(
    BuildContext context,
    WidgetRef ref,
    TeacherProfile profile,
  ) {
    final selected = Set<LessonType>.from(profile.lessonTypes ?? []);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('레슨 방식'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: LessonType.values.map((type) {
              return CheckboxListTile(
                title: Text(_getLessonTypeLabel(type)),
                subtitle: Text(_getLessonTypeDescription(type)),
                value: selected.contains(type),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      selected.add(type);
                    } else {
                      selected.remove(type);
                    }
                  });
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                ref.read(teacherExtendedProfileProvider.notifier)
                    .updateLessonTypes(selected.toList());
                Navigator.pop(context);
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAreasDialog(
    BuildContext context,
    WidgetRef ref,
    TeacherProfile profile,
  ) {
    final controller = TextEditingController();
    final areas = List<String>.from(profile.lessonAreas ?? []);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('레슨 가능 지역'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: '예: 서울 강남구',
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (controller.text.isNotEmpty) {
                          setState(() {
                            areas.add(controller.text);
                            controller.clear();
                          });
                        }
                      },
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space3),
                if (areas.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: areas.map((area) {
                      return Chip(
                        label: Text(area),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() => areas.remove(area));
                        },
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                ref.read(teacherExtendedProfileProvider.notifier)
                    .updateLessonAreas(areas);
                Navigator.pop(context);
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    String itemType,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$itemType 삭제'),
        content: Text('이 $itemType 정보를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getCompletionLevelColor(ProfileCompletionLevel level) {
    switch (level) {
      case ProfileCompletionLevel.minimum:
        return AppColors.warning;
      case ProfileCompletionLevel.basic:
        return AppColors.info;
      case ProfileCompletionLevel.standard:
        return AppColors.success;
      case ProfileCompletionLevel.complete:
        return AppColors.primary;
    }
  }

  String _getCompletionLevelLabel(ProfileCompletionLevel level) {
    switch (level) {
      case ProfileCompletionLevel.minimum:
        return '최소';
      case ProfileCompletionLevel.basic:
        return '기본';
      case ProfileCompletionLevel.standard:
        return '표준';
      case ProfileCompletionLevel.complete:
        return '완료';
    }
  }

  String _getLessonTypeLabel(LessonType type) {
    switch (type) {
      case LessonType.inPerson:
        return '대면 레슨';
      case LessonType.online:
        return '온라인 레슨';
      case LessonType.visit:
        return '방문 레슨';
    }
  }

  String _getLessonTypeDescription(LessonType type) {
    switch (type) {
      case LessonType.inPerson:
        return '학원/연습실에서 직접 레슨';
      case LessonType.online:
        return '화상 통화로 레슨';
      case LessonType.visit:
        return '학생 집으로 방문 레슨';
    }
  }
}
