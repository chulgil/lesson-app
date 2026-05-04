import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/presentation/widgets/schedule_weekly_grid_view.dart';

void main() {
  test('weekly grid compact labels are enlarged by 1.5x', () {
    expect(scheduleWeeklyGridLessonNameFontSize, 18);
    expect(scheduleWeeklyGridUtilityLabelFontSize, 16.5);
  });
}
