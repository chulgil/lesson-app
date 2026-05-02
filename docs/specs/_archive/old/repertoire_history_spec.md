# 레퍼토리 히스토리 스펙

> 작성일: 2026-03-02
> 상태: 설계 완료
> Pain Point: A(2년간 뭘 배웠는지 기록 없음)
> 관련 문서: [repertoire_detail_spec.md](repertoire_detail_spec.md)
> 엔티티: `PracticeRepertoire` in [practice_repertoire.dart](../../../frontend/lib/features/practice/domain/entities/practice_repertoire.dart)

<!-- @uses: tokens/colors, tokens/typography -->

---

## 1. 개요

### 1.1 목적

"작년에 무슨 곡 했죠?" → 레퍼토리를 월별 그룹 타임라인으로 시각화하여
**2년간 배운 곡의 흐름을 한눈에 파악**할 수 있게 한다.

### 1.2 핵심 결정사항

| 항목 | 결정 |
|------|------|
| 뷰 형식 | 월별 그룹 타임라인 (최신 → 과거) |
| 진입 경로 | 연습 탭 > [히스토리] 아이콘 |
| 데이터 소스 | PracticeRepertoire.startDate/endDate/isArchived |
| 활성/아카이브 | 활성 레퍼토리 + 아카이브 레퍼토리 통합 표시 |
| 기간 표시 | "2025년 3월 ~ 6월 (4개월)" |
| 녹음 연동 | 레퍼토리별 대표 녹음 재생 가능 |

---

## 2. 기존 활용 엔티티

### 2.1 PracticeRepertoire

**파일**: `frontend/lib/features/practice/domain/entities/practice_repertoire.dart`

```dart
class PracticeRepertoire {
  final String id;
  final String studentId;
  final String name;               // 곡명 ("바흐 소나타 1번")
  final String? description;
  final DateTime startDate;        // ← 시작일 (타임라인 기준)
  final DateTime? endDate;         // ← 종료일 (null = 진행 중)
  final bool isArchived;           // ← 아카이브 여부
  final DateTime? archivedAt;      // ← 아카이브 시점
  final int? sortOrder;
  final List<PracticeSection> sections;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Computed
  bool get isActive => !isArchived;
  double get completionRate => ...;   // 완료율 (0.0~1.0)
}
```

### 2.2 타임라인에 활용하는 필드

| 필드 | 타임라인 용도 |
|------|-------------|
| `name` | 곡명 표시 |
| `startDate` | 시작 월 기준 그룹핑 |
| `endDate` | 종료 월 표시 (null = "진행 중") |
| `isArchived` | 아카이브 뱃지 |
| `completionRate` | 완성도 프로그레스 바 |
| `sections` | 섹션 수 표시 |

---

## 3. 사용자 플로우

### 3.1 진입

```
연습 탭 (StudentPracticeTab)
    │
    └─ 상단 바 [📋 히스토리] 아이콘 버튼
        │
        └─ RepertoireHistoryScreen (풀스크린)
```

### 3.2 타임라인 탐색

```
RepertoireHistoryScreen
    │
    ├─ 상단: 통계 요약 카드
    │   ├─ 전체 레퍼토리: 15곡
    │   ├─ 완료: 12곡
    │   └─ 진행 중: 3곡
    │
    └─ 월별 타임라인 (스크롤)
        ├─ 2026년 1월 (진행 중)
        │   ├─ 🎵 비발디 사계 — 여름 1악장   [진행 중 85%]
        │   └─ 🎵 스케일 연습 G major         [진행 중 60%]
        │
        ├─ 2025년 11월
        │   └─ 🎵 모차르트 소나타 K.304      [완료 ✓]
        │                                     3개월 (9월~11월)
        │
        ├─ 2025년 9월
        │   └─ 🎵 바흐 소나타 1번 1악장      [완료 ✓]
        │                                     6개월 (3월~9월)
        │
        └─ 2025년 3월
            └─ 🎵 바흐 소나타 1번 1악장 시작  [시작]
```

### 3.3 레퍼토리 상세 진입

```
타임라인 항목 탭
    │
    └─ RepertoireDetailScreen (기존 화면)
        ├─ 섹션 목록
        ├─ 녹음 목록
        └─ 연습 기록
```

---

## 4. 화면 스펙

### 4.1 히스토리 메인 화면

