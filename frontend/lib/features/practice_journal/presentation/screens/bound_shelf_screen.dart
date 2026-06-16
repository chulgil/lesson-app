import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/core/theme/app_spacing.dart';
import 'package:lessonaza/core/theme/notebook_typography.dart';
import 'package:lessonaza/core/widgets/empty_state_widget.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_screen_scaffold.dart';
import 'package:lessonaza/features/practice/practice_facade.dart'
    show PracticeRepertoire, activeRepertoiresProvider;

import '../../domain/entities/bound_volume.dart';
import '../providers/practice_journal_provider.dart';
import '../widgets/bound_volume_spine.dart';

/// 완성본 책장 — 완성본(실선·로마숫자)과 연습중(점선)을 구분해 보여준다.
///
/// 곡(레퍼토리)을 끝내면(archive) 완성본 1권이 제본되어 여기에 꽂힌다.
class BoundShelfScreen extends ConsumerWidget {
  final String childProfileId;

  const BoundShelfScreen({super.key, required this.childProfileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boundAsync = ref.watch(boundVolumesProvider(childProfileId));
    final activeAsync = ref.watch(activeRepertoiresProvider(childProfileId));

    Widget body;
    if (boundAsync.isLoading || activeAsync.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (boundAsync.hasError) {
      body = _ErrorBody(message: boundAsync.error.toString());
    } else if (activeAsync.hasError) {
      body = _ErrorBody(message: activeAsync.error.toString());
    } else {
      body = _ShelfBody(
        bound: boundAsync.value ?? const [],
        active: activeAsync.value ?? const [],
      );
    }

    return NotebookScreenScaffold(
      appBarTitle: AppStrings.boundShelfTitle,
      body: body,
    );
  }
}

class _ShelfBody extends StatelessWidget {
  final List<BoundVolume> bound;
  final List<PracticeRepertoire> active;

  const _ShelfBody({required this.bound, required this.active});

  @override
  Widget build(BuildContext context) {
    if (bound.isEmpty && active.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.menu_book_outlined,
        title: AppStrings.boundShelfEmptyTitle,
        subtitle: AppStrings.boundShelfEmptySubtitle,
        scrollable: true,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bound.isNotEmpty) ...[
            _SectionHeader(label: AppStrings.boundShelfCompletedSection),
            const SizedBox(height: AppSpacing.space3),
            _SpineWrap(
              spines: [
                for (final v in bound)
                  BoundVolumeSpine(volumeNo: v.volumeNo, title: v.pieceName),
              ],
            ),
            const SizedBox(height: AppSpacing.space6),
          ],
          if (active.isNotEmpty) ...[
            _SectionHeader(label: AppStrings.boundShelfInProgress),
            const SizedBox(height: AppSpacing.space3),
            _SpineWrap(
              spines: [for (final r in active) BoundVolumeSpine(title: r.name)],
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) =>
      Text(label, style: NotebookTypography.sectionTitle);
}

class _SpineWrap extends StatelessWidget {
  final List<Widget> spines;

  const _SpineWrap({required this.spines});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.space3,
    runSpacing: AppSpacing.space3,
    children: spines,
  );
}

class _ErrorBody extends StatelessWidget {
  final String message;

  const _ErrorBody({required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Text(message, style: const TextStyle(color: AppColors.paperMargin)),
  );
}
