# 바로 녹음 기능 스펙

> 작성일: 2026-01-24
> 상태: 설계 완료
> 연관 스펙: [practice_system.md](practice_system.md), [recording_requirement.md](recording_requirement.md)

## 개요

레퍼토리/섹션을 먼저 선택하지 않고도 즉시 녹음할 수 있는 "바로 녹음" 기능입니다.
기존 연습 도구 모달에 녹음 버튼을 추가하고, 디폴트 섹션을 활용하여 UI 일관성을 유지합니다.

---

## 배경

### 현재 문제점

```
현재 녹음 플로우 (4단계):
연습 탭 → 레퍼토리 선택 → 섹션 선택 → 녹음 시작
                    ↓
        최소 10초 이상 소요
        진입장벽 높음
```

### 사용자 시나리오

| 상황 | 현재 | 개선 후 |
|------|------|---------|
| 연습 중 좋은 연주 캡처 | 레퍼토리 찾아서 녹음 (불편) | 바로 녹음 버튼 클릭 |
| 레퍼토리 미등록 상태 | 녹음 불가 | 바로 녹음 가능 |
| 빠른 메모 녹음 | 복잡한 절차 | 즉시 가능 |

---

## 설계 원칙

### 핵심 원칙

1. **기존 UI 100% 재사용**: 새 화면 없이 기존 섹션 상세 화면 활용
2. **디폴트 섹션 활용**: "무제 > 바로 녹음" 섹션 자동 생성
3. **연습 도구 통합**: 메트로놈/튜너/녹음을 한 곳에서 접근
4. **컨텍스트 스마트 동작**: 현재 화면에 따라 적절히 분기

---

## 기능 상세

### 1. 디폴트 레퍼토리/섹션 자동 생성

앱 첫 실행 시 "무제" 레퍼토리와 "바로 녹음" 섹션을 자동 생성합니다.

```
┌─────────────────────────────────────────────────────────┐
│  레퍼토리 목록                                          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  📁 무제                           ← 자동 생성 (기본)   │
│     └── 📄 바로 녹음               ← 자동 생성 (기본)   │
│                                                         │
│  📁 스즈키 바이올린 1권            ← 사용자 생성        │
│     └── 📄 작은별 변주곡                                │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

#### 데이터 모델 확장

```dart
// lib/features/practice/domain/entities/practice_repertoire.dart
class PracticeRepertoire {
  final String id;
  final String name;
  final bool isDefault;  // 🆕 기본 레퍼토리 여부
  // ... 기존 필드
}

// lib/features/practice/domain/entities/practice_section.dart
class PracticeSection {
  final String id;
  final String repertoireId;
  final String pieceName;
  final bool isDefault;  // 🆕 기본 섹션 여부
  // ... 기존 필드
}
```

#### 상수 정의

```dart
// lib/core/constants/default_ids.dart
class DefaultIds {
  static const String repertoireId = 'default_repertoire';
  static const String quickRecordSectionId = 'default_quick_record_section';
}
```

### 2. 연습 도구 모달 개선

기존 메트로놈/튜너 모달에 녹음 버튼을 추가합니다.

#### 현재 → 개선

```
현재:                              개선:
┌─────────────────────┐           ┌─────────────────────┐
│   연습 도구         │           │   연습 도구         │
├─────────────────────┤           ├─────────────────────┤
│                     │           │                     │
│  ┌─────┐  ┌─────┐  │           │       ┌─────┐       │
│  │메트로│  │튜너 │  │    →     │       │ 🎙️  │       │
│  │ 놈  │  │     │  │           │       │녹음 │       │
│  └─────┘  └─────┘  │           │       └─────┘       │
│                     │           │                     │
│                     │           │  ┌─────┐  ┌─────┐  │
│                     │           │  │메트로│  │튜너 │  │
│                     │           │  │ 놈  │  │     │  │
│                     │           │  └─────┘  └─────┘  │
└─────────────────────┘           └─────────────────────┘
```

#### UI 상세

```
┌─────────────────────────────────────────────────────────┐
│                    연습 도구                      [ X ] │
├─────────────────────────────────────────────────────────┤
│                                                         │
│                    ┌───────────┐                        │
│                    │    🎙️     │                        │
│                    │   녹음    │                        │
│                    │           │                        │
│                    └───────────┘                        │
│                                                         │
│         ┌───────────┐        ┌───────────┐             │
│         │    🎵     │        │    🎸     │             │
│         │  메트로놈  │        │   튜너    │             │
│         │           │        │           │             │
│         └───────────┘        └───────────┘             │
│                                                         │
│  ─────────────────────────────────────────────────────  │
│                                                         │
│  💡 녹음 버튼 동작:                                     │
│     • 섹션 화면에서 → 현재 섹션에서 바로 녹음           │
│     • 다른 화면에서 → "바로 녹음" 섹션으로 이동         │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 3. 녹음 버튼 동작 로직

