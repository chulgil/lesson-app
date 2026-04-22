import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/profile/domain/entities/teacher_profile.dart';
import '../../../../features/profile/domain/entities/teacher_search.dart';
import '../../../../features/schedule/presentation/screens/unified_lesson_request_screen.dart';
import '../../../../features/search/presentation/providers/teacher_search_provider.dart';
import '../../../profile/domain/entities/invite.dart';
import '../../../profile/presentation/providers/invite_provider.dart';

/// Teacher public profile detail screen
class TeacherDetailScreen extends ConsumerWidget {
  final String teacherId;

  const TeacherDetailScreen({super.key, required this.teacherId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(teacherPublicProfileProvider(teacherId));

    return Scaffold(
      backgroundColor: AppColors.paperDark,
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
                    '프로필을 불러올 수 없습니다',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('돌아가기'),
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
                    '선생님 정보를 찾을 수 없습니다',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.inkSecondary,
                    ),
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
    return CustomScrollView(
      slivers: [
        // App bar with profile image
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: AppColors.paperAccent,
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
                    AppColors.paperAccent,
                    AppColors.paperAccent.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: AppSpacing.space4),
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        backgroundImage:
                            profile.profileImage != null
                                ? NetworkImage(profile.profileImage!)
                                : null,
                        child:
                            profile.profileImage == null
                                ? const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.white,
                                )
                                : null,
                      ),
                      const SizedBox(height: AppSpacing.space3),
                      Text(
                        profile.name ?? '익명 선생님',
                        style: AppTypography.headingMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
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
                  title: '전문 악기',
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
                  title: '소개',
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
                    title: '경력',
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
                    title: '수업 방식',
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
                    title: '수업 지역',
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
                    title: '학력',
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
                    title: '경력 사항',
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
                                    decoration: const BoxDecoration(
                                      color: AppColors.paperAccent,
                                      shape: BoxShape.circle,
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
                    title: '인증된 자격증',
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
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMedium,
                                ),
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
                      label: const Text('레슨 신청'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.paperAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.space3,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLarge,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.space6),
              ],
            ),
          ),
        ),
      ],
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
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
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
                      '이전에 레슨을 받았던 선생님입니다',
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
            label: const Text('다시 시작하기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.paperAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        // Info text
        Text(
          '선생님에게 레슨 신청서가 전달됩니다',
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
                borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
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
            Text(title, style: AppTypography.headingSmall),
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
        return '휴대폰 인증';
      case VerificationBadge.certified:
        return '자격증 인증';
      case VerificationBadge.premium:
        return '프리미엄 프로필';
    }
  }

  String _getLessonTypeLabel(LessonType type) {
    switch (type) {
      case LessonType.inPerson:
        return '대면 수업';
      case LessonType.online:
        return '온라인';
      case LessonType.visit:
        return '방문 수업';
    }
  }
}
