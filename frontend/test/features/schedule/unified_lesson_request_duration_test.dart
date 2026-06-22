import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/providers/repository_provider.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_settings.dart';
import 'package:lessonaza/features/schedule/presentation/screens/unified_lesson_request_screen.dart';
import 'package:lessonaza/features/settings/presentation/providers/teacher_settings_provider.dart';

/// #209: 학생 레슨 신청 폼의 "예상 레슨 시간" 이 60분 하드코딩이 아니라
/// 교사가 설정한 lessonDurationMinutes 를 표시해야 한다.
void main() {
  testWidgets('#209 예상 레슨 시간 = 교사 설정값 (60분 하드코딩 아님)', (tester) async {
    const teacherId = 'teacher-209';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mockDataModeProvider.overrideWithValue(true),
          teacherSettingsByIdProvider(teacherId).overrideWith(
            (ref) async => TeacherSettings(
              id: teacherId,
              instruments: const ['바이올린'],
              createdAt: DateTime(2026),
              lessonDurationMinutes: 45,
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const UnifiedLessonRequestScreen(
            params: UnifiedLessonRequestParams(
              teacherId: teacherId,
              teacherName: '김선생님',
              teacherInstruments: ['바이올린'],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('45분'), findsOneWidget);
    expect(find.text('60분'), findsNothing);
  });
}
