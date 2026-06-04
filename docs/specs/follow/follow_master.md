# 팔로우 시스템 Master Spec

> 구현 상태: Phase 1, 3 완료 / Phase 2 — FollowButton + FollowNotifier 구현 완료 (2026-06-04), 프로필/검색 화면 통합 미완료
> Last updated: 2026-05-02

## 1. 개요

팔로우 시스템은 **소식 구독** 전용 기능이다. 레슨 관계(수강권 기반)와 완전히 분리되어, 누구나 승인 없이 선생님이나 학원을 팔로우하여 공연/이벤트/공지 등의 소식을 받아볼 수 있다.

인스타그램의 일방향 팔로우 모델과 같다. 팔로우한다고 레슨 관계가 생기는 것은 아니며, 소식 알림 수신 여부만 결정한다.

### 설계 원칙

- **레슨 관계와 분리**: 팔로우는 소식 구독 용도. 수강권 기반 관계와 독립적으로 동작
- **승인 불필요**: 일방향 팔로우 (Instagram 스타일)
- **알림 제어**: 팔로우별 알림 on/off 가능

### 참조 문서

- [수강권 중심 관계 모델](../lesson/invite/subscription_based_relationship.md)

---

## 2. 핵심 기능

### 2.1 팔로우/언팔로우

| 기능 | 설명 |
|------|------|
| 팔로우 | 선생님 또는 학원을 팔로우 (승인 불필요, 즉시 반영) |
| 언팔로우 | 팔로우 해제 |
| 중복 방지 | 이미 팔로우 중이면 기존 Follow 반환 |

### 2.2 팔로우 대상 유형 (FollowTargetType)

| 값 | 표시명 | 설명 |
|----|--------|------|
| `teacher` | 선생님 | 개별 선생님 소식 구독 |
| `academy` | 학원 | 학원 소식/이벤트 구독 |

### 2.3 알림 설정

- 팔로우별 `notificationEnabled` 플래그 (기본값: `true`)
- 알림 ON: 팔로우 대상의 소식/공연/이벤트 알림 수신
- 알림 OFF: 팔로우는 유지하되 알림만 차단

### 2.4 조회 기능

| 기능 | 설명 |
|------|------|
| 내 팔로잉 목록 | 내가 팔로우한 선생님/학원 전체 |
| 타입별 필터 | 선생님만, 학원만 필터링 |
| 팔로워 목록 | 특정 선생님/학원의 팔로워 |
| 팔로우 여부 확인 | 특정 대상 팔로우 중인지 확인 |
| 팔로워/팔로잉 수 | 카운트 조회 |

---

## 3. 화면/UI 구조

### 3.1 현재 상태

팔로우 전용 화면 2개 구현 완료 (2026-03):
- `FollowFeedScreen` — 팔로우 피드
- `FollowListScreen` — 팔로잉 목록

팔로우 기능은 아래 화면들에서도 사용된다:
- **선생님 프로필 화면**: 팔로우/언팔로우 버튼, 팔로워 수 표시
- **학원 프로필 화면**: 팔로우/언팔로우 버튼
- **선생님 검색 결과**: 팔로우 상태 표시

### 3.2 화면 설계

#### FollowListScreen (팔로우 목록)

팔로우 중인 선생님/학원 목록을 표시하는 화면. 프로필 탭 또는 설정에서 진입한다.

```
/profile/following
┌──────────────────────────────────┐
│  <- 팔로잉               [전체|선생님|학원] │
├──────────────────────────────────┤
│  ┌──────────────────────────────┐│
│  │ [👤] 김선생님                    ││
│  │     바이올린 · 팔로워 128명       ││
│  │                    [팔로잉 ✓]  ││
│  └──────────────────────────────┘│
│  ┌──────────────────────────────┐│
│  │ [👤] 박선생님                    ││
│  │     첼로 · 팔로워 56명           ││
│  │                    [팔로잉 ✓]  ││
│  └──────────────────────────────┘│
│  ┌──────────────────────────────┐│
│  │ [🏫] 음악나라학원                 ││
│  │     종합음악 · 팔로워 342명       ││
│  │                    [팔로잉 ✓]  ││
│  └──────────────────────────────┘│
└──────────────────────────────────┘
```

