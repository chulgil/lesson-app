# Lesson App - Project Overview

## Purpose
Music lesson management app for teachers and students (Flutter)

## Tech Stack
- **Framework**: Flutter (Dart SDK ^3.7.0)
- **State Management**: Riverpod (@riverpod code generation)
- **Navigation**: Go Router
- **Local Storage**: Hive, flutter_secure_storage
- **Audio**: record, just_audio, audioplayers, metronome
- **Push Notifications**: Firebase (firebase_core, firebase_messaging)
- **Network**: Dio

## Platforms
- iOS
- Android
- macOS (for development testing)

## Architecture
- Clean Architecture + Feature-based structure
- Re-export pattern for backward compatibility

## Project Structure
```
lib/
├── core/                    # Common utilities
│   ├── audio/               # Audio engine (metronome, recording)
│   ├── models/              # Shared enums
│   ├── router/              # GoRouter configuration
│   └── theme/               # AppColors, AppTypography
├── features/                # Feature modules (Clean Architecture)
│   ├── auth/                # Authentication
│   ├── home/                # Teacher home
│   ├── student_home/        # Student home
│   ├── parent_home/         # Parent home
│   ├── lessons/             # Lesson management
│   ├── students/            # Student management
│   ├── practice/            # Practice management
│   ├── profile/             # Profile
│   ├── schedule/            # Schedule
│   ├── search/              # Teacher search
│   ├── onboarding/          # Onboarding
│   ├── notifications/       # Notifications
│   ├── calendar/            # Calendar
│   └── invite/              # Invite system
├── models/                  # Legacy models (re-export only)
├── providers/               # Legacy providers (re-export only)
├── repositories/            # Legacy repositories (re-export only)
└── services/                # Service layer
```

## Feature Structure (Clean Architecture)
```
feature/
├── domain/
│   ├── entities/            # Domain models
│   └── repositories/        # Repository interfaces
├── data/
│   └── repositories/        # Repository implementations (Mock)
└── presentation/
    ├── screens/             # UI screens
    ├── widgets/             # UI widgets
    └── providers/           # Riverpod providers
```
