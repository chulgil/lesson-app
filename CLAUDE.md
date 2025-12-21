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
| 7 | 연습 체크리스트 | 🔄 진행 중 |
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

## 관련 문서

- [요구사항](../../idea/lesson-app/requirement.md)
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
