# 레퍼토리 빠른 편집 스펙

> 버전: 1.1
> 작성일: 2026-01-24
> 상태: 설계 중
> 관련: [repertoire_detail_spec.md](./repertoire_detail_spec.md), [section_detail_spec.md](./section_detail_spec.md)

---

## 1. 개요

### 1.1 목적

레퍼토리와 섹션을 **한 화면**에서 추가/편집할 수 있는 통합 UI 제공.
기존에 분리된 레퍼토리 추가 → 섹션 추가 플로우를 단순화하여 사용자 편의성 향상.

### 1.2 문제점 (현재)

```
현재 플로우 (분리됨):
1. 레퍼토리 추가 화면 → 레퍼토리만 생성
2. 레퍼토리 상세 → 섹션 추가 버튼 클릭
3. 섹션 추가 화면 → 섹션 생성
4. (반복) 섹션 추가...

→ 최소 4단계 이상, 복잡함
→ 사용자가 사용하지 않게 됨
```

### 1.3 해결책

```
개선 플로우 (통합):
1. 빠른 편집 화면 → 레퍼토리 + 여러 섹션 동시 생성/수정/삭제

→ 1단계로 완료
→ 직관적이고 심플한 UX
```

---

## 2. 화면 구성

### 2.1 화면 목록

| 화면 | 라우트 | 용도 | 상태 |
|------|--------|------|:----:|
| 빠른 추가 | `/practice/repertoire/quick-add` | 새 레퍼토리 + 섹션 생성 | ✅ 구현 완료 |
| 빠른 편집 | `/practice/repertoire/:id/quick-edit` | 기존 레퍼토리 + 섹션 수정 | ❌ 미구현 |

### 2.2 통합 화면 레이아웃