- **상단 탭**: 전체 / 선생님 / 학원 필터 (FollowTargetType 기반)
- **카드 탭**: 선생님/학원 프로필 화면으로 이동
- **빈 상태**: "아직 팔로우한 선생님이 없습니다" + 선생님 검색 버튼

#### FollowFeedScreen (팔로잉 소식 피드)

팔로우 중인 선생님/학원의 소식을 시간순으로 표시하는 피드 화면.

```
/follow/feed
┌──────────────────────────────────┐
│  <- 소식                          │
├──────────────────────────────────┤
│  ┌──────────────────────────────┐│
│  │ [👤] 김선생님              3시간 전 ││
│  │ 🎵 발표회 안내                    ││
│  │ "3월 정기 발표회를 진행합니다.     ││
│  │  일시: 3/15 토 14:00..."         ││
│  │                    [자세히 보기]  ││
│  └──────────────────────────────┘│
│  ┌──────────────────────────────┐│
│  │ [🏫] 음악나라학원           1일 전 ││
│  │ 🎉 이벤트                        ││
│  │ "신규 등록 할인 이벤트 진행중..."   ││
│  └──────────────────────────────┘│
└──────────────────────────────────┘
```

- **피드 정렬**: 최신순 (createdAt DESC)
- **피드 유형**: 공연/발표회, 이벤트, 공지사항
- **빈 상태**: "팔로우한 선생님의 소식이 표시됩니다"

#### 재사용 위젯

| 위젯 | 용도 | 위치 |
|------|------|------|
| `FollowButton` | 팔로우/언팔로우 토글 버튼 | 선생님 프로필, 검색 결과, FollowCard |
| `FollowCard` | 팔로우 목록의 선생님/학원 카드 | FollowListScreen |
| `FollowFeedItem` | 피드 개별 소식 항목 | FollowFeedScreen |

**FollowButton 동작**:
- 미팔로우 상태: "팔로우" (outlined 스타일) → 탭 시 팔로우 + filled 스타일로 전환
- 팔로우 상태: "팔로잉 ✓" (filled 스타일) → 탭 시 "언팔로우 하시겠습니까?" 확인 다이얼로그
- 로딩 중: 버튼 비활성화 + CircularProgressIndicator

---

## 4. 데이터 모델

### Follow 엔티티

```
@HiveType(typeId: 93)
Follow
├── id: String                        // 고유 ID
├── followerId: String                // 팔로워 사용자 ID (학생, 학부모 등)
├── followingId: String               // 팔로우 대상 ID (선생님 또는 학원)
├── targetType: FollowTargetType      // 대상 유형 (teacher / academy)
├── notificationEnabled: bool         // 알림 활성화 (기본 true)
└── createdAt: DateTime               // 팔로우 시점
```

### FollowTargetType 열거형

```
@HiveType(typeId: 94)
enum FollowTargetType { teacher, academy }
```

### Repository 인터페이스

| 메서드 | 반환 | 설명 |
|--------|------|------|
| `getById(id)` | `Follow?` | ID로 조회 |
| `getFollow(followerId, followingId)` | `Follow?` | 특정 팔로우 조회 |
| `isFollowing(followerId, followingId)` | `bool` | 팔로우 여부 확인 |
| `getByFollower(followerId)` | `List<Follow>` | 내 팔로잉 목록 |
| `getFollowers(followingId)` | `List<Follow>` | 팔로워 목록 |
| `getByFollowerAndType(followerId, type)` | `List<Follow>` | 타입별 필터 |
| `getFollowerCount(followingId)` | `int` | 팔로워 수 |
| `getFollowingCount(followerId)` | `int` | 팔로잉 수 |
| `follow(...)` | `Follow` | 팔로우 |
| `unfollow(followerId, followingId)` | `void` | 언팔로우 |
| `updateNotification(id, enabled)` | `Follow` | 알림 설정 변경 |
| `delete(id)` | `void` | 삭제 |

### Provider 구성

