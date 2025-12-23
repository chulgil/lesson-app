# CLAUDE.md - Lesson App

음악 레슨/연습 관리 앱 - Flutter 프로젝트

---

## 프로젝트 개요

| 항목 | 내용 |
|------|------|
| **이름** | Lesson App |
| **설명** | 선생님과 학생을 위한 음악 레슨/연습 관리 앱 |
| **플랫폼** | iOS, Android |
| **기술 스택** | Flutter, Riverpod, Go Router, Hive |

---

## 프로젝트 구조

```
lib/
├── main.dart                 # 앱 진입점
├── core/                     # 핵심 설정
│   ├── theme/                # 디자인 시스템
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   ├── app_spacing.dart
│   │   └── app_theme.dart
│   ├── router/               # 라우팅
│   │   └── app_router.dart
│   ├── constants/            # 상수
│   └── utils/                # 유틸리티
├── features/                 # 기능별 모듈
│   ├── auth/                 # 인증
│   ├── home/                 # 홈/대시보드
│   ├── students/             # 학생 관리
│   ├── lessons/              # 레슨 관리
│   ├── practice/             # 연습 관리
│   ├── profile/              # 프로필 및 설정
│   │   └── presentation/screens/
│   │       ├── profile_tab.dart
│   │       ├── payment_management_screen.dart
│   │       ├── lesson_time_settings_screen.dart
│   │       └── repertoire_management_screen.dart
│   └── student_home/         # 학생용 화면
├── shared/                   # 공유 위젯
│   └── widgets/
├── models/                   # 데이터 모델
│   ├── student.dart          # 학생 모델 (레벨, 수강료)
│   ├── payment.dart          # 결제 모델 (체험/정규, 주차)
│   ├── lesson.dart           # 레슨 모델
│   └── piece.dart            # 곡 모델
├── repositories/             # 데이터 저장소
│   ├── student_repository.dart
│   ├── payment_repository.dart
│   └── lesson_repository.dart
├── providers/                # Riverpod 상태관리
│   ├── student/
│   ├── payment/
│   └── lesson/
└── services/                 # 서비스 (API, Storage)
```

---

## 주요 명령어

```bash
# 의존성 설치
flutter pub get

# 앱 실행
flutter run

# iOS 시뮬레이터 실행
flutter run -d ios

# Android 에뮬레이터 실행
flutter run -d android

# 코드 생성 (Riverpod, Hive 등)
dart run build_runner build --delete-conflicting-outputs

# 분석
flutter analyze

# 테스트
flutter test

# 빌드 (Release)
flutter build ios
flutter build apk
```

---

## 디자인 시스템

### 색상

| 이름 | HEX | 용도 |
|------|-----|------|
| Primary | `#6B5B95` | 주요 액션, 브랜드 |
| Secondary | `#F4A460` | 보조, 악기 느낌 |
| Background | `#FFFAF5` | 배경 (Light) |
| Success | `#2E8B57` | 완료, 좋음 |
| Warning | `#F4A460` | 보통 |
| Error | `#DC143C` | 에러, 부족 |

### 타이포그래피

- **폰트**: Pretendard
- **스케일**: Display → Heading → Body → Caption

### 스페이싱

- **기본 단위**: 8pt 그리드
- **화면 패딩**: 16px
- **카드 패딩**: 16px
- **섹션 간격**: 24px

---

## 기능 목록

### Phase 0 (MVP)

| # | 기능 | 상태 |
|---|------|------|
| 1 | 로그인 (Google/Kakao) | ✅ UI 완료 |
| 2 | 선생님 대시보드 | ✅ UI 완료 |
| 3 | 학생 대시보드 | ✅ UI 완료 |
| 4 | 학생 관리 목록 | ✅ 구현 완료 |
| 5 | 레슨 캘린더 | ✅ 구현 완료 |
| 6 | 레슨 노트/녹음 | ✅ 구현 완료 |
| 7 | 연습 시스템 | 🔄 진행 중 |
| 8 | 수강료 관리 | ✅ 구현 완료 |

### 추가 기능 (Phase 1+)

| 기능 | 상태 |
|------|------|
| 2단계 입금확인 (학생→선생님) | ✅ 완료 |
| 월 4/8회 레슨 횟수 설정 | ✅ 완료 |
| 푸시 알림 / 알림 시스템 | 예정 |
| AI 레슨 요약 (Whisper + Claude) | 예정 |
| 연습 통계/리포트 | 예정 |