```
┌─────────────────────────────────────────────────────────┐
│ ←  레퍼토리 편집                                        │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  📋 기본 정보                                           │
│  ─────────────────────────────────────────────────────  │
│                                                         │
│  레퍼토리 이름 *                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ 스즈키 바이올린 1권                              │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  [스즈키1] [스즈키2] [스즈키3] [바흐]  ← 빠른 선택     │
│                                                         │
│  📅 연습 기간                                           │
│  ─────────────────────────────────────────────────────  │
│  시작일: 2026.01.24                              [>]   │
│  종료일: 설정 안함 (매일 반복)                   [X]   │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  🎵 섹션 목록                                    [+ 추가]│
│  ─────────────────────────────────────────────────────  │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ 섹션 1                                      [X] │   │
│  │ ┌─────────────────────────────────────────┐     │   │
│  │ │ 곡명: 작은별 변주곡                     │     │   │
│  │ └─────────────────────────────────────────┘     │   │
│  │ [1번] [2번] [3번] [Allegro]  ← 빠른 선택       │   │
│  │ 구간: [전체] [줄] [마디]                        │   │
│  │       [1마디] ~ [4마디]                         │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ 섹션 2                                      [X] │   │
│  │ ┌─────────────────────────────────────────┐     │   │
│  │ │ 곡명: Minuet                            │     │   │
│  │ └─────────────────────────────────────────┘     │   │
│  │ 구간: [전체] [줄] [마디]                        │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │             [+ 섹션 추가]                        │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              [ 저장하기 ]                        │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  🗄️ 관리                           ← 편집 모드에서만   │
│  ─────────────────────────────────────────────────────  │
│  [아카이브]  [레퍼토리 삭제]                            │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 3. 기능 상세

### 3.1 추가 모드 vs 편집 모드

| 기능 | 추가 모드 | 편집 모드 |
|------|:--------:|:--------:|
| 레퍼토리 이름 | ✅ 입력 | ✅ 수정 |
| 연습 기간 | ✅ 설정 | ✅ 수정 |
| 섹션 추가 | ✅ | ✅ |
| 섹션 수정 | - | ✅ |
| 섹션 삭제 | ✅ (미저장) | ✅ (확인 필요) |
| 레퍼토리 아카이브 | - | ✅ |
| 레퍼토리 삭제 | - | ✅ |

### 3.2 섹션 카드 필드

| 필드 | 필수 | 설명 |
|------|:----:|------|
| 곡명 | ✅ | 곡/연습곡 이름 |
| 구간 유형 | ✅ | 전체 / 줄 / 마디 |
| 시작/끝 범위 | 조건부 | 줄/마디 선택 시 |
| 섹션 별칭 | ❌ | 선택적 이름 |
| N회 반복 | ❌ | 2~10회 (기본: 없음) |
| 목표 연습시간 | ❌ | 분 단위 목표 설정 |

> **참고**: 섹션은 별도 날짜 없이 **레퍼토리 기간을 상속**합니다.
> 타 서비스 분석 결과, 개별 항목에 날짜 설정은 사용자 혼란을 유발함.
> → [날짜 관리 분석](../../proposal/repertoire_date_management_analysis.md)

### 3.3 빠른 선택 (Suggestions)

**레퍼토리:**
- 스즈키 1~6권
- 크로이처 에튀드
- 세브시크
- 바흐 파르티타/소나타
- 스케일/아르페지오

**섹션 곡명:**
- 1번, 2번, 3번...
- Allegro, Andante, Minuet
- Etude No.1, Variation
- 도입부, 주제, 코다

---

## 4. 구현 계획

### 4.1 현재 상태

| 화면 | 파일 | 상태 |
|------|------|:----:|
| 빠른 추가 | `quick_add_screen.dart` | ✅ 구현 완료 |
| 빠른 편집 | `quick_edit_screen.dart` | ❌ 미구현 |

### 4.2 구현 작업

#### Phase 1: 빠른 편집 화면 생성 (1일)

| 작업 | 설명 |
|------|------|
| 화면 생성 | `quick_edit_screen.dart` 신규 생성 |
| 라우트 추가 | `/practice/repertoire/:id/quick-edit` |
| 데이터 로딩 | 기존 레퍼토리 + 섹션 로드 |
| 저장 로직 | 변경사항 감지 및 업데이트 |

#### Phase 2: 빠른 추가 화면 개선 (0.5일)

| 작업 | 설명 |
|------|------|
| UI 통일 | `SectionHeader` 위젯 적용 |
| 연습 기간 | `DateRangeSection` 추가 |
| 섹션 옵션 | N회 반복, 목표 시간 추가 |

#### Phase 3: 통합 (0.5일)

| 작업 | 설명 |
|------|------|
| 공통 위젯 | 섹션 카드 위젯 분리 |
| 네비게이션 | 상세 화면에서 빠른 편집 연결 |

---

## 5. 파일 구조

```
lib/features/practice/presentation/
├── screens/
│   ├── quick_add_screen.dart          # ✅ 빠른 추가 (구현 완료)
│   ├── quick_edit_screen.dart         # 🆕 빠른 편집 (신규)
│   ├── add_repertoire_screen.dart     # 기존 (유지)
│   └── edit_repertoire_screen.dart    # 기존 (유지)
│
└── widgets/
    └── repertoire_form/               # 🆕 공통 폼 위젯
        ├── repertoire_section_card.dart   # 섹션 카드
        └── repertoire_suggestions.dart    # 빠른 선택 칩

docs/specs/practice/
├── repertoire_detail_spec.md          # 기존 스펙
├── repertoire_quick_edit_spec.md      # 🆕 이 문서
└── section_detail_spec.md             # 섹션 스펙
```

---

## 6. 라우트

```dart
// lib/core/router/app_routes.dart
class AppRoutes {
  static const quickAddRepertoire = '/practice/repertoire/quick-add';       // ✅ 기존
  static const quickEditRepertoire = '/practice/repertoire/:id/quick-edit'; // 🆕 신규
}

// lib/core/router/routes/practice_routes.dart
GoRoute(
  path: AppRoutes.quickEditRepertoire,
  name: 'quickEditRepertoire',
  builder: (context, state) {
    final repertoireId = state.pathParameters['id']!;
    final studentId = state.uri.queryParameters['studentId'] ?? '';
    return QuickEditScreen(
      repertoireId: repertoireId,
      studentId: studentId,
    );
  },
),
```

---

## 7. 접근 경로

### 빠른 추가 진입점
- 연습 탭 → + 버튼 → 빠른 추가
- 레퍼토리 목록 → + 버튼 → 빠른 추가

### 빠른 편집 진입점
- 레퍼토리 상세 → 편집 버튼 → 빠른 편집
- 레퍼토리 카드 → 더보기 → 편집 → 빠른 편집

---

## 8. 섹션 리스트 구현

### 8.1 데이터 구조

```dart
// 섹션 입력 데이터 (추가/편집 공통)
class SectionInputData {
  final String? id;                    // 기존 섹션 ID (편집 시)
  final TextEditingController pieceNameController;
  SectionRangeType rangeType;
  int startMeasure;
  int endMeasure;
  int startLine;
  int endLine;
  int? repeatCount;                    // N회 반복
  int? targetPracticeMinutes;          // 목표 시간
  bool isDeleted;                      // 삭제 표시 (편집 시)

