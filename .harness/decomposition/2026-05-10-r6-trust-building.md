# Decomposition — r6-trust-building

> 스펙: .harness/spec/2026-05-10-r6-trust-building.md (locked)

## DAG

```
Job 1 (BE API) ──→ Job 2 (FE 캐시 + 강제 업데이트) ──→ Job 3 (프로필 메뉴 통합)
```

Job 1이 완료되어야 Job 2에서 Remote 리포지토리 연결 가능. Job 3은 Job 2 이후 통합.

## Jobs

### Job 1: 백엔드 `GET /api/v1/app/version` API
- **AC**: AC-1, AC-6
- **파일**:
  - `backend/app/models/app_version.py` (신규: AppVersion, AppNews, AppRoadmap 모델)
  - `backend/alembic/versions/YYYYMMDD_add_app_version_tables.py` (신규: 마이그레이션)
  - `backend/app/api/v1/app_version.py` (신규: 엔드포인트)
  - `backend/app/api/v1/__init__.py` (수정: 라우터 등록)
  - `backend/scripts/seeds/scenarios/app_version.py` (신규: 시드 데이터)
  - `backend/tests/test_app_version_api.py` (신규: API 테스트)
- **커밋 단위**: 1커밋 (모델 + 마이그레이션 + API + 시드 + 테스트)

### Job 2: FE 버전 캐시 + 강제 업데이트
- **AC**: AC-2, AC-3, AC-4, AC-6
- **의존**: Job 1
- **파일**:
  - `frontend/lib/features/settings/domain/entities/app_release.dart` (수정: minVersion 추가)
  - `frontend/lib/features/settings/data/repositories/remote_app_release_repository.dart` (수정: min_version 파싱)
  - `frontend/lib/features/settings/data/repositories/cached_app_release_repository.dart` (신규: SharedPreferences 1시간 캐시)
  - `frontend/lib/features/settings/presentation/screens/force_update_screen.dart` (신규)
  - `frontend/lib/core/router/app_router.dart` (수정: 강제 업데이트 라우트 가드)
  - `frontend/lib/features/settings/presentation/providers/app_release_provider.dart` (수정: 캐시 리포지토리 사용)
- **커밋 단위**: 2커밋 (엔티티+캐시 / 강제업데이트 화면+라우트)

### Job 3: 프로필 메뉴 통합
- **AC**: AC-5, AC-7
- **의존**: Job 2
- **파일**:
  - `frontend/lib/features/profile/presentation/widgets/profile_tab.dart` (수정: "새 소식" 메뉴 추가)
  - 기존 `NewsRoadmapScreen` + 라우트 이미 구현됨 → 연결만
- **커밋 단위**: 1커밋
