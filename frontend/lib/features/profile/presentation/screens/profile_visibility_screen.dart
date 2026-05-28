import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/profile/domain/entities/teacher_profile.dart';
import '../../../../features/profile/profile_facade.dart';
import '../../../../features/academy/domain/repositories/academy_visibility_repository.dart';
import '../../../../features/academy/presentation/providers/academy_visibility_provider.dart';
import '../widgets/profile_visibility_widgets.dart';

/// Screen for managing profile visibility settings
class ProfileVisibilityScreen extends ConsumerStatefulWidget {
  const ProfileVisibilityScreen({super.key});

  @override
  ConsumerState<ProfileVisibilityScreen> createState() =>
      _ProfileVisibilityScreenState();
}

class _ProfileVisibilityScreenState
    extends ConsumerState<ProfileVisibilityScreen> {
  // ignore: unused_field -- Save CTA is currently hidden while the visibility flow is being rebuilt.
  bool _isLoading = false;
  late ProfileVisibilitySettings _settings;
  // ignore: unused_field -- Save CTA is currently hidden while the visibility flow is being rebuilt.
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final profile = ref.read(teacherExtendedProfileProvider).valueOrNull;
    _settings =
        profile?.visibilitySettings ?? const ProfileVisibilitySettings();
  }

  void _updateSettings(ProfileVisibilitySettings newSettings) {
    setState(() {
      _settings = newSettings;
      _hasChanges = true;
    });
  }

  // ignore: unused_element -- Save CTA is currently hidden while the visibility flow is being rebuilt.
  Future<void> _save() async {
    setState(() => _isLoading = true);

    try {
      await ref
          .read(teacherExtendedProfileProvider.notifier)
          .updateVisibilitySettings(_settings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.proposalSettingsSavedSnackbar),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.profileVisibilitySaveErrorSnackbar),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(teacherExtendedProfileProvider);
    final academiesAsync = ref.watch(
      teacherAcademiesProvider(
        ref.watch(teacherExtendedProfileProvider).valueOrNull?.userId ?? '',
      ),
    );

    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(
        title: AppStrings.profileVisibilityAppBarTitle,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (_, __) => const Center(
              child: Text(AppStrings.profileVisibilityErrorState),
            ),
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Text(AppStrings.profileVisibilityNullState),
            );
          }
          return _buildContent(context, profile, academiesAsync);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    TeacherProfile profile,
    AsyncValue<List<TeacherAcademyMembership>> academiesAsync,
  ) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        // Profile completion info
        ProfileCompletionCard(profile: profile),
        const SizedBox(height: AppSpacing.space4),

        // Search visibility toggle
        SearchToggle(
          isSearchable: _settings.isSearchable,
          onChanged: (value) {
            _updateSettings(_settings.copyWith(isSearchable: value));
          },
        ),
        const SizedBox(height: AppSpacing.space4),

        // Section visibility settings
        const VisibilitySectionTitle(
          title: AppStrings.profileVisibilitySectionTitle,
        ),
        const SizedBox(height: AppSpacing.space3),

        VisibilityTile(
          title: AppStrings.profileVisibilityNameTitle,
          subtitle: AppStrings.profileVisibilityNameSubtitle,
          icon: Icons.person,
          value: _settings.nameVisibility,
          onChanged:
              (v) => _updateSettings(_settings.copyWith(nameVisibility: v)),
        ),

        VisibilityTile(
          title: AppStrings.profileVisibilityPhotoTitle,
          subtitle: AppStrings.profileVisibilityPhotoSubtitle,
          icon: Icons.photo_camera,
          value: _settings.photoVisibility,
          onChanged:
              (v) => _updateSettings(_settings.copyWith(photoVisibility: v)),
        ),

        VisibilityTile(
          title: AppStrings.profileVisibilityContactTitle,
          subtitle: AppStrings.profileVisibilityContactSubtitle,
          icon: Icons.phone,
          value: _settings.contactVisibility,
          onChanged:
              (v) => _updateSettings(_settings.copyWith(contactVisibility: v)),
        ),

        VisibilityTile(
          title: AppStrings.profileVisibilityFeeTitle,
          subtitle: AppStrings.profileVisibilityFeeSubtitle,
          icon: Icons.payments,
          value: _settings.feeVisibility,
          onChanged:
              (v) => _updateSettings(_settings.copyWith(feeVisibility: v)),
        ),

        VisibilityTile(
          title: AppStrings.profileVisibilityCareerTitle,
          subtitle: AppStrings.profileVisibilityCareerSubtitle,
          icon: Icons.work,
          value: _settings.careerVisibility,
          onChanged:
              (v) => _updateSettings(_settings.copyWith(careerVisibility: v)),
        ),

        VisibilityTile(
          title: AppStrings.profileVisibilityCertificateTitle,
          subtitle: AppStrings.profileVisibilityCertificateSubtitle,
          icon: Icons.verified,
          value: _settings.certificateVisibility,
          onChanged:
              (v) =>
                  _updateSettings(_settings.copyWith(certificateVisibility: v)),
        ),

        const SizedBox(height: AppSpacing.space4),

        // Academy visibility section (only if teacher has academy affiliations)
        academiesAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (academies) {
            if (academies.isEmpty) {
              return const SizedBox.shrink();
            }
            return AcademyVisibilitySection(
              academies:
                  academies
                      .map(
                        (a) => AcademyVisibilityItem(
                          academyId: a.academyId,
                          academyName: a.academyName,
                          consent: a.publicPageConsent,
                        ),
                      )
                      .toList(),
              onToggle: (academyId, consent) async {
                final notifierState = ref.read(
                  academyVisibilityNotifierProvider,
                );
                if (notifierState is! AsyncValue) return;
                // Call the update via the provider itself
                // For this, we'll use a simpler approach: just call the repository
                final repo = ref.read(academyVisibilityRepositoryProvider);
                await repo.updateTeacherAcademyConsent(
                  academyId,
                  profile.userId,
                  consent,
                );
                // Invalidate the academies list to refresh
                ref.invalidate(teacherAcademiesProvider(profile.userId));
              },
              isLoading: false,
            );
          },
        ),

        const SizedBox(height: AppSpacing.space4),

        // Info card
        const VisibilityInfoCard(),

        const SizedBox(height: AppSpacing.space6),

        // Preview button
        SizedBox(
          width: double.infinity,
          height: AppSpacing.buttonHeight,
          child: OutlinedButton.icon(
            onPressed:
                () => showProfilePreviewSheet(
                  context: context,
                  profile: profile,
                  settings: _settings,
                ),
            icon: const Icon(Icons.preview),
            label: const Text(AppStrings.profileVisibilityPreviewButton),
          ),
        ),
      ],
    );
  }
}
