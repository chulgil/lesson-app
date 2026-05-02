---
name: import-refactor
description: 파일 이동 후 import 경로를 자동으로 업데이트합니다.
allowed-tools: Read, Grep, Edit, Glob
---

# Import Refactor Skill - Lesson App (Flutter/Dart)

파일 이동/리네이밍 후 **모든 import 경로를 자동으로 업데이트**합니다.

## 사용 시점

- 파일을 다른 폴더로 이동할 때
- 파일명을 변경할 때
- 폴더 구조를 재구성할 때
- Clean Architecture 마이그레이션 시

## 작업 순서

### 1. 변경 사항 파악
```
이전 경로: lib/models/student.dart
새 경로: lib/features/students/domain/entities/student.dart
```

### 2. 영향받는 파일 검색
```bash
# 기존 경로를 import하는 모든 파일 찾기
grep -r "import.*models/student" lib/
```

### 3. import 경로 업데이트
```dart
// Before
import 'package:lesson_app/models/student.dart';

// After
import 'package:lesson_app/features/students/domain/entities/student.dart';
```

### 4. Re-export 추가 (하위 호환성)
```dart
// lib/models/student.dart (레거시 위치에 유지)
export '../features/students/domain/entities/student.dart';
```

## 사용법

```
"student.dart를 features/students/domain/entities/로 이동하고 import 업데이트해줘"
"lib/providers/를 features/ 아래로 마이그레이션해줘"
"이 파일 이름을 변경하고 참조 업데이트해줘"
```

## Clean Architecture 마이그레이션 패턴

### 모델 이동
```
Before: lib/models/lesson.dart
After:  lib/features/lessons/domain/entities/lesson.dart

+ Re-export: lib/models/lesson.dart
  export '../features/lessons/domain/entities/lesson.dart';
```

### Provider 이동
```
Before: lib/providers/lesson_providers.dart
After:  lib/features/lessons/presentation/providers/lesson_providers.dart

+ Re-export: lib/providers/lesson_providers.dart
  export '../features/lessons/presentation/providers/lesson_providers.dart';
```

### Repository 이동
```
Before: lib/repositories/lesson_repository.dart
After:  lib/features/lessons/data/repositories/lesson_repository_impl.dart

+ Interface: lib/features/lessons/domain/repositories/lesson_repository.dart
+ Re-export: lib/repositories/lesson_repository.dart
```

## 체크리스트

- [ ] 모든 import 경로가 업데이트되었는가?
- [ ] 레거시 위치에 re-export가 추가되었는가?
- [ ] `flutter analyze` 경고 없는가?
- [ ] 순환 참조가 발생하지 않는가?
- [ ] 빌드가 성공하는가?

## 주의사항

### 1. 패키지 import vs 상대 import
```dart
// 권장: 패키지 import
import 'package:lesson_app/features/lessons/domain/entities/lesson.dart';

// 비권장: 상대 import (같은 feature 내에서만 사용)
import '../../../domain/entities/lesson.dart';
```

### 2. part/part of 파일
```dart
// .g.dart 파일은 자동 생성되므로 수동 수정 불필요
// build_runner가 자동으로 처리
```

### 3. barrel 파일 활용
```dart
// lib/features/lessons/lessons.dart (barrel file)
export 'domain/entities/lesson.dart';
export 'presentation/providers/lesson_providers.dart';
export 'presentation/screens/lesson_detail_screen.dart';
```

## 관련 명령어

```bash
# 특정 import를 사용하는 파일 찾기
grep -r "import.*old_path" lib/

# 모든 dart 파일에서 교체
# (Claude가 수동으로 처리하는 것을 권장)

# 분석 실행
flutter analyze
```
