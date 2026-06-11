// W2 Task 2.2 — 5묶음 카테고리 진행 상태 provider.
// spec §11.1: 카테고리 카드 라벨 규칙
// spec §5.3: 5묶음 엔티티 매핑
// glossary §14: 카테고리 표
//
// Directive: 5묶음 진행 라벨 데이터 소스 = FE entity 직접 계산 (O3 결정)
// Constraint: pure function — clock 의존 없음, 테스트 결정성

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/auth_facade.dart' show currentUserIdProvider;
import '../../../onboarding/onboarding_facade.dart'
    show currentTeacherProfileProvider;
import '../../../schedule/domain/entities/teacher_availability.dart';
import '../../../schedule/presentation/providers/teacher_availability_providers.dart';
import '../../../settings/settings_facade.dart' show teacherSettingsProvider;
import '../../domain/entities/teacher_profile.dart';
import '../../domain/entities/teacher_settings.dart';

part 'category_status_provider.g.dart';

// Hint key constants — extension 이 AppStrings 로 매핑한다.
// flutter-architecture: domain/data 에서 AppStrings 직접 의존 금지.
const String categoryHintKeyBreakTimeMissing = 'breakTimeMissing';
const String categoryHintKeyBankAccountMissing = 'bankAccountMissing';
const String categoryHintKeyPriceTableMissing = 'priceTableMissing';

/// 5묶음 카테고리 진행 상태 (sealed).
///
/// - [CategoryStatusComplete]: 설정완료 ✓
/// - [CategoryStatusPartial]: 부분 입력 ("N/M 항목" 등)
/// - [CategoryStatusEmpty]: 미설정 ⚠ ●
/// - [CategoryStatusNeutral]: 정책·알림처럼 선택적 설정 — "기본값" 표시
sealed class CategoryStatus {
  const CategoryStatus();
}

/// 설정완료.
class CategoryStatusComplete extends CategoryStatus {
  const CategoryStatusComplete();
}

/// 부분 입력. [filled]/[total] 항목 또는 단일 [hintKey] 라벨.
///
/// Display label 매핑은 `CategoryStatusVisuals` (presentation extension) 에서 수행.
class CategoryStatusPartial extends CategoryStatus {
  /// Number of filled items (for "N/M 항목" label).
  final int filled;

  /// Total number of items (for "N/M 항목" label).
  final int total;

  /// Optional hint key — extension 이 AppStrings 로 매핑.
  ///
  /// 사용 가능 key: `'breakTimeMissing'`, `'bankAccountMissing'`,
  /// `'priceTableMissing'`. null 이면 "N/M 항목" 라벨로 표시.
  final String? hintKey;

  const CategoryStatusPartial({
    required this.filled,
    required this.total,
    this.hintKey,
  });
}

/// 미설정.
class CategoryStatusEmpty extends CategoryStatus {
  /// Optional hint key — extension 이 AppStrings 로 매핑.
  final String? hintKey;

  const CategoryStatusEmpty({this.hintKey});
}

/// 중립 상태 — "기본값" 같은 선택적 설정용. 노란 점/체크 표시 없음.
///
/// [labelKey] 는 미래 확장 용도 — 현재는 null 만 사용 (extension 이 "기본값" 매핑).
class CategoryStatusNeutral extends CategoryStatus {
  final String? labelKey;

  const CategoryStatusNeutral({this.labelKey});
}

/// Pure calculator — clock 의존 없음, Riverpod 의존 없음.
///
/// 각 메서드는 spec §11.1 라벨 규칙을 결정한다. 실제 표시 라벨
/// (이모지/색상) 은 위젯 레이어 (`CategoryCard`, Task 2.3) 에서 매핑.
class CategoryStatusCalculator {
  CategoryStatusCalculator._();

  /// 🕐 운영시간 묶음.
  ///
  /// Complete: weeklySchedules 1개 이상 + breakTimeBetweenLessons > 0
  /// Partial : weeklySchedules 있고 breakTime == 0
  /// Empty   : weeklySchedules 비어있거나 availability null
  static CategoryStatus operatingHours({
    required TeacherAvailability? availability,
  }) {
    if (availability == null) {
      return const CategoryStatusEmpty();
    }
    final hasSlot = availability.weeklySchedules.isNotEmpty;
    if (!hasSlot) {
      return const CategoryStatusEmpty();
    }
    if (availability.breakTimeBetweenLessons <= 0) {
      return const CategoryStatusPartial(
        filled: 1,
        total: 2,
        hintKey: categoryHintKeyBreakTimeMissing,
      );
    }
    return const CategoryStatusComplete();
  }

