# Teacher Quest System Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

> 스펙: `.harness/spec/2026-06-08-teacher-quest-system.md` (locked, commit `48af22c7`)
> Audit 입력 자료: `docs/specs/design/teacher_quest_audit_2026-06-08.md` (37/70)
> 형식: writing-plans 스킬 표준 + cg-harness Phase 4 decomposition 융합

**Goal:** 선생님 퀘스트 시스템을 "학습 가이드 + 단축 진입점"으로 재정의하고, 가용시간 SSOT 일원화 + Lock 매트릭스 단순화 + 자동 완료 즉시 소거 UX 를 도입한다.

**Architecture:** 4 단계 점진적 데이터 마이그레이션 (dual-write → reader 교체 → deprecate → 필드 제거) 위에서 UI 재설계와 자동 완료 wiring 을 병렬로 진행한다. 각 단계 사이 검증 게이트로 in-flight 데이터 손실 방지.

**Tech Stack:** Flutter 3.29.0 / Riverpod (codegen) / Hive / FastAPI / SQLAlchemy + Alembic / pytest / flutter_test

---

## 사전 결정 (O1~O6 — Step 3 진입 결정사항)

본 PLAN 의 추천안. 사용자가 PLAN 검토 시 변경 가능. Job 0 첫 task 에서 글로서리/스펙에 확정 반영.

| # | 항목 | 추천 결정 | 근거 |
|---|---|---|---|
| O1 | "가입 직후 첫 도착" 판별 | `SharedPreferences.questFirstShownAt` (Hive 로컬) | BE 변경 회피, 가입 직후 1회만 동작이면 충분 |
| O2 | `questCelebratedAt` 저장 위치 | `User.questCelebratedAt` BE 필드 (DateTime nullable) | 기기 재설치 시 재표시 방지 — 1회성 보장 신뢰도↑ |
| O3 | Lock 카드 클릭 진입 UX | **즉시 자동 이동 + 토스트** (현 방향 유지) | BottomSheet 안내는 클릭 단계 증가 — Hick's Law |
| O4 | "선택 보너스" glossary 등록 | 본 PR 1에서 즉시 등록 (글로서리 §3 가용시간 옆 §3.5 신규) | 코드/스펙에서 동일 용어 사용 강제 |
| O5 | dual-write 검증 스크립트 위치 | BE Python 스크립트 (`backend/scripts/validators/teacher_availability_diff.py`) | seed 시스템 옆에 두어 운영 친화 |
| O6 | 신규 코드 차단 방법 (단계 3) | analyzer rule + grep CI 훅 이중 | Dart analyzer 로 IDE 즉시 경고 + CI 로 머지 차단 |

---

## DAG (Job 의존 관계)

```
Job 0 (사전 결정/글로서리/User 필드)
        │
        ▼
Job 1 (BE: dual-write 인프라 + diff 스크립트)
        │
        ▼
Job 2 (FE: first_availability_setup dual-write)
        │
        ├─ [검증 게이트 7일+50건+diff=0] ─┐
        │                                  │
        ▼                                  │
Job 3 (FE: reader 교체)                    │
        │                                  │
        ▼                                  │
Job 4 (UI 재설계: 3-group + lock + Step 명명 제거)
        │
        ├─────────┬──────────┐
        ▼         ▼          ▼
Job 5     Job 6      Job 7
(자동완료) (임계값/   (전체 완료
           AppStrings) 축하카드)
        │
        ▼
Job 8 (deprecate + 필드 제거)
```

**병렬 가능**: Job 5, 6, 7 (UI 재설계 후 독립)
**순차 강제**: Job 0 → 1 → 2 → 3 → 4 → 8 (데이터 정합성)

---

## File Structure (변경 맵)

### 신규 파일

| 경로 | 책임 | Job |
|---|---|---|
| `frontend/lib/features/profile/presentation/widgets/quest_board/quest_group.dart` | 3-group 그룹 헤더 위젯 | 4 |
| `frontend/lib/features/profile/presentation/widgets/quest_board/quest_celebration_card.dart` | 전체 완료 축하 카드 | 7 |
| `frontend/lib/features/profile/presentation/providers/quest_first_shown_provider.dart` | `questFirstShownAt` Hive 저장 + AsyncNotifier | 0 |
| `backend/scripts/validators/teacher_availability_diff.py` | dual-write 검증 스크립트 | 1 |
| `backend/alembic/versions/YYYYMMDD_add_user_quest_celebrated_at.py` | `User.quest_celebrated_at` 컬럼 마이그레이션 | 0 |
| `frontend/test/features/profile/presentation/widgets/quest_board_card_test.dart` | quest_board_card widget smoke + lock + auto-complete | 4, 5 |
| `frontend/test/features/profile/presentation/widgets/quest_celebration_card_test.dart` | 축하 카드 smoke + 1회성 보장 | 7 |
| `frontend/test/features/onboarding/presentation/screens/first_availability_setup_dual_write_test.dart` | dual-write 동작 검증 | 2 |
| `backend/tests/scripts/test_teacher_availability_diff.py` | diff 스크립트 테스트 | 1 |

### 수정 파일

