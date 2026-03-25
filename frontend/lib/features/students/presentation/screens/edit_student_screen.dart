import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/profile_photo_header.dart';
import '../../../../features/students/domain/entities/student.dart';
import '../../../../features/students/presentation/providers/student_crud_provider.dart';
import '../providers/membership_providers.dart';
import '../providers/student_image_provider.dart';
import '../widgets/student_form/student_form_dialogs.dart';
import '../widgets/student_form_widgets.dart';

/// Screen for editing an existing student
class EditStudentScreen extends ConsumerStatefulWidget {
  final String studentId;

  const EditStudentScreen({
    super.key,
    required this.studentId,
  });

  @override
  ConsumerState<EditStudentScreen> createState() => _EditStudentScreenState();
}

class _EditStudentScreenState extends ConsumerState<EditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _monthlyFeeController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _addressController = TextEditingController();
  final _addressDetailController = TextEditingController();

  String? _selectedInstrument;
  StudentLevel _selectedLevel = StudentLevel.intermediate;
  int _lessonsPerWeek = 1;
  int _lessonDuration = 60;
  final Set<int> _selectedDays = {};
  TimeOfDay _lessonTime = const TimeOfDay(hour: 14, minute: 0);
  final Map<int, TimeOfDay> _dayTimeMap = {};

  bool _isInitialized = false;
  bool _hasChanges = false;
  bool _isSaving = false;

  static const List<String> _dayNames = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _notesController.dispose();
    _monthlyFeeController.dispose();
    _postalCodeController.dispose();
    _addressController.dispose();
    _addressDetailController.dispose();
    super.dispose();
  }

  void _populateFields(Student student) {
    _nameController.text = student.name;
    _phoneController.text = student.phone ?? '';
    _emailController.text = student.email ?? '';
    _parentNameController.text = student.parentName ?? '';
    _parentPhoneController.text = student.parentPhone ?? '';
    _selectedInstrument = student.instrument;
    _selectedLevel = student.level;
    _lessonsPerWeek = student.lessonsPerWeek;
    _monthlyFeeController.text = student.monthlyFee.toString();
    _lessonDuration = student.lessonDuration;
    _notesController.text = student.notes ?? '';
    _postalCodeController.text = student.postalCode ?? '';
    _addressController.text = student.address ?? '';
    _addressDetailController.text = student.addressDetail ?? '';

    // Parse lesson days
    _selectedDays.clear();
    if (student.lessonDay != null) {
      for (final day in student.lessonDay!.split(', ')) {
        final index = _dayNames.indexOf(day.trim());
        if (index >= 0) _selectedDays.add(index);
      }
    }

    // Parse lesson time (supports "14:00" or "월14:00,수15:30" format)
    _dayTimeMap.clear();
    if (student.lessonTime != null) {
      final timeStr = student.lessonTime!;
      if (timeStr.contains(',') || RegExp(r'^[가-힣]').hasMatch(timeStr)) {
        // Per-day format: "월14:00,수15:30"
        for (final entry in timeStr.split(',')) {
          final trimmed = entry.trim();
          if (trimmed.length >= 6) {
            final dayChar = trimmed[0];
            final dayIndex = _dayNames.indexOf(dayChar);
            final timePart = trimmed.substring(1);
            final parts = timePart.split(':');
            if (dayIndex >= 0 && parts.length == 2) {
              final hour = int.tryParse(parts[0]);
              final minute = int.tryParse(parts[1]);
              if (hour != null && minute != null) {
                _dayTimeMap[dayIndex] = TimeOfDay(hour: hour, minute: minute);
              }
            }
          }
        }
        // Set default lessonTime from first entry
        if (_dayTimeMap.isNotEmpty) {
          _lessonTime = _dayTimeMap.values.first;
        }
      } else {
        // Simple format: "14:00"
        final parts = timeStr.split(':');
        if (parts.length == 2) {
          final hour = int.tryParse(parts[0]);
          final minute = int.tryParse(parts[1]);
          if (hour != null && minute != null) {
            _lessonTime = TimeOfDay(hour: hour, minute: minute);
          }
        }
        // Populate dayTimeMap with same time for all selected days
        for (final day in _selectedDays) {
          _dayTimeMap[day] = _lessonTime;
        }
      }
    }

    _isInitialized = true;
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentAsync = ref.watch(studentProvider(widget.studentId));
    final membershipsAsync =
        ref.watch(studentMembershipsProvider(widget.studentId));
    final isLinked = membershipsAsync.whenOrNull(
          data: (memberships) => memberships.isNotEmpty,
        ) ??
        false;

    return studentAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('학생 수정')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('학생 수정')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.space3),
              Text('학생 정보를 불러올 수 없습니다', style: TextStyle(color: AppColors.error)),
              const SizedBox(height: AppSpacing.space3),
              FilledButton(
                onPressed: () => ref.invalidate(studentProvider(widget.studentId)),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
      data: (student) {
        if (student == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('학생 수정')),
            body: const Center(child: Text('학생을 찾을 수 없습니다')),
          );
        }

        if (!_isInitialized) {
          _populateFields(student);
        }

        return PopScope(
          canPop: !_isSaving,
          child: Scaffold(
          appBar: AppBar(
            title: const Text('학생 수정'),
            leading: IconButton(
              onPressed: _isSaving
                  ? null
                  : () => showExitConfirmation(
                        context,
                        hasChanges: _hasChanges,
                        onExit: () => context.pop(),
                      ),
              icon: const Icon(Icons.close),
            ),
            actions: [
              TextButton(
                onPressed: _hasChanges && !_isSaving
                    ? () => _saveStudent(student)
                    : null,
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        '저장',
                        style: TextStyle(
                          color: _hasChanges ? null : AppColors.textTertiaryLight,
                        ),
                      ),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            onChanged: _markChanged,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile + background photo header
                  _buildPhotoHeader(student),

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
                      setState(() {
                        _selectedInstrument = value;
                        _hasChanges = true;
                      });
                    },
                  ),

                  const SizedBox(height: AppSpacing.space6),

                  // Level and tuition section
                  const FormSectionTitle('레벨 및 수강료'),
                  FormSectionSubtitle(
                    isLinked
                        ? '수강권이 발급된 학생입니다'
                        : '레벨에 따라 기본 수강료가 설정됩니다',
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  LevelAndTuitionSection(
                    selectedLevel: _selectedLevel,
                    onLevelChanged: (level) {
                      setState(() {
                        _selectedLevel = level;
                        if (!isLinked) {
                          _monthlyFeeController.text =
                              level.defaultMonthlyFee.toString();
                        }
                        _hasChanges = true;
                      });
                    },
                    feeController: _monthlyFeeController,
                    lessonsPerWeek: _lessonsPerWeek,
                    onFrequencyChanged: (value) {
                      setState(() {
                        _lessonsPerWeek = value;
                        _hasChanges = true;
                      });
                    },
                    onFeeChanged: () {
                      _markChanged();
                      setState(() {});
                    },
                    isLinked: isLinked,
                    onManageSubscription: isLinked
                        ? () => context.push(
                              '${AppRoutes.issueSubscription}?studentId=${widget.studentId}',
                            )
                        : null,
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
                        _hasChanges = true;
                      });
                    },
                    lessonTime: _lessonTime,
                    onTimeTap: () async {
                      final picked = await selectTime(context, _lessonTime);
                      if (picked != null) {
                        setState(() {
                          _lessonTime = picked;
                          _hasChanges = true;
                        });
                      }
                    },
                    lessonDuration: _lessonDuration,
                    onDurationChanged: (value) {
                      setState(() {
                        _lessonDuration = value;
                        _hasChanges = true;
                      });
                    },
                    dayTimeMap: _dayTimeMap,
                    onDayTimeChanged: (dayIndex, time) {
                      setState(() {
                        _dayTimeMap[dayIndex] = time;
                        _hasChanges = true;
                      });
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
                      onPressed: _hasChanges && !_isSaving
                          ? () => _saveStudent(student)
                          : null,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('변경사항 저장'),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.space4),

                  // Delete button
                  SizedBox(
                    width: double.infinity,
                    height: AppSpacing.buttonHeight,
                    child: OutlinedButton.icon(
                      onPressed: _isSaving
                          ? null
                          : () => showDeleteStudentConfirmation(
                                context,
                                studentName: _nameController.text,
                                onDelete: () => _deleteStudent(student),
                              ),
                      icon: Icon(Icons.delete_outline, color: AppColors.error),
                      label: Text(
                        '학생 삭제',
                        style: TextStyle(color: AppColors.error),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: AppColors.error.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.space6),
                ],
              ),
            ),
          ),
        ),
        );
      },
    );
  }

  Widget _buildPhotoHeader(Student student) {
    final profileImagePath =
        ref.watch(studentProfileImageNotifierProvider(student.id)).valueOrNull;
    final backgroundImagePath =
        ref.watch(studentBackgroundImageNotifierProvider(student.id)).valueOrNull;
    final displayName = _nameController.text;
    final initial = displayName.isNotEmpty ? displayName[0] : '?';

    return ProfilePhotoHeader(
      profileImagePath: profileImagePath,
      backgroundImagePath: backgroundImagePath,
      initial: initial,
      avatarColor: student.profileColor,
      onTapProfile: () => _onTapStudentProfileImage(student.id),
      onTapBackground: () => _onTapStudentBackgroundImage(student.id),
    );
  }

  Future<void> _onTapStudentProfileImage(String studentId) async {
    final currentPath =
        ref.read(studentProfileImageNotifierProvider(studentId)).valueOrNull;

    final action = await showImagePickerBottomSheet(
      context,
      title: '프로필 사진',
      showDelete: currentPath != null,
    );
    if (action == null || !mounted) return;

    final notifier =
        ref.read(studentProfileImageNotifierProvider(studentId).notifier);

    if (action == ImagePickerAction.delete) {
      await notifier.removeImage();
      _markChanged();
      return;
    }

    final source = action == ImagePickerAction.camera
        ? ImageSource.camera
        : ImageSource.gallery;

    if (!mounted) return;
    final success = await notifier.pickAndSaveImage(source, context);
    if (success) _markChanged();
  }

  Future<void> _onTapStudentBackgroundImage(String studentId) async {
    final currentPath =
        ref.read(studentBackgroundImageNotifierProvider(studentId)).valueOrNull;

    final action = await showImagePickerBottomSheet(
      context,
      title: '배경 사진',
      showDelete: currentPath != null,
    );
    if (action == null || !mounted) return;

    final notifier =
        ref.read(studentBackgroundImageNotifierProvider(studentId).notifier);

    if (action == ImagePickerAction.delete) {
      await notifier.removeImage();
      _markChanged();
      return;
    }

    final source = action == ImagePickerAction.camera
        ? ImageSource.camera
        : ImageSource.gallery;

    if (!mounted) return;
    final success = await notifier.pickAndSaveImage(source, context);
    if (success) _markChanged();
  }

  Future<void> _deleteStudent(Student student) async {
    try {
      await ref.read(studentsNotifierProvider.notifier).deleteStudent(student.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${student.name} 학생이 삭제되었습니다'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('학생 삭제에 실패했습니다. 다시 시도해주세요.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _saveStudent(Student original) async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedInstrument == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('악기를 선택해주세요'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final sortedDays = _selectedDays.toList()..sort();
    final lessonDays = sortedDays.map((i) => _dayNames[i]).join(', ');
    final lessonTimeStr = _buildLessonTimeString(sortedDays);
    final monthlyFee =
        int.tryParse(_monthlyFeeController.text) ?? original.monthlyFee;

    final updated = original.copyWith(
      name: _nameController.text.trim(),
      instrument: _selectedInstrument!,
      level: _selectedLevel,
      monthlyFee: monthlyFee,
      lessonsPerWeek: _lessonsPerWeek,
      phone: _phoneController.text.isNotEmpty
          ? _phoneController.text.trim()
          : null,
      parentName: _parentNameController.text.isNotEmpty
          ? _parentNameController.text.trim()
          : null,
      parentPhone: _parentPhoneController.text.isNotEmpty
          ? _parentPhoneController.text.trim()
          : null,
      email: _emailController.text.isNotEmpty
          ? _emailController.text.trim()
          : null,
      lessonDay: lessonDays.isNotEmpty ? lessonDays : null,
      lessonTime: lessonTimeStr,
      lessonDuration: _lessonDuration,
      notes: _notesController.text.isNotEmpty
          ? _notesController.text.trim()
          : null,
      postalCode: _postalCodeController.text.isNotEmpty
          ? _postalCodeController.text.trim()
          : null,
      address: _addressController.text.isNotEmpty
          ? _addressController.text.trim()
          : null,
      addressDetail: _addressDetailController.text.isNotEmpty
          ? _addressDetailController.text.trim()
          : null,
      district: _addressController.text.isNotEmpty
          ? _extractDistrict(_addressController.text.trim())
          : null,
      updatedAt: DateTime.now(),
    );

    try {
      await ref.read(studentsNotifierProvider.notifier).updateStudent(updated);

      if (!mounted) return;

      // Invalidate cached student data so detail screen shows updated info
      ref.invalidate(studentProvider(widget.studentId));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_nameController.text} 학생 정보가 수정되었습니다'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.practiceGood,
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('학생 정보 저장에 실패했습니다. 다시 시도해주세요.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Extract district (구/동) from full address.
  /// e.g. "서울시 강남구 역삼동" -> "강남구 역삼동"
  String? _extractDistrict(String address) {
    final parts = address.split(' ');
    if (parts.length >= 3) {
      return parts.sublist(1).join(' ');
    }
    if (parts.length == 2) {
      return address;
    }
    return null;
  }

  /// Build lessonTime string: "14:00" if all same, "월14:00,수15:30" if different.
  String _buildLessonTimeString(List<int> sortedDays) {
    if (sortedDays.isEmpty) return formatTime(_lessonTime);

    final times = sortedDays.map((d) => _dayTimeMap[d] ?? _lessonTime).toList();
    final allSame = times.every(
      (t) => t.hour == times.first.hour && t.minute == times.first.minute,
    );

    if (allSame) return formatTime(times.first);

    return sortedDays.map((d) {
      final time = _dayTimeMap[d] ?? _lessonTime;
      return '${_dayNames[d]}${formatTime(time)}';
    }).join(',');
  }
}
