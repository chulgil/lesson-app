# 외부 선생님 등록 시스템 스펙

> 작성일: 2025-12-27
> 최종 수정: 2026-01-24
> 상태: 스펙 확정
> 엔티티 스키마: [teacher.md](../../schema/entities/teacher.md)

> **관련 문서**: [3자 관계 설계](../lesson/three_party_relationship_spec.md) - 학원 소속 선생님 관련

---

## 개요

외부 선생님이 앱에 가입하여 학생을 관리할 수 있는 온보딩 시스템

### 활동 유형

선생님은 다음 유형으로 활동할 수 있습니다:

| 유형 | 설명 | organizationId |
|------|------|----------------|
| **개인 선생님** | 독립적으로 학생 관리 | `null` |
| **학원 소속 선생님** | 학원에 소속되어 활동 | 학원 ID |
| **겸업** | 개인 + 학원 소속 동시 | Context에 따라 다름 |

> **Note**: 학원 소속 가입은 [초대 시스템](../invite/invite_system_v2.md#학원-선생님-초대-시스템) 참조

### 핵심 결정사항

| 항목 | 결정 |
|------|------|
| 가입 방식 | 공개 가입 + 프로필 심사 |
| 프로필 정보 | 단계별 (최소 → 기본 → 상세) |
| 자격증 검증 | 선택적 인증 (뱃지 부여) |
| 온보딩 | 프로필 완성 유도 + 튜토리얼 |
| 학생 연결 | 초대 + 검색 모두 지원 |
| 공개 프로필 | 선생님이 공개 범위 설정 |
| 수수료 | Phase 1 무료 (추후 결정) |
| 신원 확인 | 휴대폰 인증 |

---

## 1. 가입 플로우

### 1.1 전체 흐름

```
소셜 로그인 → 약관 동의 → 역할 선택 → 휴대폰 인증 → 필수 프로필 → 튜토리얼 → 대시보드
     ↓            ↓           ↓            ↓              ↓
  Google/Kakao  이용약관    "선생님"     본인 확인      최소 정보
               개인정보동의
```

### 1.2 단계별 상세

#### Step 1: 소셜 로그인
- Google / Kakao OAuth

#### Step 2: 역할 선택
- "선생님으로 시작하기" / "학생으로 시작하기"
- 최초 로그인 시에만 표시

#### Step 3: 휴대폰 인증

> 📦 **엔티티 정의**: [teacher.md - PhoneVerification](../../schema/entities/teacher.md#phoneverification-휴대폰-인증)

| 단계 | 설명 |
|:----:|------|
| 1 | 휴대폰 번호 입력 |
| 2 | 인증번호 발송 (6자리) |
| 3 | 인증번호 입력 (3분 유효) |
| 4 | 인증 완료 |

#### Step 4: 필수 프로필 입력

| 항목 | 필수 | 설명 |
|------|:----:|------|
| name | ✓ | 이름 |
| profileImage | ✓ | 프로필 사진 |
| instruments | ✓ | 가르치는 악기 (최소 1개) |
| introduction | ✓ | 소개글 (최소 20자) |

#### Step 5: 튜토리얼

> 📦 **엔티티 정의**: [teacher.md - TutorialProgress](../../schema/entities/teacher.md#tutorialprogress-튜토리얼)

| 단계 | 내용 |
|------|------|
| welcome | "환영합니다! 레슨앱에서 학생을 관리해보세요" |
| inviteStudent | "학생을 초대하는 방법" |
| createLesson | "레슨 일정 등록하기" |
| writeFeedback | "레슨 노트 작성하기" |
| completed | "준비 완료!" |

---

## 2. 프로필 시스템

### 2.1 프로필 완성도

> 📦 **엔티티 정의**: [teacher.md - ProfileCompletionLevel](../../schema/entities/teacher.md#profilecompletionlevel-프로필-완성도)

| 레벨 | 완성도 | 기능 제한 |
|------|:------:|----------|
| minimum | 30% | 학생 초대 불가, 검색 노출 불가, 레슨 생성 불가 |
| basic | 60% | 검색 노출 불가, 학생 수 5명 제한 |
| standard | 80% | 정상 활동 가능 |
| complete | 100% | 검색 상위 노출, 프리미엄 뱃지 |

### 2.2 프로필 항목

#### 필수 (Minimum) - 30%
| 항목 | 타입 | 설명 |
|------|------|------|
| name | String | 이름 |
| profileImage | String | 프로필 사진 |
| instruments | List<Instrument> | 가르치는 악기 (최소 1개) |
| introduction | String | 소개글 (최소 20자) |

#### 기본 (Basic) - 60%
| 항목 | 타입 | 설명 |
|------|------|------|
| experience | int | 경력 (년) |
| lessonAreas | List<String> | 레슨 가능 지역 |
| lessonTypes | List<LessonType> | 대면/비대면/방문 |
| feeRange | FeeRange | 레슨료 범위 |

#### 상세 (Standard) - 80%
| 항목 | 타입 | 설명 |
|------|------|------|
| education | List<Education> | 학력 |
| certificates | List<Certificate> | 자격증 |
| career | List<Career> | 경력 상세 |

#### 완성 (Complete) - 100%
| 항목 | 타입 | 설명 |
|------|------|------|
| portfolioVideos | List<Video> | 연주 영상 |
| teachingStyle | String | 레슨 스타일 설명 |
| specialties | List<String> | 전문 분야 |

### 2.3 완성도별 기능 제한

| 기능 | minimum (30%) | basic (60%) | standard (80%) | complete (100%) |
|------|:-------------:|:-----------:|:--------------:|:---------------:|
| 학생 초대 | ❌ | ✓ | ✓ | ✓ |
| 검색 노출 | ❌ | ❌ | ✓ | ✓ (상위) |
| 레슨 생성 | ❌ | ✓ | ✓ | ✓ |
| 대시보드 | ✓ | ✓ | ✓ | ✓ |
| 최대 학생 수 | - | 5명 | 무제한 | 무제한 |
| 프리미엄 뱃지 | - | - | - | ⭐ |

---

## 3. 자격증 인증 시스템

### 3.1 인증 플로우

```
자격증 업로드 → 운영팀 검토 → 승인/반려 → 뱃지 부여
     ↓              ↓            ↓
  사진/PDF       1-3일 소요    "인증됨" 표시
```

### 3.2 모델

> 📦 **엔티티 정의**: [teacher.md - Certificate, TeacherVerification](../../schema/entities/teacher.md#certificate-자격증)

**자격증 상태:**

| 상태 | 설명 |
|------|------|
| pending | 검토 중 |
| approved | 승인됨 |
| rejected | 반려됨 |

**자격증 유형:**

| 유형 | 설명 |
|------|------|
| musicTeacher | 실용음악강사 |
| cultureArtsEducator | 문화예술교육사 |
| schoolTeacher | 정교사 자격증 |
| conservatory | 음악원 수료 |
| degree | 음대 학위 |
| performance | 연주 경력 증빙 |
| other | 기타 |

### 3.3 뱃지 표시

> 📦 **엔티티 정의**: [teacher.md - VerificationBadge](../../schema/entities/teacher.md#verificationbadge-인증-뱃지)

| 뱃지 | 아이콘 | 조건 |
|------|:------:|------|
| phoneVerified | 📱 | 휴대폰 인증 완료 |
| certified | ✓ | 자격증 1개 이상 승인 |
| premium | ⭐ | 프로필 100% 완성 |

---

## 4. 학생 연결 시스템

### 4.1 초대 방식 (기존 requirement.md 기반)

> 📦 **엔티티 정의**: [teacher.md - InviteMethod, TeacherInvite](../../schema/entities/teacher.md#invitemethod-초대-방식)

| 방식 | 설명 |
|------|------|
| qrCode | QR 코드 (대면 레슨 시) |
| urlLink | URL 링크 (메시지/카카오톡) |
| inAppSearch | 앱 내 검색 |

### 4.2 검색 시스템

> 📦 **엔티티 정의**: [teacher.md - TeacherSearchFilter, TeacherSearchResult](../../schema/entities/teacher.md#teachersearchfilter-검색-필터)

#### 검색 탭 구분 ✅ 구현 완료

| 탭 | 설명 | 필터 조건 |
|----|------|----------|
| **학원** | 학원 소속 선생님 검색 | `organizationId != null` |
| **개인 선생님** | 개인 선생님 검색 | `organizationId == null` |

```
┌─────────────────────────────────────────┐
│  [🏫 학원]  [👤 개인 선생님]            │  ← TabBar
├─────────────────────────────────────────┤
│  🔍 학원 이름, 악기, 지역으로 검색      │  ← 탭별 힌트 변경
├─────────────────────────────────────────┤
│  [관련도순] [경력높은순] [레슨료낮은순] │  ← 정렬 옵션
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐    │
│  │ [🏫 김지수 음악학원]            │    │  ← 학원 뱃지
│  │ 김지수 선생님            ✓ ⭐  │    │
│  │ 피아노 · 작곡                   │    │
│  │ 📍 서울 강남 · 💰 6~8만원      │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

#### 검색 필터

| 필터 | 설명 |
|------|------|
| teacherType | 학원/개인 (탭으로 제어) |
| instruments | 악기 |
| area | 지역 |
| lessonType | 대면/비대면 |
| feeRange | 레슨료 범위 |
| hasVerifiedCertificate | 자격인증 여부 |
| minExperience | 최소 경력 |

#### 검색 랭킹 요소

| 순위 | 요소 |
|:----:|------|
| 1 | 프로필 완성도 (complete > standard) |
| 2 | 자격인증 여부 |
| 3 | 학생 수 / 리뷰 수 (추후) |
| 4 | 최근 활동일 |

---

## 5. 공개 프로필 설정

### 5.1 공개 범위 설정

> 📦 **엔티티 정의**: [teacher.md - ProfileVisibilitySettings](../../schema/entities/teacher.md#profilevisibilitysettings-공개-범위-설정)

| 공개 범위 | 설명 |
|----------|------|
| public | 모든 사용자에게 공개 |
| students | 연결된 학생에게만 공개 |
| private | 비공개 |

### 5.2 기본값

| 항목 | 기본 공개 범위 |
|------|:-------------:|
| name | public |
| photo | public |
| contact | students (연결 후 공개) |
| fee | public |
| career | public |
| certificate | public |

### 5.3 공개 프로필 화면

검색 결과에서 보이는 프로필:
- 이름, 프로필 사진 (visibility에 따라)
- 가르치는 악기, 소개글
- 레슨 가능 지역, 레슨료 범위 (visibility에 따라)
- 인증 뱃지, 경력

**Actions:**
- "연결 요청" 버튼
- "프로필 더보기" (연결 후)

---

## 6. 온보딩 UI 플로우

### 6.1 화면 구성

```
1. WelcomeScreen
   └── "레슨앱에 오신 것을 환영합니다"
   └── [선생님으로 시작] [학생으로 시작]

2. PhoneVerificationScreen
   └── 휴대폰 번호 입력
   └── 인증번호 입력

3. ProfileSetupScreen (Step-by-step)
   └── Step 1: 이름, 사진
   └── Step 2: 악기 선택
   └── Step 3: 소개글 작성
   └── [나중에 완성하기] 옵션

4. TutorialScreen (스킵 가능)
   └── 학생 초대 방법
   └── 레슨 등록 방법
   └── 피드백 작성 방법

5. DashboardScreen
   └── 프로필 완성도 카드 (incomplete일 경우)
   └── "프로필 완성하고 학생 초대하기" CTA
```

### 6.2 프로필 완성 유도

프로필 완성 카드 구성:
- Progress bar (완성도 %)
- 현재 레벨 표시
- 다음 단계 안내 (예: "경력을 추가하세요", "자격증을 인증하세요")

---

## 7. 데이터 모델 요약

> 📦 **전체 엔티티 정의**: [teacher.md](../../schema/entities/teacher.md)

| 엔티티 | 설명 |
|--------|------|
| Teacher | 선생님 메인 모델 |
| ProfileCompletionLevel | 프로필 완성도 레벨 |
| PhoneVerification | 휴대폰 인증 |
| Certificate | 자격증 |
| TeacherVerification | 선생님 인증 정보 |
| VerificationBadge | 인증 뱃지 |
| ProfileVisibilitySettings | 공개 범위 설정 |
| Education | 학력 |
| Career | 경력 |
| FeeRange | 레슨료 범위 |
| LessonType | 레슨 형태 (대면/비대면) |
| Video | 포트폴리오 영상 |
| TeacherSearchFilter | 검색 필터 |
| TeacherSearchResult | 검색 결과 |
| TutorialProgress | 튜토리얼 진행 |

---

## 8. 구현 우선순위

### Phase 1 (MVP)
1. 소셜 로그인 + 역할 선택
2. 휴대폰 인증
3. 필수 프로필 (이름, 사진, 악기, 소개)
4. 튜토리얼 (스킵 가능)
5. 프로필 완성도 표시

### Phase 2
1. 확장 프로필 (경력, 학력, 레슨료)
2. 자격증 인증 시스템
3. 공개 프로필 설정
4. 선생님 검색

### Phase 3
1. 검색 랭킹 알고리즘
2. 리뷰/평점 시스템
3. 프리미엄 기능 (수수료 모델)

---

## 9. 학원 소속 등록 (선택)

가입 후 학원에 소속될 수 있습니다.

### 학원 소속 방법

| 방법 | 설명 |
|------|------|
| **학원 초대 수락** | 학원 관리자가 초대 → 선생님이 수락 |
| **가입 요청** | 선생님이 학원 검색 → 가입 요청 → 학원 승인 |

### 소속 후 변화

| 항목 | 변화 |
|------|------|
| Context Switcher | 개인 / 학원 컨텍스트 전환 가능 |
| 학생 등록 | 학원 컨텍스트에서 등록 시 `organizationId` 설정 |
| 데이터 소유권 | 학원 학생 데이터는 학원 소유 |
| 정산 | 학원 통해 정산 (학원 설정에 따름) |

> **자세한 내용**: [초대 시스템 v2 - 학원-선생님 초대](../invite/invite_system_v2.md#학원-선생님-초대-시스템)

---

## 10. 관련 문서

| 문서 | 설명 |
|------|------|
| [three_party_relationship_spec.md](../lesson/three_party_relationship_spec.md) | 학원-선생님-학생 3자 관계 |
| [invite_system_v2.md](../invite/invite_system_v2.md) | 초대 시스템 (학원-선생님 포함) |
| [trial_lesson_system.md](../trial/trial_lesson_system.md) | 체험 레슨 예약 |
| [payment_unified_spec.md](../payment/payment_unified_spec.md) | 통합 결제 스펙 |
| [notification_system.md](../notification/notification_system.md) | 알림 시스템 |