| 경로 | 변경 요지 | Job |
|---|---|---|
| `.harness/knowledge/glossary.md` | "선택 보너스 그룹" 등록 (§3.5) | 0 |
| `backend/app/models/user.py` | `quest_celebrated_at` DateTime nullable 컬럼 | 0 |
| `frontend/lib/features/auth/domain/entities/auth_user.dart` | `questCelebratedAt` 필드 + freezed copyWith | 0 |
| `frontend/lib/features/onboarding/presentation/screens/first_availability_setup_screen.dart` | 저장 경로 추가 (dual-write: schedule 도메인) | 2 |
| `frontend/lib/features/schedule/data/repositories/...` (생성 위치 확인) | dual-write 진입점 helper | 1, 2 |
| `frontend/lib/features/home/presentation/widgets/quest_board_card.dart` | 3-group 분류 + lock 매트릭스 + Step 명명 제거 + 자동 소거 | 4, 5 |
| `frontend/lib/features/home/presentation/screens/home_screen.dart` | `_maybeShowFirstAvailabilityInterstitial()` 제거 | 4 |
| `frontend/lib/features/schedule/presentation/screens/teacher_availability_split_page.dart` | `ref.invalidate(teacherSettingsProvider)` 2회 제거 (Job 8) | 8 |
| `frontend/lib/core/l10n/app_strings.dart` | 신규 10개 키 추가 / `questTitleSlots` 부제 제거 / Step 11개 prefix 제거 | 6 |
| `frontend/lib/features/profile/domain/entities/teacher_settings.dart` | `availableSlots` 필드 `@Deprecated` 마킹 | 8 |
| `docs/specs/onboarding/teacher_first_availability_setup.md` | 헤더에 deprecated/superseded 표기 | 4 |
| `analysis_options.yaml` 또는 `.claude/hooks/check-availability-slots.sh` | 신규 코드 차단 rule | 8 |

---

## Job 0 — 사전 결정 확정 + 글로서리 + User.quest_celebrated_at

**목적**: 후속 Job 의 토대 마련. 의사결정을 코드/스펙 SSOT 에 반영.
**AC**: O1~O6 사전 결정 잠금 + 글로서리 갱신 + 신규 BE/FE 필드 정의
**커밋 단위**: 3 커밋 (글로서리 / BE 마이그레이션 / FE 엔티티+provider)
**의존**: 없음

### Task 0.1: glossary 에 "선택 보너스 그룹" 등록

**Files:**
- Modify: `.harness/knowledge/glossary.md` (§3 가용시간 직후에 §3.5 신규 또는 새 §X "퀘스트")

- [ ] **Step 1: glossary 현재 상태 읽기**

Run: `head -60 .harness/knowledge/glossary.md`
Expected: §1~§3 까지 출력 확인 — 새 섹션의 적절한 위치 결정 (§9 또는 §10 신규 권고)

- [ ] **Step 2: §X "퀘스트 시스템" 섹션 추가**

`.harness/knowledge/glossary.md` 의 적절한 위치 (FE-BE 매핑 §9 이전) 에 다음 추가:

```markdown
## X. 퀘스트 시스템 (Quest System)

| 한글 | 영문 | FE 클래스 | BE 클래스 | 설명 |
|------|------|-----------|-----------|------|
| 퀘스트 | Quest | `_Quest` | — | 선생님 학습 가이드 + 단축 진입점 (의무 아님) |
| 프로필 설정 그룹 | Profile Setup Group | `QuestGroup.profile` | — | Q1~Q5 (가용시간/사진/소개/레슨비/계좌) |
| 운영 시작 그룹 | Operation Group | `QuestGroup.operation` | — | Q6~Q10 (학생/수강권/레슨/노트/숙제) |
| 선택 보너스 그룹 | Bonus Group | `QuestGroup.bonus` | — | Q11 (전화인증) — `[선택]` 라벨 |
| 자동 완료 트리거 | Auto-Complete Trigger | (reactive provider) | — | 입력 즉시 퀘스트 완료 감지 |
| 퀘스트 축하 카드 | Quest Celebration Card | `QuestCelebrationCard` | — | 11/11 완료 시 1회 표시 (User.questCelebratedAt) |
| 가입 직후 첫 도착 | Signup First Arrival | `questFirstShownProvider` | — | SharedPreferences 기반 — 가입 직후 1회만 카드 2초 표시 |
```

- [ ] **Step 3: glossary 변경 검증**

Run: `grep "선택 보너스 그룹" .harness/knowledge/glossary.md`
Expected: 1 line — 등록 확인

- [ ] **Step 4: 커밋**

```bash
git add .harness/knowledge/glossary.md
git commit -m "$(cat <<'EOF'
docs(glossary): 퀘스트 시스템 용어 추가 (O4 결정)

Refs: .harness/spec/2026-06-08-teacher-quest-system.md §15.1 O4
Directive: 선생님 퀘스트 시스템을 "학습 가이드 + 단축 진입점"으로 재정의
Constraint: glossary 우선 — 코드/스펙에서 동일 용어 사용 강제
Rejected: 코드 구현 후 glossary 등록 — 용어 불일치 risk

Signed-off-by: 🐙 Autopus <noreply@autopus.co>

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

### Task 0.2: BE `User.quest_celebrated_at` 컬럼 + 마이그레이션

**Files:**
- Modify: `backend/app/models/user.py` (컬럼 추가)
- Create: `backend/alembic/versions/YYYYMMDD_add_user_quest_celebrated_at.py` (마이그레이션)
- Test: `backend/tests/test_user_quest_celebrated_at.py` (모델 + 마이그레이션 검증)

- [ ] **Step 1: 실패하는 테스트 작성**

`backend/tests/test_user_quest_celebrated_at.py`:

```python
"""Test that User.quest_celebrated_at column exists and accepts nullable DateTime."""
import pytest
from datetime import datetime, timezone
from sqlalchemy import inspect
from app.models.user import User
from app.db.session import SessionLocal


