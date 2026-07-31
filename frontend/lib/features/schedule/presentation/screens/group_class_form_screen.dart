// Group class create / edit form for teachers (P1-1)
//
// One form, not two flows: a class is a 반(cohort) by default and becomes a
// drop-in through a switch inside the form — the teacher is never asked to pick
// a type before seeing the fields (spec D1).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/utils/price_input.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../core/widgets/selectors/selectors.dart';
import '../../domain/entities/group_class.dart';
import '../../domain/entities/group_class_draft.dart';
import '../providers/group_class_providers.dart';
import '../widgets/group_class_form_fields.dart';

/// Create or edit a group class. Pass [groupClass] to edit an existing one.
class GroupClassFormScreen extends ConsumerStatefulWidget {
  const GroupClassFormScreen({
    super.key,
    required this.teacherId,
    this.groupClass,
  });

  final String teacherId;

  /// Null for create, populated for edit.
  final GroupClass? groupClass;

  @override
  ConsumerState<GroupClassFormScreen> createState() =>
      _GroupClassFormScreenState();
}

class _GroupClassFormScreenState extends ConsumerState<GroupClassFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  bool _isSaving = false;
  bool _isDropIn = false;
  String? _instrument;
  int _maxCapacity = 4;
  int _durationMinutes = 60;
  NoShowPolicy _noShowPolicy = NoShowPolicy.deductCredit;
  int _bookingDeadlineMinutes = 60;
  int _cancelDeadlineMinutes = 1440;
  final Set<int> _repeatDays = {};
  TimeOfDay _startTime = const TimeOfDay(hour: 17, minute: 0);
  DateTime _dropInDate = DateTime.now().add(const Duration(days: 7));

  bool get _isEditing => widget.groupClass != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.groupClass;
    if (existing == null) return;

    _nameController.text = existing.name;
    _descriptionController.text = existing.description ?? '';
    if (existing.pricePerSession != null) {
      _priceController.text = formatPriceWithCommas(existing.pricePerSession!);
    }
    _isDropIn = existing.type == GroupClassType.dropIn;
    _instrument = existing.instrument;
    _maxCapacity = existing.maxCapacity;
    _durationMinutes = existing.durationMinutes;
    _noShowPolicy = existing.noShowPolicy;
    _bookingDeadlineMinutes = existing.bookingDeadlineMinutes;
    _cancelDeadlineMinutes = existing.cancelDeadlineMinutes;
    _repeatDays.addAll(existing.repeatDaysOfWeek ?? const []);
    _startTime = _parseTimeOfDay(existing.repeatTimeOfDay) ?? _startTime;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotebookScreenScaffold(
      appBar: NotebookDetailAppBar(
        title:
            _isEditing
                ? AppStrings.groupClassFormEditTitle
                : AppStrings.groupClassFormCreateTitle,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(AppStrings.formSectionBasicInfo),
              const SizedBox(height: AppSpacing.space3),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: AppStrings.groupClassFormNameLabel,
                  hintText: AppStrings.groupClassFormNameHint,
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        (value == null || value.trim().isEmpty)
                            ? AppStrings.groupClassFormNameRequired
                            : null,
              ),
              const SizedBox(height: AppSpacing.space3),
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: AppStrings.groupClassFormDescriptionLabel,
                  hintText: AppStrings.groupClassFormDescriptionHint,
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: AppSpacing.space6),

              // Drop-in is an option on the cohort form, never a separate flow.
              _dropInToggle(),

              const SizedBox(height: AppSpacing.space6),

              _sectionTitle(AppStrings.formSectionInstrument),
              const SizedBox(height: AppSpacing.space3),
              GroupClassInstrumentChips(
                selectedInstrument: _instrument,
                onChanged: (value) => setState(() => _instrument = value),
              ),

              const SizedBox(height: AppSpacing.space6),

              _sectionTitle(AppStrings.groupClassFormCapacityLabel),
              const SizedBox(height: AppSpacing.space3),
              GroupClassCapacityChips(
                selectedCapacity: _maxCapacity,
                onChanged: (value) => setState(() => _maxCapacity = value),
              ),

              const SizedBox(height: AppSpacing.space6),

              _sectionTitle(AppStrings.formSectionSchedule),
              const SizedBox(height: AppSpacing.space3),
              if (_isDropIn) _dropInDateField() else _repeatDaysField(),
              const SizedBox(height: AppSpacing.space4),
              _startTimeField(),
              const SizedBox(height: AppSpacing.space4),
              LessonDurationSelector(
                selectedDuration: _durationMinutes,
                allowCustomInput: false,
                label: AppStrings.groupClassFormDurationLabel,
                onDurationChanged:
                    (minutes, _) => setState(() => _durationMinutes = minutes),
              ),

              const SizedBox(height: AppSpacing.space6),

              _sectionTitle(AppStrings.groupClassFormSectionPolicy),
              const SizedBox(height: AppSpacing.space3),
              _fieldLabel(AppStrings.groupClassFormNoShowPolicyLabel),
              const SizedBox(height: AppSpacing.space2),
              GroupClassNoShowPolicyChips(
                selectedPolicy: _noShowPolicy,
                onChanged: (policy) => setState(() => _noShowPolicy = policy),
              ),
              const SizedBox(height: AppSpacing.space4),
              _fieldLabel(AppStrings.groupClassFormBookingDeadlineLabel),
              const SizedBox(height: AppSpacing.space2),
              GroupClassDeadlineChips(
                selectedMinutes: _bookingDeadlineMinutes,
                onChanged:
                    (minutes) =>
                        setState(() => _bookingDeadlineMinutes = minutes),
              ),
              const SizedBox(height: AppSpacing.space4),
              _fieldLabel(AppStrings.groupClassFormCancelDeadlineLabel),
              const SizedBox(height: AppSpacing.space2),
              GroupClassDeadlineChips(
                selectedMinutes: _cancelDeadlineMinutes,
                onChanged:
                    (minutes) =>
                        setState(() => _cancelDeadlineMinutes = minutes),
              ),

              const SizedBox(height: AppSpacing.space6),

              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: AppStrings.groupClassFormPriceLabel,
                  hintText: AppStrings.groupClassFormPriceHint,
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: AppSpacing.space8),

              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: Text(
                    _isEditing
                        ? AppStrings.save
                        : AppStrings.groupClassFormCreateTitle,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.space6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) =>
      Text(title, style: NotebookTypography.sectionTitle);

  Widget _fieldLabel(String label) => Text(
    label,
    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
  );

  Widget _dropInToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _isDropIn,
        onChanged: (value) => setState(() => _isDropIn = value),
        title: Text(
          AppStrings.groupClassFormDropInToggleTitle,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          AppStrings.groupClassFormDropInToggleSubtitle,
          style: AppTypography.caption.copyWith(color: AppColors.inkSecondary),
        ),
      ),
    );
  }

  Widget _repeatDaysField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(AppStrings.groupClassFormRepeatDaysLabel),
        const SizedBox(height: AppSpacing.space2),
        GroupClassWeekdayChips(
          selectedDays: _repeatDays,
          onToggle:
              (weekday) => setState(() {
                if (!_repeatDays.remove(weekday)) _repeatDays.add(weekday);
              }),
        ),
      ],
    );
  }

  Widget _dropInDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(AppStrings.groupClassFormDropInDateLabel),
        const SizedBox(height: AppSpacing.space2),
        _pickerButton(
          icon: Icons.calendar_today,
          label: formatDateYMDWithDay(_dropInDate),
          onPressed: _pickDropInDate,
        ),
      ],
    );
  }

  Widget _startTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(AppStrings.groupClassFormStartTimeLabel),
        const SizedBox(height: AppSpacing.space2),
        _pickerButton(
          icon: Icons.access_time,
          label: _formatTimeOfDay(_startTime),
          onPressed: _pickStartTime,
        ),
      ],
    );
  }

  /// Compact button — the theme's minimumSize is `Size(infinity, h)`, which
  /// overflows inside an Align/Row, so width is released explicitly.
  Widget _pickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, AppSpacing.buttonHeight),
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.inkQuaternary),
        ),
      ),
    );
  }

  Future<void> _pickDropInDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dropInDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dropInDate = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder:
          (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    if (!_isDropIn && _repeatDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.groupClassFormRepeatDaysRequired),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final saved = await ref
          .read(groupClassFormNotifierProvider.notifier)
          .save(
            teacherId: widget.teacherId,
            draft: _buildDraft(),
            classId: widget.groupClass?.id,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? AppStrings.groupClassFormUpdated
                : AppStrings.groupClassFormCreated,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(saved);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.groupClassFormSaveFailed),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.paperAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  GroupClassDraft _buildDraft() {
    final sortedDays = _repeatDays.toList()..sort();
    final description = _descriptionController.text.trim();
    return GroupClassDraft(
      name: _nameController.text.trim(),
      type: _isDropIn ? GroupClassType.dropIn : GroupClassType.regular,
      maxCapacity: _maxCapacity,
      durationMinutes: _durationMinutes,
      noShowPolicy: _noShowPolicy,
      bookingDeadlineMinutes: _bookingDeadlineMinutes,
      cancelDeadlineMinutes: _cancelDeadlineMinutes,
      description: description.isEmpty ? null : description,
      instrument: _instrument,
      repeatDaysOfWeek: _isDropIn ? null : sortedDays,
      repeatTimeOfDay: _isDropIn ? null : _formatTimeOfDay(_startTime),
      dropInStartsAt: _isDropIn ? _dropInStartsAt() : null,
      pricePerSession: parsePrice(_priceController.text),
    );
  }

  DateTime _dropInStartsAt() => DateTime(
    _dropInDate.year,
    _dropInDate.month,
    _dropInDate.day,
    _startTime.hour,
    _startTime.minute,
  );

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  TimeOfDay? _parseTimeOfDay(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }
}
