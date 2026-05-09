# Spec — r6-trust-building

> 날짜: 2026-05-10 | 상태: draft
> 인터뷰: .harness/interview/2026-05-10-r6-trust-building.md
> 관련 스펙: docs/specs/settings/app_rating_prompt_spec.md (리뷰 프롬프트 v2 — 별도 완료)

## 1. 목표 (한 문장)

"방치 앱" 인식을 방지하기 위해 버전 체크 + 업데이트 배너 + 새 소식/로드맵을 백엔드 API 기반으로 전환하고, 프로필 메뉴에 통합한다.

## 2. 성공 기준 (측정 가능)

- [ ] AC-1: `GET /api/v1/app/version` 이 latest, min, news, roadmap 을 JSON 으로 반환한다
- [ ] AC-2: 앱 버전 < latest 이면 로그인 화면에 업데이트 배너가 노출된다 (현재 위치 유지)
- [ ] AC-3: 앱 버전 < min 이면 ForceUpdateScreen 이 홈을 차단한다
- [ ] AC-4: 버전 체크 결과가 SharedPreferences 에 1시간 캐시된다
- [ ] AC-5: 프로필 탭 지원 섹션에 "새 소식" 메뉴가 존재하고 탭하면 NewsRoadmapScreen 이 열린다
- [ ] AC-6: API 실패 시 앱이 정상 작동한다 (배너 미노출, graceful degradation)
- [ ] AC-7: 백엔드 테스트 통과, 프론트엔드 `flutter analyze` 0 에러

## 3. 사용자 시나리오 (Given/When/Then)

### 시나리오 1: 선택 업데이트 배너
- Given: 사용자 앱 버전 1.0.0, 서버 latest 1.2.0, min 1.0.0
- When: 로그인 화면 진입
- Then: "새 버전 1.2.0" 배너 노출, 탭하면 새 소식 화면 이동
- Note: 업무 화면(대시보드)에는 배너 미노출 — 사용자는 업무 중 앱 소식을 원하지 않음

### 시나리오 2: 강제 업데이트
- Given: 사용자 앱 버전 0.9.0, 서버 min 1.0.0
- When: 앱 실행
- Then: ForceUpdateScreen 이 홈을 차단, 스토어 이동 버튼만 표시

### 시나리오 3: 최신 버전
- Given: 사용자 앱 버전 1.2.0, 서버 latest 1.2.0
- When: 홈 대시보드 진입
- Then: 업데이트 배너 미노출

### 시나리오 4: API 실패
- Given: 서버 응답 없음 또는 5xx
- When: 앱 실행
- Then: 배너 미노출, 앱 정상 작동

### 시나리오 5: 캐시 유효
- Given: 마지막 체크 30분 전
- When: 홈 대시보드 진입
- Then: API 호출 없이 캐시 데이터 사용

### 시나리오 6: 프로필 메뉴 진입
- Given: 사용자가 프로필 탭에 있음
- When: "새 소식" 메뉴 탭
- Then: NewsRoadmapScreen 으로 이동, 새 소식 + 로드맵 표시

## 4. 스키마 / 인터페이스

### 새 엔티티 (백엔드)

```python
# backend/app/models/app_version.py

class AppVersion(Base):
    __tablename__ = "app_versions"

    id: str                    # UUID
    platform: str              # "ios" | "android"
    latest_version: str        # "1.2.0"
    min_version: str           # "1.0.0"
    release_notes: str | None  # 릴리즈 노트 (텍스트)
    published_at: datetime     # UTC
    created_at: datetime
    updated_at: datetime

class AppNews(Base):
    __tablename__ = "app_news"

    id: str                    # UUID
    title: str                 # "레슨 운영 흐름 안정화"
    summary: str               # 한 줄 요약
    link: str | None           # 외부 링크 (선택)
    published_at: datetime     # UTC
    is_active: bool            # 노출 여부

class AppRoadmap(Base):
    __tablename__ = "app_roadmap"

    id: str                    # UUID
    title: str                 # "악보 PDF 첨부"
    summary: str               # 한 줄 요약
    status: str                # "planned" | "inProgress" | "shipped"
    display_order: int         # 정렬 순서
    target_date: date | None   # 예상 완료일 (선택)
    is_active: bool            # 노출 여부
```

### 4.1 도메인 용어 (Ubiquitous Language)

> glossary §10 에 등록 완료 (2026-05-10)

| 한글 | 영문 | FE 클래스 | BE 클래스 | 신규/기존 |
|------|------|-----------|-----------|----------|
| 앱 버전 스냅샷 | AppVersionSnapshot | `AppVersionSnapshot` | — | 기존 |
| 새 소식 | AppNewsItem | `AppNewsItem` | `AppNews` | 기존 |
| 로드맵 항목 | AppRoadmapItem | `AppRoadmapItem` | `AppRoadmap` | 기존 |
| 릴리즈 스냅샷 | AppReleaseSnapshot | `AppReleaseSnapshot` | — | 기존 |
| 강제 업데이트 | ForceUpdate | `ForceUpdateScreen` | — | 신규 |
| 앱 버전 | AppVersion | — | `AppVersion` | 신규 (BE only) |