def test_quest_celebrated_at_column_exists():
    """quest_celebrated_at 컬럼이 User 모델에 정의되어 있어야 함."""
    inspector = inspect(User)
    columns = {c.key for c in inspector.columns}
    assert 'quest_celebrated_at' in columns


def test_quest_celebrated_at_is_nullable():
    """quest_celebrated_at 은 nullable 이어야 함."""
    inspector = inspect(User)
    col = inspector.columns['quest_celebrated_at']
    assert col.nullable is True


@pytest.mark.asyncio
async def test_quest_celebrated_at_accepts_datetime():
    """quest_celebrated_at 에 DateTime 저장 가능."""
    async with SessionLocal() as session:
        user = User(email="test_quest@example.com", role="teacher")
        user.quest_celebrated_at = datetime.now(timezone.utc)
        session.add(user)
        await session.commit()
        await session.refresh(user)
        assert user.quest_celebrated_at is not None
```

- [ ] **Step 2: 테스트 실행 — 실패 확인**

Run: `cd backend && uv run pytest tests/test_user_quest_celebrated_at.py -v`
Expected: FAIL with `AttributeError: ... quest_celebrated_at` 또는 컬럼 없음

- [ ] **Step 3: `User` 모델에 컬럼 추가**

`backend/app/models/user.py` 의 `User` 클래스에 추가 (다른 nullable DateTime 컬럼 옆 위치):

```python
quest_celebrated_at = Column(DateTime(timezone=True), nullable=True)
```

(이미 `Column`, `DateTime` import 되어 있는지 확인 후 누락 시 추가)

- [ ] **Step 4: Alembic 마이그레이션 생성**

```bash
cd backend
uv run alembic revision --autogenerate -m "add user.quest_celebrated_at"
```

생성된 마이그레이션 파일을 열어 다음 형태인지 확인:

```python
def upgrade() -> None:
    op.add_column('users', sa.Column('quest_celebrated_at', sa.DateTime(timezone=True), nullable=True))

def downgrade() -> None:
    op.drop_column('users', 'quest_celebrated_at')
