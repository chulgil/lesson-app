// W2 Task 2.2 — category_status_provider test.
// spec §11.1: 5묶음 카테고리 카드 라벨 규칙 검증.
// glossary §14: 5묶음 카테고리 표.

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_profile.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_settings.dart';
import 'package:lessonaza/features/profile/presentation/providers/category_status_provider.dart';
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';

void main() {
  final fixedNow = DateTime(2026, 6, 11);

  TeacherAvailability buildAvailability({
    List<WeeklySchedule> weeklySchedules = const [],
    int breakTimeBetweenLessons = 0,
  }) {
    return TeacherAvailability(
      id: 'avail-1',
      teacherId: 't-1',
      weeklySchedules: weeklySchedules,
      breakTimeBetweenLessons: breakTimeBetweenLessons,
      createdAt: fixedNow,
    );
  }

  WeeklySchedule buildSlot({int dayOfWeek = 0}) {
    return WeeklySchedule(
      id: 'ws-$dayOfWeek',
      dayOfWeek: dayOfWeek,
      startTime: '10:00',
      endTime: '18:00',
      createdAt: fixedNow,
    );
  }

  TeacherSettings buildSettings({
    int lessonDurationMinutes = 50,
    int minBookingHours = 24,
    String? bookingGuidanceMessage,
    Map<String, Map<String, int>>? lessonPriceTable,
  }) {
    return TeacherSettings(
      id: 'settings-1',
      instruments: const ['바이올린'],
      lessonDurationMinutes: lessonDurationMinutes,
      minBookingHours: minBookingHours,
      bookingGuidanceMessage: bookingGuidanceMessage,
      lessonPriceTable: lessonPriceTable,
      createdAt: fixedNow,
    );
  }

  TeacherProfile buildProfile({
    String name = '김선생',
    String? profileImage,
    List<String> instruments = const ['바이올린'],
    List<BankAccount> bankAccounts = const [],
  }) {
    return TeacherProfile(
      id: 'profile-1',
      userId: 'user-1',
      name: name,
      profileImage: profileImage,
      instruments: instruments,
      introduction: '',
      bankAccounts: bankAccounts,
      createdAt: fixedNow,
    );
  }

  BankAccount buildBankAccount() {
    return BankAccount(
      id: 'ba-1',
      bankName: '국민',
      accountNumber: '123-456',
      accountHolder: '김선생',
      createdAt: fixedNow,
    );
  }

  group('CategoryStatusCalculator.operatingHours (운영시간 묶음)', () {
    test('weeklySchedules 1개 이상 + breakTime > 0 → complete', () {
      final status = CategoryStatusCalculator.operatingHours(
        availability: buildAvailability(
          weeklySchedules: [buildSlot()],
          breakTimeBetweenLessons: 10,
        ),
      );
      expect(status, isA<CategoryStatusComplete>());
    });

    test('weeklySchedules 1개 이상 + breakTime == 0 → partial', () {
      final status = CategoryStatusCalculator.operatingHours(
        availability: buildAvailability(
          weeklySchedules: [buildSlot()],
          breakTimeBetweenLessons: 0,
        ),
      );
      expect(status, isA<CategoryStatusPartial>());
    });

    test('weeklySchedules 비어있음 → empty', () {
      final status = CategoryStatusCalculator.operatingHours(
        availability: buildAvailability(),
      );
      expect(status, isA<CategoryStatusEmpty>());
    });

    test('availability null → empty', () {
      final status = CategoryStatusCalculator.operatingHours(
        availability: null,
      );
      expect(status, isA<CategoryStatusEmpty>());
    });
  });

  group('CategoryStatusCalculator.lessonStyle (수업방식 묶음)', () {
    test('3항목 모두 입력 → complete', () {
      final status = CategoryStatusCalculator.lessonStyle(
        settings: buildSettings(
          lessonDurationMinutes: 50,
          minBookingHours: 24,
          bookingGuidanceMessage: '메시지 주세요',
        ),
      );
      expect(status, isA<CategoryStatusComplete>());
    });

    test('bookingGuidanceMessage 없음 → 2/3 항목 partial', () {
      final status = CategoryStatusCalculator.lessonStyle(
        settings: buildSettings(
          lessonDurationMinutes: 50,
          minBookingHours: 24,
          bookingGuidanceMessage: null,
        ),
      );
      expect(status, isA<CategoryStatusPartial>());
      final partial = status as CategoryStatusPartial;
      expect(partial.filled, 2);
      expect(partial.total, 3);
    });

    test('bookingGuidanceMessage 빈 문자열 → 2/3 항목 partial', () {
      final status = CategoryStatusCalculator.lessonStyle(
        settings: buildSettings(bookingGuidanceMessage: ''),
      );
      expect(status, isA<CategoryStatusPartial>());
    });

    test('settings null → empty', () {
      final status = CategoryStatusCalculator.lessonStyle(settings: null);
      expect(status, isA<CategoryStatusEmpty>());
    });
  });

  group('CategoryStatusCalculator.subscriptionBilling (수강권·정산 묶음)', () {
    test('가격표 + 계좌 → complete', () {
      final status = CategoryStatusCalculator.subscriptionBilling(
        settings: buildSettings(
          lessonPriceTable: {
            '바이올린': {'beginner': 40000},
          },
        ),
        bankAccounts: [buildBankAccount()],
      );
      expect(status, isA<CategoryStatusComplete>());
    });

    test('가격표만 → partial (계좌 미설정)', () {
      final status = CategoryStatusCalculator.subscriptionBilling(
        settings: buildSettings(
          lessonPriceTable: {
            '바이올린': {'beginner': 40000},
          },
        ),
        bankAccounts: const [],
      );
      expect(status, isA<CategoryStatusPartial>());
    });

    test('계좌만 → partial (가격표 미설정)', () {
      final status = CategoryStatusCalculator.subscriptionBilling(
        settings: buildSettings(lessonPriceTable: null),
        bankAccounts: [buildBankAccount()],
      );
      expect(status, isA<CategoryStatusPartial>());
    });

    test('둘 다 없음 → empty', () {
      final status = CategoryStatusCalculator.subscriptionBilling(
        settings: buildSettings(),
        bankAccounts: const [],
      );
      expect(status, isA<CategoryStatusEmpty>());
    });

    test('settings null + 계좌 없음 → empty', () {
      final status = CategoryStatusCalculator.subscriptionBilling(
        settings: null,
        bankAccounts: const [],
      );
      expect(status, isA<CategoryStatusEmpty>());
    });

    test('lessonPriceTable 비어있는 맵 → 가격표 없음으로 취급', () {
      final status = CategoryStatusCalculator.subscriptionBilling(
        settings: buildSettings(lessonPriceTable: {}),
        bankAccounts: [buildBankAccount()],
      );
      expect(status, isA<CategoryStatusPartial>());
    });
  });

  group('CategoryStatusCalculator.myProfile (내 프로필 묶음)', () {
    test('이름·사진·악기 모두 → complete', () {
      final status = CategoryStatusCalculator.myProfile(
        profile: buildProfile(
          name: '김선생',
          profileImage: 'https://example.com/photo.jpg',
          instruments: const ['바이올린'],
        ),
      );
      expect(status, isA<CategoryStatusComplete>());
    });

    test('이름만 입력 → partial', () {
      final status = CategoryStatusCalculator.myProfile(
        profile: buildProfile(
          name: '김선생',
          profileImage: null,
          instruments: const [],
        ),
      );
      expect(status, isA<CategoryStatusPartial>());
      final partial = status as CategoryStatusPartial;
      expect(partial.filled, 1);
      expect(partial.total, 3);
    });

    test('이름·사진만 → partial 2/3', () {
      final status = CategoryStatusCalculator.myProfile(
        profile: buildProfile(
          name: '김선생',
          profileImage: 'https://example.com/photo.jpg',
          instruments: const [],
        ),
      );
      expect(status, isA<CategoryStatusPartial>());
      final partial = status as CategoryStatusPartial;
      expect(partial.filled, 2);
      expect(partial.total, 3);
    });

    test('이름 빈 문자열 → 미입력 취급', () {
      final status = CategoryStatusCalculator.myProfile(
        profile: buildProfile(
          name: '',
          profileImage: 'https://example.com/photo.jpg',
          instruments: const ['바이올린'],
        ),
      );
      expect(status, isA<CategoryStatusPartial>());
    });

    test('profile null → empty', () {
      final status = CategoryStatusCalculator.myProfile(profile: null);
      expect(status, isA<CategoryStatusEmpty>());
    });
  });

  group('CategoryStatusCalculator.policyNotifications (정책·알림·지원 묶음)', () {
    test('항상 neutral (기본값) — spec §11.1 선택적 설정', () {
      final status = CategoryStatusCalculator.policyNotifications();
      expect(status, isA<CategoryStatusNeutral>());
    });
  });

  group('CategoryStatus sealed type', () {
    test('partial label getter — N/M 항목 포맷', () {
      const partial = CategoryStatusPartial(filled: 2, total: 3);
      expect(partial.label, '2/3 항목');
    });

    test('neutral default label is 기본값', () {
      final status = CategoryStatusCalculator.policyNotifications();
      final neutral = status as CategoryStatusNeutral;
      expect(neutral.label, '기본값');
    });
  });
}
