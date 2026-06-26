import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_profile.dart';

/// #964 — TeacherProfile.specialties → expertiseTags 리네임.
/// BE 와이어 키는 'specialties' 유지(호환). copyWith·completion% 보존.
void main() {
  TeacherProfile profile({List<String>? expertiseTags}) => TeacherProfile(
    id: 'tp_1',
    userId: 'user_1',
    name: '이선생',
    instruments: const ['바이올린'],
    introduction: '안녕하세요 바이올린을 가르치는 강사입니다. 잘 부탁드립니다.',
    expertiseTags: expertiseTags,
    createdAt: DateTime(2026, 3, 1),
  );

  group('expertiseTags 직렬화 — 와이어 키 specialties (BE 호환)', () {
    test('toJson 은 specialties 키로 직렬화 (expertise_tags 키 없음)', () {
      final json = profile(expertiseTags: ['클래식', '재즈']).toJson();
      expect(json['specialties'], ['클래식', '재즈']);
      expect(json.containsKey('expertise_tags'), isFalse);
    });

    test('fromJson — specialties 키를 expertiseTags 로 역직렬화', () {
      final restored = TeacherProfile.fromJson(
        profile(expertiseTags: ['클래식']).toJson(),
      );
      expect(restored.expertiseTags, ['클래식']);
    });

    test('legacy specialties 키 보존 (무손상)', () {
      final json = profile().toJson();
      json['specialties'] = ['현대음악'];
      expect(TeacherProfile.fromJson(json).expertiseTags, ['현대음악']);
    });
  });

  test('copyWith 으로 expertiseTags 설정', () {
    expect(profile().copyWith(expertiseTags: ['락']).expertiseTags, ['락']);
  });

  test('completionPercentage — expertiseTags 채우면 +6', () {
    final without = profile().completionPercentage;
    final withTags = profile(expertiseTags: ['클래식']).completionPercentage;
    expect(withTags - without, 6);
  });
}
