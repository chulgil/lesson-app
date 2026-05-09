import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../domain/entities/unified_lesson_request.dart';
import '../../../../features/profile/domain/entities/teacher_settings.dart';
import '../../../../features/settings/settings_facade.dart';
import '../../../../features/students/domain/entities/lesson_location.dart';
import '../extensions/unified_lesson_request_visuals.dart';
import '../providers/unified_lesson_request_providers.dart';
import '../widgets/weekly_calendar_picker.dart';
import 'request_completion_screen.dart';

/// Parameters passed via GoRouter extra for the unified lesson request screen.
class UnifiedLessonRequestParams {
  final String teacherId;
  final String teacherName;
  final List<String> teacherInstruments;
  final bool isReturningStudent;
  final String? previousInstrument;
  final int? previousDay;
  final String? previousTime;

  const UnifiedLessonRequestParams({
    required this.teacherId,
    required this.teacherName,
    required this.teacherInstruments,
    this.isReturningStudent = false,
    this.previousInstrument,
    this.previousDay,
    this.previousTime,
  });
}

/// Unified lesson request screen — students fill and submit trial or regular
/// lesson requests through a single form.
class UnifiedLessonRequestScreen extends ConsumerStatefulWidget {
  final UnifiedLessonRequestParams params;

  const UnifiedLessonRequestScreen({super.key, required this.params});

  @override
  ConsumerState<UnifiedLessonRequestScreen> createState() =>
      _UnifiedLessonRequestScreenState();
}