| Provider | 용도 |
|----------|------|
| `followRepositoryProvider` | Repository 인스턴스 (keepAlive, Mock/Remote 전환) |
| `followByIdProvider` | ID로 팔로우 조회 |
| `isFollowingProvider` | 팔로우 여부 확인 |
| `userFollowingProvider` | 사용자 팔로잉 목록 |
| `targetFollowersProvider` | 대상의 팔로워 목록 |
| `userFollowingByTypeProvider` | 타입별 팔로잉 |
| `followerCountProvider` | 팔로워 수 |
| `followingCountProvider` | 팔로잉 수 |
| `followedTeachersProvider` | 팔로우한 선생님 목록 |
| `followedAcademiesProvider` | 팔로우한 학원 목록 |

### Provider 설계 (Claude 구현 가이드)

아래는 주요 Provider의 코드 수준 설계이다. Phase 3 화면 구현 시 이 패턴을 따른다.

```dart
// 사용자의 팔로잉 목록 (FollowListScreen용)
@riverpod
Future<List<Follow>> followingList(Ref ref) async {
  final repo = ref.read(followRepositoryProvider);
  final userId = ref.read(currentUserIdProvider);
  return repo.getByFollower(userId);
}

// 팔로우/언팔로우 액션 (FollowButton에서 사용)
@riverpod
class FollowNotifier extends _$FollowNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> follow(String teacherId, {FollowTargetType type = FollowTargetType.teacher}) async {
    final repo = ref.read(followRepositoryProvider);
    final userId = ref.read(currentUserIdProvider);
    await repo.follow(
      followerId: userId,
      followingId: teacherId,
      targetType: type,
    );
    // 관련 Provider 갱신
    ref.invalidate(followingListProvider);
    ref.invalidate(isFollowingProvider(teacherId));
    ref.invalidate(followerCountProvider(teacherId));
  }

  Future<void> unfollow(String teacherId) async {
    final repo = ref.read(followRepositoryProvider);
    final userId = ref.read(currentUserIdProvider);
    await repo.unfollow(userId, teacherId);
    // 관련 Provider 갱신
    ref.invalidate(followingListProvider);
    ref.invalidate(isFollowingProvider(teacherId));
    ref.invalidate(followerCountProvider(teacherId));
  }
}

// 팔로우 여부 확인 (FollowButton 상태 표시용)
@riverpod
Future<bool> isFollowing(Ref ref, String targetId) async {
  final repo = ref.read(followRepositoryProvider);
  final userId = ref.read(currentUserIdProvider);
  return repo.isFollowing(userId, targetId);
}

// 타입별 팔로잉 필터 (FollowListScreen 탭 전환용)
@riverpod
Future<List<Follow>> followingByType(Ref ref, FollowTargetType type) async {
  final repo = ref.read(followRepositoryProvider);
  final userId = ref.read(currentUserIdProvider);
  return repo.getByFollowerAndType(userId, type);
}
```

> **참고**: `follow()`/`unfollow()` 호출 시 반드시 `isFollowingProvider`, `followerCountProvider`, `followingListProvider`를 invalidate하여 UI가 즉시 반영되도록 한다.

### 백엔드 API (RemoteFollowRepository)

| 메서드 | API 엔드포인트 |
|--------|---------------|
| 팔로우 | `POST /follows` (`following_id`, `target_type`) |
| 언팔로우 | `DELETE /follows/{id}` |
| 알림 설정 | `PATCH /follows/{id}` (`notification_enabled`) |
| 목록 조회 | `GET /follows` (클라이언트 필터링) |

---

## 5. 구현 현황

| 레이어 | 파일 | 상태 |
|--------|------|:----:|
| Entity | `follow/domain/entities/follow.dart` | 완료 |
| Entity | `follow/domain/entities/follow_target_type.dart` | 완료 |
| Repository Interface | `follow/domain/repositories/follow_repository.dart` | 완료 |
| Mock Repository | `follow/data/repositories/mock_follow_repository.dart` | 완료 |
| Remote Repository | `follow/data/repositories/remote_follow_repository.dart` | 완료 |
| Providers | `follow/presentation/providers/follow_providers.dart` | 완료 |
| FollowFeedScreen | `follow/presentation/screens/follow_feed_screen.dart` | 완료 |
| FollowListScreen | `follow/presentation/screens/follow_list_screen.dart` | 완료 |

### Mock 데이터

- `student_1` -> `teacher_1`, `teacher_2`, `academy_1` 팔로우
- `student_2` -> `teacher_1` 팔로우
- `parent_1` -> `teacher_1` 팔로우
- `student_3` -> `teacher_1` 팔로우 (알림 OFF)

