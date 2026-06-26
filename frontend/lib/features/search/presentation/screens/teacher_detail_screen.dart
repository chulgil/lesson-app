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
import '../../../../features/profile/domain/entities/teacher_profile.dart';
import '../../../../features/profile/domain/entities/teacher_search.dart';
import '../../../../features/schedule/schedule_ui_facade.dart';
import '../../../profile/domain/entities/invite.dart';
import '../../../profile/profile_facade.dart';
import '../../search_facade.dart';

/// Teacher public profile detail screen
class TeacherDetailScreen extends ConsumerWidget {
  final String teacherId;

  const TeacherDetailScreen({super.key, required this.teacherId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(teacherPublicProfileProvider(teacherId));

    return NotebookScreenScaffold(
      backgroundColor: AppColors.paperDark,
      appBar: NotebookDetailAppBar(
        title: profileAsync.valueOrNull?.name != null
            ? '${profileAsync.valueOrNull!.name} (선생님)'
            : AppStrings.searchAnonymousTeacher,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.inkSecondary,
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    AppStrings.searchProfileLoadError,
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
            ),
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    size: 48,
                    color: AppColors.inkSecondary,
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    AppStrings.searchProfileNotFound,
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
          return _TeacherDetailContent(profile: profile);
        },
      ),
    );
  }
}

class _TeacherDetailContent extends ConsumerWidget {
  final TeacherPublicProfile profile;

