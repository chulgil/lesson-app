import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/teacher.dart';
import '../../../../models/teacher_settings.dart';
import '../../../../providers/providers.dart';

/// Screen for selecting a teacher for trial lesson
class SelectTeacherScreen extends ConsumerStatefulWidget {
  const SelectTeacherScreen({super.key});

  @override
  ConsumerState<SelectTeacherScreen> createState() =>
      _SelectTeacherScreenState();
}

class _SelectTeacherScreenState extends ConsumerState<SelectTeacherScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teachersAsync = ref.watch(availableTeachersProvider);
    final selectedInstrument = ref.watch(selectedInstrumentFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('선생님 찾기'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              0,
              AppSpacing.screenPadding,
              AppSpacing.space3,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '선생님 이름, 악기, 지역 검색',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(teacherSearchQueryProvider.notifier).state =
                              '';
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceSecondaryLight,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMedium),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space4,
                  vertical: AppSpacing.space3,
                ),
              ),
              onChanged: (value) {
                ref.read(teacherSearchQueryProvider.notifier).state = value;
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Instrument filter chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              children: [
                _buildFilterChip(
                  label: '전체',
                  isSelected: selectedInstrument == null,
                  onTap: () {
                    ref.read(selectedInstrumentFilterProvider.notifier).state =
                        null;
                  },
                ),
                const SizedBox(width: AppSpacing.space2),
                ...InstrumentList.common.map((instrument) {
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.space2),
                    child: _buildFilterChip(
                      label: instrument,
                      isSelected: selectedInstrument == instrument,
                      onTap: () {
                        ref
                            .read(selectedInstrumentFilterProvider.notifier)
                            .state = instrument;
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.space3),

          // Teachers list
          Expanded(
            child: teachersAsync.when(
              data: (teachers) {
                if (teachers.isEmpty) {
                  return _buildEmptyState(selectedInstrument);
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  itemCount: teachers.length,
                  itemBuilder: (context, index) {
                    return _TeacherCard(
                      teacher: teachers[index],
                      onTap: () => _onTeacherSelected(teachers[index]),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    Text(
                      '선생님 목록을 불러올 수 없습니다',
                      style: AppTypography.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    TextButton(
                      onPressed: () => ref.invalidate(availableTeachersProvider),
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondaryLight,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String? selectedInstrument) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 64,
            color: AppColors.textTertiaryLight,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            selectedInstrument != null
                ? '$selectedInstrument 선생님이 없습니다'
                : '등록된 선생님이 없습니다',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          if (selectedInstrument != null) ...[
            const SizedBox(height: AppSpacing.space2),
            TextButton(
              onPressed: () {
                ref.read(selectedInstrumentFilterProvider.notifier).state =
                    null;
              },
              child: const Text('전체 보기'),
            ),
          ],
        ],
      ),
    );
  }

  void _onTeacherSelected(Teacher teacher) {
    context.push(
      '${AppRoutes.trialLessonRequest}?teacherId=${teacher.id}&teacherName=${Uri.encodeComponent(teacher.name)}',
    );
  }
}

/// Teacher card widget
class _TeacherCard extends StatelessWidget {
  final Teacher teacher;
  final VoidCallback onTap;

  const _TeacherCard({
    required this.teacher,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary,
                    backgroundImage: teacher.profileImageUrl != null
                        ? NetworkImage(teacher.profileImageUrl!)
                        : null,
                    child: teacher.profileImageUrl == null
                        ? Text(
                            teacher.initials,
                            style: AppTypography.headingMedium.copyWith(
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.space3),

                  // Name and instruments
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              teacher.name,
                              style: AppTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (!teacher.isAvailable) ...[
                              const SizedBox(width: AppSpacing.space2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.textTertiaryLight
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '모집마감',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textTertiaryLight,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: AppSpacing.space1,
                          children: teacher.instruments.map((instrument) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryLight
                                    .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                instrument,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  // Rating
                  if (teacher.rating != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber[600],
                            ),
                            const SizedBox(width: 2),
                            Text(
                              teacher.rating!.toStringAsFixed(1),
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '(${teacher.reviewCount})',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiaryLight,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: AppSpacing.space3),

              // Bio (truncated)
              if (teacher.bio != null)
                Text(
                  teacher.bio!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: AppSpacing.space3),

              // Info row
              Row(
                children: [
                  // Location
                  if (teacher.location != null) ...[
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.textTertiaryLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      teacher.location!,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space3),
                  ],

                  // Experience
                  Icon(
                    Icons.work_outline,
                    size: 14,
                    color: AppColors.textTertiaryLight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    teacher.formattedExperience,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),

              const Divider(height: AppSpacing.space6),

              // Fee and action row
              Row(
                children: [
                  // Trial fee
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '체험레슨',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiaryLight,
                        ),
                      ),
                      Text(
                        teacher.formattedTrialFee,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: AppSpacing.space4),

                  // Regular fee
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '정규레슨',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiaryLight,
                        ),
                      ),
                      Text(
                        teacher.formattedRegularFee,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Action button
                  FilledButton(
                    onPressed: teacher.isAvailable ? onTap : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space4,
                        vertical: AppSpacing.space2,
                      ),
                    ),
                    child: const Text('체험신청'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
