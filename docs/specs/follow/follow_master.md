# 팔로우 시스템 Master Spec

> Last updated: 2026-03-06

## 1. 개요

팔로우 시스템은 **소식 구독** 전용 기능이다. 레슨 관계(수강권 기반)와 완전히 분리되어, 누구나 승인 없이 선생님이나 학원을 팔로우하여 공연/이벤트/공지 등의 소식을 받아볼 수 있다.

인스타그램의 일방향 팔로우 모델과 같다. 팔로우한다고 레슨 관계가 생기는 것은 아니며, 소식 알림 수신 여부만 결정한다.

### 설계 원칙

- **레슨 관계와 분리**: 팔로우는 소식 구독 용도. 수강권 기반 관계와 독립적으로 동작
- **승인 불필요**: 일방향 팔로우 (Instagram 스타일)
- **알림 제어**: 팔로우별 알림 on/off 가능

### 참조 문서

- [수강권 중심 관계 모델](../invite/subscription_based_relationship.md)

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

현재 팔로우 전용 화면(Screen)은 구현되어 있지 않다. 팔로우 기능은 아래 화면들에서 사용된다:

- **선생님 프로필 화면**: 팔로우/언팔로우 버튼, 팔로워 수 표시
- **학원 프로필 화면**: 팔로우/언팔로우 버튼
- **선생님 검색 결과**: 팔로우 상태 표시

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
| 전용 UI 화면 | - | 미구현 |

### Mock 데이터

- `student_1` -> `teacher_1`, `teacher_2`, `academy_1` 팔로우
- `student_2` -> `teacher_1` 팔로우
- `parent_1` -> `teacher_1` 팔로우
- `student_3` -> `teacher_1` 팔로우 (알림 OFF)

---

## 6. 관련 스펙

| 스펙 | 관계 |
|------|------|
| [수강권 기반 관계 모델](../invite/subscription_based_relationship.md) | 팔로우와 레슨 관계 분리 설계 |
| [알림 시스템](../notification/notification_master.md) | 팔로우 알림 (NEW_FOLLOWER, TEACHER_NEWS 등) |

---

## 7. 변경 이력

| 날짜 | 변경 내용 |
|------|----------|
| 2026-03-06 | 코드 기반 역설계로 초기 스펙 작성 |