  const _TeacherDetailContent({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if this is a previous teacher (disconnected)
    final disconnectedConnectionsAsync = ref.watch(
      myDisconnectedConnectionsProvider,
    );
    final isPreviousTeacher =
        disconnectedConnectionsAsync.valueOrNull?.any(
          (c) => c.teacherId == profile.id,
        ) ??
        false;
    final disconnectedConnection =
        disconnectedConnectionsAsync.valueOrNull
            ?.where((c) => c.teacherId == profile.id)
            .firstOrNull;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile image header (previously in SliverAppBar flexibleSpace)
          Container(
            width: double.infinity,
            color: AppColors.paperAccent,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.space6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.paper.withValues(alpha: 0.2),
                  backgroundImage:
                      profile.profileImage != null
                          ? NetworkImage(profile.profileImage!)
                          : null,
                  child:
                      profile.profileImage == null
                          ? const Icon(
                            Icons.person,
                            size: 50,
                            color: AppColors.paper,
                          )
                          : null,
                ),
                const SizedBox(height: AppSpacing.space3),
                Text(
                  profile.name ?? AppStrings.searchAnonymousTeacher,
                  style: AppTypography.headingMedium.copyWith(
                    color: AppColors.paper,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badges
                if (profile.badges.isNotEmpty) ...[
                  _buildBadgesSection(),
                  const SizedBox(height: AppSpacing.space4),
                ],

                // Instruments
                _buildSection(
                  icon: Icons.music_note,
                  title: AppStrings.searchSpecialtyInstrumentTitle,
                  child: Wrap(
                    spacing: AppSpacing.space2,
                    runSpacing: AppSpacing.space1,
                    children:
                        profile.instruments
                            .map(
                              (i) => Chip(
                                label: Text(i),
                                backgroundColor: AppColors.paperAccent
                                    .withValues(alpha: 0.1),
                                labelStyle: AppTypography.bodySmall.copyWith(
                                  color: AppColors.paperAccent,
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),

                // Introduction
                _buildSection(
                  icon: Icons.info_outline,
                  title: AppStrings.profilePreviewSectionIntro,
                  child: Text(
                    profile.introduction,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.inkSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),

                // Experience
                if (profile.experienceYears != null) ...[
                  _buildSection(
                    icon: Icons.work_outline,
                    title: AppStrings.profileVisibilityCareerTitle,
                    child: Text(
                      '${profile.experienceYears}년 경력',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                ],

                // Lesson types
                if (profile.lessonTypes != null &&
                    profile.lessonTypes!.isNotEmpty) ...[
                  _buildSection(
                    icon: Icons.school_outlined,
                    title: AppStrings.searchLessonStyleTitle,
                    child: Wrap(
                      spacing: AppSpacing.space2,
                      runSpacing: AppSpacing.space1,
                      children:
                          profile.lessonTypes!
                              .map(
                                (t) => Chip(
                                  label: Text(_getLessonTypeLabel(t)),
                                  backgroundColor: AppColors.paperAccent
                                      .withValues(alpha: 0.1),
                                  labelStyle: AppTypography.bodySmall.copyWith(
                                    color: AppColors.paperAccent,
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                ],

                // Lesson areas
                if (profile.lessonAreas != null &&
                    profile.lessonAreas!.isNotEmpty) ...[
                  _buildSection(
                    icon: Icons.location_on_outlined,
                    title: AppStrings.searchLessonAreaTitle,
                    child: Wrap(
                      spacing: AppSpacing.space2,
                      runSpacing: AppSpacing.space1,
                      children:
                          profile.lessonAreas!
                              .map(
                                (a) => Chip(
                                  label: Text(a),
                                  backgroundColor: AppColors.inkSecondary
                                      .withValues(alpha: 0.1),
                                  labelStyle: AppTypography.bodySmall.copyWith(
                                    color: AppColors.inkSecondary,
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                ],

                // 수강료는 선생님이 제안 시 직접 안내하므로 공개 프로필에서 제외
                // (수강권 시스템으로 가격 협상 가능)

                // Education
                if (profile.education != null &&
                    profile.education!.isNotEmpty) ...[
                  _buildSection(
                    icon: Icons.school,
                    title: AppStrings.profilePreviewSectionEducation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          profile.education!.map((edu) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.space2,
                              ),
                              child: Text(
                                '${edu.school} ${edu.major} (${edu.degree})',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.inkSecondary,
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                ],

                // Career
                if (profile.career != null && profile.career!.isNotEmpty) ...[
                  _buildSection(
                    icon: Icons.work,
                    title: AppStrings.searchCareerDetailTitle,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          profile.career!.map((career) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.space2,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(
                                      top: 6,
                                      right: AppSpacing.space2,
                                    ),
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: AppColors.paperAccent,
                                      borderRadius: BorderRadius.zero,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${career.organization} - ${career.position} (${career.period})',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.inkSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                ],

                // Verified certificates
                if (profile.verifiedCertificates.isNotEmpty) ...[
                  _buildSection(
                    icon: Icons.verified,
                    title: AppStrings.searchCertifiedTitle,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          profile.verifiedCertificates.map((cert) {
                            return Container(
                              margin: const EdgeInsets.only(
                                bottom: AppSpacing.space2,
                              ),
                              padding: const EdgeInsets.all(AppSpacing.space3),
                              decoration: BoxDecoration(
                                color: AppColors.paperOk.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: AppColors.paperOk.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.verified,
                                    color: AppColors.paperOk,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppSpacing.space2),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cert.name,
                                          style: AppTypography.bodyMedium
                                              .copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        Text(
                                          cert.issuingBody,
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                                color: AppColors.inkSecondary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                ],

                // Lesson request buttons or Reconnect button
                const SizedBox(height: AppSpacing.space6),
                if (isPreviousTeacher) ...[
                  // Previous teacher - show "다시 시작하기" button
                  _buildReconnectSection(context, ref, disconnectedConnection),
                ] else ...[
                  // New teacher - single "레슨 신청" button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push(
                          AppRoutes.lessonBooking,
                          extra: UnifiedLessonRequestParams(
                            teacherId: profile.id,
                            teacherName: profile.name ?? '',
                            teacherInstruments: profile.instruments,
                            isReturningStudent: false,
                          ),
                        );
                      },
                      icon: const Icon(Icons.send_outlined),
                      label: const Text(AppStrings.searchLessonApply),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.paperAccent,
                        foregroundColor: AppColors.paper,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.space3,
                        ),
                        shape: const RoundedRectangleBorder(),
                      ),
                    ),
                  ),
                ],
                // Notebook × Score: "Fine." 종지부
                const SizedBox(height: AppSpacing.space6),
                Center(child: Text('Fine.', style: NotebookTypography.fine)),
                const SizedBox(height: AppSpacing.space8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReconnectSection(
    BuildContext context,
    WidgetRef ref,
    Connection? disconnectedConnection,
  ) {
    // Format previous lesson period
    String? previousLessonPeriod;
    if (disconnectedConnection?.connectedAt != null) {
      final start = _formatDate(disconnectedConnection!.connectedAt);
      final end =
          disconnectedConnection.deactivatedAt != null
              ? _formatDate(disconnectedConnection.deactivatedAt!)
              : '';
      previousLessonPeriod = '$start ~ $end';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Previous lesson info banner
        Container(
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            color: AppColors.ink.withValues(alpha: 0.1),
            border: Border.all(color: AppColors.ink.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.history, color: AppColors.ink, size: 24),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.searchPreviousLessonTeacher,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    if (previousLessonPeriod != null)
                      Text(
                        previousLessonPeriod,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        // Unified lesson request (returning student)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              context.push(
                AppRoutes.lessonBooking,
                extra: UnifiedLessonRequestParams(
                  teacherId: profile.id,
                  teacherName: profile.name ?? '',
                  teacherInstruments: profile.instruments,
                  isReturningStudent: true,
                  previousInstrument:
                      profile.instruments.isNotEmpty
                          ? profile.instruments.first
                          : null,
                ),
              );
            },
            icon: const Icon(Icons.replay),
            label: const Text(AppStrings.searchRestartLesson),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.paperAccent,
              foregroundColor: AppColors.paper,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
              shape: const RoundedRectangleBorder(),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        // Info text
        Text(
          AppStrings.searchLessonRequestInfo,
          style: AppTypography.caption.copyWith(color: AppColors.inkSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month}.${date.day}';
  }

  Widget _buildBadgesSection() {
    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space2,
      children:
          profile.badges.map((badge) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space1,
              ),
              decoration: BoxDecoration(
                color: _getBadgeColor(badge).withValues(alpha: 0.1),
                borderRadius: BorderRadius.zero,
                border: Border.all(
                  color: _getBadgeColor(badge).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getBadgeIcon(badge),
                    size: 16,
                    color: _getBadgeColor(badge),
                  ),
                  const SizedBox(width: AppSpacing.space1),
                  Text(
                    _getBadgeLabel(badge),
                    style: AppTypography.bodySmall.copyWith(
                      color: _getBadgeColor(badge),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.paperAccent),
            const SizedBox(width: AppSpacing.space2),
            // Notebook × Score: 카테고리 섹션 제목은 Playfair sectionTitle
            // (§7.17). 8개 호출부 모두 정적 명사 헤더('전문 악기'/'소개'/
            // '경력'/'수업 방식'/'수업 지역'/'학력'/'경력 사항'/'인증된 자격증')
            // 이므로 공통 헬퍼에서 일괄 승격.
            Text(title, style: NotebookTypography.sectionTitle),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),
        Padding(padding: const EdgeInsets.only(left: 28), child: child),
      ],
    );
  }

  Color _getBadgeColor(VerificationBadge badge) {
    switch (badge) {
      case VerificationBadge.phoneVerified:
        return AppColors.ink;
      case VerificationBadge.certified:
        return AppColors.paperOk;
      case VerificationBadge.premium:
        return AppColors.amber;
    }
  }

  IconData _getBadgeIcon(VerificationBadge badge) {
    switch (badge) {
      case VerificationBadge.phoneVerified:
        return Icons.phone_android;
      case VerificationBadge.certified:
        return Icons.workspace_premium;
      case VerificationBadge.premium:
        return Icons.star;
    }
  }

  String _getBadgeLabel(VerificationBadge badge) {
    switch (badge) {
      case VerificationBadge.phoneVerified:
        return AppStrings.onboardingPhoneVerification;
      case VerificationBadge.certified:
        return AppStrings.verificationBadgeCertifiedLabel;
      case VerificationBadge.premium:
        return AppStrings.searchPremiumProfileLabel;
    }
  }

  String _getLessonTypeLabel(LessonType type) {
    switch (type) {
      case LessonType.inPerson:
        return AppStrings.searchLessonTypeInPerson;
      case LessonType.online:
        return AppStrings.locationOnlineLabel;
      case LessonType.visit:
        return AppStrings.searchLessonTypeVisit;
    }
  }
}
