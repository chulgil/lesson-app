import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../features/profile/domain/entities/teacher_search.dart';
import '../../../../features/search/search_facade.dart'
    show
        availableAreasProvider,
        availableInstrumentsProvider,
        teacherSearchFilterStateProvider;
import '../../../profile/domain/entities/teacher_profile.dart';

/// Filter bottom sheet for teacher search
class TeacherSearchFilterSheet extends ConsumerStatefulWidget {
  const TeacherSearchFilterSheet({super.key});

  @override
  ConsumerState<TeacherSearchFilterSheet> createState() =>
      _TeacherSearchFilterSheetState();
}

class _TeacherSearchFilterSheetState
    extends ConsumerState<TeacherSearchFilterSheet> {
  late TeacherSearchFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = ref.read(teacherSearchFilterStateProvider);
  }

  @override
  Widget build(BuildContext context) {
    final instrumentsAsync = ref.watch(availableInstrumentsProvider);
    final areasAsync = ref.watch(availableAreasProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder:
          (context, scrollController) => Container(
            decoration: const BoxDecoration(color: AppColors.paper),
            child: Column(
              children: [
                // Handle
                const BottomSheetHandle(
                  margin: EdgeInsets.symmetric(vertical: AppSpacing.space3),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Notebook × Score: 바텀시트 커스텀 헤더 제목도 Playfair appBarTitle 로 통일 (§7.27 패턴).
                      Text(
                        AppStrings.searchFilter,
                        style: NotebookTypography.appBarTitle,
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => _filter = TeacherSearchFilter.empty);
                        },
                        child: const Text(AppStrings.searchFilterReset),
                      ),
                    ],
                  ),
                ),

                const ThinRule(),

                // Filter options
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(AppSpacing.space4),
                    children: [
                      // Instruments
                      _buildSectionTitle(AppStrings.filterInstruments),
                      const SizedBox(height: AppSpacing.space2),
                      instrumentsAsync.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) => const Text(AppStrings.errorOccurred),
                        data:
                            (instruments) => _buildChipSelection(
                              instruments,
                              _filter.instruments ?? [],
                              (selected) {
                                setState(() {
                                  _filter = _filter.copyWith(
                                    instruments:
                                        selected.isEmpty ? null : selected,
                                  );
                                });
                              },
                            ),
                      ),

                      const SizedBox(height: AppSpacing.space6),

                      // Areas
                      _buildSectionTitle(AppStrings.filterLocation),
                      const SizedBox(height: AppSpacing.space2),
                      areasAsync.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) => const Text(AppStrings.errorOccurred),
                        data:
                            (areas) => _buildChipSelection(
                              areas,
                              _filter.areas ?? [],
                              (selected) {
                                setState(() {
                                  _filter = _filter.copyWith(
                                    areas: selected.isEmpty ? null : selected,
                                  );
                                });
                              },
                            ),
                      ),

                      const SizedBox(height: AppSpacing.space6),

                      // Lesson types
                      _buildSectionTitle(AppStrings.filterLessonType),
                      const SizedBox(height: AppSpacing.space2),
                      _buildLessonTypeOptionSelection(),

                      const SizedBox(height: AppSpacing.space6),

                      // Experience
                      _buildSectionTitle(AppStrings.filterMinExperience),
                      const SizedBox(height: AppSpacing.space2),
                      _buildExperienceSelection(),

                      const SizedBox(height: AppSpacing.space6),

                      // Certificate
                      SwitchListTile(
                        title: const Text(
                          AppStrings.searchCertifiedTeachersOnly,
                        ),
                        subtitle: const Text(
                          AppStrings.searchCertifiedTeachersSubtitle,
                        ),
                        value: _filter.hasVerifiedCertificate ?? false,
                        onChanged: (value) {
                          setState(() {
                            _filter = _filter.copyWith(
                              hasVerifiedCertificate: value ? true : null,
                            );
                          });
                        },
                        activeThumbColor: AppColors.paperAccent,
                      ),

                      const SizedBox(height: AppSpacing.space6),

                      // Fee range (search_master.md §39 — minFee/maxFee, 2026-06-04)
                      _buildSectionTitle(AppStrings.filterFeeRange),
                      const SizedBox(height: AppSpacing.space2),
                      _buildFeeRangeInput(),

                      const SizedBox(height: AppSpacing.space6),

                      // Minimum profile completion (search_master.md §42, 2026-06-04)
                      _buildSectionTitle(AppStrings.filterMinCompletionLevel),
                      const SizedBox(height: AppSpacing.space2),
                      _buildCompletionLevelSelection(),
                    ],
                  ),
                ),

                // Apply button
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  decoration: BoxDecoration(color: AppColors.paper),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      height: AppSpacing.buttonHeight,
                      child: ElevatedButton(
                        onPressed: () {
                          // Apply filters
                          final notifier = ref.read(
                            teacherSearchFilterStateProvider.notifier,
                          );
                          notifier.updateInstruments(_filter.instruments);
                          notifier.updateAreas(_filter.areas);
                          notifier.updateLessonTypes(_filter.lessonTypes);
                          notifier.updateMinExperience(_filter.minExperience);
                          notifier.updateHasVerifiedCertificate(
                            _filter.hasVerifiedCertificate,
                          );
                          notifier.updateFeeRange(
                            minFee: _filter.minFee,
                            maxFee: _filter.maxFee,
                          );
                          notifier.updateMinCompletionLevel(
                            _filter.minCompletionLevel,
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.paperAccent,
                          foregroundColor: AppColors.paper,
                          shape: const RoundedRectangleBorder(),
                        ),
                        child: const Text(AppStrings.searchFilterApply),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: NotebookTypography.sectionTitle);
  }

  Widget _buildChipSelection(
    List<String> options,
    List<String> selected,
    ValueChanged<List<String>> onChanged,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (value) {
                final newList = List<String>.from(selected);
                if (value) {
                  newList.add(option);
                } else {
                  newList.remove(option);
                }
                onChanged(newList);
              },
              selectedColor: AppColors.paperAccentSoft,
              checkmarkColor: AppColors.paperAccent,
            );
          }).toList(),
    );
  }

  Widget _buildLessonTypeOptionSelection() {
    final selected = _filter.lessonTypes ?? [];
    final types = [
      (LessonTypeOption.inPerson, '대면 레슨'),
      (LessonTypeOption.online, '온라인 레슨'),
      (LessonTypeOption.visit, '방문 레슨'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          types.map((tuple) {
            final (type, label) = tuple;
            final isSelected = selected.contains(type);
            return FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (value) {
                final newList = List<LessonTypeOption>.from(selected);
                if (value) {
                  newList.add(type);
                } else {
                  newList.remove(type);
                }
                setState(() {
                  _filter = _filter.copyWith(
                    lessonTypes: newList.isEmpty ? null : newList,
                  );
                });
              },
              selectedColor: AppColors.paperAccentSoft,
              checkmarkColor: AppColors.paperAccent,
            );
          }).toList(),
    );
  }

  Widget _buildExperienceSelection() {
    final options = [null, 3, 5, 10];
    final labels = [
      AppStrings.experienceAny,
      AppStrings.experience3plus,
      AppStrings.experience5plus,
      AppStrings.experience10plus,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(options.length, (index) {
        final isSelected = _filter.minExperience == options[index];
        return ChoiceChip(
          label: Text(labels[index]),
          selected: isSelected,
          onSelected: (value) {
            setState(() {
              _filter = _filter.copyWith(minExperience: options[index]);
            });
          },
          selectedColor: AppColors.paperAccentSoft,
        );
      }),
    );
  }

  /// Fee range (minFee / maxFee) — text input fields side by side.
  Widget _buildFeeRangeInput() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            initialValue: _filter.minFee?.toString() ?? '',
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: AppStrings.filterFeeMinHint,
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (value) {
              final parsed = int.tryParse(value);
              setState(() {
                _filter = _filter.copyWith(minFee: parsed);
              });
            },
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        const Text('~'),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: TextFormField(
            initialValue: _filter.maxFee?.toString() ?? '',
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: AppStrings.filterFeeMaxHint,
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (value) {
              final parsed = int.tryParse(value);
              setState(() {
                _filter = _filter.copyWith(maxFee: parsed);
              });
            },
          ),
        ),
      ],
    );
  }

  /// Min profile completion level — ChoiceChip row (Any / basic / standard / complete).
  Widget _buildCompletionLevelSelection() {
    final options = <ProfileCompletionLevel?>[
      null,
      ProfileCompletionLevel.basic,
      ProfileCompletionLevel.standard,
      ProfileCompletionLevel.complete,
    ];
    final labels = [
      AppStrings.completionAny,
      AppStrings.completionBasic,
      AppStrings.completionStandard,
      AppStrings.completionComplete,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(options.length, (index) {
        final isSelected = _filter.minCompletionLevel == options[index];
        return ChoiceChip(
          label: Text(labels[index]),
          selected: isSelected,
          onSelected: (value) {
            setState(() {
              _filter = _filter.copyWith(minCompletionLevel: options[index]);
            });
          },
          selectedColor: AppColors.paperAccentSoft,
        );
      }),
    );
  }
}
