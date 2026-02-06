// Dialogs for extended profile screen.
//
// These dialogs allow editing various profile fields.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/teacher_profile.dart';
import '../../../../providers/profile/teacher_extended_profile_provider.dart';

/// Shows dialog to edit experience years.
void showExperienceDialog(
  BuildContext context,
  WidgetRef ref,
  TeacherProfile profile,
) {
  int years = profile.experienceYears ?? 0;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('교육 경력'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$years년',
              style: AppTypography.headingLarge,
            ),
            const SizedBox(height: AppSpacing.space4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: years > 0
                      ? () => setState(() => years--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  iconSize: 32,
                ),
                Slider(
                  value: years.toDouble(),
                  min: 0,
                  max: 50,
                  divisions: 50,
                  onChanged: (value) => setState(() => years = value.round()),
                ),
                IconButton(
                  onPressed: years < 50
                      ? () => setState(() => years++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                  iconSize: 32,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(teacherExtendedProfileProvider.notifier)
                  .updateExperienceYears(years);
              Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    ),
  );
}

/// Shows dialog to edit fee range.
void showFeeDialog(
  BuildContext context,
  WidgetRef ref,
  TeacherProfile profile,
) {
  int minFee = profile.feeRange?.minFee ?? 30000;
  int maxFee = profile.feeRange?.maxFee ?? 50000;
  int duration = profile.feeRange?.duration ?? 60;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('레슨료 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('레슨 시간', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.space2),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 30, label: Text('30분')),
                ButtonSegment(value: 45, label: Text('45분')),
                ButtonSegment(value: 60, label: Text('60분')),
              ],
              selected: {duration},
              onSelectionChanged: (value) {
                setState(() => duration = value.first);
              },
            ),
            const SizedBox(height: AppSpacing.space4),
            Text('최소 레슨료', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            Slider(
              value: minFee.toDouble(),
              min: 10000,
              max: 200000,
              divisions: 38,
              label: '${minFee ~/ 10000}만원',
              onChanged: (value) {
                setState(() {
                  minFee = value.round();
                  if (maxFee < minFee) maxFee = minFee;
                });
              },
            ),
            Text('최대 레슨료', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            Slider(
              value: maxFee.toDouble(),
              min: minFee.toDouble(),
              max: 300000,
              divisions: 58,
              label: '${maxFee ~/ 10000}만원',
              onChanged: (value) => setState(() => maxFee = value.round()),
            ),
            const SizedBox(height: AppSpacing.space2),
            Center(
              child: Text(
                FeeRange(minFee: minFee, maxFee: maxFee, duration: duration).formatted,
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(teacherExtendedProfileProvider.notifier).updateFeeRange(
                FeeRange(minFee: minFee, maxFee: maxFee, duration: duration),
              );
              Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    ),
  );
}

/// Shows dialog to select lesson types.
void showLessonTypesDialog(
  BuildContext context,
  WidgetRef ref,
  TeacherProfile profile,
) {
  final selected = Set<LessonType>.from(profile.lessonTypes ?? []);

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('레슨 방식'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: LessonType.values.map((type) {
            return CheckboxListTile(
              title: Text(getLessonTypeLabel(type)),
              subtitle: Text(getLessonTypeDescription(type)),
              value: selected.contains(type),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    selected.add(type);
                  } else {
                    selected.remove(type);
                  }
                });
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(teacherExtendedProfileProvider.notifier)
                  .updateLessonTypes(selected.toList());
              Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    ),
  );
}

/// Shows dialog to edit lesson areas.
void showAreasDialog(
  BuildContext context,
  WidgetRef ref,
  TeacherProfile profile,
) {
  final controller = TextEditingController();
  final areas = List<String>.from(profile.lessonAreas ?? []);

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('레슨 가능 지역'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: '예: 서울 강남구',
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (controller.text.isNotEmpty) {
                        setState(() {
                          areas.add(controller.text);
                          controller.clear();
                        });
                      }
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space3),
              if (areas.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: areas.map((area) {
                    return Chip(
                      label: Text(area),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() => areas.remove(area));
                      },
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(teacherExtendedProfileProvider.notifier)
                  .updateLessonAreas(areas);
              Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    ),
  );
}

/// Shows confirmation dialog for deleting an item.
void showDeleteConfirmDialog(
  BuildContext context,
  String itemType,
  VoidCallback onConfirm,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('$itemType 삭제'),
      content: Text('이 $itemType 정보를 삭제하시겠습니까?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
          ),
          child: const Text('삭제'),
        ),
      ],
    ),
  );
}

// Helper functions for lesson types

/// Returns display label for lesson type.
String getLessonTypeLabel(LessonType type) {
  switch (type) {
    case LessonType.inPerson:
      return '대면 레슨';
    case LessonType.online:
      return '온라인 레슨';
    case LessonType.visit:
      return '방문 레슨';
  }
}

/// Returns description for lesson type.
String getLessonTypeDescription(LessonType type) {
  switch (type) {
    case LessonType.inPerson:
      return '학원/연습실에서 직접 레슨';
    case LessonType.online:
      return '화상 통화로 레슨';
    case LessonType.visit:
      return '학생 집으로 방문 레슨';
  }
}
