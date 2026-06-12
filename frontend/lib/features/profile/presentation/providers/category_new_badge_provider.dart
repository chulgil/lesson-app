// W6 Task 6.2 — 5묶음 카테고리 NEW 배지 영속 provider.
//
// spec §10.2: 새 카테고리 카드에 7일간 NEW 점 표시.
//   - 최초 노출 시점 (`markCategoryIntroduced`) 기준 7일 윈도우
//   - 한 번 진입 시 해당 카드만 dismiss (`markEntered`)
//   - 7일 경과 시 자동 dismiss
//
// Directive: NEW 배지 키는 한글 라벨이 아닌 영문 enum 식별자 사용 — i18n 변경에도 안전
// Constraint: introducedAt 은 멱등 — 이미 기록되어 있으면 재호출 무시
// Constraint: shouldShowNew 는 `now` 를 파라미터로 받아 pure → 테스트 결정성 보장

import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/durations.dart';

part 'category_new_badge_provider.g.dart';

const _kBoxName = 'category_new_badge_state';
const _kIntroducedSuffix = ':introducedAt';
const _kEnteredSuffix = ':entered';

/// ProfileTab 5묶음 카테고리 식별자 — NEW 배지 영속 키.
///
/// 한글 라벨 (`AppStrings.category…`) 대신 영문 enum 을 키로 사용하여,
/// 라벨 변경/번역이 발생해도 NEW 배지 상태가 유지된다.
enum ProfileCategoryId {
  operatingHours,
  lessonStyle,
  subscriptionBilling,
  myProfile,
  policyNotifications,
}

/// 카테고리별 NEW 배지 상태 — pure value object.
///
/// [shouldShowNew] 는 `now` 를 파라미터로 받아 clock 의존 없음.
class CategoryNewBadgeState {
  final Map<ProfileCategoryId, CategoryNewBadgeEntry> entries;

  const CategoryNewBadgeState({required this.entries});

  /// 지정 카테고리의 NEW 배지 표시 여부.
  ///
  /// 다음 모두 참이어야 표시:
  ///   1. `introducedAt` 기록 존재
  ///   2. `entered == false`
  ///   3. `now - introducedAt < kCategoryNewBadgeWindow`
  bool shouldShowNew(ProfileCategoryId id, DateTime now) {
    final entry = entries[id];
    if (entry == null) return false;
    if (entry.entered) return false;
    final introducedAt = entry.introducedAt;
    if (introducedAt == null) return false;
    return now.difference(introducedAt) < kCategoryNewBadgeWindow;
  }
}

/// 단일 카테고리 NEW 배지 상태.
class CategoryNewBadgeEntry {
  final DateTime? introducedAt;
  final bool entered;

  const CategoryNewBadgeEntry({this.introducedAt, this.entered = false});
}

/// W6 마이그레이션 NEW 배지 영속 provider.
///
/// Hive box (`category_new_badge_state`) 에 카테고리별 introducedAt /
/// entered flag 를 ISO 문자열 / boolean 으로 저장.
///
/// keepAlive — ProfileTab 탭 전환 시 상태 유지.
@Riverpod(keepAlive: true)
class CategoryNewBadge extends _$CategoryNewBadge {
  Box<dynamic>? _box;

  Future<Box<dynamic>> _openBox() async {
    return _box ??= await Hive.openBox(_kBoxName);
  }

  @override
  Future<CategoryNewBadgeState> build() async {
    final box = await _openBox();
    final entries = <ProfileCategoryId, CategoryNewBadgeEntry>{};
    for (final id in ProfileCategoryId.values) {
      final introducedStr = box.get('${id.name}$_kIntroducedSuffix') as String?;
      final entered =
          box.get('${id.name}$_kEnteredSuffix', defaultValue: false) as bool;
      entries[id] = CategoryNewBadgeEntry(
        introducedAt:
            introducedStr == null ? null : DateTime.parse(introducedStr),
        entered: entered,
      );
    }
    return CategoryNewBadgeState(entries: entries);
  }

  /// 카테고리 최초 노출 시점 기록 — 이미 기록되어 있으면 noop (멱등).
  ///
  /// 호출 측은 `await container.read(categoryNewBadgeProvider.future)` 등으로
  /// build() 완료를 보장한 뒤 호출한다. 그래야 `state.requireValue` 가 안전.
  Future<void> markCategoryIntroduced(
    ProfileCategoryId id,
    DateTime now,
  ) async {
    final box = await _openBox();
    final key = '${id.name}$_kIntroducedSuffix';
    if (box.get(key) != null) return;
    await box.put(key, now.toIso8601String());
    _updateEntry(id, introducedAt: now);
  }

  /// 5묶음 카테고리 전체에 markCategoryIntroduced(now) 일괄 호출.
  ///
  /// W6 마이그레이션 overlay 진행/스킵 시 사용 — TeacherMigrationOverlayGate 가
  /// 한 번에 5개 카테고리의 NEW 윈도우를 시작한다. 이미 기록된 카테고리는
  /// markCategoryIntroduced 의 멱등 보장으로 건너뜀.
  Future<void> markAllIntroduced(DateTime now) async {
    for (final id in ProfileCategoryId.values) {
      await markCategoryIntroduced(id, now);
    }
  }

  /// 카테고리 카드 진입 — 즉시 dismiss.
  ///
  /// CategoryCard 의 `onTap` 콜백에서 호출.
  Future<void> markEntered(ProfileCategoryId id) async {
    final box = await _openBox();
    await box.put('${id.name}$_kEnteredSuffix', true);
    _updateEntry(id, entered: true);
  }

  /// State 직접 갱신 — invalidateSelf 회피로 notifier 재생성/캐시 box 손실 방지.
  ///
  /// `state.requireValue` 가 호출 가능한 시점에만 호출 (build 완료 후).
  void _updateEntry(
    ProfileCategoryId id, {
    DateTime? introducedAt,
    bool? entered,
  }) {
    final current = state.requireValue;
    final next = Map<ProfileCategoryId, CategoryNewBadgeEntry>.from(
      current.entries,
    );
    final previous = next[id];
    next[id] = CategoryNewBadgeEntry(
      introducedAt: introducedAt ?? previous?.introducedAt,
      entered: entered ?? previous?.entered ?? false,
    );
    state = AsyncValue.data(CategoryNewBadgeState(entries: next));
  }
}
