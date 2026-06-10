import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/swipe_action_tile.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../features/profile/domain/entities/teacher_settings.dart';
import '../../../settings/settings_facade.dart';

/// Screen for managing teacher's instruments
class InstrumentManagementScreen extends ConsumerStatefulWidget {
  const InstrumentManagementScreen({super.key});

  @override
  ConsumerState<InstrumentManagementScreen> createState() =>
      _InstrumentManagementScreenState();
}

class _InstrumentManagementScreenState
    extends ConsumerState<InstrumentManagementScreen> {
  final _customInstrumentController = TextEditingController();

  @override
  void dispose() {
    _customInstrumentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(teacherSettingsNotifierProvider);

    return NotebookScreenScaffold(
      appBar: NotebookDetailAppBar(
        title: AppStrings.profileInstrumentTitle,
        actions: [DetailAppBarAction.add],
        onAction: _handleHeaderAction,
      ),
      body: settingsAsync.when(
        data: (settings) => _buildContent(settings),
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
                        () =>
                            ref
                                .read(teacherSettingsNotifierProvider.notifier)
                                .refresh(),
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildContent(TeacherSettings settings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current instruments section
          _buildCurrentInstruments(settings.instruments),
        ],
      ),
    );
  }

  void _handleHeaderAction(DetailAppBarAction action) {
    if (action == DetailAppBarAction.add) {
      final settings = ref.read(teacherSettingsNotifierProvider).valueOrNull;
      _showAddInstrumentSheet(settings?.instruments ?? []);
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

  void _addInstrument(String instrument) async {
    try {
      await ref
          .read(teacherSettingsNotifierProvider.notifier)
          .addInstrument(instrument);
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

  void _addCustomInstrument() async {
    final instrument = _customInstrumentController.text.trim();
    if (instrument.isEmpty) return;

    try {
      await ref
          .read(teacherSettingsNotifierProvider.notifier)
          .addInstrument(instrument);
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

  void _removeInstrument(String instrument) async {
    await ref
        .read(teacherSettingsNotifierProvider.notifier)
        .removeInstrument(instrument);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$instrument이(가) 삭제되었습니다')));
    }
  }
}