---

## 수강료 관리 시스템

### 개요

선생님이 학생별 수강료를 관리하고, 입금 상태를 추적하는 기능

### 데이터 모델

#### StudentLevel (학생 레벨)
| 레벨 | 한글명 | 기본 월 수강료 |
|------|--------|----------------|
| beginner | 입문 | 160,000원 |
| elementary | 초급 | 180,000원 |
| intermediate | 중급 | 200,000원 |
| advanced | 고급 | 240,000원 |

#### PaymentType (결제 유형)
| 유형 | 설명 |
|------|------|
| trial | 체험 레슨 (1회, 기본 30,000원) |
| regular | 정규 레슨 (월/주 단위) |

#### PaymentStatus (결제 상태)
| 상태 | 설명 |
|------|------|
| pending | 입금 대기 |
| completed | 입금 완료 |
| cancelled | 취소 |
| refunded | 환불 |

### 주요 기능

1. **결제 유형 분리**: 체험 레슨과 정규 레슨 구분
2. **주차 범위 설정**: 월 전체(1~4주) 또는 부분 기간(예: 3~4주) 선택
3. **레벨별 자동 금액**: 학생 레벨에 따라 기본 수강료 자동 설정
4. **입금 확인**: 선생님이 실제 입금 확인 후 상태 변경

### 완료된 기능

#### 2단계 입금확인 시스템
학생이 먼저 "입금완료"를 알리고, 선생님이 계좌 확인 후 "입금확인" 처리하는 2단계 워크플로우

| 단계 | 액션 | 상태 표시 |
|------|------|-----------|
| 1단계 | 학생이 "입금완료" 버튼 클릭 | "확인 대기" (🔔 아이콘) |
| 2단계 | 선생님이 계좌 확인 후 "입금확인" | "완료" |

**관련 필드**:
- `Payment.studentConfirmed`: 학생 입금완료 표시 여부
- `Payment.studentConfirmedAt`: 학생 입금완료 표시 시간
- `Payment.isAwaitingTeacherConfirmation`: 선생님 확인 대기 여부
- `Payment.displayStatus`: 2단계 상태 고려한 표시 상태

#### 월 4/8회 레슨 횟수 설정
주 1회(월 4회) 또는 주 2회(월 8회) 레슨 횟수 설정 기능

| 설정 | 월 레슨 횟수 | 회당 수강료 계산 |
|------|-------------|-----------------|
| 주 1회 | 4회 | 월 수강료 ÷ 4 |
| 주 2회 | 8회 | 월 수강료 ÷ 8 |

**관련 필드**:
- `Student.lessonsPerWeek`: 주당 레슨 횟수 (1 또는 2)
- `Student.monthlyLessonCount`: 월 레슨 횟수 (lessonsPerWeek × 4)
- `Student.lessonFee`: 회당 수강료 (monthlyFee ÷ monthlyLessonCount)
- `Student.lessonFrequency`: 표시용 문자열 ("주 1회 (월 4회)")

### 향후 계획

- [ ] SMS 자동 감지 (Android)

---

## API 연동

### 백엔드 (예정)

- **URL**: `https://api.lessonapp.com` (예정)
- **Framework**: Python FastAPI
- **Server**: codenavi (기존 인프라)

### 인증

- Google OAuth 2.0
- Kakao Login

---

## 개발 규칙

### 디자인 규칙 ⭐ 중요

**모든 UI 작업 전 반드시 앱 브랜드 색상을 확인하세요!**

