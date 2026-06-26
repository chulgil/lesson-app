import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../features/profile/domain/entities/teacher_profile.dart';
import '../../../../features/profile/presentation/widgets/verification_badge_chip.dart';
import '../../../../features/profile/profile_facade.dart';

/// Preview screen showing the teacher's public profile as students would see it
class ProfilePreviewScreen extends ConsumerWidget {
  const ProfilePreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(teacherExtendedProfileProvider);

    final profile = profileAsync.valueOrNull;
    return NotebookScreenScaffold(
      appBar: NotebookDetailAppBar(
        title: AppStrings.profilePreviewTitle,
        actions: [if (profile != null) DetailAppBarAction.copy],
        onAction: (action) {
          if (action == DetailAppBarAction.copy && profile != null) {
            _copyProfileToClipboard(context, profile);
          }
        },
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text(AppStrings.profilePreviewNotFound));
          }
          return _buildPreview(context, profile);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (_, __) =>
                const Center(child: Text(AppStrings.profilePreviewError)),
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
              title: AppStrings.profilePreviewSectionIntro,
              child: Text(
                profile.introduction,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.ink,
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
              title: AppStrings.profilePreviewSectionTeachingStyle,
              child: Text(
                profile.teachingStyle!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.ink,
                  height: 1.6,
                ),
              ),
            ),

          // Specialties chips
          if (profile.expertiseTags != null && profile.expertiseTags!.isNotEmpty)
            _buildSection(
              title: AppStrings.profilePreviewSectionSpecialty,
              child: Wrap(
                spacing: AppSpacing.space2,
                runSpacing: AppSpacing.space2,
                children:
                    profile.expertiseTags!.map((specialty) {
                      return Chip(
                        label: Text(specialty),
                        labelStyle: AppTypography.bodySmall.copyWith(
                          color: AppColors.paperAccent,
                          fontWeight: FontWeight.w500,
                        ),
                        backgroundColor: AppColors.paperAccent.withValues(
                          alpha: 0.08,
                        ),
                        side: BorderSide(color: AppColors.paperAccentSoft),
                        shape: const RoundedRectangleBorder(),
                      );
                    }).toList(),
              ),
            ),

          // Education list
          if (profile.education != null && profile.education!.isNotEmpty)
            _buildSection(
              title: AppStrings.profilePreviewSectionEducation,
              child: Column(
                children:
                    profile.education!.map((edu) {
                      return _buildListItem(
                        icon: Icons.school_outlined,
                        title: '${edu.school} ${edu.major}',
                        subtitle:
                            '${edu.degree}${edu.graduationYear != null ? ' · ${edu.graduationYear}' : ''}',
                      );
                    }).toList(),
              ),
            ),

          // Career list
          if (profile.career != null && profile.career!.isNotEmpty)
            _buildSection(
              title: AppStrings.profilePreviewSectionCareer,
              child: Column(
                children:
                    profile.career!.map((c) {
                      final period =
                          c.endYear != null
                              ? '${c.startYear} - ${c.endYear}'
                              : '${c.startYear} - 현재';
                      return _buildListItem(
                        icon: Icons.business_outlined,
                        title:
                            '${c.organization}${c.position.isNotEmpty ? ' · ${c.position}' : ''}',
                        subtitle: period,
                      );
                    }).toList(),
              ),
            ),

          // Certificates list
          if (profile.verification.certificates.isNotEmpty)
            _buildSection(
              title: AppStrings.profilePreviewSectionCertificate,
              child: Column(
                children:
                    profile.verification.certificates
                        .where((c) => c.isApproved)
                        .map((cert) {
                          return _buildListItem(
                            icon: Icons.verified_outlined,
                            title: cert.name,
                            subtitle: cert.issuingBody,
                          );
                        })
                        .toList(),
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
                label: const Text(AppStrings.profilePreviewEditCta),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.paperAccent,
                  side: const BorderSide(color: AppColors.paperAccent),
                  shape: const RoundedRectangleBorder(),
                ),
              ),
            ),
          ),

          SizedBox(
            height:
                AppSpacing.space8 + MediaQuery.of(context).padding.bottom + 32,
          ),
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
          colors: [AppColors.paperAccent, AppColors.paperAccent],
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
                backgroundColor: AppColors.paper.withValues(alpha: 0.2),
                backgroundImage:
                    profile.profileImage != null
                        ? NetworkImage(profile.profileImage!)
                        : null,
                child:
                    profile.profileImage == null
                        ? Text(
                          initial,
                          style: AppTypography.displayLarge.copyWith(
                            color: AppColors.paper,
                          ),
                        )
                        : null,
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                profile.name,
                style: AppTypography.headingLarge.copyWith(
                  color: AppColors.paper,
                ),
              ),
              if (profile.verification.isPhoneVerified) ...[
                const SizedBox(height: AppSpacing.space2),
                const VerificationBadgeChip(
                  badge: VerificationBadge.phoneVerified,
                ),
              ],
              if (profile.instruments.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.space2),
                Text(
                  profile.instruments.join(' · '),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.paper.withValues(alpha: 0.85),
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
        chips.add(
          _InfoChipData(icon: Icons.music_note_outlined, label: instrument),
        );
      }
    }

    if (profile.experienceYears != null) {
      chips.add(
        _InfoChipData(
          icon: Icons.work_outline,
          label:
              '${AppStrings.profilePreviewExperienceYearsLabel} ${profile.experienceYears}년',
        ),
      );
    }

    if (profile.lessonAreas != null && profile.lessonAreas!.isNotEmpty) {
      for (final area in profile.lessonAreas!.take(3)) {
        chips.add(_InfoChipData(icon: Icons.location_on_outlined, label: area));
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
        children:
            chips.map((chip) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space3,
                  vertical: AppSpacing.space2,
                ),
                decoration: const BoxDecoration(color: AppColors.paperDark),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(chip.icon, size: 16, color: AppColors.inkSecondary),
                    const SizedBox(width: AppSpacing.space1),
                    Text(
                      chip.label,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.inkSecondary,
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

  Widget _buildSection({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.space6),
          // Notebook × Score: _buildSection 의 section title 은 Playfair sectionTitle
          // 로 통일. 6개 호출부(소개/교수 스타일/전문 분야/학력/경력/자격증) 에 일괄 반영 (§7.17).
          Text(
            title,
            style: NotebookTypography.sectionTitle.copyWith(
              color: AppColors.ink,
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
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.paperAccent),
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
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copyProfileToClipboard(BuildContext context, TeacherProfile profile) {
    final text = _formatProfileAsText(profile);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppStrings.profilePreviewCopied),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatProfileAsText(TeacherProfile profile) {
    final buffer = StringBuffer();
    const divider = '──────────────────────────────';

    // Header: name + instruments + experience + areas
    buffer.writeln('${profile.name} 선생님');

    final headerParts = <String>[];
    if (profile.instruments.isNotEmpty) {
      headerParts.add(profile.instruments.join(' · '));
    }
    if (profile.experienceYears != null) {
      headerParts.add('경력 ${profile.experienceYears}년');
    }
    if (headerParts.isNotEmpty) {
      buffer.writeln(headerParts.join(' | '));
    }
    if (profile.lessonAreas != null && profile.lessonAreas!.isNotEmpty) {
      buffer.writeln(profile.lessonAreas!.join(', '));
    }

    buffer.writeln();
    buffer.writeln(divider);

    // Introduction
    if (profile.introduction.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('[소개]');
      buffer.writeln(profile.introduction);
    }

    // Teaching style
    if (profile.teachingStyle != null && profile.teachingStyle!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('[교수 스타일]');
      buffer.writeln(profile.teachingStyle);
    }

    // Specialties
    if (profile.expertiseTags != null && profile.expertiseTags!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('[전문 분야]');
      buffer.writeln(profile.expertiseTags!.join(', '));
    }

    // Education
    if (profile.education != null && profile.education!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('[학력]');
      for (final edu in profile.education!) {
        final yearPart =
            edu.graduationYear != null ? ', ${edu.graduationYear}' : '';
        buffer.writeln('- ${edu.school} ${edu.major} (${edu.degree}$yearPart)');
      }
    }

    // Career
    if (profile.career != null && profile.career!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('[경력]');
      for (final c in profile.career!) {
        final period =
            c.endYear != null
                ? '${c.startYear} - ${c.endYear}'
                : '${c.startYear} - 현재';
        final positionPart = c.position.isNotEmpty ? ' ${c.position}' : '';
        buffer.writeln('- ${c.organization}$positionPart ($period)');
      }
    }

    // Certificates (approved only)
    final approvedCerts =
        profile.verification.certificates.where((c) => c.isApproved).toList();
    if (approvedCerts.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('[자격증]');
      for (final cert in approvedCerts) {
        buffer.writeln('- ${cert.name} — ${cert.issuingBody}');
      }
    }

    // Fee range
    if (profile.feeRange != null) {
      buffer.writeln();
      buffer.writeln('[레슨료]');
      buffer.writeln(profile.feeRange!.formatted);
    }

    buffer.writeln();
    buffer.writeln(divider);
    buffer.writeln('Lessonaza에서 확인하기');

    return buffer.toString();
  }
}

class _InfoChipData {
  final IconData icon;
  final String label;

  const _InfoChipData({required this.icon, required this.label});
}