```
┌─────────────────────────────────────────┐
│ ← 레퍼토리 히스토리              [필터] │
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │ 🎵 전체 15곡  ✅ 완료 12  📝 진행 3 │ │  ← 요약 카드
│ └─────────────────────────────────────┘ │
│                                         │
│ ── 2026년 1월 (진행 중) ──────────────  │  ← 월 헤더
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ 🎵 비발디 사계 — 여름 1악장        │ │
│ │    1월~ (진행 중)                   │ │
│ │    섹션 3개 · 녹음 7개             │ │
│ │    ████████████░░░░ 85%            │ │  ← 완성도 바
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ 🎵 스케일 연습 G major             │ │
│ │    1월~ (진행 중)                   │ │
│ │    섹션 2개 · 녹음 3개             │ │
│ │    ██████████░░░░░░ 60%            │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ── 2025년 11월 ───────────────────────  │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ 🎵 모차르트 소나타 K.304     [✓]  │ │
│ │    9월~11월 (3개월)                │ │
│ │    섹션 4개 · 녹음 12개            │ │
│ │    ████████████████ 100%           │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ── 2025년 9월 ────────────────────────  │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ 🎵 바흐 소나타 1번 1악장     [✓]  │ │
│ │    3월~9월 (6개월)                 │ │
│ │    섹션 5개 · 녹음 23개            │ │
│ │    ████████████████ 100%           │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ── 2025년 3월 ────────────────────────  │
│ ...                                     │
└─────────────────────────────────────────┘
```

### 4.2 필터 옵션

```
┌─────────────────────────────────────────┐
│ 필터                                    │
├─────────────────────────────────────────┤
│ 상태                                    │
│ [전체] [진행 중] [완료] [아카이브]      │
│                                         │
│ 기간                                    │
│ [전체] [올해] [작년] [사용자 지정]      │
└─────────────────────────────────────────┘
```

### 4.3 타임라인 항목 상세

| 요소 | 표시 내용 |
|------|----------|
| 곡명 | PracticeRepertoire.name |
| 기간 | "3월~9월 (6개월)" or "1월~ (진행 중)" |
| 섹션 수 | sections.length |
| 녹음 수 | 모든 섹션 녹음 합산 |
| 완성도 | completionRate × 100% 프로그레스 바 |
| 상태 뱃지 | [✓] 완료 / [진행 중] / [아카이브] |

### 4.4 상태표

| 상태 | 타임라인 표시 |
|------|-------------|
| 활성 + 진행 중 | "1월~ (진행 중)" + 프로그레스 바 |
| 활성 + endDate 있음 | "3월~9월 (6개월)" + [✓] |
| 아카이브 | "3월~9월 (6개월)" + [✓] + 흐린 스타일 |
| startDate만 있음 (endDate null) | "3월~ (진행 중)" |
| 시작/종료 같은 달 | "3월 (1개월 미만)" |

---

## 5. 데이터 모델

### 5.1 타임라인 뷰 모델 (신규)

```dart
/// 월별 그룹 타임라인
class RepertoireTimeline {
  final List<MonthGroup> monthGroups;
  final int totalCount;
  final int completedCount;
  final int inProgressCount;

  RepertoireTimeline({required List<PracticeRepertoire> repertoires}) :
    totalCount = repertoires.length,
    completedCount = repertoires.where((r) => r.endDate != null).length,
    inProgressCount = repertoires.where((r) => r.endDate == null).length,
    monthGroups = _groupByStartMonth(repertoires);

  static List<MonthGroup> _groupByStartMonth(List<PracticeRepertoire> reps) {
    final grouped = <String, List<PracticeRepertoire>>{};
    for (final rep in reps) {
      final key = '${rep.startDate.year}-${rep.startDate.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(rep);
    }
    return grouped.entries
        .map((e) => MonthGroup(
              yearMonth: e.key,
              year: int.parse(e.key.split('-')[0]),
              month: int.parse(e.key.split('-')[1]),
              repertoires: e.value,
            ))
        .toList()
      ..sort((a, b) => b.yearMonth.compareTo(a.yearMonth)); // newest first
  }
}

/// 월별 그룹
class MonthGroup {
  final String yearMonth;     // "2025-03"
  final int year;
  final int month;
  final List<PracticeRepertoire> repertoires;

  String get label => '$year년 $month월';
  bool get hasInProgress => repertoires.any((r) => r.endDate == null);
}

/// 타임라인 항목 (레퍼토리 + 계산된 메타데이터)
class RepertoireTimelineItem {
  final PracticeRepertoire repertoire;

  String get durationLabel {
    final start = repertoire.startDate;
    final end = repertoire.endDate;
    if (end == null) {
      return '${start.month}월~ (진행 중)';
    }
    final months = (end.year - start.year) * 12 + (end.month - start.month);
    if (months == 0) return '${start.month}월 (1개월 미만)';
    return '${start.month}월~${end.month}월 (${months}개월)';
  }

  int get totalRecordingCount =>
      repertoire.sections.fold(0, (sum, s) => sum + s.recordings.length);

  bool get isCompleted => repertoire.endDate != null;
}
```

