# Frontend - Lesson App

> Flutter 기반 음악 레슨/연습 관리 앱

## 기술 스택

- **Framework**: Flutter
- **State Management**: Riverpod (@riverpod 코드 생성)
- **Router**: Go Router
- **Local Storage**: Hive

## 명령어

```bash
# 의존성 설치
flutter pub get

# 코드 생성 (Provider, JSON)
dart run build_runner build --delete-conflicting-outputs

# 앱 실행
flutter run

# 분석
flutter analyze

# 테스트
flutter test
```

## 폴더 구조

```
frontend/
├── lib/
│   ├── core/           # 공통 (라우터, 테마, 유틸)
│   ├── features/       # 기능별 모듈 (Clean Architecture)
│   ├── models/         # 레거시 (re-export only)
│   ├── providers/      # 레거시 (re-export only)
│   └── repositories/   # 레거시 (re-export only)
├── assets/             # 리소스
├── android/            # Android 네이티브
├── ios/                # iOS 네이티브
├── macos/              # macOS 네이티브
└── test/               # 테스트
```

## 아키텍처

Clean Architecture + Feature-based 구조:
```
features/[domain]/
├── domain/
│   └── entities/       # 모델/엔티티
├── data/
│   └── repositories/   # Repository 구현
└── presentation/
    ├── providers/      # Riverpod Provider
    ├── screens/        # 화면
    └── widgets/        # 위젯
```

자세한 내용은 [docs/architecture.md](../docs/architecture.md) 참조