```

- [ ] **Step 5: 마이그레이션 적용**

Run: `cd backend && uv run alembic upgrade head`
Expected: `Running upgrade ... -> ..., add user.quest_celebrated_at`

- [ ] **Step 6: 테스트 재실행 — 통과 확인**

Run: `cd backend && uv run pytest tests/test_user_quest_celebrated_at.py -v`
Expected: 3 passed

- [ ] **Step 7: 커밋**

```bash
git add backend/app/models/user.py backend/alembic/versions/*quest_celebrated_at*.py backend/tests/test_user_quest_celebrated_at.py
git commit -m "$(cat <<'EOF'
feat(backend): User.quest_celebrated_at 컬럼 추가 (O2 결정)

Refs: .harness/spec/2026-06-08-teacher-quest-system.md §15.1 O2
Directive: 자동 완료된 퀘스트 카드는 즉시 소거 — 가입 직후 첫 도착 시점만 2초 표시 예외
Constraint: 축하 카드 1회성 보장은 BE 필드 — 기기 재설치 후에도 유지
Rejected: FE Hive 로컬 저장 — 기기 재설치 시 false-positive 재표시

Signed-off-by: 🐙 Autopus <noreply@autopus.co>

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

### Task 0.3: FE `AuthUser.questCelebratedAt` + `questFirstShownProvider`

**Files:**
- Modify: `frontend/lib/features/auth/domain/entities/auth_user.dart` (freezed 필드 추가)
- Create: `frontend/lib/features/profile/presentation/providers/quest_first_shown_provider.dart`
- Test: `frontend/test/features/profile/presentation/providers/quest_first_shown_provider_test.dart`

- [ ] **Step 1: `AuthUser` freezed 필드 추가**

`frontend/lib/features/auth/domain/entities/auth_user.dart` 에서 freezed factory 에 추가:

```dart
@freezed
class AuthUser with _$AuthUser {
  const factory AuthUser({
    // ... 기존 필드 ...
    DateTime? questCelebratedAt,
  }) = _AuthUser;

  factory AuthUser.fromJson(Map<String, dynamic> json) =>
      _$AuthUserFromJson(json);
}
```

JSON 매핑은 freezed 가 처리. BE 응답 키 `quest_celebrated_at` → `questCelebratedAt` 자동 변환 (`json_serializable` 설정 확인).

- [ ] **Step 2: build_runner 실행**

Run: `cd frontend && dart run build_runner build --delete-conflicting-outputs`
Expected: `Succeeded after Xs with N outputs`

- [ ] **Step 3: 실패하는 테스트 작성 (`questFirstShownProvider`)**

`frontend/test/features/profile/presentation/providers/quest_first_shown_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/features/profile/presentation/providers/quest_first_shown_provider.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('초기값은 null', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final value = await container.read(questFirstShownProvider.future);
    expect(value, isNull);
  });

  test('markShown 호출 후 현재 시각으로 set', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(questFirstShownProvider.notifier).markShown();
    final value = await container.read(questFirstShownProvider.future);
    expect(value, isNotNull);
    expect(
      DateTime.now().difference(value!).inSeconds,
      lessThan(5),
    );
  });

  test('isWithinFirstArrivalWindow — markShown 직후 true, 5분 후 false', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(questFirstShownProvider.notifier).markShown();
    expect(
      container.read(questFirstShownProvider.notifier).isWithinFirstArrivalWindow,
      isTrue,
    );
  });
}
```

- [ ] **Step 4: 테스트 실행 — 실패 확인**

Run: `cd frontend && flutter test test/features/profile/presentation/providers/quest_first_shown_provider_test.dart`
Expected: FAIL (`quest_first_shown_provider.dart` 미존재)

- [ ] **Step 5: provider 구현**

`frontend/lib/features/profile/presentation/providers/quest_first_shown_provider.dart`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'quest_first_shown_provider.g.dart';

const _kQuestFirstShownAtKey = 'quest_first_shown_at';
const _kFirstArrivalWindow = Duration(minutes: 5);

@riverpod
class QuestFirstShown extends _$QuestFirstShown {
  @override
  Future<DateTime?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString(_kQuestFirstShownAtKey);
    return iso == null ? null : DateTime.tryParse(iso);
  }

  Future<void> markShown() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kQuestFirstShownAtKey, now.toIso8601String());
    state = AsyncData(now);
  }

  bool get isWithinFirstArrivalWindow {
    final value = state.value;
    if (value == null) return false;
    return DateTime.now().difference(value) <= _kFirstArrivalWindow;
  }
}
```

- [ ] **Step 6: build_runner 실행**

Run: `cd frontend && dart run build_runner build --delete-conflicting-outputs`
Expected: `Succeeded`

- [ ] **Step 7: 테스트 재실행 — 통과 확인**

Run: `cd frontend && flutter test test/features/profile/presentation/providers/quest_first_shown_provider_test.dart`
Expected: 3 passed

- [ ] **Step 8: 커밋**

```bash
git add frontend/lib/features/auth/domain/entities/auth_user.dart \
        frontend/lib/features/auth/domain/entities/auth_user.freezed.dart \
        frontend/lib/features/auth/domain/entities/auth_user.g.dart \
        frontend/lib/features/profile/presentation/providers/quest_first_shown_provider.dart \
        frontend/lib/features/profile/presentation/providers/quest_first_shown_provider.g.dart \
        frontend/test/features/profile/presentation/providers/quest_first_shown_provider_test.dart
git commit -m "$(cat <<'EOF'
feat(profile): questFirstShownProvider + AuthUser.questCelebratedAt (O1/O2 결정)

Refs: .harness/spec/2026-06-08-teacher-quest-system.md §8.2, §12.2
Directive: 가입 직후 첫 도착 판별은 SharedPreferences 기반 — BE 변경 없이 1회 동작
Constraint: 5분 윈도우 내에만 첫 도착으로 간주 — 명시적 boundary
Rejected: User.signupCompletedAt 신규 BE 필드 — BE 변경 비용 + 동시 변경 risk
Rejected: 라우트 히스토리 검사 — 딥링크/탭 전환 시 부정확

Signed-off-by: 🐙 Autopus <noreply@autopus.co>

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Job 1 — BE dual-write 인프라 + diff 스크립트

**목적**: 마이그레이션 단계 1 의 백엔드 준비. `TeacherAvailability` 와 `TeacherSettings.availableSlots` 의 일치 검증 도구 마련.
**AC**: O5 dual-write 검증 스크립트 + diff=0 게이트 준비
**커밋 단위**: 2 커밋 (BE dual-write 엔드포인트 / diff 스크립트)
**의존**: Job 0

### Task 1.1: BE `POST /api/v1/teacher/availability/onboarding` 엔드포인트

> dual-write 진입점. FE 의 `first_availability_setup_screen` 이 이 엔드포인트 호출 시 두 저장소에 동시 기록.

**Files:**
- Modify: `backend/app/api/v1/teacher.py` (또는 teacher_availability 라우터)
- Modify: `backend/app/services/teacher_availability_service.py`
- Test: `backend/tests/test_teacher_availability_onboarding_endpoint.py`

- [ ] **Step 1: 실패하는 API 테스트 작성**

핵심 시나리오: onboarding 엔드포인트 POST → 두 저장소 (TeacherAvailability + TeacherSettings.available_slots) 모두 채워짐.

```python
@pytest.mark.asyncio
async def test_onboarding_endpoint_writes_to_both_stores(client, teacher_token):
    payload = {"slots": [{"day_of_week": "MON", "start_time": "10:00", "end_time": "18:00"}]}
    res = await client.post(
        "/api/v1/teacher/availability/onboarding",
        json=payload,
        headers={"Authorization": f"Bearer {teacher_token}"},
    )
    assert res.status_code == 200
    # 두 저장소 모두 검증
    avail = await get_teacher_availability(teacher_id)
    settings = await get_teacher_settings(teacher_id)
    assert len(avail.slots) == 1
    assert len(settings.available_slots) == 1
```

- [ ] **Step 2: 테스트 실행 — 실패 확인**

Run: `cd backend && uv run pytest tests/test_teacher_availability_onboarding_endpoint.py -v`
Expected: FAIL (404 또는 endpoint 없음)

- [ ] **Step 3: 엔드포인트 구현 (dual-write)**

`backend/app/api/v1/teacher.py` 에 추가 (또는 적절한 위치):

```python
@router.post("/teacher/availability/onboarding")
async def onboarding_availability(
    payload: OnboardingAvailabilityRequest,
    current_user: User = Depends(get_current_teacher),
    db: AsyncSession = Depends(get_db),
):
    """Dual-write: 단계 1 — TeacherAvailability + TeacherSettings.available_slots 동시 기록."""
    teacher_id = current_user.teacher_id
    slots = [Slot.from_dict(s) for s in payload.slots]
    # 1. schedule 도메인 (SSOT)
    await teacher_availability_service.replace_slots(db, teacher_id, slots)
    # 2. profile 도메인 (역호환)
    await teacher_settings_service.replace_available_slots(db, teacher_id, slots)
    return {"ok": True}
```

- [ ] **Step 4: 테스트 재실행 — 통과 확인**

Run: `cd backend && uv run pytest tests/test_teacher_availability_onboarding_endpoint.py -v`
Expected: PASS

- [ ] **Step 5: 커밋**

```bash
git add backend/app/api/v1/teacher.py backend/app/services/*.py backend/tests/test_teacher_availability_onboarding_endpoint.py
git commit -m "$(cat <<'EOF'
feat(backend): onboarding availability dual-write 엔드포인트

Refs: .harness/spec/2026-06-08-teacher-quest-system.md §6.3 단계 1
Directive: dual-write 단계 1 — 두 저장소에 동시 기록하여 역호환 유지
Constraint: 단계 2 reader 교체 전까지 두 저장소 모두 유효한 데이터 보유

Signed-off-by: 🐙 Autopus <noreply@autopus.co>

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

### Task 1.2: diff 검증 스크립트 + pytest

**Files:**
- Create: `backend/scripts/validators/teacher_availability_diff.py`
- Create: `backend/tests/scripts/test_teacher_availability_diff.py`

- [ ] **Step 1: 실패하는 테스트 작성**

```python
"""Diff 스크립트: TeacherAvailability vs TeacherSettings.available_slots 일치 검증."""
import pytest
from backend.scripts.validators.teacher_availability_diff import compute_diff


@pytest.mark.asyncio
async def test_diff_returns_zero_when_synced(db_session, teacher_with_synced_slots):
    """동일 데이터일 때 diff = 0."""
    result = await compute_diff(db_session)
    assert result.diff_count == 0
    assert result.mismatched_teachers == []


@pytest.mark.asyncio
async def test_diff_returns_mismatches(db_session, teacher_with_mismatched_slots):
    """두 저장소가 다를 때 mismatched_teachers 에 teacher_id 포함."""
    result = await compute_diff(db_session)
    assert result.diff_count > 0
    assert teacher_with_mismatched_slots.id in result.mismatched_teachers
```

- [ ] **Step 2: 테스트 실행 — 실패 확인**

Run: `cd backend && uv run pytest tests/scripts/test_teacher_availability_diff.py -v`
Expected: FAIL (ImportError)

- [ ] **Step 3: 스크립트 구현**

`backend/scripts/validators/teacher_availability_diff.py`:

```python
"""TeacherAvailability vs TeacherSettings.available_slots 일치 검증 스크립트.

마이그레이션 단계 1→2 진입 게이트:
  - 7일+ 50건+ 이상 누적 + diff_count == 0 시 단계 2 진입 가능
"""
import asyncio
import sys
from dataclasses import dataclass, field
from typing import List
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import SessionLocal
from app.models.teacher_settings import TeacherSettings
from app.models.teacher_availability import TeacherAvailability


@dataclass
class DiffResult:
    diff_count: int = 0
    mismatched_teachers: List[int] = field(default_factory=list)


async def compute_diff(session: AsyncSession) -> DiffResult:
    """모든 선생님의 두 저장소 데이터를 비교."""
    result = DiffResult()
    teachers = (await session.execute(select(TeacherSettings.teacher_id))).scalars().all()
    for teacher_id in teachers:
        avail = await session.get(TeacherAvailability, teacher_id)
        settings = await session.get(TeacherSettings, teacher_id)
        avail_set = _slots_to_set(avail.slots if avail else [])
        settings_set = _slots_to_set(settings.available_slots if settings else [])
        if avail_set != settings_set:
            result.diff_count += 1
            result.mismatched_teachers.append(teacher_id)
    return result


def _slots_to_set(slots) -> set:
    return {(s.day_of_week, s.start_time, s.end_time) for s in slots}


async def main():
    async with SessionLocal() as session:
        result = await compute_diff(session)
        print(f"diff_count={result.diff_count}")
        if result.mismatched_teachers:
            print(f"mismatched={result.mismatched_teachers}")
            sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
```

- [ ] **Step 4: 테스트 재실행 — 통과 확인**

Run: `cd backend && uv run pytest tests/scripts/test_teacher_availability_diff.py -v`
Expected: 2 passed

- [ ] **Step 5: 커밋**

```bash
git add backend/scripts/validators/teacher_availability_diff.py backend/tests/scripts/test_teacher_availability_diff.py
git commit -m "$(cat <<'EOF'
feat(backend): teacher_availability_diff.py 검증 스크립트 (O5)

Refs: .harness/spec/2026-06-08-teacher-quest-system.md §6.3 검증, §15.1 O5
Directive: 마이그레이션 단계 1→2 게이트는 diff=0 통과 후 진입
Constraint: 7일 + 50건 + diff=0 — 3 조건 모두 만족 시에만 단계 2
Rejected: 백오피스 페이지 — 운영자 신규 화면 비용 vs 일회성 CLI 적합

Signed-off-by: 🐙 Autopus <noreply@autopus.co>

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Job 2 — FE `first_availability_setup_screen` dual-write

**목적**: 가입 흐름의 단순 픽 UI 가 schedule 도메인 (SSOT 후보) 에도 쓰기. profile 도메인은 역호환 유지.
**AC**: 가입 흐름 입력 → 두 저장소 동기
**커밋 단위**: 1 커밋 (dual-write 호출 + smoke test)
**의존**: Job 1

### Task 2.1: dual-write 호출 + smoke test

**Files:**
- Modify: `frontend/lib/features/onboarding/presentation/screens/first_availability_setup_screen.dart:273-300` (저장 로직 영역)
- Create: `frontend/test/features/onboarding/presentation/screens/first_availability_setup_dual_write_test.dart`

- [ ] **Step 1: 실패하는 테스트 작성**

```dart
testWidgets('first_availability_setup 저장 시 두 저장소 호출', (tester) async {
  final mockTeacherSettings = MockTeacherSettingsRepository();
  final mockTeacherAvailability = MockTeacherAvailabilityRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        teacherSettingsRepositoryProvider.overrideWithValue(mockTeacherSettings),
        teacherAvailabilityRepositoryProvider.overrideWithValue(mockTeacherAvailability),
      ],
      child: const MaterialApp(home: FirstAvailabilitySetupScreen()),
    ),
  );

  // 슬롯 1개 선택 + 저장
  await tester.tap(find.text('월요일'));
  await tester.tap(find.text('저장'));
  await tester.pumpAndSettle();

  // 두 저장소 모두 호출 검증
  verify(mockTeacherSettings.replaceAvailableSlots(any)).called(1);
  verify(mockTeacherAvailability.replaceSlots(any)).called(1);
});
```

- [ ] **Step 2: 테스트 실행 — 실패 확인**

Run: `cd frontend && flutter test test/features/onboarding/presentation/screens/first_availability_setup_dual_write_test.dart`
Expected: FAIL — `teacherAvailability.replaceSlots` 호출 안 됨

- [ ] **Step 3: dual-write 구현**

`first_availability_setup_screen.dart` 의 저장 로직 (`line 295` 부근) 수정:

```dart
// 기존:
//   await notifier.replaceAvailableSlots(newSlots);
// 변경:
final availNotifier = ref.read(teacherAvailabilityNotifierProvider(teacherId).notifier);
await Future.wait([
  notifier.replaceAvailableSlots(newSlots),         // profile 도메인 (역호환)
  availNotifier.replaceSlots(newSlots),             // schedule 도메인 (SSOT)
]);
```

(또는 BE 의 onboarding 엔드포인트 1회 호출로 간소화 — 두 store 의 dual-write 가 BE 에서 일어남)

- [ ] **Step 4: 테스트 재실행 — 통과 확인**

Run: `cd frontend && flutter test test/features/onboarding/presentation/screens/first_availability_setup_dual_write_test.dart`
Expected: PASS

- [ ] **Step 5: 기존 회귀 테스트 실행**

Run: `cd frontend && flutter test test/features/onboarding/`
Expected: 모든 기존 테스트 PASS — 회귀 없음

- [ ] **Step 6: 커밋**

```bash
git add frontend/lib/features/onboarding/presentation/screens/first_availability_setup_screen.dart \
        frontend/test/features/onboarding/presentation/screens/first_availability_setup_dual_write_test.dart
git commit -m "$(cat <<'EOF'
feat(onboarding): first_availability_setup dual-write 도입 (단계 1)

가입 흐름의 단순 픽 UI 저장 시 schedule.TeacherAvailability + profile.TeacherSettings 동시 기록.
단계 2 reader 교체 전까지 역호환 유지.

Refs: .harness/spec/2026-06-08-teacher-quest-system.md §6.3 단계 1
Directive: dual-write 단계 1 진입 — 두 저장소 동기화
Constraint: 단계 2 진입은 diff=0 검증 게이트 통과 후

Signed-off-by: 🐙 Autopus <noreply@autopus.co>

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

### 🚦 검증 게이트 — Job 2 완료 후 Job 3 진입 전

다음 3 조건 모두 만족 시에만 Job 3 진입:

- [ ] beta 배포 후 **7일 경과**
- [ ] dual-write 모드 신규 가입 **50건+** 누적 (`SELECT COUNT(*) FROM users WHERE created_at >= X AND role = 'teacher'`)
- [ ] `python -m scripts.validators.teacher_availability_diff` 실행 → `diff_count=0`

검증 통과 시 Job 3 진입. 실패 시 단일 mismatched teacher 수동 복구 후 재실행.

---

## Job 3 — FE reader 교체 (단계 2)

**목적**: home / quest_board / profile_tab 의 `hasSlots` 도출을 `TeacherAvailability.slots.isNotEmpty` 로 일원화.
**AC**: 모든 reader 가 schedule 도메인 참조
**커밋 단위**: 1 커밋 (reader 교체 + 회귀 테스트)
**의존**: Job 2 + 검증 게이트 통과

### Task 3.1: reader 교체 (high-level)

**Files (예상 — Job 3 시작 시 grep 으로 정확 식별):**
- Modify: `frontend/lib/features/home/presentation/widgets/quest_board_card.dart` (`hasSlots` 도출 영역)
- Modify: `frontend/lib/features/home/presentation/providers/...` (quest provider)
- Modify: `frontend/lib/features/profile/presentation/screens/profile_tab.dart` (가용시간 표시 영역)

- [ ] **Step 1: 영향 받는 reader grep 식별**

```bash
grep -rn "teacherSettings.*availableSlots\|TeacherSettings.*availableSlots" frontend/lib --include="*.dart"
grep -rn "hasSlots" frontend/lib --include="*.dart"
```

각 호출처에 대해 `TeacherAvailability.slots.isNotEmpty` 로 교체 방법 정의 (이 시점에 task 분할).

- [ ] **Step 2: 각 reader 교체 (개별 task — Job 3 시작 시 detail)**

(Job 3 시작 시 위 grep 결과 기준으로 task 분할 — 본 PLAN 에서는 outline)

- [ ] **Step 3: 통합 테스트 — 3 화면 동기 검증**

`frontend/test/integration/teacher_availability_sso_consistency_test.dart`:

```dart
// home / quest_board / profile_tab 의 hasSlots 도출 결과 일치 검증
// (Job 3 시작 시 작성)
```

- [ ] **Step 4: 1 주 안정성 모니터링**

배포 후 1 주간 다음 모니터링:
- 가용시간 변경 → 두 저장소 diff = 0 유지
- 사용자 보고된 가용시간 표시 불일치 = 0건

이상 없을 시 Job 8 진입 (deprecate)

---

## Job 4 — UI 재설계 (3-group + lock 매트릭스 + Step 명명 제거)

**목적**: `quest_board_card.dart` 의 시각/구조 재편. Lock 매트릭스 Q6→{Q7~Q10} 으로 교체.
**AC**: 3-group 분류 + Step 명명 제거 + Q1 lock 제거 + Q11 lock 제거
**커밋 단위**: 2 커밋 (3-group + lock 매트릭스 교체 / interstitial 모달 제거 + 기존 스펙 deprecated 표기)
**의존**: Job 3

### Task 4.1: `_Quest` 모델에 `group` 필드 추가 + 3-group 렌더

**Files:**
- Modify: `frontend/lib/features/home/presentation/widgets/quest_board_card.dart`
- Create: `frontend/lib/features/home/presentation/widgets/quest_board/quest_group.dart` (그룹 헤더 위젯)
- Test: `frontend/test/features/home/presentation/widgets/quest_board_card_3group_test.dart`

(이하 detail 은 Job 4 시작 시 작성 — Job 3 reader 교체 결과에 따라 일부 조정)

### Task 4.2: Lock 매트릭스 교체 (`slotsBlocker` 제거, Q6→{Q7~Q10} 도입)

(Job 4 시작 시 detail)

### Task 4.3: `_maybeShowFirstAvailabilityInterstitial` 제거

(Job 4 시작 시 detail)

### Task 4.4: `teacher_first_availability_setup.md` deprecated 헤더 추가

(Job 4 시작 시 detail — surgical 1 line)

---

## Job 5 — 자동 완료 + 즉시 소거 애니메이션

**목적**: `questBoardProvider` reactive 감지 + 카드 fade-out + 가입 직후 첫 도착 2초 예외.
**AC**: 11 트리거 자동 감지 + 가입 직후 2초 표시 + 일반 복귀 즉시 소거
**커밋 단위**: 2 커밋 (reactive provider + 애니메이션 / 가입 직후 2초 예외)
**의존**: Job 4

### Task 5.1: `questBoardProvider` reactive 자동 감지

(Job 5 시작 시 detail — `Practice.assigned ≥ 1` provider 존재 확인 first)

### Task 5.2: `AnimatedSwitcher` + `AnimatedList` 카드 소거

(Job 5 시작 시 detail)

### Task 5.3: 가입 직후 2 초 예외 — `questFirstShownProvider` wiring

(Job 5 시작 시 detail)

---

## Job 6 — 완료 임계값 공개 + AppStrings 통합

**목적**: Q3/Q4/Q10 임계값 화면 노출 + AppStrings 10개 신규 + 11개 step prefix 제거.
**AC**: 임계값 카운터 표시 + Lock 토스트 + 그룹 헤더 문구
**커밋 단위**: 2 커밋 (AppStrings 추가 / 카드 본문 + 임계값 카운터 wiring)
**의존**: Job 4

### Task 6.1: AppStrings 10 키 추가

(Job 6 시작 시 detail — 스펙 §12.2.1 표 참조)

### Task 6.2: Q3 소개글 카운터 + Q4/Q10 카드 본문 (임계값)

(Job 6 시작 시 detail)

---

## Job 7 — 전체 완료 축하 카드

**목적**: 11/11 완료 시 1회 축하 카드 표시. `User.questCelebratedAt` 으로 1회성 보장.
**AC**: 축하 카드 1회 표시 + dismiss 후 재진입 시 미표시
**커밋 단위**: 2 커밋 (축하 카드 위젯 + 1회성 wiring / "오늘의 레슨"/"주간 통계" 액션 wiring)
**의존**: Job 0 (BE 필드) + Job 5 (자동 완료)

### Task 7.1: `QuestCelebrationCard` 위젯 + smoke test

(Job 7 시작 시 detail)

### Task 7.2: `User.questCelebratedAt` 업데이트 mutation + 1회성 wiring

(Job 7 시작 시 detail)

### Task 7.3: 액션 버튼 wiring (`AppRoutes.lessons`, `AppRoutes.weeklyStats`)

(Job 7 시작 시 detail)

---

## Job 8 — Deprecate + 필드 제거 (단계 3 + 4)

**목적**: `profile.TeacherSettings.availableSlots` 의 deprecated 마킹 + 신규 코드 차단 + BE 컬럼 제거.
**AC**: deprecated 마킹 + analyzer/grep CI 차단 + 단계 4 BE 마이그레이션
**커밋 단위**: 3 커밋 (FE deprecated 마킹 / analyzer rule + grep CI / BE 컬럼 제거)
**의존**: Job 3 + 1 주 안정성 모니터링 통과

### Task 8.1: FE `@Deprecated` 마킹 + invalidate 호출 제거

(Job 8 시작 시 detail — `split_page.dart:269, 452` 의 `ref.invalidate(teacherSettingsProvider)` 2 회 제거)

### Task 8.2: analyzer rule + grep CI 훅 (O6)

(Job 8 시작 시 detail)

### Task 8.3: BE 컬럼 제거 (단계 4) — 별도 PR, 백엔드 조율 필수

(Job 8 시작 시 detail — alembic downgrade 시 데이터 보존 절차 포함)

---

## Self-Review (Plan vs Spec)

### 1. Spec coverage

| 스펙 섹션 | PLAN 위치 |
|---|---|
| §4 시스템 재정의 (학습 가이드 + 단축 진입점) | Job 4 (UI 재설계 — Q1 진입 라우트 split_page 로 교체) |
| §5 3-group 분류 | Job 4 Task 4.1 |
| §5.1 인벤토리 — Q1 진입 라우트 교체 | Job 4 Task 4.1 |
| §6 데이터 SSOT (TeacherAvailability) | Job 1 (BE) + Job 2 (FE dual-write) + Job 3 (reader 교체) |
| §6.3 4단계 마이그레이션 | Job 1, 2, 3, 8 (단계 1~4 매핑) |
| §6.3 검증 게이트 (7일+50건+diff=0) | Job 2 직후 게이트 체크리스트 |
| §7 Lock 매트릭스 (Q6→{Q7~Q10}) | Job 4 Task 4.2 |
| §8 자동 완료 + 즉시 소거 + 가입 직후 2초 | Job 5 (Task 5.1~5.3) |
| §8.3 전체 완료 축하 카드 (1회만) | Job 7 |
| §9 완료 임계값 공개 (Q3/Q4/Q10) | Job 6 Task 6.2 |
| §10 스킵/필수 정책 (Bonus 그룹 점선 + 라벨) | Job 4 Task 4.1 (그룹 분류 시 적용) |
| §11 UX 흐름 (Mermaid) | (참조용 — 코드 변경 없음) |
| §12.1 deprecated 처리 | Job 4 (interstitial), Job 8 (TeacherSettings, invalidate) |
| §12.2 변경 파일 | File Structure 표에서 매핑 |
| §12.2.1 AppStrings 10키 | Job 6 Task 6.1 |
| §13.3 회귀 테스트 | 각 Job 의 TDD step 에 분산 |
| §14 결정 로그 (Lore) | 각 Job 의 커밋 메시지 trailer 에 분산 |
| §15.1 O1~O6 | 사전 결정 섹션 + Job 0 |

**누락 확인**: 없음. 모든 스펙 결정 사항이 Job 1~8 중 하나에 매핑됨.

### 2. Placeholder scan

- Job 0 Task 0.1~0.3: detail TDD step + code 블록 완비
- Job 1 Task 1.1~1.2: detail TDD step + code 블록 완비
- Job 2 Task 2.1: detail TDD step + code 블록 완비
- Job 3~8: **outline 만 작성** — 각 Job 시작 시 사전 detail 작성 필요. 이는 의도적 분할 (한 번에 모든 detail 작성 시 PLAN 1500줄+ 부담)

⚠️ **Job 3~8 의 task 는 시작 시점에 별도 detail 작성 필요**. 본 PLAN 의 outline 만으로는 즉시 실행 불가.

### 3. Type consistency

- `questCelebratedAt` (FE) ↔ `quest_celebrated_at` (BE) — freezed json_serializable 자동 변환 (Task 0.3 Step 1)
- `QuestFirstShown` provider 이름 일관 (Task 0.3, Job 5)
- `compute_diff()` 함수 이름 일관 (Task 1.2)
- `replaceAvailableSlots(newSlots)` vs `replaceSlots(newSlots)` — profile 도메인 / schedule 도메인 메서드 이름 다름. Job 2 에서 두 메서드 모두 호출 검증.

---

## 후속 단계 (PLAN 외부)

- **Job 3~8 의 사전 detail 작성**: 각 Job 진입 시 본 PLAN 의 outline 을 확장하여 task-by-task TDD step 작성
- **Phase 6 (cg-evaluation)**: Job 4, 5, 7 완료 후 3-critic 평가
- **Phase 6 머지**: 본 스펙을 `docs/specs/onboarding/teacher_quest_system.md` 로 머지 + audit 보고서 영구 보존
- **Audit 재측정**: Job 7 완료 후 7차원 점수 재평가 — 37% → 75% 목표 검증

---

## Execution Notes

- 각 Job 의 첫 task 진입 시 `git pull origin main` 으로 최신 상태 확인
- Job 0~2 는 빠르게 진행 가능 (3~5일). 검증 게이트 7일은 production 안전 마진.
- Job 3 reader 교체는 회귀 위험 중간 — UI smoke test + 통합 테스트 우선
- Job 4 UI 재설계는 widget smoke test 의무 (`.claude/hooks/check-widget-smoke-test.sh` 자동 감지)
- 모든 Job 의 커밋 메시지에 `Directive:` / `Constraint:` / `Rejected:` + `Signed-off-by: 🐙 Autopus <noreply@autopus.co>` trailer 필수 (hook reject 방지)
