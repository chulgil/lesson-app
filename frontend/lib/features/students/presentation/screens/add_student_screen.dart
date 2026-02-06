import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../models/student.dart';
import '../../../../providers/student/student_crud_provider.dart';
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

  String? _selectedInstrument;
  StudentLevel _selectedLevel = StudentLevel.intermediate;
  late TextEditingController _monthlyFeeController;
  int _lessonsPerWeek = 1;
  int _lessonDuration = 60;
  final Set<int> _selectedDays = {};
  TimeOfDay _lessonTime = const TimeOfDay(hour: 14, minute: 0);

  static const List<String> _dayNames = ['월', '화', '수', '목', '금', '토', '일'];

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('학생 작성'),
        leading: IconButton(
          onPressed: () => showExitConfirmation(
            context,
            hasChanges: _hasFormData(),
            onExit: () => context.pop(),
          ),
          icon: const Icon(Icons.close),
        ),
        actions: [
          TextButton(
            onPressed: _saveStudent,
            child: const Text('저장'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile photo section
              StudentProfileSection(
                displayName: _nameController.text,
                onTapPhoto: () => showImagePickerOptions(context),
              ),

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
                    } else {
                      _selectedDays.add(index);
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
        _notesController.text.isNotEmpty;
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

    final monthlyFee = int.tryParse(_monthlyFeeController.text) ??
        _selectedLevel.defaultMonthlyFee;

    // Create lesson day string from selected days
    final lessonDays = _selectedDays.map((i) => _dayNames[i]).join(', ');

    // Generate random profile color
    final profileColors = [
      AppColors.primary,
      AppColors.secondary,
      const Color(0xFF2E8B57),
      const Color(0xFF6B5B95),
      const Color(0xFFE57373),
      const Color(0xFF4FC3F7),
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
      phone: _phoneController.text.isNotEmpty
          ? _phoneController.text.trim()
          : null,
      parentPhone: _parentPhoneController.text.isNotEmpty
          ? _parentPhoneController.text.trim()
          : null,
      email:
          _emailController.text.isNotEmpty ? _emailController.text.trim() : null,
      profileColor: profileColor,
      lessonDay: lessonDays.isNotEmpty ? lessonDays : null,
      lessonTime: formatTime(_lessonTime),
      lessonDuration: _lessonDuration,
      notes:
          _notesController.text.isNotEmpty ? _notesController.text.trim() : null,
      createdAt: DateTime.now(),
    );

    try {
      // Save student using provider
      await ref.read(studentsNotifierProvider.notifier).addStudent(student);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_nameController.text} 학생이 추가되었습니다'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.practiceGood,
        ),
      );

      // Go back
      context.pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('학생 추가 실패: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