#### 컨텍스트별 분기

```dart
// lib/features/practice/presentation/widgets/practice_tools_modal.dart

void _onRecordingButtonTap(BuildContext context, WidgetRef ref) {
  final currentRoute = GoRouterState.of(context).uri.path;

  // 현재 섹션 상세 화면인지 체크
  final sectionMatch = RegExp(r'/practice/section/(.+)').firstMatch(currentRoute);

  if (sectionMatch != null) {
    // Case 1: 섹션 화면 → 모달 닫고 녹음 시작
    final sectionId = sectionMatch.group(1)!;
    Navigator.pop(context);  // 모달 닫기

    // 녹음 시작 트리거
    ref.read(recordingControllerProvider(sectionId).notifier).startRecording();

  } else {
    // Case 2: 다른 화면 → 디폴트 섹션으로 이동
    Navigator.pop(context);  // 모달 닫기
    context.push('/practice/section/${DefaultIds.quickRecordSectionId}');
  }
}
```

#### 플로우 다이어그램

```
┌─────────────────────────────────────────────────────────┐
│                    녹음 버튼 클릭                        │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
          ┌───────────────────────┐
          │  현재 화면이 섹션인가? │
          └───────────┬───────────┘
                      │
           ┌──────────┴──────────┐
           │                     │
           ▼                     ▼
    ┌─────────────┐       ┌─────────────┐
    │     YES     │       │     NO      │
    │  섹션 화면  │       │  다른 화면  │
    └──────┬──────┘       └──────┬──────┘
           │                     │
           ▼                     ▼
    ┌─────────────┐       ┌─────────────┐
    │ 모달 닫기   │       │ 모달 닫기   │
    │ 녹음 시작   │       │ 디폴트 섹션 │
    │ (현재 섹션) │       │  으로 이동  │
    └─────────────┘       └─────────────┘
```

### 4. 바로 녹음 섹션 화면

디폴트 "바로 녹음" 섹션도 기존 섹션 상세 화면과 100% 동일합니다.

```
┌─────────────────────────────────────────────────────────┐
│ ←  바로 녹음                                            │
│     무제                                                │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │        00:00         [ ⏺️ ]                     │   │
│  │   ▁▂▃▅▇█▇▅▃▂▁▂▃▅▇█▇▅▃▂▁  (파형)                │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  오늘의 녹음 (3개)                              [전체↗] │
│  ┌─────────────────────────────────────────────────┐   │
│  │ ┌────┐  ┌────┐  ┌────┐                         │   │
│  │ │14:30│  │14:15│  │13:52│                       │   │
│  │ │1:24 │  │2:01 │  │0:45 │                       │   │
│  │ └────┘  └────┘  └────┘                         │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌──────────┐             │
│  │ 메트로놈  │  │   튜너   │  │ 스톱워치 │             │
│  │  ♩=120  │  │  A4     │  │  00:00  │             │
│  └──────────┘  └──────────┘  └──────────┘             │
└─────────────────────────────────────────────────────────┘
```

