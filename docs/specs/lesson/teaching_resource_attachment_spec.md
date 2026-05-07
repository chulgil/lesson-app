# 첨부파일 시스템 스펙 — 유튜브 검색 + 선생님 녹음

> 상태: 📋 설계 완료
> Last updated: 2026-05-07
> 관련: [lesson_master.md](../lesson/lesson_master.md), [practice_master.md](../practice/practice_master.md)

**⚠️ 이 문서는 레슨 첨부파일(유튜브/녹음/외부링크)의 Single Source of Truth입니다.**

---

## 1. 현황 + 갭 분석

### 1.1 이미 구현된 것

| 기능 | 상태 | 파일 |
|------|------|------|
| TeachingResource 엔티티 (3타입) | ✅ | `teaching_resource.dart` |
| 유튜브 URL 직접 입력 + 시간 구간 | ✅ | `add_youtube_resource_sheet.dart` |
| 썸네일 자동 생성 | ✅ | `TeachingResource.thumbnailUrl()` |
| 녹음 업로드 API (Vultr S3) | ✅ | `recordings.py` + `storage.py` |
| 리소스 첨부 UI (레슨/연습) | ✅ | `resource_attachment_section.dart` |

### 1.2 누락된 것 (본 스펙 범위)

| 기능 | 상태 | 설명 |
|------|------|------|
| **유튜브 검색 팝업** | ❌ | URL 수기 입력만 가능, 검색 불가 |
| **유튜브 구간 선택 프리뷰** | ❌ | 시간 입력은 있으나 비디오 재생 프리뷰 없음 |
| **선생님 참고 녹음 업로드 플로우** | ⚠️ | Recording API 존재하나 선생님 전용 플로우 미완 |
| **녹음 스토리지 비용 최적화** | ❌ | Vultr 유료, 무료 대안 검토 필요 |

---

## 2. 유사 서비스 분석

### 2.1 유튜브 검색 + 구간 선택

| 서비스 | 유튜브 연동 | 구간 선택 | 배울 점 |
|--------|-----------|----------|---------|
| **Yousician** | 유튜브 없음 (자체 라이브러리) | 자체 트랙 구간 루프 | 정확한 구간 반복 연습 |
| **Soundslice** | 유튜브 임베드 + 싱크 | 악보 위치 ↔ 영상 위치 싱크 | 악보-영상 연동 (고급) |
| **Musescore** | 유튜브 링크 첨부 | 없음 (단순 링크) | 심플 |
| **Simply Piano** | 자체 영상 | 구간 반복 | 인앱 플레이어 |
| **Notion (노트 앱)** | 유튜브 임베드 | 타임스탬프 북마크 | 인라인 임베드 |
| **카카오톡** | 유튜브 공유 시 썸네일 프리뷰 | 없음 | OG 태그 기반 프리뷰 |

### 2.2 선생님 녹음 공유

| 서비스 | 녹음 공유 | 스토리지 | 배울 점 |
|--------|----------|---------|---------|
| **My Music Staff** | 파일 업로드 (레슨 노트 첨부) | 자체 서버 | 단순 첨부 |
| **Tonara** | 선생님 모범 연주 녹음 → 학생 앱 | 클라우드 | 모범 연주 비교 |
| **Practice+** | 선생님 녹음 + 악보 싱크 | 클라우드 | 녹음-악보 연동 |
| **SoundCloud** | 무료 업로드 + 공유 링크 | SoundCloud 서버 | 무료지만 상업 제한 |

---

## 3. 유튜브 검색 팝업 설계

### 3.1 플로우

