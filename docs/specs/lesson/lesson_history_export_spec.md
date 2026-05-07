# 레슨 이력 내보내기 스펙 (CSV / PDF)

> 작성일: 2026-05-07
> 상태: 신규 스펙 (미구현)
> 관련 스펙: [lesson_master.md](./lesson_master.md), [subscription_master.md](../subscription/subscription_master.md)
> 관련 엔티티: Lesson, LessonBooking, Subscription, Student, Teacher

---

## 목차

1. [개요](#1-개요)
2. [사용 시나리오](#2-사용-시나리오)
3. [내보내기 데이터 정의](#3-내보내기-데이터-정의)
4. [CSV 포맷](#4-csv-포맷)
5. [PDF 템플릿](#5-pdf-템플릿)
6. [API 계약](#6-api-계약)
7. [프론트엔드 UX](#7-프론트엔드-ux)
8. [구현 단계](#8-구현-단계)
9. [변경 이력](#9-변경-이력)

---

## 1. 개요

### 1.1 배경

학부모/학생이 레슨 이력을 외부로 내보내야 하는 경우가 있다.

| 목적 | 설명 |
|------|------|
| **교육비 세액공제** | 연말정산 시 교육비 지출 증빙 (학원비 공제) |
| **학교 제출 서류** | 방과후 활동 증빙, 포트폴리오 첨부 |
| **개인 기록 관리** | 레슨 이력 백업, 전 선생님 이력 보관 |
| **선생님 정산 증빙** | 레슨 완료 횟수 기준 정산 시 근거 자료 |

### 1.2 핵심 원칙

- **데이터 소유권**: 학생/학부모는 자신의 레슨 이력을 항상 내보낼 수 있다.
- **선생님 관점**: 학생별 수업 이력 일괄 내보내기 (정산, 증빙).
- **CSV = 가공용, PDF = 제출용**: 두 형식의 목적을 명확히 구분한다.
- **한글 Excel 호환**: CSV는 UTF-8 BOM + CRLF 줄바꿈으로 Excel(Windows) 호환.

---

## 2. 사용 시나리오

### 2.1 학부모 연말정산 흐름

```
학부모: 앱 → 내 자녀 레슨 내역 → [내보내기]
    │
    ├── 연도 선택 (2025년)
    ├── 형식 선택 (PDF — 세무사 제출용)
    │
    ▼
PDF 다운로드
    │
    └── 세무사 / 홈택스에 첨부
```

### 2.2 선생님 월별 정산 흐름

```
선생님: 학생 상세 → [레슨 이력 내보내기]
    │
    ├── 기간 선택 (이번 달)
    ├── 형식 선택 (CSV — 스프레드시트 가공)
    │
    ▼
CSV 다운로드 → Excel/Numbers에서 열기 → 정산
```

### 2.3 학생 포트폴리오 흐름

```
학생: 내 레슨 → [내보내기]
    │
    ├── 전체 기간 선택
    ├── PDF 형식
    │
    ▼
PDF — 악기 학습 이력 정리본
```

---

## 3. 내보내기 데이터 정의

### 3.1 포함 데이터

| 필드 | 설명 | CSV 컬럼명 | PDF 표시 |
|------|------|-----------|---------|
| 레슨 날짜 | `lesson_date` | `레슨날짜` | O |
| 요일 | 계산값 | `요일` | O |
| 시작 시간 | `start_time` | `시작시간` | O |
| 종료 시간 | `end_time` | `종료시간` | O |
| 수업 시간(분) | 계산값 | `수업시간(분)` | O |
| 학생 이름 | `student.name` | `학생명` | O (선생님 뷰) |
| 선생님 이름 | `teacher.name` | `선생님명` | O |
| 악기 | `student.instrument` | `악기` | O |
| 레슨 유형 | `lesson_type` | `레슨유형` | O |
| 레슨 상태 | `status` | `상태` | O |
| 레슨 장소 | `location` | `장소` | O (선택) |
| 수강권 명 | `subscription.name` | `수강권` | O |
| 수강료 | `subscription.amount / total_lessons` | `수강료(원)` | O (선택) |
| 노트 여부 | `has_teacher_notes` | `노트작성여부` | X |

### 3.2 요약 정보 (PDF / CSV 하단)

| 항목 | 설명 |
|------|------|
| 조회 기간 | 내보내기 요청 기간 |
| 총 레슨 횟수 | 기간 내 전체 레슨 수 |
| 완료 횟수 | status = `completed` |
| 취소 횟수 | status = `cancelled` |
| 노쇼 횟수 | status = `no_show` |
| 출석률 | 완료 / (완료 + 노쇼) × 100% |
| 총 수업 시간 | 완료 레슨의 총 분 합산 |

### 3.3 레슨 상태 표기 (한글)

| 내부 값 | CSV 표기 | PDF 표기 |
|---------|---------|---------|
| `completed` | 완료 | ✓ 완료 |
| `cancelled` | 취소 | 취소 |
| `no_show` | 노쇼 | 노쇼 |
| `pending` | 예정 | 예정 |
| `scheduled` | 확정 | 확정 |

---

## 4. CSV 포맷

### 4.1 파일 규격

| 항목 | 값 |
|------|-----|
| 인코딩 | UTF-8 with BOM (`\ufeff`) |
| 줄바꿈 | CRLF (`\r\n`) |
| 구분자 | 쉼표 (`,`) |
| 텍스트 묶음 | 큰따옴표 (`"`) |
| 날짜 형식 | `YYYY-MM-DD` |
| 시간 형식 | `HH:MM` |
| 금액 형식 | 정수 (원), 쉼표 없음 |

> BOM 필수 이유: Windows Excel에서 한글이 깨지는 문제 방지. Numbers(macOS)는 BOM 있어도 정상 처리.

### 4.2 헤더 행 (한국어)

```csv
레슨날짜,요일,시작시간,종료시간,수업시간(분),선생님명,악기,레슨유형,상태,수강권,수강료(원)
```

### 4.3 샘플 출력

```csv
﻿레슨날짜,요일,시작시간,종료시간,수업시간(분),선생님명,악기,레슨유형,상태,수강권,수강료(원)
2026-05-07,수,15:00,16:00,60,김선생,바이올린,정기,완료,5월 정기 8회권,40000
2026-04-30,수,15:00,16:00,60,김선생,바이올린,정기,완료,5월 정기 8회권,40000
2026-04-23,수,15:00,15:30,30,김선생,바이올린,정기,노쇼,5월 정기 8회권,0
```

### 4.4 파일명 규칙

```
레슨이력_{학생명}_{YYYYMMDD}-{YYYYMMDD}.csv

# 예시
레슨이력_홍길동_20260101-20261231.csv
레슨이력_전체학생_20260501-20260531.csv   (선생님: 전체 학생)
```

---

## 5. PDF 템플릿

### 5.1 Notebook × Score 디자인 적용

PDF 헤더는 앱의 [Notebook × Score 디자인 시스템](../design/notebook/README.md)을 따른다.

```
┌─────────────────────────────────────────────────────────┐
│  [Vermillion 왼쪽 여백선 #A83E3A]                         │
│                                                          │
│  ♩ LESSONAZA                      [Playfair Display]    │
│  ─────────────────────────────────────────────────────  │
│                                                          │
│  레 슨 이 력 보 고 서              [Playfair, 22pt bold] │
│  LESSON HISTORY REPORT           [Pretendard, 11pt]     │
│                                                          │
│  학생: 홍길동   악기: 바이올린   선생님: 김선생              │
│  조회 기간: 2026년 1월 ~ 2026년 5월 (5개월)               │
│  출력일: 2026년 5월 7일                                   │
│  ─────────────────────────────────────────────────────  │
│                                                          │
│  ── 요약 ─────────────────────────────────────────────  │
│  총 레슨    완료    취소    노쇼    출석률    총 수업시간    │
│     42      38      3       1      97.4%    38시간       │
│                                                          │
│  ─────────────────────────────────────────────────────  │
│  번호   날짜           시간          유형   상태   수강권   │
│  ─────────────────────────────────────────────────────  │
│   I.   2026-01-08 (수) 15:00-16:00  정기   ✓완료  1월권  │
│  II.   2026-01-15 (수) 15:00-16:00  정기   ✓완료  1월권  │
│  III.  2026-01-22 (수) 15:00-16:00  정기   ✓완료  1월권  │
│   ...                                                    │
│  ─────────────────────────────────────────────────────  │
│                                                          │
│  * 본 이력은 Lessonaza 앱에서 기록된 레슨 데이터입니다.     │
│  * 법적 효력은 없으며 참고용으로만 사용하십시오.             │
│                                                          │
│                         Powered by Lessonaza            │
└─────────────────────────────────────────────────────────┘
```

### 5.2 레슨 번호 표기

PDF 내 레슨에는 **로마숫자** 인덱스를 사용한다 (Notebook × Score 시그니처 §1.1 #2).

```
I.  2026-01-08 ...
II. 2026-01-15 ...
...
XLII. 2026-05-07 ...
```

### 5.3 다중 페이지 처리

- 레슨 수 > 30건: 자동 페이지 분리
- 각 페이지 하단: 페이지 번호 (`Page N of M`)
- 요약 섹션은 항상 1페이지에 위치

### 5.4 파일명 규칙

```
레슨이력보고서_{학생명}_{YYYYMMDD}-{YYYYMMDD}.pdf

# 예시
레슨이력보고서_홍길동_20260101-20261231.pdf
```

---

## 6. API 계약

### 6.1 엔드포인트 목록

| Method | Path | 역할 | 권한 |
|--------|------|------|------|
| `GET` | `/api/v1/lessons/export` | CSV 또는 PDF 생성 후 다운로드 URL 반환 | 선생님/학생/학부모 |

### 6.2 쿼리 파라미터 상세

| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|---------|------|:---:|--------|------|
| `format` | `csv` \| `pdf` | O | — | 내보내기 형식 |
| `from` | `YYYY-MM-DD` | O | — | 조회 시작일 |
| `to` | `YYYY-MM-DD` | O | — | 조회 종료일 |
| `student_id` | string | X | — | 특정 학생 필터 (선생님만) |
| `lesson_type` | `trial` \| `regular` \| `package` \| `all` | X | `all` | 레슨 유형 필터 |
| `include_fee` | boolean | X | `false` | 수강료 컬럼 포함 여부 |
| `include_location` | boolean | X | `false` | 장소 컬럼 포함 여부 |

**파라미터 제약:**
- `from` ~ `to` 최대 기간: **3년** (과도한 데이터 방지)
- `from` > `to` 시 400 오류

### 6.3 응답 형식

**비동기 방식 (권장):**

> 레슨 수가 많거나 PDF 생성 시간이 길 수 있으므로, 즉각 반환 대신 작업 ID를 발급하고 준비되면 Presigned URL을 반환한다.

1단계 — 내보내기 요청:

```http
GET /api/v1/lessons/export?format=pdf&from=2026-01-01&to=2026-05-07&student_id=xxx
```

응답 (202 Accepted):

```json
{
  "export_id": "uuid",
  "status": "processing",
  "estimated_seconds": 5,
  "poll_url": "/api/v1/lessons/export/uuid/status"
}
```

2단계 — 상태 폴링:

```http
GET /api/v1/lessons/export/{export_id}/status
```

응답 — 처리 중 (200):

```json
{
  "export_id": "uuid",
  "status": "processing"
}
```

응답 — 완료 (200):

```json
{
  "export_id": "uuid",
  "status": "ready",
  "download_url": "https://storage.vultr.com/...",
  "expires_at": "2026-05-07T16:00:00Z",
  "filename": "레슨이력보고서_홍길동_20260101-20260507.pdf",
  "record_count": 42
}
```

응답 — 실패 (200):

```json
{
  "export_id": "uuid",
  "status": "failed",
  "error": "레슨 데이터를 찾을 수 없습니다."
}
```

**동기 방식 (CSV 소량 데이터, ≤ 100건):**

```http
GET /api/v1/lessons/export?format=csv&from=2026-04-01&to=2026-04-30
```

응답 (200 OK):

```
Content-Type: text/csv; charset=utf-8
Content-Disposition: attachment; filename*=UTF-8''%EB%A0%88%EC%8A%A8%EC%9D%B4%EB%A0%A5_...csv
```

> 100건 초과이거나 format=pdf인 경우에는 항상 비동기 방식 사용.

### 6.4 권한 검증

| 요청자 | 허용 데이터 |
|--------|-----------|
| 선생님 | 자신이 담당한 학생들의 레슨. `student_id` 미지정 시 전체 학생 |
| 학생 | 본인의 레슨만 |
| 학부모 | 연결된 자녀의 레슨만 |

### 6.5 내보내기 이력 저장 (선택적)

```sql
CREATE TABLE lesson_export_jobs (
    id              VARCHAR(36) PRIMARY KEY,
    requester_id    VARCHAR(36) NOT NULL,    -- User.id
    requester_role  VARCHAR(20) NOT NULL,    -- teacher | student | parent
    student_id      VARCHAR(36),             -- 학생 필터 (선생님 전체 내보내기 시 NULL)
    format          VARCHAR(5) NOT NULL,     -- csv | pdf
    from_date       DATE NOT NULL,
    to_date         DATE NOT NULL,
    lesson_type     VARCHAR(20) DEFAULT 'all',
    status          VARCHAR(20) DEFAULT 'pending',  -- pending | processing | ready | failed
    file_key        VARCHAR(500),            -- Vultr S3 key
    record_count    INTEGER,
    error_message   VARCHAR(500),
    expires_at      TIMESTAMP,               -- Presigned URL 만료
    created_at      TIMESTAMP DEFAULT NOW(),
    completed_at    TIMESTAMP
);
```

---

## 7. 프론트엔드 UX

### 7.1 진입점

| 화면 | 위치 | 역할 |
|------|------|------|
| 레슨 목록 화면 | 상단 우측 `[⋯]` → 내보내기 | 학생/학부모 전체 이력 |
| 학생 상세 화면 | 하단 액션 → 이력 내보내기 | 선생님: 특정 학생 이력 |
| 설정 → 내 데이터 | 내 레슨 이력 내보내기 | 학생/학부모 자체 내보내기 |

### 7.2 ExportBottomSheet (공통)

```
┌──────────────────────────────────────────┐
│  ▔▔▔▔▔▔                                  │
│  레슨 이력 내보내기                         │
│                                          │
│  ── 기간 선택 ──                          │
│  ○ 최근 3개월     ● 최근 6개월            │
│  ○ 올해 전체      ○ 직접 선택...          │
│                                          │
│  [2026-01-01]   ~   [2026-05-07]         │
│                                          │
│  ── 형식 ──                              │
│  ┌────────────────┐  ┌────────────────┐  │
│  │  📄 CSV         │  │  📋 PDF         │  │
│  │  Excel 가공용   │  │  제출 · 인쇄용  │  │
│  └────────────────┘  └────────────────┘  │
│                                          │
│  ── 옵션 ──                              │
│  ☑ 수강료 포함   ☐ 레슨 장소 포함        │
│                                          │
│  ┌──────────────────────────────────┐    │
│  │          내보내기 시작            │    │
│  └──────────────────────────────────┘    │
└──────────────────────────────────────────┘
```

### 7.3 내보내기 진행 상태 UI

```
┌──────────────────────────────────────────┐
│  ▔▔▔▔▔▔                                  │
│                                          │
│         ♩                               │
│    레슨 이력을 준비 중입니다...             │
│                                          │
│    ████████████░░░░  65%                 │
│    42개 레슨 처리 중                      │
│                                          │
│    [취소]                                │
└──────────────────────────────────────────┘
```

**완료 시:**

```
┌──────────────────────────────────────────┐
│                                          │
│  ✓  준비 완료!                            │
│  레슨이력보고서_홍길동_20260101-20260507.pdf │
│  42개 레슨 · 38시간                       │
│                                          │
│  ┌──────────────┐  ┌──────────────────┐  │
│  │   공유하기    │  │   다운로드       │  │
│  └──────────────┘  └──────────────────┘  │
│                                          │
│  * 다운로드 링크는 1시간 후 만료됩니다.     │
└──────────────────────────────────────────┘
```

### 7.4 Flutter 구현 가이드

```dart
// 진입: ExportBottomSheet
class ExportBottomSheet extends ConsumerWidget {
  final String? studentId;  // null이면 본인 전체
}

// Provider (Riverpod codegen)
@riverpod
class LessonExportNotifier extends _$LessonExportNotifier {
  Future<void> requestExport({
    required ExportFormat format,
    required DateTime from,
    required DateTime to,
    String? studentId,
    bool includeFee = false,
  }) async { ... }
}

// 상태
sealed class ExportState {
  const factory ExportState.idle() = _Idle;
  const factory ExportState.processing(double progress) = _Processing;
  const factory ExportState.ready(ExportResult result) = _Ready;
  const factory ExportState.failed(String message) = _Failed;
}
```

**파일 공유/저장 구현:**

```dart
// iOS/Android: Share Sheet
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

Future<void> shareExportedFile(String downloadUrl, String filename) async {
  final response = await http.get(Uri.parse(downloadUrl));
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(response.bodyBytes);
  await Share.shareXFiles([XFile(file.path)], subject: filename);
}
```

---

## 8. 구현 단계

### Phase 1 (MVP) — CSV 내보내기

**대상:** 학생/선생님의 레슨 이력 CSV 직접 다운로드

| # | 작업 | 예상 공수 |
|---|------|---------|
| 1-1 | `GET /api/v1/lessons/export?format=csv` 동기 방식 | 1일 |
| 1-2 | CSV 생성 로직 (UTF-8 BOM, 한글 컬럼명) | 0.5일 |
| 1-3 | 권한 검증 (선생님/학생/학부모 분기) | 0.5일 |
| 1-4 | `ExportBottomSheet` (Flutter) — 기간 선택 + CSV | 1일 |
| 1-5 | 파일 공유 (share_plus) | 0.5일 |
| 1-6 | 테스트 | 0.5일 |

### Phase 2 — PDF 내보내기 (비동기)

| # | 작업 | 예상 공수 |
|---|------|---------|
| 2-1 | DB 마이그레이션: `lesson_export_jobs` 테이블 | 0.5일 |
| 2-2 | 비동기 export job 생성 + 폴링 엔드포인트 | 1일 |
| 2-3 | PDF 생성 (WeasyPrint, Notebook × Score 템플릿) | 2일 |
| 2-4 | Vultr S3 업로드 + Presigned URL | 0.5일 |
| 2-5 | Flutter: 진행 중 UI + 완료 알림 | 1일 |
| 2-6 | 테스트 (다양한 기간/데이터 크기) | 1일 |

### Phase 3 (미래 후보)

- 이메일로 직접 전송 (SendGrid 연동)
- 학원 전체 월별 리포트 (학원 관리자용)
- 자동 연간 리포트 생성 (매년 1월 1일 전년도 요약)

---

## 9. 변경 이력

| 날짜 | 변경 내용 | 작성자 |
|------|---------|-------|
| 2026-05-07 | 최초 작성 | Claude |
