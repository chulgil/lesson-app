# 프로필 마스터 스펙

> 마지막 업데이트: 2026-04-16
> 구현 상태: ✅ 구현 완료 (10x Vision 진행 중)
> 관련 코드: `features/profile/`

---

## 1. 개요

선생님 프로필 관리, 확장 프로필(경력/자격/학력), 초대 시스템, 리뷰, 수강권 입금 상태 화면 제공.

**핵심 설계 원칙 (2026-04-16 10x Vision)**:
- 24개 메뉴 탐색 압박 해소 → **자주 쓰는 3개 바로가기 카드** 상단 배치
- 팔로워 수 → **입금 확인 대기 통계**로 교체 (선생님 실용성)
- 프로필 미리보기를 **상단 CTA**로 승격
- **프로필 완성도 게이지** 추가 (0~100%) — 신규 선생님 온보딩 독려
- 섹션 순서: 자주 쓰는 것 먼저 (수강권·입금 → 레슨 운영 → 내 소개)

---

## 2. 화면 구조

### 2.1 선생님 프로필 탭 (TO-BE)

**순서**:

| 순서 | 섹션 | 설명 |
|:---:|------|------|
| 1 | 프로필 헤더 | 이름, 악기, 소개 |
| 2 | **⭐ 프로필 미리보기 CTA** | [🎭 내 프로필 미리보기 →] 버튼 (최상단) |
| 3 | **⭐ 통계 (학생·레슨·입금 확인 대기)** | 팔로워 → 입금 확인 대기로 교체 |
| 4 | **⭐ 프로필 완성도 게이지** | 0~100%, 다음 단계 안내 |
| 5 | **⭐ 자주 쓰는 설정 (3개 카드)** | 가용시간 · 입금 확인 대기 · 수강권 템플릿 |
| 6 | 💳 수강권·입금 | (상단 이동) |
| 7 | 🎵 레슨 운영 | |
| 8 | 📝 내 소개 | |
| 9 | 👥 소셜 | |
| 10 | ⚙️ 설정 | |
| 11 | 🛟 지원·계정 | |

### 2.2 프로필 완성도 게이지 (신규)

**목적**: 신규 선생님이 학생을 초대하기 전에 필수 프로필을 완성하도록 유도.

**완성도 계산 (100%)**:

| 항목 | 가중치 | 기준 |
|------|:------:|------|
| 프로필 사진 | 20% | 업로드됨 |
| 자기소개 | 20% | 20자 이상 |
| 악기 | 15% | 1개 이상 |
| 가용시간 설정 | 15% | 주간 스케줄 1개 이상 |
| 수강권 템플릿 | 10% | 1개 이상 |
| 입금 계좌 | 10% | 등록됨 |
| 경력·학력 | 10% | 1개 이상 |

**UI**:
```
프로필 완성도   60%
▓▓▓▓▓▓░░░░░░░░░░
다음: 가용시간을 설정해보세요 →
```

**표시 조건**:
- 100% 미만일 때만 표시
- 100% 달성 시 축하 메시지 후 다음 세션부터 숨김

### 2.3 자주 쓰는 설정 카드 (3개)

**고정 3개**:
1. **가용시간** → TeacherAvailabilityScreen
2. **수강권 입금 상태** → Subscription status views
3. **수강권 템플릿** → ProposalSettingsScreen or SubscriptionTemplateListScreen

**카드 스타일**: 정사각형 3분할, 아이콘 + 라벨 + 현재 값 (있으면)

### 2.4 통계 (재정의)

**AS-IS**: 학생 수 · 이번달 레슨 · 팔로워
**TO-BE**: 학생 수 · 이번달 레슨 · **입금 확인 대기** (N건)

입금 확인 대기 0건일 때: "0건 ✓"

---

## 3. 기존 화면 (유지)

- **ProfilePreviewScreen**: 공개 프로필 미리보기 (학생 뷰)
- **BasicInfoEditScreen**: 기본 정보 편집
- **ExtendedProfileScreen**: 확장 프로필 (경력·자격·학력)
- **BankAccountEditScreen**: 계좌 관리
- **Subscription status views**: 수강권 입금 상태 확인 (독립 결제 기능 아님)
- **TipTemplateManagementScreen**: 피드백 템플릿
- **LessonTimeSettingsScreen**: 레슨 시간 설정
- **TeacherAvailabilityScreen**: 가용시간 관리

---

## 4. 코드 위치

| 레이어 | 파일 | 비고 |
|--------|------|------|
| 엔티티 | `features/profile/domain/entities/` (12개: invite, review, teacher, teacher_profile 등) | |
| Repository 인터페이스 | `features/profile/domain/repositories/` (3개: teacher_profile, teacher, invite) | Mock 구현 포함 |
| Remote 구현체 | `features/onboarding/data/repositories/remote_teacher_profile_repository.dart` | cross-domain 재사용 |
| Remote 구현체 | `features/invite/data/repositories/remote_invite_repository.dart` | cross-domain 재사용 |
| Provider | `features/profile/presentation/providers/` (invite, profile, extended_profile 등 9개) | |
| 화면 | `features/profile/presentation/screens/` (15개) | |
| 위젯 | `features/profile/presentation/widgets/` | |

> **구조 참고**: Remote Repository가 `onboarding/`, `invite/` 도메인에 위치하는 것은 cross-domain 재사용 패턴. profile 도메인 내에 별도 data/ 계층을 두지 않는 것은 의도적 설계.

---

## 5. 구현 현황

| 기능 | 상태 | 비고 |
|------|:----:|------|
| 기본 섹션 구조 | 완료 | 2026-03 |
| BasicInfoEdit / ExtendedProfile | 완료 | |
| BankAccountEdit / OutstandingPayments | 완료 | 2026-03 |
| ProfilePreviewScreen | 완료 | 2026-03 |
| TipTemplate / LessonTime | 완료 | |
| **⭐ 프로필 완성도 게이지** | **진행 중** | 2026-04-16 |
| **⭐ 자주 쓰는 설정 카드** | **진행 중** | 2026-04-16 |
| **⭐ 통계 미수금 교체** | **진행 중** | 2026-04-16 |
| **⭐ 미리보기 상단 CTA** | **진행 중** | 2026-04-16 |
| **⭐ 섹션 순서 재정렬** | **진행 중** | 2026-04-16 |

---

## 6. 관련 마스터 스펙

- 초대: [user_master.md §3](../user/user_master.md)
- 리뷰: [user_master.md §6](../user/user_master.md)
- UX 원칙: [ux_guidelines.md](../design/ux_guidelines.md)

---

## 7. 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-04-16 | 10x Vision UX 개선 — 완성도 게이지, 바로가기 카드, 통계 재정의, 섹션 순서 변경 |
| 2026-04-15 | 계좌 관리, 미수금, 미리보기 화면 추가 |
| 2026-03-12 | 초기 스펙 작성 |
