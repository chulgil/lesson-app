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
│   └── └── app_theme.dart
│   ├── router/               # 라우팅
│   │   └── app_router.dart
│   ├── constants/            # 상수
│   └── utils/                # 유틸리티
├── features/                 # 기능별 모듈
│   ├── auth/                 # 인증
│   │   └── presentation/
│   │       ├── screens/
│   │       └── widgets/
│   ├── home/                 # 홈/대시보드
│   ├── students/             # 학생 관리
│   ├── lessons/              # 레슨 관리
│   ├── practice/             # 연습 관리
│   └── profile/              # 프로필
├── shared/                   # 공유 위젯
│   └── widgets/
├── services/                 # 서비스 (API, Storage)
└── models/                   # 데이터 모델
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
| 1 | 로그인 (Google/Kakao) | 🔄 UI 완료 |
| 2 | 선생님 대시보드 | 🔄 UI 완료 |
| 3 | 학생 대시보드 | ⏳ 대기 |
| 4 | 학생 관리 목록 | ⏳ 대기 |
| 5 | 레슨 캘린더 | ⏳ 대기 |
| 6 | 레슨 상세 (녹음) | ⏳ 대기 |
| 7 | 연습 체크리스트 | ⏳ 대기 |

### 추가 기능 (Phase 1+)

- 푸시 알림
- AI 레슨 요약 (Whisper + Claude)
- 연습 통계/리포트
- 결제 시스템

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