---

## 6. 파일 구조

```
frontend/lib/features/practice/
├── domain/
│   └── entities/
│       ├── practice_repertoire.dart         ← 기존 (startDate/endDate/isArchived)
│       └── repertoire_timeline.dart         ← (신규) 타임라인 뷰 모델
├── presentation/
│   ├── providers/
│   │   ├── repertoire_archive_provider.dart ← 기존 (active/archived 조회)
│   │   └── repertoire_history_provider.dart ← (신규) 타임라인 Provider
│   ├── screens/
│   │   ├── student_practice_tab.dart        ← [히스토리] 버튼 추가
│   │   └── repertoire_history_screen.dart   ← (신규) 히스토리 화면
│   └── widgets/
│       ├── repertoire_timeline_card.dart     ← (신규) 타임라인 항목 카드
│       ├── month_group_header.dart           ← (신규) 월 구분 헤더
│       └── history_summary_card.dart         ← (신규) 상단 요약 카드
```

---

## 7. Provider / Repository

### 7.1 타임라인 Provider

```dart
/// 학생의 전체 레퍼토리 타임라인
@riverpod
Future<RepertoireTimeline> repertoireTimeline(
  RepertoireTimelineRef ref,
  String studentId,
) async {
  final repository = ref.watch(practiceRepositoryProvider);
  final active = await repository.getActiveRepertoires(studentId);
  final archived = await repository.getArchivedRepertoires(studentId);
  final all = [...active, ...archived];
  return RepertoireTimeline(repertoires: all);
}

/// 필터링된 타임라인
@riverpod
Future<RepertoireTimeline> filteredRepertoireTimeline(
  FilteredRepertoireTimelineRef ref,
  String studentId, {
  RepertoireFilter filter = const RepertoireFilter(),
}) async {
  final timeline = await ref.watch(repertoireTimelineProvider(studentId).future);
  return timeline.applyFilter(filter);
}
```

### 7.2 필터 모델

```dart
class RepertoireFilter {
  final RepertoireStatus? status;  // all | inProgress | completed | archived
  final DateRange? dateRange;      // all | thisYear | lastYear | custom

  const RepertoireFilter({this.status, this.dateRange});
}

enum RepertoireStatus { all, inProgress, completed, archived }
```

---

## 8. 에러/엣지 케이스

| 상황 | 동작 |
|------|------|
| 레퍼토리 0개 | "아직 레퍼토리가 없습니다" 빈 상태 |
| startDate 없는 레거시 데이터 | createdAt을 startDate로 대체 |
| 같은 달 시작/종료 | "3월 (1개월 미만)" 표시 |
| 매우 긴 기간 (2년+) | 연도별 구분선 추가 |
| 아카이브 후 복원 | isArchived → false, 활성 섹션으로 복귀 |
| 녹음 0개 레퍼토리 | "녹음 0개" 표시, 프로그레스 바 유지 |

---

## 9. 구현 체크리스트

### Phase 1: 월별 타임라인

- [ ] RepertoireTimeline / MonthGroup / RepertoireTimelineItem 모델
- [ ] repertoireTimeline Provider
- [ ] RepertoireHistoryScreen
- [ ] RepertoireTimelineCard 위젯 (곡명/기간/완성도)
- [ ] MonthGroupHeader 위젯 (월 구분선)
- [ ] HistorySummaryCard 위젯 (전체/완료/진행 중)
- [ ] StudentPracticeTab에 [히스토리] 버튼 추가
- [ ] 라우팅 추가 (GoRoute)

### Phase 2: 필터 + 검색

- [ ] RepertoireFilter 모델
- [ ] 상태 필터 (전체/진행 중/완료/아카이브)
- [ ] 기간 필터 (전체/올해/작년/사용자 지정)
- [ ] 곡명 검색

### Phase 3: 선생님 뷰

- [ ] 선생님 > 학생 상세에서 타임라인 조회
- [ ] 학생 간 레퍼토리 비교 (향후)

---

## 10. 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.0 | 2026-03-02 | 초안 — 월별 그룹 타임라인 + 필터 + 선생님 뷰 설계 |