  bool get isNew => id == null;        // 새로 추가된 섹션
  bool get isModified => /* 변경 감지 */;
}
```

### 8.2 리스트 UI 구조

```
┌─────────────────────────────────────────────────────────┐
│  🎵 섹션 목록                                    [+ 추가]│
│  ─────────────────────────────────────────────────────  │
│                                                         │
│  ListView.builder (shrinkWrap: true)                    │
│  ├── 섹션 카드 1 (기존, 수정됨)         [되돌리기] [X] │
│  ├── 섹션 카드 2 (기존, 변경 없음)               [X] │
│  ├── 섹션 카드 3 (새로 추가됨)                   [X] │
│  └── + 섹션 추가 버튼                                  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 8.3 섹션 카드 컴포넌트

```dart
class SectionEditCard extends StatelessWidget {
  final int index;
  final SectionInputData data;
  final bool canDelete;              // 최소 1개는 유지
  final VoidCallback onDelete;
  final VoidCallback? onRevert;      // 수정된 경우만

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.space4),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더: 섹션 N + 삭제 버튼
            _buildHeader(),

            // 곡명 입력 + 빠른 선택 칩
            _buildPieceNameField(),

            // 구간 유형 선택 (전체/줄/마디)
            _buildRangeTypeSelector(),

            // 범위 입력 (줄/마디 선택 시)
            if (data.rangeType != SectionRangeType.full)
              _buildRangeInput(),

            // 섹션 별칭 (선택)
            _buildAliasField(),
          ],
        ),
      ),
    );
  }
}
```

### 8.4 리스트 동작

| 동작 | 추가 모드 | 편집 모드 |
|------|:--------:|:--------:|
| 섹션 추가 | 리스트에 새 카드 추가 | 리스트에 새 카드 추가 (isNew=true) |
| 섹션 삭제 | 즉시 리스트에서 제거 | `isDeleted=true` 표시, 저장 시 삭제 |
| 섹션 수정 | - | 변경 추적, 되돌리기 가능 |
| 순서 변경 | ReorderableListView | ReorderableListView |

### 8.5 저장 로직 (편집 모드)

```dart
Future<void> _submit() async {
  // 1. 레퍼토리 업데이트
  await updateRepertoire(repertoireId, name, dates);

  // 2. 삭제된 섹션 처리
  for (final section in _sections.where((s) => s.isDeleted)) {
    await deleteSection(section.id!);
  }

  // 3. 새 섹션 생성
  for (final section in _sections.where((s) => s.isNew && !s.isDeleted)) {
    await createSection(repertoireId, section);
  }

  // 4. 수정된 섹션 업데이트
  for (final section in _sections.where((s) => !s.isNew && s.isModified)) {
    await updateSection(section.id!, section);
  }

  // 5. Provider 무효화
  ref.invalidate(repertoireProvider(repertoireId));
  ref.invalidate(studentRepertoiresProvider(studentId));
}
```

### 8.6 변경 감지

```dart
// 저장 버튼 활성화 조건
bool get hasChanges {
  // 레퍼토리 정보 변경
  if (_nameChanged || _datesChanged) return true;

  // 섹션 추가/삭제
  if (_sections.any((s) => s.isNew || s.isDeleted)) return true;

  // 섹션 수정
  if (_sections.any((s) => s.isModified)) return true;

  return false;
}

// 뒤로가기 시 확인
Future<bool> _onWillPop() async {
  if (!hasChanges) return true;

  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('변경사항이 있습니다'),
      content: Text('저장하지 않고 나가시겠습니까?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text('취소')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text('나가기')),
      ],
    ),
  ) ?? false;
}
```

---

## 9. 변경 이력

| 날짜 | 버전 | 변경 내용 |
|------|------|----------|
| 2026-01-24 | 1.0 | 초안 작성 - 통합 편집 화면 스펙 |
| 2026-01-24 | 1.1 | 섹션 날짜 필드 제거 명시 (레퍼토리 기간 상속) |