### API 엔드포인트

| Method | Path | Headers | Response |
|--------|------|---------|----------|
| GET | `/api/v1/app/version` | `X-App-Version: 1.0.0`, `X-App-Platform: ios` | 아래 참조 |

**Response 200:**
```json
{
  "version": {
    "latest_version": "1.2.0",
    "min_version": "1.0.0",
    "release_notes": "레슨 통계 추가"
  },
  "news": [
    {
      "id": "uuid",
      "title": "레슨 운영 흐름 안정화",
      "summary": "스케줄 변경 요청과 취소...",
      "published_at": "2026-05-07T00:00:00Z",
      "link": null
    }
  ],
  "roadmap": [
    {
      "id": "uuid",
      "title": "악보 PDF 첨부",
      "summary": "선생님 홈에서...",
      "status": "planned",
      "target_date": null
    }
  ]
}
```

- 인증 불필요 (공개 엔드포인트)
- `X-App-Version` 헤더 없으면 latest 만 반환 (min 비교 불가)

### 기존 FE 엔티티 변경

`AppVersionSnapshot` 에 `minVersion` 필드 추가:
```dart
class AppVersionSnapshot {
  final String currentVersion;
  final String? buildNumber;
  final String? latestVersion;
  final String? minVersion;      // ← 추가
  final DateTime checkedAt;

  bool get hasUpdate => ...;
  bool get requiresForceUpdate => // ← 추가
      minVersion != null &&
      _compareVersions(currentVersion, minVersion!) < 0;
}
```

## 5. 비기능 요구사항

- **성능**: 버전 API p95 < 100ms (단순 DB 조회)
- **캐시**: SharedPreferences 1시간 TTL, 앱 재실행 시 캐시 우선
- **보안**: 공개 엔드포인트, 인증 불필요. min_version 은 서버에서만 관리 (클라이언트 조작 불가)
- **관측성**: API 호출 횟수 로그 (향후 CDN 캐시 검토용)

## 6. 아키텍처 결정

- **채택**: 백엔드 DB 기반 버전/뉴스/로드맵 관리 → 앱 업데이트 없이 콘텐츠 변경 가능
- **거절**: 하드코딩 JSON (현재 LocalAppReleaseRepository) — 매번 앱 배포 필요, 강제 업데이트 불가능
- **거절**: Firebase Remote Config — 추가 의존성, 이미 백엔드 인프라 존재
- **채택**: SharedPreferences 캐시 — Hive 보다 가벼움, 단순 key-value 저장에 적합
- **거절**: Hive 캐시 — 오버킬, 이미 sync 큐 등에 사용 중이라 box 관리 복잡

## 7. 품질 계약 (이 feature 에 적용)

- 단위 테스트 커버리지: ≥ 80%
  - 백엔드: API 엔드포인트 테스트, 버전 비교 로직 테스트
  - 프론트엔드: 버전 비교 로직, 캐시 TTL 로직
- Widget smoke test: ForceUpdateScreen 1개
- E2E: 수동 (버전 조작 → 배너/강제 화면 확인)
- Lint 예외: 없음

## 8. 위험과 완화

| 위험 | 영향도 | 완화 |
|------|--------|------|
| API 다운 시 강제 업데이트 차단 불가 | 중 | 캐시된 min_version 으로 폴백, API 실패 시 앱 정상 작동 |
| 잘못된 min_version 설정 시 전체 사용자 차단 | 고 | 시드/어드민에서만 설정, min < latest 검증 |
| iOS in_app_review 연간 3회 제한 | 저 | 앱 레벨 90일 쿨다운으로 충분히 희소 |

## 9. 범위 외

- 어드민 대시보드 (초기에는 DB 직접 또는 시드 스크립트)
- Push 알림 기반 업데이트 강제
- 사용자 투표 기반 로드맵 우선순위
- 리뷰 프롬프트 (별도 스펙 `app_rating_prompt_spec.md` v2 로 완료)

## 10. 구현 작업 목록 (갭 기반)

### Job 1: 백엔드 API (BE)
- [ ] `app_versions`, `app_news`, `app_roadmap` 모델
- [ ] Alembic 마이그레이션 (SQLite guard 포함)
- [ ] `GET /api/v1/app/version` 엔드포인트
- [ ] 시드 데이터 (초기 버전 + 뉴스 2건 + 로드맵 3건)
- [ ] API 테스트

### Job 2: FE 버전 캐시 + 강제 업데이트
- [ ] `AppVersionSnapshot` 에 `minVersion` + `requiresForceUpdate` 추가
- [ ] `RemoteAppReleaseRepository` 에서 min_version 파싱
- [ ] SharedPreferences 1시간 캐시 래퍼
- [ ] `ForceUpdateScreen` 위젯
- [ ] 앱 시작 시 버전 체크 → 강제 업데이트 라우팅

### Job 3: FE 프로필 메뉴 통합
- [ ] 프로필 탭 지원 섹션에 "새 소식" 메뉴 추가
- [ ] `AppUpdateBanner` 는 로그인 화면 유지 (업무 화면에 앱 소식 미노출 원칙)
- [ ] 라우트 연결 확인