---

## 6. 구현 우선순위

| Phase | 범위 | 상태 |
|-------|------|:----:|
| **Phase 1 (MVP)** | Follow 엔티티, Repository (Mock/Remote), 기본 Provider | ✅ 완료 |
| **Phase 2** | FollowButton 위젯 + FollowNotifier, 선생님 프로필/검색에서 팔로우 기능 통합 | ⚠️ 부분 |
| **Phase 3** | FollowListScreen, FollowFeedScreen, FollowCard, 피드 시스템 | ✅ 완료 (2026-03) |

**Phase 2 상태 (2026-06-04)**: `FollowButton` 위젯 (`features/follow/presentation/widgets/follow_button.dart`) 와 `FollowNotifier` (`features/follow/presentation/providers/follow_providers.dart`) 구현 완료 — 스펙 §4 Provider 설계의 stateful `@riverpod class` 패턴 + 관련 read-side provider 자동 invalidate. 선생님 프로필/검색 화면에 진입점 wiring 은 후속 작업.

---

## 7. 관련 스펙

| 스펙 | 관계 |
|------|------|
| [수강권 기반 관계 모델](../lesson/invite/subscription_based_relationship.md) | 팔로우와 레슨 관계 분리 설계 |
| [알림 시스템](../notification/notification_master.md) | 팔로우 알림 (NEW_FOLLOWER, TEACHER_NEWS 등) |

---

## 8. 코드 반영 추가 (2026-06-03)

> 코드에 구현되어 있으나 §4 데이터 모델에 누락되어 있던 피드 게시물(TeacherPost) 모델을 단방향(코드→스펙)으로 반영. §3.2 FollowFeedScreen이 표시하는 소식의 실제 데이터 모델이다.

> 소스: `domain/entities/teacher_post.dart`, `domain/repositories/post_repository.dart`, `data/repositories/{mock,remote}_post_repository.dart`, `presentation/providers/post_providers.dart`, `presentation/extensions/teacher_post_visuals.dart`

### 8.1 PostType enum (코드 반영 2026-06-03)

| 값 | 의미 |
|----|------|
| `performance` | 공연/발표회 안내 |
| `event` | 이벤트 (할인/캠페인 등) |
| `notice` | 일반 공지 |

### 8.2 TeacherPost 엔티티 (코드 반영 2026-06-03)

선생님 또는 학원이 작성한 게시물/공지. FollowFeedScreen에서 팔로워에게 표시.

| 필드 | 타입 | 설명 |
|------|------|------|
| id | String | 고유 ID |
| authorId | String | 작성자 ID (선생님 또는 학원) |
| authorName | String | 작성자 표시명 |
| postType | PostType | 게시물 유형 |
| title | String | 제목 |
| content | String | 본문 |
| createdAt | DateTime | 작성 시점 |

### 8.3 PostRepository (코드 반영 2026-06-03)

| 메서드 | 반환 | 설명 |
|--------|------|------|
| `getByAuthor(authorId)` | `List<TeacherPost>` | 특정 작성자의 게시물 |
| `getByAuthors(authorIds)` | `List<TeacherPost>` | 다수 작성자 게시물 (피드 집계용) |

Mock/Remote 구현 존재.

### 8.4 Provider (코드 반영 2026-06-03)

| Provider | 용도 |
|----------|------|
| `postRepositoryProvider` | Repository 인스턴스 (keepAlive, Mock/Remote 전환) |
| `followFeedProvider(followerId)` | 팔로우한 작성자들의 게시물을 집계해 최신순 피드 반환 |

`followFeedProvider`는 `followRepository.getByFollower(followerId)`로 팔로잉 ID를 모은 뒤 `postRepository.getByAuthors(ids)`로 게시물을 집계한다.

---

## 9. 변경 이력

| 날짜 | 변경 내용 |
|------|----------|
| 2026-03-06 | 코드 기반 역설계로 초기 스펙 작성 |
| 2026-03-07 | 화면 설계 상세(FollowListScreen, FollowFeedScreen, 위젯), Provider 코드 설계, 구현 우선순위 섹션 추가 |
| 2026-06-03 | 코드 반영: TeacherPost/PostType/PostRepository/followFeedProvider (§8) |