  /// 🎓 수업방식 묶음.
  ///
  /// 3 항목: lessonDurationMinutes, minBookingHours, bookingGuidanceMessage.
  /// 앞 두 항목은 기본값이 있으므로 항상 "입력됨" 으로 카운트한다.
  /// 가이드 메시지만 사용자 입력 여부를 판정.
  ///
  /// Complete: 3/3 항목
  /// Partial : 1~2/3 항목 ("N/3 항목")
  /// Empty   : settings null
  static CategoryStatus lessonStyle({required TeacherSettings? settings}) {
    if (settings == null) {
      return const CategoryStatusEmpty();
    }
    var filled = 0;
    // lessonDurationMinutes 는 entity constructor 기본 50 → 항상 "입력".
    if (settings.lessonDurationMinutes > 0) filled++;
    // minBookingHours 는 기본 24 → 항상 "입력".
    if (settings.minBookingHours > 0) filled++;
    final guidance = settings.bookingGuidanceMessage?.trim();
    if (guidance != null && guidance.isNotEmpty) filled++;
    const total = 3;
    if (filled >= total) {
      return const CategoryStatusComplete();
    }
    return CategoryStatusPartial(filled: filled, total: total);
  }

  /// 💰 수강권·정산 묶음.
  ///
  /// Complete: 가격표 (lessonPriceTable 비어있지 않음) + 계좌 1개 이상
  /// Partial : 가격표만 또는 계좌만
  /// Empty   : 둘 다 없음
  static CategoryStatus subscriptionBilling({
    required TeacherSettings? settings,
    required List<BankAccount> bankAccounts,
  }) {
    final priceTable = settings?.lessonPriceTable;
    final hasPriceTable = priceTable != null && priceTable.isNotEmpty;
    final hasBankAccount = bankAccounts.isNotEmpty;
    if (hasPriceTable && hasBankAccount) {
      return const CategoryStatusComplete();
    }
    if (hasPriceTable && !hasBankAccount) {
      return const CategoryStatusPartial(
        filled: 1,
        total: 2,
        hintKey: categoryHintKeyBankAccountMissing,
      );
    }
    if (!hasPriceTable && hasBankAccount) {
      return const CategoryStatusPartial(
        filled: 1,
        total: 2,
        hintKey: categoryHintKeyPriceTableMissing,
      );
    }
    return const CategoryStatusEmpty();
  }

  /// 👤 내 프로필 묶음.
  ///
  /// 3 항목: name, profileImage, instruments.
  ///
  /// Complete: 3/3
  /// Partial : 1~2/3 ("N/3 항목")
  /// Empty   : profile null 또는 0/3
  static CategoryStatus myProfile({required TeacherProfile? profile}) {
    if (profile == null) {
      return const CategoryStatusEmpty();
    }
    var filled = 0;
    if (profile.name.trim().isNotEmpty) filled++;
    final image = profile.profileImage?.trim();
    if (image != null && image.isNotEmpty) filled++;
    if (profile.instruments.isNotEmpty) filled++;
    const total = 3;
    if (filled == 0) {
      return const CategoryStatusEmpty();
    }
    if (filled >= total) {
      return const CategoryStatusComplete();
    }
    return CategoryStatusPartial(filled: filled, total: total);
  }

  /// ⚙️ 정책·알림·지원 묶음.
  ///
  /// spec §11.1 — 선택적 설정이므로 항상 "기본값" 표시.
  static CategoryStatus policyNotifications() {
    return const CategoryStatusNeutral();
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider wrappers — TaskCard UI (Task 2.3) 데이터 소스.
// ---------------------------------------------------------------------------

/// 🕐 운영시간 묶음 진행 상태.
@Riverpod(keepAlive: true)
CategoryStatus operatingHoursStatus(OperatingHoursStatusRef ref) {
  final teacherId = ref.watch(currentUserIdProvider);
  final availabilityAsync = ref.watch(teacherAvailabilityProvider(teacherId));
  return CategoryStatusCalculator.operatingHours(
    availability: availabilityAsync.valueOrNull,
  );
}

/// 🎓 수업방식 묶음 진행 상태.
@Riverpod(keepAlive: true)
CategoryStatus lessonStyleStatus(LessonStyleStatusRef ref) {
  final settingsAsync = ref.watch(teacherSettingsProvider);
  return CategoryStatusCalculator.lessonStyle(
    settings: settingsAsync.valueOrNull,
  );
}

/// 💰 수강권·정산 묶음 진행 상태.
@Riverpod(keepAlive: true)
CategoryStatus subscriptionBillingStatus(SubscriptionBillingStatusRef ref) {
  final settingsAsync = ref.watch(teacherSettingsProvider);
  final profile = ref.watch(currentTeacherProfileProvider).valueOrNull;
  return CategoryStatusCalculator.subscriptionBilling(
    settings: settingsAsync.valueOrNull,
    bankAccounts: profile?.bankAccounts ?? const [],
  );
}

/// 👤 내 프로필 묶음 진행 상태.
@Riverpod(keepAlive: true)
CategoryStatus myProfileStatus(MyProfileStatusRef ref) {
  final profile = ref.watch(currentTeacherProfileProvider).valueOrNull;
  return CategoryStatusCalculator.myProfile(profile: profile);
}

/// ⚙️ 정책·알림·지원 묶음 진행 상태 — 항상 neutral "기본값".
@Riverpod(keepAlive: true)
CategoryStatus policyNotificationsStatus(PolicyNotificationsStatusRef ref) {
  return CategoryStatusCalculator.policyNotifications();
}
