// W3 Task 3.2 — LessonStyleSettingsScreen (수업방식 묶음).
// spec §6.2 — 3 항목 단일 화면:
//   ① 레슨 1회 시간 (라디오 — 30/45/50/60분, 기본 50분)
//   ② 최소 사전 예약 시간 (라디오 — 0(제한 없음)/1/2/3/6/12/24/48/72시간, 기본 0)
//   ③ 학생 안내 메시지 (TextField — 빈 입력 시 defaultGuidanceMessage fallback)
//
// W1 SSOT 사용:
//   - `TeacherSettings.lessonDurationMinutes` (대체 — `defaultLessonDuration` 은 deprecated)
//   - `TeacherSettings.minBookingHours`
//   - `TeacherSettings.bookingGuidanceMessage` (effectiveGuidanceMessage getter)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_radio.dart';
import '../../../../core/widgets/notebook/notebook_screen_scaffold.dart';
import '../../../settings/settings_facade.dart';
import '../../domain/entities/teacher_profile.dart';
import '../../domain/entities/teacher_settings.dart';
import '../extensions/lesson_type_option_visuals.dart';
import '../providers/teacher_extended_profile_provider.dart';

/// 수업방식 묶음 단일 화면 (W3 Task 3.2).
///
/// spec §6.2 — 메인 홈 5묶음 카테고리 메뉴의 🎓 수업방식 카드 진입로.
/// 3 항목을 한 화면에서 라디오 + TextField 로 결정한다.
class LessonStyleSettingsScreen extends ConsumerWidget {
  const LessonStyleSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(teacherSettingsNotifierProvider);

    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(
        title: AppStrings.lessonStyleScreenTitle,
      ),
      body: settingsAsync.when(
        data: (settings) => _LessonStyleSettingsContent(settings: settings),
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

class _LessonStyleSettingsContent extends ConsumerWidget {
  final TeacherSettings settings;

  const _LessonStyleSettingsContent({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _LessonTypeSection(),
          const SizedBox(height: AppSpacing.space5),
          _DurationSection(current: settings.lessonDurationMinutes),
          const SizedBox(height: AppSpacing.space5),
          _MinBookingSection(current: settings.minBookingHours),
          const SizedBox(height: AppSpacing.space5),
          _GuidanceSection(current: settings.bookingGuidanceMessage),
        ],
      ),
    );
  }
}

/// 레슨 방식 섹션 — 대면/온라인/방문 다중선택 (#1146).
///
/// 선생님이 켠 방식은 학생 프로필에 표시되고, 수강권 등록 시 장소 선택지를
/// 제한한다(location_option_resolver). 0~3개 선택 허용(빈 값 = 미지정, 게이팅
/// 안 함). `TeacherExtendedProfile` 을 read+write 하는 self-contained 섹션.
class _LessonTypeSection extends ConsumerWidget {
  const _LessonTypeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(teacherExtendedProfileProvider);

