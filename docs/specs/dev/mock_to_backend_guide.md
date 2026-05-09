# Mock → Backend 전환 가이드

> 작성일: 2026-03-31
> 최종 업데이트: 2026-05-10
> 상태: 런타임 전환 구현 완료

## 1. 전환 구조

### 런타임 데이터 모드 전환 (v2, 2026-05-10)

로그인 방식에 따라 Mock/Remote 모드가 **런타임에** 자동 결정됩니다.
더 이상 `--dart-define=USE_MOCK=false` 빌드 분리가 필요하지 않습니다.

```
로그인 화면
├── Google 계정 → setMockMode(false) → 실제 OAuth + Remote 레포지토리
├── Kakao로 시작 → (준비 중, 추후 실제 OAuth)
├── Apple 계정 → (준비 중, 추후 실제 OAuth)
│
└── [DEV] 테스트 계정 (debug 빌드만 표시)
    └── setMockMode(true) → Mock 레포지토리
```

**핵심 메커니즘**: `DataMode` Riverpod Notifier가 런타임 상태를 관리하고,
모든 repository provider가 `ref.watch(mockDataModeProvider)`로 모드를 관찰합니다.
모드 변경 시 keepAlive provider가 자동으로 재생성됩니다.

```bash
# 단일 빌드로 Mock + Remote 모두 테스트 가능
flutter run \
  --dart-define=API_BASE_URL=https://beta-lesson.chulgil.me/api/v1 \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id> \
  --dart-define=GOOGLE_IOS_CLIENT_ID=<ios-client-id>
```

### 핵심 파일

| 파일 | 역할 |
|------|------|
| `core/config/environment.dart` | 컴파일 타임 기본값 (API URL, 클라이언트 ID) |
| `core/providers/repository_provider.dart` | `DataMode` Notifier + Mock/Remote 전환 헬퍼 3종 |
| `core/network/api_client.dart` | HTTP 클라이언트 (토큰 자동 첨부) |
| `auth/presentation/screens/login_screen.dart` | 로그인 시 `dataModeProvider.notifier.setMockMode()` 호출 |

---

## 2. 도메인별 전환 상태

### Ready (Mock + Remote 모두 있음)

| 도메인 | Mock | Remote | Backend API |
|--------|:----:|:------:|:-----------:|
| lessons | 3 | 3 | 20 endpoints |
| practice | 4 | 4 | 15 endpoints |
| students | 4 | 4 | 10 endpoints |
| subscription | 6 | 6 | 18 endpoints |
| schedule | 4 | 4 | 7 endpoints |
| follow | 2 | 2 | - |
| gamification | 1 | 1 | 2 endpoints |
| relationship | 1 | 1 | 7 endpoints |
| student_home | 1 | 1 | - |
| analytics | 1 | 1 | - |

### Remote-Only (Backend 전용)

| 도메인 | Remote | Backend API | 비고 |
|--------|:------:|:-----------:|------|
| auth | 1 | 6 endpoints | OAuth 전용, Mock 불필요 |
| settings | 1 | 16 endpoints | Backend 설정 전용 |
| notifications | 1 | 4 endpoints | FCM + 인앱 |
| parent_home | 1 | 6 endpoints | 학부모 전용 |
| invite | 1 | 8 endpoints | 초대/연결 |
| search | 2 | - | 검색 |

### Mock-Only (프론트엔드 개발용)

| 도메인 | 비고 |
|--------|------|
| home | 대시보드 집계 (여러 API 조합) |
| profile | 프로필 편집 (settings API 활용) |
| calendar | UI 전용 (별도 API 불필요) |

---

## 3. 전환 단계

### Step 1: 백엔드 서버 실행

```bash
cd backend
cp .env.example .env  # 환경변수 설정
docker-compose up -d  # PostgreSQL + Redis
uv run alembic upgrade head  # DB 마이그레이션
uv run uvicorn app.main:app --reload
```

### Step 2: 시드 데이터 (선택)

```bash
uv run python -m scripts.seeds.runner --preset full --reset
```

### Step 3: Flutter 앱 실행

```bash
cd frontend
flutter run \
  --dart-define=API_BASE_URL=http://localhost:8000/api/v1
# USE_MOCK 플래그 불필요 — 로그인 시 자동 전환
```

### Step 4: 로그인

- **실제 백엔드 테스트**: Google 계정으로 시작 → 자동으로 Remote 모드
- **Mock 데이터 테스트**: DEV 계정 (debug 빌드만 표시) → 자동으로 Mock 모드
- **Backend dev-login API**: `GET /api/v1/auth/dev-login?role=teacher` (직접 토큰 발급)

---

## 4. Beta 서버 연결

```bash
flutter run \
  --dart-define=API_BASE_URL=https://beta-lesson.chulgil.me/api/v1 \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=312292843644-xxx.apps.googleusercontent.com
# Google 로그인 → 자동 Remote, DEV 계정 → 자동 Mock
```

Beta 서버: `108.61.162.25` (Vultr VPS)

---

## 5. 전환 체크리스트

### 인프라
- [ ] PostgreSQL 실행 + DB 생성
- [ ] Redis 실행
- [ ] `.env` 파일 설정
- [ ] Alembic 마이그레이션 실행
- [ ] 시드 데이터 적재

### 인증
- [ ] Google OAuth 클라이언트 ID 설정
- [ ] Dev-login으로 토큰 발급 테스트
- [ ] JWT 토큰 자동 갱신 확인

### 핵심 기능 테스트
- [ ] 레슨 CRUD
- [ ] 학생 관리
- [ ] 수강권 발급/사용
- [ ] 스케줄 조회
- [ ] 연습 기록

### 선택 기능 테스트
- [ ] 알림 목록 조회
- [ ] 게이미피케이션 포인트
- [ ] 팔로우/언팔로우
- [ ] 출석 관리

---

## 6. 주의사항

- **Hive 캐시**: Mock → Backend 전환 시 기존 Hive 데이터와 충돌 가능. 앱 삭제 후 재설치 권장.
- **인증 토큰**: Mock 모드에서는 인증 불필요, Backend 모드에서는 로그인 필수.
- **데이터 형식**: Mock은 Dart 객체 직접 생성, Backend은 JSON 직렬화. `fromJson()` 누락 주의.
- **타임존**: DB는 UTC 저장, 프론트엔드는 KST 표시. 변환 로직 확인.