### 5. 녹음 파일 관리 (섹션 이동)

바로 녹음한 파일을 다른 섹션으로 이동할 수 있습니다.

#### 녹음 관리 화면 (기존 orphan_recordings_screen 확장)

```
┌─────────────────────────────────────────────────────────┐
│ ←  녹음 관리                                     [필터] │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  [ 전체 ] [ 바로녹음 ] [ 레퍼토리별 ]                   │
│                                                         │
│  ─────────── 📁 바로 녹음 (5개) ───────────            │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │  🎵 01/24 14:30                         1:24    │   │
│  │     [▶️ 재생] [📁 섹션 이동] [🗑️ 삭제]          │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │  🎵 01/24 14:15                         2:01    │   │
│  │     [▶️ 재생] [📁 섹션 이동] [🗑️ 삭제]          │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ─────────── 📁 스즈키 1권 > 작은별 (3개) ───────────  │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │  🎵 01/23 16:00                         1:45    │   │
│  │     [▶️ 재생] [📁 섹션 이동] [🗑️ 삭제]          │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

#### 섹션 이동 바텀시트

```
┌─────────────────────────────────────────────────────────┐
│  섹션 이동                                        [ X ] │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  🎵 01/24 14:30 녹음 (1:24)                            │
│  [▶️ 미리듣기]                                         │
│                                                         │
│  ─────────────────────────────────────────────────────  │
│                                                         │
│  이동할 레퍼토리 선택                                   │
│  ┌─────────────────────────────────────────────────┐   │
│  │  📁 스즈키 바이올린 1권                   [ > ] │   │
│  │  📁 모차르트 소나타                       [ > ] │   │
│  │  📁 바흐 파르티타                         [ > ] │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  섹션 선택                                              │
│  ┌─────────────────────────────────────────────────┐   │
│  │  ○ 1악장 - 전체                                 │   │
│  │  ○ 1악장 - 마디 1-16                            │   │
│  │  ● 2악장 - 전체                                 │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │                   [ 이동하기 ]                   │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 구현 계획

### Phase 1: 디폴트 레퍼토리/섹션 (0.5일)

| 작업 | 파일 | 설명 |
|------|------|------|
| 모델 확장 | `practice_repertoire.dart` | `isDefault` 필드 추가 |
| 모델 확장 | `practice_section.dart` | `isDefault` 필드 추가 |
| 상수 정의 | `default_ids.dart` | 디폴트 ID 상수 |
| 서비스 생성 | `default_repertoire_service.dart` | 디폴트 생성 로직 |
| 앱 초기화 | `main.dart` | 앱 시작 시 디폴트 확인/생성 |

### Phase 2: 연습 도구 모달 개선 (0.5일)

| 작업 | 파일 | 설명 |
|------|------|------|
| UI 수정 | `practice_tools_modal.dart` | 녹음 버튼 추가 |
| 로직 추가 | `practice_tools_modal.dart` | 컨텍스트별 분기 로직 |

### Phase 3: 녹음 관리 화면 개선 (0.5일)

| 작업 | 파일 | 설명 |
|------|------|------|
| 그룹핑 개선 | `orphan_recordings_screen.dart` | 바로녹음/레퍼토리별 그룹 |
| 바텀시트 | `recording_move_sheet.dart` | 섹션 이동 UI |

### Phase 4: 테스트 및 마무리 (0.5일)

| 작업 | 설명 |
|------|------|
| 테스트 | 다양한 화면에서 녹음 버튼 동작 확인 |
| 테스트 | 섹션 이동 기능 확인 |
| 테스트 | 디폴트 섹션 자동 생성 확인 |

**총 예상 기간: 2일**

---

## 파일 구조