1. **색상 파일 위치**: `lib/core/theme/app_colors.dart`
2. **브랜드 컬러 사용 원칙**:
   - 새로운 UI 컴포넌트 작성 시 반드시 `AppColors` 클래스 사용
   - 하드코딩된 색상값(#FFFFFF 등) 사용 금지
   - 새로운 색상이 필요하면 `AppColors`에 먼저 추가 후 사용

3. **앱 브랜드 컬러**:
   | 용도 | 색상 | 사용처 |
   |------|------|--------|
   | Primary | `AppColors.primary` (#6B5B95) | 주요 액션, 브랜드, 선택 상태 |
   | Primary Light | `AppColors.primaryLight` | 배경 하이라이트 |
   | Secondary | `AppColors.secondary` (#F4A460) | 보조 액센트, 악기 느낌 |
   | Success | `AppColors.practiceGood` (#2E8B57) | 완료, 좋음 표시 |
   | Warning | `AppColors.practiceNormal` | 보통, 주의 |
   | Error | `AppColors.error` (#DC143C) | 에러, 부족, 일요일 |
   | Background | `AppColors.backgroundLight` (#FFFAF5) | 화면 배경 |
   | Surface | `AppColors.surfaceLight` | 카드 배경 |

4. **색상 추가 절차**:
   ```dart
   // lib/core/theme/app_colors.dart 에 추가
   static const newColor = Color(0xFF...);
   ```
   - 추가 시 용도 주석 필수
   - 라이트/다크 모드 둘 다 고려

5. **캘린더/위젯 디자인**:
   - 선택된 날짜: `AppColors.primary`
   - 오늘 날짜: `AppColors.secondary` 또는 골드 테두리
   - 일요일: `AppColors.error` (붉은 계열)
   - 토요일: `AppColors.primary` (연한)
   - 레슨 마커: `AppColors.secondary` 또는 음표(♪) 사용

### 코드 스타일

- Dart 공식 스타일 가이드 준수
- `flutter analyze` 경고 없이 유지
- 주석은 영어로 작성

### 커밋 메시지

- **한글**로 작성
- Conventional Commits 형식
- 예: `feat: 로그인 화면 구현`

### 브랜치 전략

- `main`: 프로덕션
- `develop`: 개발
- `feature/*`: 기능 개발
- `fix/*`: 버그 수정

---

## 연습 시스템 (이번 주 연습)

### 개요

레슨 후 학생에게 할당되는 연습 과제 관리 시스템. "과제" 대신 "이번 주 연습"으로 명명하여 심리적 부담 완화

### 상세 스펙

📖 **[연습 시스템 상세 스펙](../../../Personal/development/idea/lesson-app/Practice_System_Spec.md)**

### 핵심 기능

| 기능 | 설명 |
|------|------|
| 3단계 우선순위 | 🔴필수, 🟡추천, 🟢도전 |
| 연령별 UI | 어린이(≤12), 학생(13-18), 성인(19+) |
| 뱃지/칭호 시스템 | 12개 뱃지, 4개 카테고리 |
| 선생님 피드백 | 좋아요 버튼 + 실시간 알림 |
| 레퍼토리 연동 | 선택 또는 직접입력 + 자동등록 |

### 주요 모델

```dart
enum PracticePriority { must, should, could }
enum PracticeType { repertoire, technique, theory, custom }
enum AgeGroup { child, student, adult }

class PracticeItem {
  String id, lessonId, title;
  PracticePriority priority;
  PracticeType type;
  bool isCompleted;
  int practiceCount;
  bool hasLike;
}
```

### 구현 상태

| 단계 | 내용 | 상태 |
|------|------|------|
| Phase 1 | 기본 연습 할당/완료 | 예정 |
| Phase 2 | 뱃지 시스템 | 예정 |
| Phase 3 | 연령별 UI 분화 | 예정 |
| Phase 4 | 통계/리포트 | 예정 |
| Phase 5 | 고급 기능 (녹음/영상) | 예정 |

---

## 관련 문서

- [요구사항](../../../Personal/development/idea/lesson-app/requirement.md)
- [연습 시스템 스펙](../../../Personal/development/idea/lesson-app/Practice_System_Spec.md)
- [기술 의사결정](../../idea/lesson-app/tech_decision.md)
- [화면 명세서](../../idea/lesson-app/figma/screen_specs.md)
- [디자인 시스템](../../idea/lesson-app/figma/design_system.md)

---

## 문제 해결

### iOS 빌드 에러

```bash
cd ios && pod install && cd ..
flutter clean && flutter pub get
```

### Android 빌드 에러

```bash
cd android && ./gradlew clean && cd ..
flutter clean && flutter pub get
```

### 폰트가 적용되지 않음

`assets/fonts/` 폴더에 Pretendard 폰트 파일 추가 필요:
- Pretendard-Regular.otf
- Pretendard-Medium.otf
- Pretendard-SemiBold.otf
- Pretendard-Bold.otf
