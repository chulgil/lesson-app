import '../../../profile/domain/entities/teacher_settings.dart';
import '../../../../core/booking/entities/time_slot.dart';

/// Repository interface for teacher settings
abstract class SettingsRepository {
  Future<TeacherSettings> getTeacherSettings();
  Future<TeacherSettings> getTeacherSettingsById(String teacherId);
  Future<TeacherSettings> updateInstruments(List<String> instruments);
  Future<TeacherSettings> updateDefaultDuration(int duration);
  Future<TeacherSettings> addCustomDuration(int duration);
  Future<TeacherSettings> removeCustomDuration(int duration);
  Future<TeacherSettings> toggleDuration(int duration, bool isActive);
  Future<TeacherSettings> updateAvailableSlots(List<TimeSlot> slots);
  Future<TeacherSettings> updateTimeSlot(TimeSlot slot);
  Future<TeacherSettings> toggleTimeSlot(String slotId, bool isActive);
  Future<TeacherSettings> updateBreakTime(int minutes);
  Future<TeacherSettings> updateMinBookingHours(int hours);
  Future<void> updateTrialLessonFree(bool value);
  Future<void> updateBookingGuidanceMessage(String? message);
  Future<void> updatePriceTable(Map<String, Map<String, int>> priceTable);
}