class _UnifiedLessonRequestScreenState
    extends ConsumerState<UnifiedLessonRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();

  late LessonRequestType _selectedType;
  String? _selectedInstrument;
  UnifiedLessonGoal _selectedGoal = UnifiedLessonGoal.hobby;
  UnifiedExperienceLevel _selectedExperience = UnifiedExperienceLevel.beginner;
  List<PreferredTimeSlot> _preferredSlots = [];
  LocationType? _preferredLocationType;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedType =
        widget.params.isReturningStudent
            ? LessonRequestType.regular
            : LessonRequestType.trial;

    // Pre-fill instrument for returning students
    if (widget.params.isReturningStudent) {
      _selectedInstrument = widget.params.previousInstrument;
    }

    // Default instrument selection if only one available
    if (widget.params.teacherInstruments.length == 1) {
      _selectedInstrument = widget.params.teacherInstruments.first;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotebookScreenScaffold(
      backgroundColor: AppColors.paper,
      appBar: const NotebookDetailAppBar(
        title: AppStrings.lessonRequestFormTitle,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTeacherHeader(),
              if (widget.params.isReturningStudent) ...[
                const SizedBox(height: AppSpacing.space4),
                _buildReturningBanner(),
              ],
              const SizedBox(height: AppSpacing.space4),
              _buildGuidanceMessage(),
              const SizedBox(height: AppSpacing.space6),
              _buildLessonTypeSection(),
              const SizedBox(height: AppSpacing.space6),
              _buildInstrumentSection(),
              const SizedBox(height: AppSpacing.space6),
              _buildGoalSection(),
              const SizedBox(height: AppSpacing.space6),
              _buildExperienceSection(),
              const SizedBox(height: AppSpacing.space6),
              _buildPreferredLocationSection(),
              const SizedBox(height: AppSpacing.space6),
              _buildEstimatedDuration(),
              const SizedBox(height: AppSpacing.space6),
              _buildSlotPickerSection(),
              const SizedBox(height: AppSpacing.space6),
              _buildCancellationPolicy(),
              const SizedBox(height: AppSpacing.space6),
              _buildMessageSection(),
              const SizedBox(height: AppSpacing.space6),
              _buildReferencePriceSection(),
              const SizedBox(height: AppSpacing.space8),
              _buildSubmitButton(),
              const SizedBox(height: AppSpacing.space8),
            ],
          ),
        ),
      ),
    );
  }

  // Location option definitions for ChoiceChip display
  static const _preferredPrivateLocationOptions = [
    MapEntry(LocationType.studentHome, AppStrings.locationStudentHomeLabel),
    MapEntry(LocationType.externalPlace, AppStrings.locationExternalPlaceLabel),
    MapEntry(LocationType.teacherStudio, AppStrings.locationTeacherHomeLabel),
    MapEntry(LocationType.online, AppStrings.locationOnlineLabel),
  ];

  // ignore: unused_field — reserved for when UnifiedLessonRequestParams gains isAcademy flag
  static const _preferredAcademyLocationOptions = [
    MapEntry(LocationType.academyRoom, AppStrings.academy),
    MapEntry(LocationType.online, AppStrings.locationOnlineLabel),
  ];

  /// Convert LocationType to the raw string stored in UnifiedLessonRequest.
  String? _locationTypeToString(LocationType? type) {
    if (type == null) return null;
    return type.name; // e.g. "studentHome", "academyRoom", etc.
  }

  // -- Teacher info header --

  Widget _buildTeacherHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(color: AppColors.paper),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.paperAccent.withValues(alpha: 0.1),
            child: const Icon(
              Icons.person,
              size: 32,
              color: AppColors.paperAccent,
            ),
          ),
          const SizedBox(width: AppSpacing.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.params.teacherName,
                  style: AppTypography.headingSmall,
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  widget.params.teacherInstruments.join(', '),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -- Returning student banner --

  Widget _buildReturningBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, size: 20, color: AppColors.ink),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              AppStrings.returningStudentBanner,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -- Guidance message (Naver benchmark) --

  Widget _buildGuidanceMessage() {
    final settingsAsync = ref.watch(
      teacherSettingsByIdProvider(widget.params.teacherId),
    );
    final message =
        settingsAsync.valueOrNull?.effectiveGuidanceMessage ??
        TeacherSettings.defaultGuidanceMessage;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paperAccent.withValues(alpha: 0.05),
        border: Border.all(
          color: AppColors.paperAccent.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            size: 18,
            color: AppColors.paperAccent,
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.paperAccent,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -- Lesson type selection --

  Widget _buildLessonTypeSection() {
    return _SectionWrapper(
      icon: Icons.school,
      title: AppStrings.lessonTypeLabel,
      child: SegmentedButton<LessonRequestType>(
        segments:
            LessonRequestType.values
                .map(
                  (type) => ButtonSegment<LessonRequestType>(
                    value: type,
                    label: Text(type.label),
                  ),
                )
                .toList(),
        selected: {_selectedType},
        onSelectionChanged: (selected) {
          setState(() {
            _selectedType = selected.first;
          });
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.paperAccent;
            }
            return AppColors.paper;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.paper;
            }
            return AppColors.ink;
          }),
        ),
      ),
    );
  }

  // -- Instrument selection --

  Widget _buildInstrumentSection() {
    final instruments = widget.params.teacherInstruments;
    if (instruments.isEmpty) return const SizedBox.shrink();

    // Single instrument → hide UI, auto-selected in initState (spec Section 11)
    if (instruments.length == 1) return const SizedBox.shrink();

    return _SectionWrapper(
      icon: Icons.music_note,
      title: AppStrings.instrumentFallback,
      isRequired: true,
      child: Wrap(
        spacing: AppSpacing.space2,
        runSpacing: AppSpacing.space2,
        children:
            instruments.map((instrument) {
              final isSelected = _selectedInstrument == instrument;
              return ChoiceChip(
                label: Text(instrument),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedInstrument = selected ? instrument : null;
                  });
                },
                selectedColor: AppColors.paperAccent.withValues(alpha: 0.2),
                backgroundColor: AppColors.paper,
                labelStyle: AppTypography.bodyMedium.copyWith(
                  color: isSelected ? AppColors.paperAccent : AppColors.ink,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color:
                      isSelected
                          ? AppColors.paperAccent
                          : AppColors.inkQuaternary,
                ),
              );
            }).toList(),
      ),
    );
  }

  // -- Lesson goal --

  Widget _buildGoalSection() {
    return _SectionWrapper(
      icon: Icons.flag,
      title: AppStrings.lessonGoalLabel,
      child: DropdownButtonFormField<UnifiedLessonGoal>(
        initialValue: _selectedGoal,
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.paper,
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: AppColors.inkQuaternary),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppColors.inkQuaternary),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: AppColors.paperAccent,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
        ),
        items:
            UnifiedLessonGoal.values.map((goal) {
              return DropdownMenuItem<UnifiedLessonGoal>(
                value: goal,
                child: Text(goal.label, style: AppTypography.bodyMedium),
              );
            }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedGoal = value;
            });
          }
        },
      ),
    );
  }

  // -- Experience level --

  Widget _buildExperienceSection() {
    return _SectionWrapper(
      icon: Icons.trending_up,
      title: AppStrings.experienceLevelLabel,
      child: SegmentedButton<UnifiedExperienceLevel>(
        segments:
            UnifiedExperienceLevel.values
                .map(
                  (level) => ButtonSegment<UnifiedExperienceLevel>(
                    value: level,
                    label: Text(level.label),
                  ),
                )
                .toList(),
        selected: {_selectedExperience},
        onSelectionChanged: (selected) {
          setState(() {
            _selectedExperience = selected.first;
          });
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.paperAccent;
            }
            return AppColors.paper;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.paper;
            }
            return AppColors.ink;
          }),
        ),
      ),
    );
  }

  // -- Preferred location --

  Widget _buildPreferredLocationSection() {
    // Academy flag is not carried in params; default to private location options.
    // Academy requests would need an `isAcademy` param in UnifiedLessonRequestParams.
    const options = _preferredPrivateLocationOptions;

    return _SectionWrapper(
      icon: Icons.location_on,
      title: AppStrings.preferredLocationTitle,
      child: Wrap(
        spacing: AppSpacing.space2,
        runSpacing: AppSpacing.space2,
        children: options.map((entry) {
          final type = entry.key;
          final label = entry.value;
          final isSelected = _preferredLocationType == type;
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _preferredLocationType = selected ? type : null;
              });
            },
            selectedColor: AppColors.paperAccent.withValues(alpha: 0.2),
            backgroundColor: AppColors.paper,
            labelStyle: AppTypography.bodyMedium.copyWith(
              color: isSelected ? AppColors.paperAccent : AppColors.ink,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            side: BorderSide(
              color: isSelected
                  ? AppColors.paperAccent
                  : AppColors.inkQuaternary,
            ),
            shape: const RoundedRectangleBorder(),
          );
        }).toList(),
      ),
    );
  }

  // -- Slot picker --

  Widget _buildSlotPickerSection() {
    return _SectionWrapper(
      icon: Icons.calendar_today,
      title: AppStrings.preferredLessonTimeLabel,
      isRequired: true,
      child: WeeklyCalendarPicker(
        teacherId: widget.params.teacherId,
        lessonType: _selectedType,
        onSlotsChanged: (slots) {
          setState(() {
            _preferredSlots = slots;
          });
        },
      ),
    );
  }

  // -- Estimated duration (read-only, Naver benchmark) --

  Widget _buildEstimatedDuration() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      decoration: BoxDecoration(color: AppColors.paper),
      child: Row(
        children: [
          const Icon(Icons.schedule, size: 18, color: AppColors.inkSecondary),
          const SizedBox(width: AppSpacing.space3),
          Text(
            AppStrings.estimatedDuration,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const Spacer(),
          Text(
            AppStrings.durationMinutesValue(60),
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // -- Cancellation policy (read-only, Naver benchmark) --

  Widget _buildCancellationPolicy() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.05),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.ink),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Text(
              AppStrings.cancellationPolicy,
              style: AppTypography.bodySmall.copyWith(color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }

  // -- Message --

  Widget _buildMessageSection() {
    return _SectionWrapper(
      icon: Icons.message,
      title: AppStrings.messageLabel,
      subtitle: AppStrings.optionalParen,
      child: TextField(
        controller: _messageController,
        maxLines: 3,
        maxLength: 200,
        decoration: InputDecoration(
          hintText: AppStrings.messageHintToTeacher,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.inkTertiary,
          ),
          filled: true,
          fillColor: AppColors.paper,
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: AppColors.inkQuaternary),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppColors.inkQuaternary),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: AppColors.paperAccent,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  // -- Reference price (read-only) --

  Widget _buildReferencePriceSection() {
    // Only show when instrument and experience are selected
    if (_selectedInstrument == null) return const SizedBox.shrink();

    // TODO: Replace with actual price lookup from teacher price table
    final referencePrice = _lookupReferencePrice();
    if (referencePrice == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(color: AppColors.paperDark),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 20, color: AppColors.ink),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.referencePriceLabel,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.pricePerSession(_formatPrice(referencePrice)),
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -- Submit button --

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _handleSubmit,
        icon:
            _isSubmitting
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.paper,
                  ),
                )
                : const Icon(Icons.send),
        label: Text(
          _isSubmitting
              ? AppStrings.submittingRequest
              : AppStrings.submitRequest,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.paperAccent,
          foregroundColor: AppColors.paper,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
          shape: RoundedRectangleBorder(),
          disabledBackgroundColor: AppColors.paperAccent.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  // -- Validation & submit --

  bool _validate() {
    if (_selectedInstrument == null) {
      _showValidationError(AppStrings.validationSelectInstrument);
      return false;
    }
    if (_preferredSlots.isEmpty) {
      _showValidationError(AppStrings.validationSelectPreferredTime);
      return false;
    }
    return true;
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.paperAccent),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final now = DateTime.now();
      final request = UnifiedLessonRequest(
        id: const Uuid().v4(),
        studentId: '', // Set by auth context in real implementation
        teacherId: widget.params.teacherId,
        type: _selectedType,
        instrument: _selectedInstrument!,
        goal: _selectedGoal,
        experience: _selectedExperience,
        message:
            _messageController.text.trim().isEmpty
                ? null
                : _messageController.text.trim(),
        preferredDay:
            _preferredSlots.isNotEmpty ? _preferredSlots.first.dayOfWeek : null,
        preferredTime:
            _preferredSlots.isNotEmpty ? _preferredSlots.first.startTime : null,
        preferredDuration: 60,
        preferredSlots: _preferredSlots,
        isReturningStudent: widget.params.isReturningStudent,
        suggestedPrice: _lookupReferencePrice(),
        createdAt: now,
        preferredLocationType: _locationTypeToString(_preferredLocationType),
      );

      final actions = UnifiedLessonRequestActions(ref);
      await actions.createRequest(request);

      if (mounted) {
        context.push(
          AppRoutes.requestCompletion,
          extra: RequestCompletionParams(
            teacherName: widget.params.teacherName,
            instrument: _selectedInstrument!,
            lessonType: _selectedType,
            preferredSlots: _preferredSlots,
            duration: 60,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.requestSubmitFailedRetry),
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // -- Helpers --

  int? _lookupReferencePrice() {
    if (_selectedInstrument == null) return null;
    final settings =
        ref
            .read(teacherSettingsByIdProvider(widget.params.teacherId))
            .valueOrNull;
    if (settings == null) return null;
    return settings.getPrice(_selectedInstrument!, _selectedExperience.name);
  }

  String _formatPrice(int price) {
    final buffer = StringBuffer();
    final priceStr = price.toString();
    for (var i = 0; i < priceStr.length; i++) {
      if (i > 0 && (priceStr.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(priceStr[i]);
    }
    return buffer.toString();
  }
}

// -- Reusable section wrapper --

class _SectionWrapper extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isRequired;
  final Widget child;

  const _SectionWrapper({
    required this.icon,
    required this.title,
    this.subtitle,
    this.isRequired = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.paperAccent),
            const SizedBox(width: AppSpacing.space2),
            // Notebook × Score: _SectionWrapper 의 section title 은 Playfair
            // sectionTitle 로 통일. 6개 호출부(체험/정기/아카데미 각 폼) 에 일괄 반영 (§7.17).
            Text(title, style: NotebookTypography.sectionTitle),
            if (isRequired)
              Text(
                ' *',
                style: NotebookTypography.sectionTitle.copyWith(
                  color: AppColors.paperAccent,
                ),
              ),
            if (subtitle != null) ...[
              const SizedBox(width: AppSpacing.space2),
              Text(
                subtitle!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        child,
      ],
    );
  }
}