    return profileAsync.maybeWhen(
      data: (profile) {
        final selected = profile?.lessonTypes ?? const <LessonTypeOption>[];
        return _SectionShell(
          title: AppStrings.lessonStyleLocationSection,
          hint: AppStrings.lessonStyleLocationHint,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Wrap(
              spacing: AppSpacing.space2,
              runSpacing: AppSpacing.space2,
              children:
                  LessonTypeOption.values.map((option) {
                    final isSelected = selected.contains(option);
                    return FilterChip(
                      avatar: Icon(
                        option.icon,
                        size: 18,
                        color:
                            isSelected
                                ? AppColors.paper
                                : AppColors.inkSecondary,
                      ),
                      label: Text(option.label),
                      selected: isSelected,
                      showCheckmark: false,
                      onSelected: (value) {
                        final next =
                            LessonTypeOption.values
                                .where(
                                  (o) =>
                                      o == option
                                          ? value
                                          : selected.contains(o),
                                )
                                .toList();
                        ref
                            .read(teacherExtendedProfileProvider.notifier)
                            .updateLessonTypes(next);
                      },
                      selectedColor: AppColors.paperAccent,
                      backgroundColor: AppColors.paper,
                      labelStyle: AppTypography.bodySmall.copyWith(
                        color: isSelected ? AppColors.paper : AppColors.ink,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color:
                            isSelected
                                ? AppColors.paperAccent
                                : AppColors.inkQuaternary,
                      ),
                      shape: const RoundedRectangleBorder(),
                    );
                  }).toList(),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// ① 레슨 1회 시간 섹션 — 30/45/50/60분 라디오 (기본 50).
class _DurationSection extends ConsumerWidget {
  final int current;

  const _DurationSection({required this.current});

  /// 한국 음악 레슨 표준 옵션. spec §6.2.
  static const _options = <int>[30, 45, 50, 60];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SectionShell(
      title: AppStrings.lessonStyleDurationSection,
      hint: AppStrings.lessonStyleDurationHint,
      child: Column(
        children:
            _options
                .map(
                  (minutes) => NotebookRadioListTile<int>(
                    value: minutes,
                    groupValue: current,
                    title: Text(AppStrings.lessonStyleMinutes(minutes)),
                    onChanged: (value) {
                      if (value == null || value == current) return;
                      ref
                          .read(teacherSettingsNotifierProvider.notifier)
                          .updateDefaultDuration(value);
                    },
                  ),
                )
                .toList(),
      ),
    );
  }
}

/// ② 최소 사전 예약 시간 섹션.
///
/// 0(제한 없음)/1/2/3/6/12/24/48/72 시간 라디오 (기본 0).
class _MinBookingSection extends ConsumerWidget {
  final int current;

  const _MinBookingSection({required this.current});

  static const _options = <int>[0, 1, 2, 3, 6, 12, 24, 48, 72];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SectionShell(
      title: AppStrings.lessonStyleBookingSection,
      hint: AppStrings.lessonStyleBookingHint,
      child: Column(
        children:
            _options
                .map(
                  (hours) => NotebookRadioListTile<int>(
                    value: hours,
                    groupValue: current,
                    title: Text(_formatHours(hours)),
                    onChanged: (value) {
                      if (value == null || value == current) return;
                      ref
                          .read(teacherSettingsNotifierProvider.notifier)
                          .updateMinBookingHours(value);
                    },
                  ),
                )
                .toList(),
      ),
    );
  }

  String _formatHours(int hours) {
    if (hours <= 0) {
      return AppStrings.lessonStyleNoLimit;
    }
    if (hours < 24) {
      return AppStrings.lessonStyleHoursBefore(hours);
    }
    final days = hours ~/ 24;
    return AppStrings.lessonStyleDaysBefore(days);
  }
}

/// ③ 학생 안내 메시지 섹션 — TextField.
///
/// 빈 입력 시 [TeacherSettings.effectiveGuidanceMessage] 가
/// [TeacherSettings.defaultGuidanceMessage] 로 fallback 한다.
class _GuidanceSection extends StatelessWidget {
  final String? current;

  const _GuidanceSection({required this.current});

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      title: AppStrings.lessonStyleGuidanceSection,
      hint: AppStrings.lessonStyleGuidanceHint,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: const BoxDecoration(color: AppColors.paperDark),
        child: _GuidanceMessageField(initialValue: current ?? ''),
      ),
    );
  }
}

/// 학생 안내 메시지 TextField — 컨트롤러 lifecycle 을 자체 보유.
///
/// `build()` 안에서 컨트롤러를 만들면 매 rebuild 마다 caret 이 리셋된다 (#5 D-G3).
class _GuidanceMessageField extends ConsumerStatefulWidget {
  const _GuidanceMessageField({required this.initialValue});

  final String initialValue;

  @override
  ConsumerState<_GuidanceMessageField> createState() =>
      _GuidanceMessageFieldState();
}

class _GuidanceMessageFieldState extends ConsumerState<_GuidanceMessageField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLength: 100,
      maxLines: 2,
      decoration: InputDecoration(
        hintText: TeacherSettings.defaultGuidanceMessage,
        hintStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.inkTertiary,
        ),
        filled: true,
        fillColor: AppColors.paperDark,
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.inkQuaternary),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.inkQuaternary),
        ),
        counterText: '',
      ),
      onChanged: (value) {
        ref
            .read(teacherSettingsNotifierProvider.notifier)
            .updateBookingGuidanceMessage(value);
      },
    );
  }
}

/// 섹션 공통 셸 — Playfair sectionTitle + 보조 설명 + child.
///
/// `lesson_time_settings_screen.dart` 의 §1/§2/§4 UI 패턴을 단일 화면용으로
/// 단순화 (Section title widget 외부 의존 없이 자체 보유).
class _SectionShell extends StatelessWidget {
  final String title;
  final String hint;
  final Widget child;

  const _SectionShell({
    required this.title,
    required this.hint,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: NotebookTypography.sectionTitle),
        const SizedBox(height: AppSpacing.space2),
        Text(
          hint,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        Container(
          decoration: const BoxDecoration(color: AppColors.paperDark),
          child: child,
        ),
      ],
    );
  }
}