```
[선생님이 리소스 추가]
    │
    ├── "유튜브 추가" 탭
    │     ↓
    │   ┌─── 유튜브 검색 팝업 ──────────────────┐
    │   │                                        │
    │   │  🔍 [바이올린 스케일 연습         ] [검색] │
    │   │                                        │
    │   │  ┌────────────────────────────────┐    │
    │   │  │ [썸네일] 바이올린 초급 스케일     │    │
    │   │  │         채널: 바이올린 선생님     │    │
    │   │  │         3:45                     │    │
    │   │  │                      [선택]      │    │
    │   │  ├────────────────────────────────┤    │
    │   │  │ [썸네일] G장조 스케일 연습       │    │
    │   │  │         채널: Music Academy      │    │
    │   │  │         5:12                     │    │
    │   │  │                      [선택]      │    │
    │   │  └────────────────────────────────┘    │
    │   │                                        │
    │   │  또는 [URL 직접 입력 →]                  │
    │   └────────────────────────────────────────┘
    │     ↓ 선택
    │   ┌─── 구간 선택 화면 ─────────────────────┐
    │   │                                        │
    │   │  [썸네일 프리뷰]                        │
    │   │  바이올린 초급 스케일 (3:45)             │
    │   │                                        │
    │   │  재생 구간:                              │
    │   │  시작 [1] : [20]  ~  끝 [3] : [45]     │
    │   │                                        │
    │   │  제목: [스케일 연습 참고 영상    ]        │
    │   │  메모: [2번째 포지션부터 주의...  ]       │
    │   │                                        │
    │   │  [추가]                                 │
    │   └────────────────────────────────────────┘
```

### 3.2 YouTube Data API v3 — 서버 경유

> **프론트는 YouTube API를 직접 호출하지 않는다.** 주소 검색과 동일한 서버 경유 패턴.

```
[Frontend]
    │
    └── GET /api/v1/youtube/search?query=바이올린+스케일&max_results=10
              │
[Backend: YouTubeRouter → YouTubeService]
    │
    └── YouTube Data API v3 (search.list)
        API Key: YOUTUBE_API_KEY (환경변수)
```

**백엔드 API:**

```
GET /api/v1/youtube/search?query=...&max_results=10
```

**Response:**
```json
{
  "results": [
    {
      "video_id": "abc123",
      "title": "바이올린 초급 스케일 연습",
      "channel": "바이올린 선생님",
      "thumbnail": "https://img.youtube.com/vi/abc123/mqdefault.jpg",
      "duration_seconds": 225,
      "duration_text": "3:45"
    }
  ]
}
```

**비용:** YouTube Data API v3 무료 할당량: 일 10,000 units. `search.list` = 100 units/요청 → 일 100회 검색.

**환경변수:**
```
YOUTUBE_API_KEY=your_key_here
```

### 3.3 프론트엔드 구현

**신규 위젯: `YoutubeSearchSheet`**

```dart
/// 유튜브 검색 팝업 — 검색 → 결과 선택 → 구간 선택.
class YoutubeSearchSheet extends ConsumerStatefulWidget {
  final void Function(TeachingResource resource)? onResourceCreated;
}
```

**기존 `AddYoutubeResourceSheet`와의 관계:**
- `YoutubeSearchSheet` = 새로운 진입점 (검색 기반)
- `AddYoutubeResourceSheet` = 유지 (URL 직접 입력, "URL 직접 입력 →" 링크로 접근)
- 선택 후 구간 선택은 동일 UI 재사용

### 3.4 검색 결과 아이템 디자인 (Notebook × Score)

```
┌──────────────────────────────────────┐
│ [썸네일 64x48]  바이올린 초급 스케일    │
│                 바이올린 선생님 · 3:45  │
│                              [선택]   │
└──────────────────────────────────────┘
```

- 썸네일: 64×48 (16:9), `BorderRadius.zero`
- 제목: `AppTypography.bodyMedium.w600`
- 채널+시간: `AppTypography.captionSmall`, `inkTertiary`
- [선택] 버튼: `TextButton`, `paperAccent`

---

## 4. 선생님 참고 녹음 업로드 설계

### 4.1 플로우

