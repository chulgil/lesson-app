import '../../domain/entities/subscription_settings.dart';
import '../../domain/repositories/subscription_settings_repository.dart';

/// Mock implementation of SubscriptionSettingsRepository for development.
class MockSubscriptionSettingsRepository
    implements SubscriptionSettingsRepository {
  final Map<String, SubscriptionSettings> _settingsByTeacherId = {};
  final Map<String, SubscriptionSettings> _settingsByOrgId = {};

  MockSubscriptionSettingsRepository() {
    _initMockData();
  }

  void _initMockData() {
    final now = DateTime.now();

    // ═══════════════════════════════════════════════════════════════════
    // 📌 1. 개인 선생님 설정 (기본값)
    // ═══════════════════════════════════════════════════════════════════
    final teacher1Settings = SubscriptionSettings(
      id: 'settings_teacher_1',
      teacherId: 'teacher_1',
      renewalAlertThreshold: 1, // 1회 남았을 때 알림
      renewalAlertDays: 7, // 7일 전 알림
      discountPolicies: const [
        // 10회 이상 구매 시 +1회 무료
        PackageDiscountPolicy(
          minLessons: 10,
          type: DiscountType.bonusLessons,
          value: 1,
          description: '대량 구매 보너스',
        ),
        // 16회 이상 구매 시 +2회 무료
        PackageDiscountPolicy(
          minLessons: 16,
          type: DiscountType.bonusLessons,
          value: 2,
          description: '대량 구매 보너스',
        ),
      ],
      enablePushNotification: true,
      enableBadge: true,
      notifyParent: false,
      createdAt: now,
    );
    _settingsByTeacherId['teacher_1'] = teacher1Settings;

    // ═══════════════════════════════════════════════════════════════════
    // 📌 2. 선생님 2 - 할인 정책 (%)
    // ═══════════════════════════════════════════════════════════════════
    final teacher2Settings = SubscriptionSettings(
      id: 'settings_teacher_2',
      teacherId: 'teacher_2',
      renewalAlertThreshold: 2, // 2회 남았을 때 알림
      renewalAlertDays: 14, // 14일 전 알림
      discountPolicies: const [
        // 8회 이상 구매 시 5% 할인
        PackageDiscountPolicy(
          minLessons: 8,
          type: DiscountType.discount,
          value: 5,
          description: '8회 패키지 할인',
        ),
        // 16회 이상 구매 시 10% 할인
        PackageDiscountPolicy(
          minLessons: 16,
          type: DiscountType.discount,
          value: 10,
          description: '16회 패키지 할인',
        ),
      ],
      enablePushNotification: true,
      enableBadge: true,
      notifyParent: true, // 학부모에게도 알림
      createdAt: now,
    );
    _settingsByTeacherId['teacher_2'] = teacher2Settings;

    // ═══════════════════════════════════════════════════════════════════
    // 📌 3. 학원 설정 - 혼합 정책 (할인 + 보너스)
    // ═══════════════════════════════════════════════════════════════════
    final academy1Settings = SubscriptionSettings(
      id: 'settings_academy_1',
      organizationId: 'academy_1',
      renewalAlertThreshold: 1,
      renewalAlertDays: 7,
      discountPolicies: const [
        // 10회 이상: +1회 보너스
        PackageDiscountPolicy(
          minLessons: 10,
          type: DiscountType.bonusLessons,
          value: 1,
          description: '10회 패키지 보너스',
        ),
        // 20회 이상: +3회 보너스
        PackageDiscountPolicy(
          minLessons: 20,
          type: DiscountType.bonusLessons,
          value: 3,
          description: '20회 패키지 보너스',
        ),
        // 30회 이상: +5회 보너스
        PackageDiscountPolicy(
          minLessons: 30,
          type: DiscountType.bonusLessons,
          value: 5,
          description: '30회 패키지 보너스',
        ),
      ],
      enablePushNotification: true,
      enableBadge: true,
      notifyParent: true,
      createdAt: now,
    );
    _settingsByOrgId['academy_1'] = academy1Settings;

    // ═══════════════════════════════════════════════════════════════════
    // 📌 4. 학원 2 - 정책 없음 (기본값만)
    // ═══════════════════════════════════════════════════════════════════
    final academy2Settings = SubscriptionSettings(
      id: 'settings_academy_2',
      organizationId: 'academy_2',
      renewalAlertThreshold: 1,
      renewalAlertDays: 7,
      discountPolicies: const [], // 정책 없음
      enablePushNotification: true,
      enableBadge: true,
      notifyParent: false,
      createdAt: now,
    );
    _settingsByOrgId['academy_2'] = academy2Settings;
  }

  @override
  Future<SubscriptionSettings?> getByTeacherId(String teacherId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _settingsByTeacherId[teacherId];
  }

  @override
  Future<SubscriptionSettings?> getByOrganizationId(
      String organizationId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _settingsByOrgId[organizationId];
  }

  @override
  Future<SubscriptionSettings> create(SubscriptionSettings settings) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (settings.teacherId != null) {
      _settingsByTeacherId[settings.teacherId!] = settings;
    }
    if (settings.organizationId != null) {
      _settingsByOrgId[settings.organizationId!] = settings;
    }
    return settings;
  }

  @override
  Future<SubscriptionSettings> update(SubscriptionSettings settings) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (settings.teacherId != null) {
      _settingsByTeacherId[settings.teacherId!] = settings;
    }
    if (settings.organizationId != null) {
      _settingsByOrgId[settings.organizationId!] = settings;
    }
    return settings;
  }

  @override
  Future<SubscriptionSettings> getOrCreateForTeacher(String teacherId) async {
    var settings = await getByTeacherId(teacherId);
    if (settings == null) {
      settings = SubscriptionSettings.defaultForTeacher(teacherId);
      await create(settings);
    }
    return settings;
  }
}
