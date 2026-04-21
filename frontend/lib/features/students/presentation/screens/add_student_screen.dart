import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/students/domain/entities/lesson_slot.dart';
import '../../../../features/students/domain/entities/student.dart';
import '../../../../features/students/presentation/providers/student_crud_provider.dart';
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
      text: _selectedLevel.defaultMonthlyFee.toString(),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('학생 작성'),
        leading: IconButton(
          onPressed:
              () => showExitConfirmation(
                context,
                hasChanges: _hasFormData(),
                onExit: () => context.pop(),
              ),
          icon: const Icon(Icons.close),
        ),
        actions: [TextButton(onPressed: _saveStudent, child: const Text(AppStrings.save))],
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
              const FormSectionTitle('기본 정보'),
              const SizedBox(height: AppSpacing.space3),
              BasicInfoFields(
                nameController: _nameController,
                phoneController: _phoneController,
                emailController: _emailController,
              ),

              const SizedBox(height: AppSpacing.space6),

              // Parent/Guardian info section
              const FormSectionTitle('보호자 정보'),
              const FormSectionSubtitle('미성년 학생의 경우 입력해주세요'),
              const SizedBox(height: AppSpacing.space3),
              ParentInfoFields(
                parentNameController: _parentNameController,
                parentPhoneController: _parentPhoneController,
              ),

              const SizedBox(height: AppSpacing.space6),

              // Address section
              const FormSectionTitle('주소'),
              const FormSectionSubtitle('레슨 장소가 학생 집인 경우 자동으로 사용됩니다'),
              const SizedBox(height: AppSpacing.space3),
              AddressFields(
                postalCodeController: _postalCodeController,
                addressController: _addressController,
                addressDetailController: _addressDetailController,
              ),

              const SizedBox(height: AppSpacing.space6),

              // Instrument section
              const FormSectionTitle('악기'),
              const SizedBox(height: AppSpacing.space3),
              InstrumentSelector(
                selectedInstrument: _selectedInstrument,
                onChanged: (value) {
                  setState(() => _selectedInstrument = value);
                },
              ),

              const SizedBox(height: AppSpacing.space6),

              // Level and tuition section
              const FormSectionTitle('레벨 및 수강료'),
              const FormSectionSubtitle('레벨에 따라 기본 수강료가 설정됩니다'),
              const SizedBox(height: AppSpacing.space3),
              LevelAndTuitionSection(
                selectedLevel: _selectedLevel,
                onLevelChanged: (level) {
                  setState(() {
                    _selectedLevel = level;
                    _monthlyFeeController.text =
                        level.defaultMonthlyFee.toString();
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
              const FormSectionTitle('레슨 일정'),
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
              const FormSectionTitle('메모'),
              const FormSectionSubtitle('레슨 시 참고할 내용을 입력해주세요'),
              const SizedBox(height: AppSpacing.space3),
              NotesField(controller: _notesController),

              const SizedBox(height: AppSpacing.space8),

              // Save button
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: FilledButton(
                  onPressed: _saveStudent,
                  child: const Text('학생 추가'),
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedInstrument == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('악기를 선택해주세요'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final monthlyFee =
        int.tryParse(_monthlyFeeController.text) ??
        _selectedLevel.defaultMonthlyFee;

    final sortedDays = _selectedDays.toList()..sort();
    final lessonSlots =
        sortedDays.map((d) {
          final time = _dayTimeMap[d] ?? _lessonTime;
          final startTime = formatTime(time);
          return LessonSlot(dayOfWeek: d, startTime: startTime, endTime: '');
        }).toList();

    // Generate random profile color
    final profileColors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.paperOk,
      AppColors.profilePurple,
      AppColors.profileRed,
      AppColors.profileBlue,
    ];
    final profileColor =
        profileColors[DateTime.now().millisecond % profileColors.length];

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
      profileColor: profileColor,
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
      final issueSubscription = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('학생 추가 완료'),
              content: Text(
                '${_nameController.text} 학생이 추가되었습니다.\n수강권을 발급하시겠습니까?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('나중에'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('발급하기'),
                ),
              ],
            ),
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
          content: const Text('학생 추가에 실패했습니다. 다시 시도해주세요.'),
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
