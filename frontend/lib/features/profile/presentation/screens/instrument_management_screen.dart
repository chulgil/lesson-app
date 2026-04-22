import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/profile/domain/entities/teacher_settings.dart';
import '../../../settings/presentation/providers/teacher_settings_provider.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('악기 관리'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
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
                  const Text('오류가 발생했습니다.'),
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

          const SizedBox(height: AppSpacing.space6),

          // Add instrument section
          _buildAddInstrumentSection(settings.instruments),
        ],
      ),
    );
  }

  Widget _buildCurrentInstruments(List<String> instruments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('현재 가르치는 악기', style: AppTypography.headingSmall),
        const SizedBox(height: AppSpacing.space2),
        Text(
          '악기를 탭하면 삭제할 수 있습니다',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        if (instruments.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.space6),
            decoration: BoxDecoration(
              color: AppColors.paperDark,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
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
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: instruments.length,
            onReorder:
                (oldIndex, newIndex) =>
                    _reorderInstrument(instruments, oldIndex, newIndex),
            itemBuilder: (context, index) {
              final instrument = instruments[index];
              return _buildInstrumentTile(
                key: ValueKey(instrument),
                instrument: instrument,
                index: index,
              );
            },
          ),
      ],
    );
  }

  Widget _buildInstrumentTile({
    required Key key,
    required String instrument,
    required int index,
  }) {
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.paperAccent.withValues(alpha: 0.1),
          child: Icon(
            _getInstrumentIcon(instrument),
            color: AppColors.paperAccent,
          ),
        ),
        title: Text(instrument, style: AppTypography.bodyLarge),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.paperAccent,
              ),
              onPressed: () => _showDeleteConfirmation(instrument),
            ),
            ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle),
            ),
          ],
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
        Text('악기 추가', style: AppTypography.headingSmall),
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
                decoration: InputDecoration(
                  hintText: '악기 이름 입력',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space4,
                    vertical: AppSpacing.space3,
                  ),
                ),
                onSubmitted: (_) => _addCustomInstrument(),
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            FilledButton(
              onPressed: _addCustomInstrument,
              child: const Text('추가'),
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
    await ref
        .read(teacherSettingsNotifierProvider.notifier)
        .addInstrument(instrument);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$instrument이(가) 추가되었습니다')));
    }
  }

  void _addCustomInstrument() async {
    final instrument = _customInstrumentController.text.trim();
    if (instrument.isEmpty) return;

    await ref
        .read(teacherSettingsNotifierProvider.notifier)
        .addInstrument(instrument);
    _customInstrumentController.clear();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$instrument이(가) 추가되었습니다')));
    }
  }

  void _showDeleteConfirmation(String instrument) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('악기 삭제'),
            content: Text('$instrument을(를) 목록에서 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(AppStrings.cancel),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  _removeInstrument(instrument);
                },
                child: const Text(AppStrings.delete),
              ),
            ],
          ),
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

  void _reorderInstrument(
    List<String> instruments,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final reordered = List<String>.from(instruments);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);
    await ref
        .read(teacherSettingsNotifierProvider.notifier)
        .reorderInstruments(reordered);
  }
}
