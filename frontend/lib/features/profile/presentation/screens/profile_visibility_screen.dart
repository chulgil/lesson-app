import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/profile/domain/entities/teacher_profile.dart';
import '../../../../features/profile/presentation/providers/teacher_extended_profile_provider.dart';
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
  bool _isLoading = false;
  late ProfileVisibilitySettings _settings;
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profileVisibilityAppBarTitle),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _save,
              child:
                  _isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text(AppStrings.save),
            ),
        ],
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
          return _buildContent(context, profile);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, TeacherProfile profile) {
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
