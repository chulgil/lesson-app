# 로그인 테스트 시나리오

> 마지막 업데이트: 2025-12-28

## 개요

개발 및 테스트 시 다양한 사용자 상태를 시뮬레이션하기 위한 로그인 테스트 시나리오입니다.
소셜 로그인 제공자(Google, Kakao, Apple)별로 다른 사용자 상태로 진입할 수 있습니다.

---

## 선생님 (Teacher)

로그인 화면에서 소셜 로그인 버튼 클릭 → 역할 선택 다이얼로그 → "선생님" 선택

| 소셜 로그인 | 시나리오 | 설명 | 라우팅 |
|-------------|----------|------|--------|
| **Google** | 기존 선생님 (학생 있음) | 이미 가입된 선생님, 등록된 학생이 있음 | → `/home` |
| **Kakao** | 기존 선생님 (학생 없음) | 이미 가입된 선생님, 아직 학생이 없음 | → `/home` |
| **Apple** | 신규 가입 → SMS 인증 | 처음 가입하는 선생님 | → `/onboarding/phone-verification` |

### 테스트 플로우

```
[로그인 화면]
    ↓
[Google/Kakao/Apple 버튼 클릭]
    ↓
[역할 선택 다이얼로그]
    ├─ 선생님 선택
    │   ├─ Google → 홈 화면 (학생 목록 있음)
    │   ├─ Kakao → 홈 화면 (학생 목록 비어있음)
    │   └─ Apple → SMS 인증 → 프로필 설정 → 튜토리얼 → 홈
    │
    └─ 학생 선택 (아래 참조)
```

---

## 학생 (Student)

로그인 화면에서 소셜 로그인 버튼 클릭 → 역할 선택 다이얼로그 → "학생" 선택

| 소셜 로그인 | 시나리오 | 설명 | 라우팅 |
|-------------|----------|------|--------|
| **Google** | 기존 학생 (레슨 있음) | 이미 가입된 학생, 등록된 레슨이 있음 | → `/student-home` |
| **Kakao** | 기존 학생 (레슨 없음) | 이미 가입된 학생, 아직 레슨이 없음 | → `/student-home` |
| **Apple** | 신규 학생 → 초대코드 입력 | 처음 가입하는 학생 | → `/student/invite-code` |

### 테스트 플로우

```
[로그인 화면]
    ↓
[Google/Kakao/Apple 버튼 클릭]
    ↓
[역할 선택 다이얼로그]
    └─ 학생 선택
        ├─ Google → 학생 홈 화면 (레슨 목록 있음)
        ├─ Kakao → 학생 홈 화면 (레슨 목록 비어있음)
        └─ Apple → 초대코드 입력 화면 → 학생 홈
```

---

## 학부모 (Parent)

로그인 화면에서 "학부모이신가요?" 링크 클릭 → 학부모 로그인 바텀시트

| 소셜 로그인 | 시나리오 | 설명 | 라우팅 |
|-------------|----------|------|--------|
| **Google** | 기존 학부모 (자녀 등록됨) | 이미 가입된 학부모, 연결된 자녀가 있음 | → `/parent-home` |
| **Kakao** | 기존 학부모 (자녀 없음) | 이미 가입된 학부모, 아직 자녀 연결 없음 | → `/parent-home` |
| **Apple** | 신규 가입 → 초대코드 입력 | 처음 가입하는 학부모 | → `/parent/invite-code` |

### 테스트 플로우

```
[로그인 화면]
    ↓
["학부모이신가요?" 클릭]
    ↓
[학부모 로그인 바텀시트]
    ├─ Google → 학부모 홈 (자녀 프로필 있음)
    ├─ Kakao → 학부모 홈 (자녀 프로필 비어있음)
    └─ Apple → 초대코드 입력 화면 → 학부모 홈
```

---

## 관련 파일

| 파일 | 설명 |
|------|------|
| `lib/features/auth/presentation/screens/login_screen.dart` | 로그인 화면 및 테스트 시나리오 라우팅 |
| `lib/features/auth/presentation/screens/student_invite_code_screen.dart` | 학생 초대코드 입력 화면 |
| `lib/features/auth/presentation/screens/parent_invite_code_screen.dart` | 학부모 초대코드 입력 화면 |
| `lib/core/router/app_router.dart` | 라우터 설정 |

---

## 구현 상세

### login_screen.dart 주요 메서드

```dart
// 선생님 테스트 시나리오
String _getTeacherDescription(String authProvider)
void _handleTeacherLogin(BuildContext context, String authProvider)

// 학생 테스트 시나리오
String _getStudentDescription(String authProvider)
void _handleStudentLogin(BuildContext context, String authProvider)

// 학부모 테스트 시나리오
void _handleParentLogin(BuildContext context)  // 바텀시트에 직접 시나리오 포함
```

---

## 참고사항

1. **Mock 인증**: 현재 실제 OAuth 연동 없이 Mock으로 동작합니다.
2. **6자리 코드**: 초대코드 입력 시 6자리 이상이면 통과합니다 (테스트용).
3. **SMS 인증**: 6자리 숫자 입력 시 인증 통과합니다 (테스트용).
4. **역할 전환**: 디버그 모드에서 프로필 화면의 역할 전환 기능 사용 가능합니다.
