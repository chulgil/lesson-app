import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/price_input.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../features/students/domain/entities/lesson_slot.dart';
import '../../../../features/students/domain/entities/student.dart';
import '../../../../features/students/students_facade.dart'
    show studentsNotifierProvider;
import '../widgets/student_form_widgets.dart';

/// Screen for adding a new student
class AddStudentScreen extends ConsumerStatefulWidget {
  const AddStudentScreen({super.key});

  @override
  ConsumerState<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends ConsumerState<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _addressController = TextEditingController();
  final _addressDetailController = TextEditingController();

  bool _isSaving = false;

  String? _selectedInstrument;
  StudentLevel _selectedLevel = StudentLevel.intermediate;
  late TextEditingController _monthlyFeeController;
  int _lessonsPerWeek = 1;
  int _lessonDuration = 60;
  final Set<int> _selectedDays = {};
  TimeOfDay _lessonTime = const TimeOfDay(hour: 14, minute: 0);
  final Map<int, TimeOfDay> _dayTimeMap = {};

  @override
  void initState() {
    super.initState();
    _monthlyFeeController = TextEditingController(
      text: formatPriceWithCommas(_selectedLevel.defaultMonthlyFee),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _monthlyFeeController.dispose();
    _notesController.dispose();
    _postalCodeController.dispose();
    _addressController.dispose();
    _addressDetailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotebookScreenScaffold(
      appBar: NotebookDetailAppBar(
        title: AppStrings.studentFormTitle,
        onLeadingTap:
            () => showExitConfirmation(
              context,
              hasChanges: _hasFormData(),
              onExit: () => context.pop(),
            ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile photo section
              StudentProfileSection(displayName: _nameController.text),

              const SizedBox(height: AppSpacing.space6),

              // Basic info section
              const FormSectionTitle(AppStrings.formSectionBasicInfo),
              const SizedBox(height: AppSpacing.space3),
              BasicInfoFields(
                nameController: _nameController,
                phoneController: _phoneController,
                emailController: _emailController,
              ),

              const SizedBox(height: AppSpacing.space6),

              // Parent/Guardian info section
              const FormSectionTitle(AppStrings.formSectionGuardianInfo),
              const FormSectionSubtitle(AppStrings.formSectionGuardianHint),
              const SizedBox(height: AppSpacing.space3),
              ParentInfoFields(
                parentNameController: _parentNameController,
                parentPhoneController: _parentPhoneController,
              ),

              const SizedBox(height: AppSpacing.space6),

              // Address section
              const FormSectionTitle(AppStrings.formSectionAddress),
              const FormSectionSubtitle('레슨 장소가 학생 집인 경우 자동으로 사용됩니다'),
              const SizedBox(height: AppSpacing.space3),
              AddressFields(
                postalCodeController: _postalCodeController,
                addressController: _addressController,
                addressDetailController: _addressDetailController,
              ),

              const SizedBox(height: AppSpacing.space6),

              // Instrument section
              const FormSectionTitle(AppStrings.formSectionInstrument),
              const SizedBox(height: AppSpacing.space3),
              InstrumentSelector(
                selectedInstrument: _selectedInstrument,
                onChanged: (value) {
                  setState(() => _selectedInstrument = value);
                },
              ),

              const SizedBox(height: AppSpacing.space6),

              // Level and tuition section
              const FormSectionTitle(AppStrings.formSectionLevelTuition),
              const FormSectionSubtitle('레벨에 따라 기본 수강료가 설정됩니다'),
              const SizedBox(height: AppSpacing.space3),
              LevelAndTuitionSection(
                selectedLevel: _selectedLevel,
                onLevelChanged: (level) {
                  setState(() {
                    _selectedLevel = level;
                    _monthlyFeeController.text = formatPriceWithCommas(
                      level.defaultMonthlyFee,
                    );
                  });
                },
                feeController: _monthlyFeeController,
                lessonsPerWeek: _lessonsPerWeek,
                onFrequencyChanged: (value) {
                  setState(() => _lessonsPerWeek = value);
                },
                onFeeChanged: () => setState(() {}),
              ),

              const SizedBox(height: AppSpacing.space6),

              // Lesson schedule section
              const FormSectionTitle(AppStrings.formSectionSchedule),
              const SizedBox(height: AppSpacing.space3),
              ScheduleSection(
                selectedDays: _selectedDays,
                onDayToggle: (index) {
                  setState(() {
                    if (_selectedDays.contains(index)) {
                      _selectedDays.remove(index);
                      _dayTimeMap.remove(index);
                    } else {
                      _selectedDays.add(index);
                      _dayTimeMap[index] = _lessonTime;
                    }
                  });
                },
                lessonTime: _lessonTime,
                onTimeTap: () async {
                  final picked = await selectTime(context, _lessonTime);
                  if (picked != null) {
                    setState(() => _lessonTime = picked);
                  }
                },
                lessonDuration: _lessonDuration,
                onDurationChanged: (value) {
                  setState(() => _lessonDuration = value);
                },
                dayTimeMap: _dayTimeMap,
                onDayTimeChanged: (dayIndex, time) {
                  setState(() => _dayTimeMap[dayIndex] = time);
                },
              ),

              const SizedBox(height: AppSpacing.space6),

              // Notes section
              const FormSectionTitle(AppStrings.formSectionNotes),
              const FormSectionSubtitle('레슨 시 참고할 내용을 입력해주세요'),
              const SizedBox(height: AppSpacing.space3),
              NotesField(controller: _notesController),

              const SizedBox(height: AppSpacing.space8),

              // Save button
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveStudent,
                  child: const Text(AppStrings.studentAddLabel),
                ),
              ),

              const SizedBox(height: AppSpacing.space6),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasFormData() {
    return _nameController.text.isNotEmpty ||
        _phoneController.text.isNotEmpty ||
        _emailController.text.isNotEmpty ||
        _parentNameController.text.isNotEmpty ||
        _parentPhoneController.text.isNotEmpty ||
        _selectedInstrument != null ||
        _selectedDays.isNotEmpty ||
        _notesController.text.isNotEmpty ||
        _postalCodeController.text.isNotEmpty ||
        _addressController.text.isNotEmpty ||
        _addressDetailController.text.isNotEmpty;
  }

  Future<void> _saveStudent() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _doSaveStudent();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _doSaveStudent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedInstrument == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.studentSelectInstrument),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final monthlyFee =
        parsePrice(_monthlyFeeController.text) ??
        _selectedLevel.defaultMonthlyFee;

    final sortedDays = _selectedDays.toList()..sort();
    final lessonSlots =
        sortedDays.map((d) {
          final time = _dayTimeMap[d] ?? _lessonTime;
          final startTime = formatTime(time);
          return LessonSlot(dayOfWeek: d, startTime: startTime, endTime: '');
        }).toList();

    // Generate random semantic profile color.
    const profileColorKeys = [
      'paperAccent',
      'paperAccent',
      'paperOk',
      'profilePurple',
      'profileRed',
      'profileBlue',
    ];
    final profileColorKey =
        profileColorKeys[DateTime.now().millisecond % profileColorKeys.length];

    // Create Student object
    final student = Student(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      instrument: _selectedInstrument!,
      level: _selectedLevel,
      status: StudentStatus.trial,
      monthlyFee: monthlyFee,
      lessonsPerWeek: _lessonsPerWeek,
      phone:
          _phoneController.text.isNotEmpty
              ? _phoneController.text.trim()
              : null,
      parentName:
          _parentNameController.text.isNotEmpty
              ? _parentNameController.text.trim()
              : null,
      parentPhone:
          _parentPhoneController.text.isNotEmpty
              ? _parentPhoneController.text.trim()
              : null,
      email:
          _emailController.text.isNotEmpty
              ? _emailController.text.trim()
              : null,
      profileColorKey: profileColorKey,
      lessonSlots: lessonSlots,
      lessonDuration: _lessonDuration,
      notes:
          _notesController.text.isNotEmpty
              ? _notesController.text.trim()
              : null,
      postalCode:
          _postalCodeController.text.isNotEmpty
              ? _postalCodeController.text.trim()
              : null,
      address:
          _addressController.text.isNotEmpty
              ? _addressController.text.trim()
              : null,
      addressDetail:
          _addressDetailController.text.isNotEmpty
              ? _addressDetailController.text.trim()
              : null,
      district:
          _addressController.text.isNotEmpty
              ? _extractDistrict(_addressController.text.trim())
              : null,
      createdAt: DateTime.now(),
    );

    try {
      // Save student using provider
      await ref.read(studentsNotifierProvider.notifier).addStudent(student);

      if (!mounted) return;

      // Ask about subscription
      final issueSubscription = await showNotebookDialog(
        context: context,
        title: AppStrings.studentAddCompleteTitle,
        message: '${_nameController.text} 학생이 추가되었습니다.\n수강권을 발급하시겠습니까?',
        confirmLabel: '발급하기',
        cancelLabel: '나중에',
      );

      if (!mounted) return;

      if (issueSubscription == true) {
        context.pop();
        context.push('${AppRoutes.issueSubscription}?studentId=${student.id}');
      } else {
        context.pop();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppStrings.studentAddFailed),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.paperAccent,
        ),
      );
    }
  }

  /// Extract district (구/동) from full address.
  /// e.g. "서울시 강남구 역삼동" -> "강남구 역삼동"
  String? _extractDistrict(String address) {
    final parts = address.split(' ');
    if (parts.length >= 3) {
      // Skip city-level (시/도) and return gu + dong
      return parts.sublist(1).join(' ');
    }
    if (parts.length == 2) {
      return address;
    }
    return null;
  }
}