```
lib/
├── core/
│   └── constants/
│       └── default_ids.dart                    # 🆕 디폴트 ID 상수
│
├── features/
│   └── practice/
│       ├── domain/
│       │   └── entities/
│       │       ├── practice_repertoire.dart    # 수정: isDefault 추가
│       │       └── practice_section.dart       # 수정: isDefault 추가
│       │
│       ├── data/
│       │   └── services/
│       │       └── default_repertoire_service.dart  # 🆕 디폴트 생성
│       │
│       └── presentation/
│           ├── widgets/
│           │   ├── practice_tools_modal.dart   # 수정: 녹음 버튼 추가
│           │   └── recording_move_sheet.dart   # 🆕 섹션 이동 시트
│           │
│           └── screens/
│               └── orphan_recordings_screen.dart  # 수정: 그룹핑 개선
```

---

## 코드 예시

### DefaultRepertoireService

```dart
// lib/features/practice/data/services/default_repertoire_service.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/practice_repertoire.dart';
import '../../domain/entities/practice_section.dart';
import '../../../core/constants/default_ids.dart';

part 'default_repertoire_service.g.dart';

@riverpod
class DefaultRepertoireService extends _$DefaultRepertoireService {
  @override
  Future<void> build() async {
    await ensureDefaultExists();
  }

  Future<void> ensureDefaultExists() async {
    final repertoireRepo = ref.read(practiceRepertoireRepositoryProvider);
    final sectionRepo = ref.read(practiceSectionRepositoryProvider);

    // 디폴트 레퍼토리 확인/생성
    final existingRepo = await repertoireRepo.getById(DefaultIds.repertoireId);
    if (existingRepo == null) {
      await repertoireRepo.create(PracticeRepertoire(
        id: DefaultIds.repertoireId,
        name: '무제',
        isDefault: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }

    // 디폴트 섹션 확인/생성
    final existingSection = await sectionRepo.getById(DefaultIds.quickRecordSectionId);
    if (existingSection == null) {
      await sectionRepo.create(PracticeSection(
        id: DefaultIds.quickRecordSectionId,
        repertoireId: DefaultIds.repertoireId,
        pieceName: '바로 녹음',
        isDefault: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }
  }
}
```

### 연습 도구 모달 수정

```dart
// lib/features/practice/presentation/widgets/practice_tools_modal.dart

class PracticeToolsModal extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('연습 도구', style: AppTypography.title2),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 🆕 녹음 버튼 (상단 중앙)
          _RecordingToolButton(
            onTap: () => _onRecordingButtonTap(context, ref),
          ),

          const SizedBox(height: 16),

          // 메트로놈 & 튜너 (기존)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MetronomeToolButton(onTap: () => _openMetronome(context)),
              _TunerToolButton(onTap: () => _openTuner(context)),
            ],
          ),

          const SizedBox(height: 16),

          // 안내 텍스트
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline,
                     size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '녹음: 섹션 화면에서는 현재 섹션에, '
                    '다른 화면에서는 바로녹음으로 이동합니다.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onRecordingButtonTap(BuildContext context, WidgetRef ref) {
    final currentRoute = GoRouterState.of(context).uri.path;
    final sectionMatch = RegExp(r'/practice/section/(.+)').firstMatch(currentRoute);

    Navigator.pop(context);  // 모달 닫기

    if (sectionMatch != null) {
      // 섹션 화면 → 녹음 시작 트리거
      final sectionId = sectionMatch.group(1)!;
      ref.read(recordingTriggerProvider.notifier).trigger(sectionId);
    } else {
      // 다른 화면 → 디폴트 섹션으로 이동
      context.push('/practice/section/${DefaultIds.quickRecordSectionId}');
    }
  }
}
```

---

## 참조 문서

| 문서 | 내용 |
|------|------|
| [practice_system.md](practice_system.md) | 연습 시스템 전체 스펙 |
| [recording_requirement.md](recording_requirement.md) | 녹음 기능 요구사항 |
| [waveform_improvements.md](waveform_improvements.md) | 파형 UI 개선 |

---

## 변경 이력

| 날짜 | 버전 | 변경 내용 |
|------|------|----------|
| 2026-01-24 | 1.0 | 초안 작성 |