```
[선생님이 리소스 추가]
    │
    ├── "본인 녹음" 탭
    │     ↓
    │   ┌─── 녹음 업로드 시트 ───────────────────┐
    │   │                                         │
    │   │  🎵 참고 녹음 추가                        │
    │   │                                         │
    │   │  [🎤 새로 녹음하기]                       │
    │   │  또는                                    │
    │   │  [📁 파일에서 선택]                       │
    │   │                                         │
    │   │  ── 녹음 완료 후 ──                      │
    │   │                                         │
    │   │  ▶ 0:00 ━━━━━━━━━━ 2:15  [재생]         │
    │   │                                         │
    │   │  제목: [스케일 모범 연주       ]           │
    │   │  메모: [3번째 마디 아티큘레이션 주의]       │
    │   │                                         │
    │   │  [업로드 + 추가]                          │
    │   │                                         │
    │   │  ⏳ 업로드 중... ████░░░░ 65%            │
    │   └─────────────────────────────────────────┘
```

### 4.2 녹음 → 업로드 → 학생 제공 플로우

```
[선생님 앱]                    [백엔드]                    [학생 앱]
    │                           │                          │
    ├─ 녹음 또는 파일 선택        │                          │
    ├─ [업로드 + 추가]            │                          │
    │                           │                          │
    │ ── POST /recordings/upload │                          │
    │    + type=teacher          │                          │
    │    + file=audio.m4a        │                          │
    │                           │                          │
    │                    ┌─── ▼ ──────────────────┐        │
    │                    │ 1. Vultr S3에 파일 저장   │        │
    │                    │ 2. practice_recordings   │        │
    │                    │    레코드 생성           │        │
    │                    │ 3. teaching_resources    │        │
    │                    │    레코드 생성           │        │
    │                    │    audioUrl = presigned  │        │
    │                    └────────────────────────┘        │
    │                           │                          │
    │ ← TeachingResource 반환    │                          │
    │   (type: teacherRecording) │                          │
    │                           │                          │
    │ ── 레슨 노트에 첨부        │                          │
    │                           │                          │
    │                           │── 학생에게 알림 ─────────→│
    │                           │                          │
    │                           │   ← GET /recordings/{id}/download
    │                           │   → presigned URL (1h)   │
    │                           │                          │
    │                           │              [인앱 재생] ←│
```

### 4.3 스토리지 결정

> **현재: Vultr Object Storage (S3 호환)** — 프로젝트에 이미 통합됨.

| 옵션 | 무료 저장 | 무료 이그레스 | 상업 허용 | S3 호환 | 월 비용 |
|------|----------|-------------|----------|---------|--------|
| **Cloudflare R2** | **10GB** | **무제한 (0원)** | ✅ | ✅ | **무료** |
| Backblaze B2 | 10GB | 30GB | ✅ | ✅ | 무료 |
| Oracle OCI | 20GB | 10GB | ✅ | ✅ | 무료 |
| AWS S3 | 5GB | 100GB | ✅ | ✅ | 무료 |
| **Vultr (현재)** | 없음 | 1TB | ✅ | ✅ | **$18/월** |

**결정: Cloudflare R2로 전환 권장.**

이유:
1. **연 $216 절약** — R2 무료 10GB vs Vultr $18/월
2. **이그레스 무료** — 음악 녹음 파일은 다운로드 빈번, 이그레스 비용 0원이 핵심
3. **코드 변경 0** — 동일 `aioboto3` S3 API, `storage.py`의 endpoint/credentials만 변경
4. **영구 무료** — AWS 12개월 한정과 달리 R2 무료 티어 영구
5. **성장 경로** — 50GB 사용 시에도 R2 = $0.60/월 vs Vultr = $18/월

**마이그레이션:**
```python
# backend/app/core/config.py 변경만 필요
# 현재 (Vultr)
VULTR_STORAGE_ENDPOINT = "https://sgp1.vultrobjects.com"
# 변경 (R2)
R2_STORAGE_ENDPOINT = "https://<account_id>.r2.cloudflarestorage.com"
# storage.py의 aioboto3 코드는 동일 (S3 호환)
```

