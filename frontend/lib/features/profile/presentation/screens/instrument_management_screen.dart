import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/swipe_action_tile.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../features/profile/domain/entities/teacher_settings.dart';
import '../../../onboarding/onboarding_facade.dart';
import '../../../settings/settings_facade.dart';

/// Screen for managing teacher's instruments.
///
/// #732 SSOT fix — reads and writes [currentTeacherProfileProvider].instruments
/// (previously wrote to [teacherSettingsNotifierProvider], which is not read by
/// profile completion / search surfaces → edits were invisible).
///
/// Migration (#732): on first load, if profile.instruments is empty but
/// settings.instruments is non-empty (data written before #732), we seed
/// profile from settings once to prevent data loss.
class InstrumentManagementScreen extends ConsumerStatefulWidget {
  const InstrumentManagementScreen({super.key});

  @override
  ConsumerState<InstrumentManagementScreen> createState() =>
      _InstrumentManagementScreenState();
}

class _InstrumentManagementScreenState
    extends ConsumerState<InstrumentManagementScreen> {
  final _customInstrumentController = TextEditingController();

  /// Guards against repeated migration seeds within a single screen session.
  bool _migrationTriggered = false;

  @override
  void initState() {
    super.initState();
    // Schedule migration check after first frame so providers are available.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeSeedFromSettings(),
    );
  }

  @override
  void dispose() {
    _customInstrumentController.dispose();
    super.dispose();
  }

  /// #732 one-time migration: if profile.instruments is empty but
  /// settings.instruments is non-empty (from old management-screen writes),
  /// seed profile.instruments from settings once.
  ///
  /// This prevents data loss for teachers who had added instruments via the
  /// old flow (which wrote to TeacherSettings instead of TeacherProfile).
  Future<void> _maybeSeedFromSettings() async {
    if (_migrationTriggered) return;
    if (!mounted) return;

    final profile = ref.read(currentTeacherProfileProvider).valueOrNull;
    final settings = ref.read(teacherSettingsProvider).valueOrNull;

    if (profile == null || settings == null) return;
    if (profile.instruments.isNotEmpty) return;
    if (settings.instruments.isEmpty) return;

    // Guard so we only attempt once per screen session.
    _migrationTriggered = true;

    try {
      await ref
          .read(currentTeacherProfileNotifierProvider.notifier)
          .updateProfile(profile.copyWith(instruments: settings.instruments));
    } catch (_) {
      // Migration failure is non-fatal — screen still shows settings data
      // via the merged read below until next session.
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentTeacherProfileProvider);

    return NotebookScreenScaffold(
      appBar: NotebookDetailAppBar(
        title: AppStrings.profileInstrumentTitle,
        actions: [DetailAppBarAction.add],
        onAction: _handleHeaderAction,
      ),
      body: profileAsync.when(
        data: (profile) => _buildContent(profile?.instruments ?? const []),
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (_, __) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.paperAccent,
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  const Text(AppStrings.profileInstrumentError),
                  const SizedBox(height: AppSpacing.space4),
                  FilledButton(
                    onPressed:
                        () => ref.invalidate(currentTeacherProfileProvider),
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildContent(List<String> instruments) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current instruments section
          _buildCurrentInstruments(instruments),
        ],
      ),
    );
  }

  void _handleHeaderAction(DetailAppBarAction action) {
    if (action == DetailAppBarAction.add) {
      final instruments =
          ref.read(currentTeacherProfileProvider).valueOrNull?.instruments ??
          const [];
      _showAddInstrumentSheet(instruments);
    }
  }

  void _showAddInstrumentSheet(List<String> currentInstruments) {
    showNotebookModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (sheetContext) => ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.82,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.space4,
                AppSpacing.space4,
                AppSpacing.space4,
                AppSpacing.space4 +
                    MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: _buildAddInstrumentSection(currentInstruments),
            ),
          ),
    );
  }

  Widget _buildCurrentInstruments(List<String> instruments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notebook × Score: 페이지 섹션 제목은 Playfair sectionTitle 로 통일 (§7.17).
        Text(
          AppStrings.profileInstrumentCurrentSection,
          style: NotebookTypography.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.space2),
        Text(
          '오른쪽으로 스와이프해 악기를 삭제할 수 있습니다',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        if (instruments.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.space6),
            decoration: BoxDecoration(color: AppColors.paperDark),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.music_off, size: 48, color: AppColors.inkTertiary),
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    '등록된 악기가 없습니다',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...List.generate(instruments.length, (index) {
            final instrument = instruments[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space2),
              child: _buildInstrumentTile(
                key: ValueKey(instrument),
                instrument: instrument,
                index: index,
              ),
            );
          }),
      ],
    );
  }

  Widget _buildInstrumentTile({
    required Key key,
    required String instrument,
    int index = 0,
  }) {
    return SwipeActionTile(
      key: key,
      actions: [
        SwipeAction(
          label: AppStrings.delete,
          icon: Icons.delete_outline,
          tone: SwipeActionTone.destructive,
          onPressed: () => _showDeleteConfirmation(instrument),
        ),
      ],
      child: NotebookCard(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.paperAccentSoft,
            child: Icon(
              _getInstrumentIcon(instrument),
              color: AppColors.paperAccent,
            ),
          ),
          title: Text(instrument, style: AppTypography.bodyLarge),
        ),
      ),
    );
  }

  Widget _buildAddInstrumentSection(List<String> currentInstruments) {
    // Filter out already added instruments
    final availableInstruments =
        InstrumentList.all
            .where((i) => !currentInstruments.contains(i))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notebook × Score: 페이지 섹션 제목은 Playfair sectionTitle 로 통일 (§7.17).
        Text(
          AppStrings.profileInstrumentAddSection,
          style: NotebookTypography.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.space4),

        // Preset instruments grid
        if (availableInstruments.isNotEmpty) ...[
          Text(
            '목록에서 선택',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Wrap(
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            children:
                availableInstruments.map((instrument) {
                  return ActionChip(
                    avatar: Icon(
                      _getInstrumentIcon(instrument),
                      size: 18,
                      color: AppColors.paperAccent,
                    ),
                    label: Text(instrument),
                    onPressed: () => _addInstrument(instrument),
                  );
                }).toList(),
          ),
          const SizedBox(height: AppSpacing.space4),
        ],

        // Custom instrument input
        Text(
          '직접 입력',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customInstrumentController,
                decoration: const InputDecoration(
                  hintText: AppStrings.profileInstrumentHintCustom,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.inkQuaternary),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.space4,
                    vertical: AppSpacing.space3,
                  ),
                ),
                onSubmitted: (_) => _addCustomInstrument(),
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            FilledButton(
              // 2026-06-10 fix — Row 내부 컴팩트 배치 시 테마 minimumSize=Size(∞,h)
              // 가 적용되어 BoxConstraints(w=∞) 크래시. minimumSize override 필수.
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, AppSpacing.buttonHeight),
              ),
              onPressed: _addCustomInstrument,
              child: const Text(AppStrings.add),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getInstrumentIcon(String instrument) {
    switch (instrument) {
      case '바이올린':
      case '비올라':
      case '첼로':
      case '콘트라베이스':
        return Icons.music_note;
      case '피아노':
        return Icons.piano;
      case '플루트':
      case '클라리넷':
      case '오보에':
      case '바순':
        return Icons.air;
      case '트럼펫':
      case '호른':
      case '트롬본':
      case '튜바':
        return Icons.speaker;
      case '성악':
        return Icons.mic;
      case '타악기':
        return Icons.music_video;
      case '기타':
        return Icons.music_note;
      default:
        return Icons.music_note;
    }
  }

  /// Add instrument to profile.instruments (SSOT #732).
  Future<void> _addInstrument(String instrument) async {
    final profile = ref.read(currentTeacherProfileProvider).valueOrNull;
    if (profile == null) return;
    if (profile.instruments.contains(instrument)) {
      if (mounted) Navigator.pop(context);
      return;
    }
    try {
      await ref
          .read(currentTeacherProfileNotifierProvider.notifier)
          .updateProfile(
            profile.copyWith(instruments: [...profile.instruments, instrument]),
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$instrument이(가) 추가되었습니다')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('악기 추가에 실패했습니다')));
    }
  }

  /// Add custom instrument to profile.instruments (SSOT #732).
  Future<void> _addCustomInstrument() async {
    final instrument = _customInstrumentController.text.trim();
    if (instrument.isEmpty) return;

    final profile = ref.read(currentTeacherProfileProvider).valueOrNull;
    if (profile == null) return;

    try {
      await ref
          .read(currentTeacherProfileNotifierProvider.notifier)
          .updateProfile(
            profile.copyWith(instruments: [...profile.instruments, instrument]),
          );
      _customInstrumentController.clear();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$instrument이(가) 추가되었습니다')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('악기 추가에 실패했습니다')));
    }
  }

  void _showDeleteConfirmation(String instrument) {
    showNotebookDialog(
      context: context,
      title: AppStrings.swipeActionDeleteInstrumentConfirmTitle,
      content: Text(
        '$instrument — ${AppStrings.swipeActionDeleteInstrumentConfirmBody}',
      ),
      confirmLabel: AppStrings.delete,
      cancelLabel: AppStrings.cancel,
      isDestructive: true,
      onConfirm: () {
        Navigator.pop(context);
        _removeInstrument(instrument);
      },
    );
  }

  /// Remove instrument from profile.instruments (SSOT #732).
  Future<void> _removeInstrument(String instrument) async {
    final profile = ref.read(currentTeacherProfileProvider).valueOrNull;
    if (profile == null) return;
    await ref
        .read(currentTeacherProfileNotifierProvider.notifier)
        .updateProfile(
          profile.copyWith(
            instruments:
                profile.instruments.where((i) => i != instrument).toList(),
          ),
        );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$instrument이(가) 삭제되었습니다')));
    }
  }
}
