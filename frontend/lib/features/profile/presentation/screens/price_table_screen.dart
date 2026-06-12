// W3 Task 3.3 — PriceTableScreen (악기·레벨별 가격표).
// spec §6.3 — LessonTimeSettingsScreen §6 가격표 섹션을 신규 전용 화면으로 분리.
//
// 진입: 메인 5묶음 카테고리 → 💰 수강권·정산 BottomSheet → "레슨 가격표" ListTile.
//
// SSOT:
//   - `TeacherSettings.lessonPriceTable: Map<instrument, Map<level, won>>`
//   - 레벨: beginner / intermediate / advanced (초급/중급/고급 라벨)
//   - 가격: 원 단위 저장, "만" 단위 표시 (10,000 으로 나눠 소수 1자리)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_alert_dialog.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_screen_scaffold.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../../../settings/settings_facade.dart';
import '../../domain/entities/teacher_settings.dart';

/// 가격표 전용 화면 (W3 Task 3.3).
///
/// spec §6.3 — 수강권·정산 묶음의 신규 화면. 악기 등록 전에는 안내 라벨만 노출.
class PriceTableScreen extends ConsumerWidget {
  const PriceTableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(teacherSettingsNotifierProvider);

    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(
        title: AppStrings.priceTableScreenTitle,
      ),
      body: settingsAsync.when(
        data: (settings) => _PriceTableContent(settings: settings),
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.space4),
                child: Text(
                  'Error: $e',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ),
            ),
      ),
    );
  }
}

/// 가격표 본문 — 악기 유무에 따라 empty / table 분기.
class _PriceTableContent extends ConsumerWidget {
  final TeacherSettings settings;

  const _PriceTableContent({required this.settings});

  /// 레벨 키 — TeacherSettings.lessonPriceTable 의 2차 키와 일치해야 한다.
  static const _levels = <String>['beginner', 'intermediate', 'advanced'];
  static const _levelLabels = <String, String>{
    'beginner': '초급',
    'intermediate': '중급',
    'advanced': '고급',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instruments = settings.instruments;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.priceTableSection,
            style: NotebookTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.space2),
          if (instruments.isEmpty)
            Text(
              AppStrings.priceTableEmptyInstruments,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            )
          else ...[
            Text(
              AppStrings.priceTableDescription,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            _PriceTable(instruments: instruments, settings: settings),
          ],
        ],
      ),
    );
  }
}

/// 가격표 그리드 — 헤더(초급/중급/고급) + 악기별 행.
class _PriceTable extends ConsumerWidget {
  final List<String> instruments;
  final TeacherSettings settings;

  const _PriceTable({required this.instruments, required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.paperDark),
      padding: const EdgeInsets.all(AppSpacing.space3),
      child: Column(
        children: [
          _HeaderRow(),
          const SizedBox(height: AppSpacing.space2),
          const ThinRule(),
          ...instruments.map(
            (instrument) =>
                _InstrumentRow(instrument: instrument, settings: settings),
          ),
        ],
      ),
    );
  }
}

/// 가격표 헤더 행 — 80px 빈 칸 + 3 레벨 라벨 (Expanded).
class _HeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 80),
        ..._PriceTableContent._levels.map(
          (level) => Expanded(
            child: Center(
              child: Text(
                _PriceTableContent._levelLabels[level]!,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkSecondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 악기 한 줄 — 80px 악기 라벨 + 3 가격 셀 (Expanded).
class _InstrumentRow extends ConsumerWidget {
  final String instrument;
  final TeacherSettings settings;

  const _InstrumentRow({required this.instrument, required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              instrument,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ..._PriceTableContent._levels.map(
            (level) => Expanded(
              child: _PriceCell(
                instrument: instrument,
                level: level,
                levelLabel: _PriceTableContent._levelLabels[level]!,
                price: settings.getPrice(instrument, level),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 가격 셀 — 탭 → 다이얼로그. price=null → '—', 있으면 "N만" 단위.
class _PriceCell extends ConsumerWidget {
  final String instrument;
  final String level;
  final String levelLabel;
  final int? price;

  const _PriceCell({
    required this.instrument,
    required this.level,
    required this.levelLabel,
    required this.price,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPrice = price != null;

    return GestureDetector(
      onTap: () => _showEditDialog(context, ref),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color:
              hasPrice
                  ? AppColors.paperAccentSoft.withValues(alpha: 0.1)
                  : null,
          border: Border.all(
            color:
                hasPrice
                    ? AppColors.paperAccent.withValues(alpha: 0.3)
                    : AppColors.inkQuaternary,
          ),
        ),
        child: Center(
          child: Text(
            hasPrice ? _formatPrice(price!) : '—',
            style: AppTypography.caption.copyWith(
              color: hasPrice ? AppColors.paperAccent : AppColors.inkTertiary,
              fontWeight: hasPrice ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  /// 원 → "N만" 단위 표시. 만원 미만 잔여는 소수 1자리.
  String _formatPrice(int won) {
    final mans = won / 10000;
    final whole = won % 10000 == 0;
    return '${mans.toStringAsFixed(whole ? 0 : 1)}만';
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(
      text: price != null ? price.toString() : '',
    );

    final result = await showDialog<int?>(
      context: context,
      builder:
          (context) => NotebookAlertDialog(
            backgroundColor: AppColors.paper,
            shape: const RoundedRectangleBorder(),
            titleTextStyle: NotebookTypography.pieceTitle,
            title: Text(
              AppStrings.priceTableDialogTitle(instrument, levelLabel),
            ),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: AppStrings.priceTableDialogFieldLabel,
                hintText: AppStrings.profilePriceTableHint,
              ),
              autofocus: true,
            ),
            actions: [
              if (price != null)
                TextButton(
                  onPressed: () => Navigator.pop(context, -1),
                  child: Text(
                    AppStrings.delete,
                    style: const TextStyle(color: AppColors.paperAccent),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(AppStrings.cancel),
              ),
              FilledButton(
                onPressed: () {
                  final value = int.tryParse(controller.text);
                  if (value != null && value > 0) {
                    Navigator.pop(context, value);
                  }
                },
                child: const Text(AppStrings.save),
              ),
            ],
          ),
    );
    controller.dispose();

    if (!context.mounted || result == null) return;

    final settings = ref.read(teacherSettingsNotifierProvider).valueOrNull;
    if (settings == null) return;

    final priceTable = Map<String, Map<String, int>>.from(
      settings.lessonPriceTable ?? const {},
    );
    if (result == -1) {
      priceTable[instrument]?.remove(level);
      if (priceTable[instrument]?.isEmpty ?? false) {
        priceTable.remove(instrument);
      }
    } else {
      priceTable[instrument] = Map<String, int>.from(
        priceTable[instrument] ?? const {},
      )..[level] = result;
    }

    await ref
        .read(teacherSettingsNotifierProvider.notifier)
        .updatePriceTable(priceTable);
  }
}