> **현재는 Vultr 유지, 다음 세션에서 R2 전환 진행.** `storage.py`의 endpoint/credentials 교체 + 환경변수 변경만으로 전환 완료.

### 4.4 파일 크기 제한 + 포맷

| 항목 | 값 |
|------|-----|
| 최대 파일 크기 | 50MB (약 25분 m4a) |
| 지원 포맷 | `.m4a` (기본), `.mp3`, `.wav` |
| 압축 | 클라이언트 측 m4a 인코딩 (기존 녹음 기능 재사용) |
| presigned URL 유효 | 1시간 |

### 4.5 백엔드 변경 사항

기존 `POST /recordings/upload`에 `resource_title`, `resource_description` 파라미터 추가:

```python
# 기존
file: UploadFile, section_id: str | None, duration_seconds: int | None, bpm: int | None

# 추가
resource_title: str | None = Form(None)      # TeachingResource 자동 생성용
resource_description: str | None = Form(None)
recording_type: str = Form("student")        # "student" | "teacher"
```

`recording_type == "teacher"` 이고 `resource_title`이 있으면:
1. 파일 업로드 (기존)
2. `practice_recordings` 저장 (기존)
3. **`teaching_resources` 자동 생성** (신규)
   - type: `teacherRecording`
   - audioUrl: presigned URL
   - title: `resource_title`
   - description: `resource_description`

---

## 5. Notebook × Score 디자인

### 5.1 유튜브 검색 시트

- 배경: `AppColors.paper`
- 검색 입력: `OutlineInputBorder`, `BorderRadius.zero`
- 결과 리스트: 1px `inkQuaternary` 구분선
- 썸네일: `BorderRadius.zero` (각진 모서리)
- [선택] 버튼: `TextButton`, `paperAccent`

### 5.2 녹음 업로드 시트

- [🎤 새로 녹음] / [📁 파일 선택]: 2개 `OutlinedButton` (full width)
- 재생 프리뷰: 웨이브폼 또는 프로그레스 바 (기존 녹음 재생 UI 재사용)
- 업로드 진행: `LinearProgressIndicator` + 퍼센트 텍스트
- [업로드 + 추가]: `FilledButton`, `paperAccent`

---

## 6. 구현 Phase

| Phase | 내용 | 파일 |
|-------|------|------|
| **A. 유튜브 검색** | `YoutubeSearchSheet` + 백엔드 `/youtube/search` | 신규 2 + 수정 1 |
| **B. 구간 선택 프리뷰** | 기존 시간 입력 UI에 썸네일 프리뷰 통합 | 수정 1 |
| **C. 녹음 업로드 시트** | `AddRecordingResourceSheet` (새로 녹음/파일 선택/업로드) | 신규 1 |
| **D. 백엔드 확장** | `recordings/upload`에 teacher 타입 + resource 자동 생성 | 수정 1 |
| **E. 리소스 추가 메뉴 통합** | "유튜브 검색" / "URL 직접 입력" / "본인 녹음" / "외부 링크" 4개 옵션 | 수정 1 |

---

## 7. Lore 결정

- **Lore-directive**: 유튜브 검색은 서버 경유 (YouTube Data API v3 키를 백엔드에서 관리).
- **Lore-directive**: 녹음 스토리지는 Vultr Object Storage 유지. Cloudflare R2는 향후 비용 최적화 시 전환 후보.
- **Lore-constraint**: 유튜브 검색 일일 한도 100회 (10,000 units / 100 units per search).
- **Lore-rejected**: SoundCloud 활용 — 상업적 사용 제한 + API 폐쇄 추세.
- **Lore-rejected**: Firebase Storage — Google 종속 + Vultr 대비 이점 없음.

---

## 8. 변경 이력

| 날짜 | 내용 |
|------|------|
| 2026-05-07 | 초판 작성 — 유튜브 검색 + 구간 선택 + 선생님 녹음 업로드 + 스토리지 결정 |
