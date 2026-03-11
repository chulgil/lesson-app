import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../models/teacher_profile.dart';
import '../../../../providers/profile/teacher_extended_profile_provider.dart';
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
          const SnackBar(content: Text('설정이 저장되었습니다')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장 중 오류가 발생했습니다. 다시 시도해주세요.')),
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
        title: const Text('공개 프로필 설정'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('저장'),
            ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('오류가 발생했습니다.')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('프로필을 찾을 수 없습니다'));
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
        const VisibilitySectionTitle(title: '항목별 공개 범위'),
        const SizedBox(height: AppSpacing.space3),

        VisibilityTile(
          title: '이름',
          subtitle: '프로필에 표시되는 이름',
          icon: Icons.person,
          value: _settings.nameVisibility,
          onChanged: (v) =>
              _updateSettings(_settings.copyWith(nameVisibility: v)),
        ),

        VisibilityTile(
          title: '프로필 사진',
          subtitle: '프로필 이미지',
          icon: Icons.photo_camera,
          value: _settings.photoVisibility,
          onChanged: (v) =>
              _updateSettings(_settings.copyWith(photoVisibility: v)),
        ),

        VisibilityTile(
          title: '연락처',
          subtitle: '전화번호, 이메일 등',
          icon: Icons.phone,
          value: _settings.contactVisibility,
          onChanged: (v) =>
              _updateSettings(_settings.copyWith(contactVisibility: v)),
        ),

        VisibilityTile(
          title: '레슨료',
          subtitle: '레슨 가격 정보',
          icon: Icons.payments,
          value: _settings.feeVisibility,
          onChanged: (v) =>
              _updateSettings(_settings.copyWith(feeVisibility: v)),
        ),

        VisibilityTile(
          title: '경력',
          subtitle: '학력 및 경력 정보',
          icon: Icons.work,
          value: _settings.careerVisibility,
          onChanged: (v) =>
              _updateSettings(_settings.copyWith(careerVisibility: v)),
        ),

        VisibilityTile(
          title: '자격증',
          subtitle: '인증된 자격증 정보',
          icon: Icons.verified,
          value: _settings.certificateVisibility,
          onChanged: (v) =>
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
            onPressed: () => showProfilePreviewSheet(
              context: context,
              profile: profile,
              settings: _settings,
            ),
            icon: const Icon(Icons.preview),
            label: const Text('공개 프로필 미리보기'),
          ),
        ),
      ],
    );
  }
}
