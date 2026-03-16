# 시나리오 테스트 가이드

> 마지막 업데이트: 2026-03-16

## 개요

사용자(선생님/학생)가 앱에서 실제로 수행하는 흐름을 시나리오로 작성하여, 백엔드 API가 순차적으로 정상 동작하는지 검증하는 E2E 테스트 프레임워크.

## 실행 방법

```bash
cd backend

# 시나리오만 실행
python -m pytest tests/test_scenarios_framework.py -v

# 전체 테스트 (시나리오 포함)
python -m pytest tests/ -v
```

---

## 프레임워크 구조

```
tests/
├── scenarios/
│   ├── __init__.py          # 패키지 (TeacherActions, StudentActions export)
│   ├── helpers.py           # TeacherActions, StudentActions 클래스
│   └── assertions.py        # 공통 검증 함수
├── conftest.py              # teacher, student fixture (자동 시드)
├── test_scenarios_teacher.py     # Raw API 호출 시나리오 (10개)
└── test_scenarios_framework.py   # 프레임워크 사용 시나리오 (10개)
```

### 핵심 클래스

| 클래스 | 역할 | 주요 메서드 |
|--------|------|------------|
| `TeacherActions` | 선생님이 수행하는 모든 액션 | `create_student`, `create_lesson`, `complete_lesson`, `write_feedback`, `create_subscription`, `use_lesson`, `create_invite`, `approve_booking` 등 50+ |
| `StudentActions` | 학생이 수행하는 모든 액션 | `send_connection_request`, `book_trial`, `accept_proposal`, `write_review` 등 |

### 공통 검증 함수 (assertions.py)

| 함수 | 용도 |
|------|------|
| `assert_status(data, "completed")` | 리소스 상태 확인 |
| `assert_subscription_remaining(sub, 2)` | 수강권 잔여 횟수 확인 |
| `assert_total(data, 3)` | 페이지네이션 total 확인 |
| `assert_list_length(data, 5)` | 리스트/items 길이 확인 |

---

## 현재 시나리오 목록

### 선생님 시나리오

| ID | 시나리오 | API 호출 순서 | 검증 포인트 |
|----|---------|--------------|------------|
| T-01 | 온보딩 → 첫 레슨 | `GET /users/me` → `GET /settings/teacher` → `POST /students` → `POST /lessons` → `PATCH /lessons/{id}/status` → `PUT /lessons/{id}/feedback` | 프로필 role=teacher, 설정 기본값, 레슨 상태 전이 scheduled→completed |
| T-02 | 수강권 생명주기 | `POST /subscriptions-templates` → `POST /subscriptions` → (`POST /lessons` → `PATCH status` → `PATCH use-lesson`) ×6 → `GET /subscriptions/{id}` → `PATCH confirm-payment` | remaining=2 (8-6), 결제 확인 |
| T-03 | 초대 → 연결 → 예약 | `POST /invites` → `POST /connection-requests` → `PATCH respond(accept)` → `POST /bookings` → `PATCH approve` | 초대 코드 6자리, 연결 생성, 예약 pending→approved |
| T-04 | 그룹수업 대기열 | `POST /groups/schedules` → `POST /bookings` ×3 → `PATCH cancel` → `PATCH attendance` | 2명 confirmed, 3번째 waitlist, 취소 시 자동 승격 |
| T-05 | 연습 → 통계 → 게이미피케이션 | `POST /practice/repertoires` → `POST /practice-logs` ×3 → `GET stats` → `POST /gamification/points` → `GET /gamification/{id}` | practiced_days=3, total_minutes=120, level=2 |
| T-06 | 대시보드 + 콘텐츠 | `GET /dashboard` → `POST /feedback-presets` ×2 → `POST /teaching-resources` → `POST /reviews` → `GET /reviews/summary` | 프리셋 2개, 리뷰 평균 4.5 |
| T-07 | 설정 전체 구성 | `PUT /settings/teacher` → `PUT /settings/subscription` → `PUT /settings/proposal` → 각 `GET` 재조회 | 변경된 값 영속성 확인 |
| T-08 | 수강권 제안 플로우 | `POST /subscriptions-templates` → `POST /subscriptions-proposals` → `PATCH respond(accept)` → `PATCH confirm` | pending→paymentNotified→confirmed |
| T-09 | 노쇼 관리 | `POST /lessons` → `PATCH status(noShow)` → `POST /no-shows` → `POST /bookings/makeup` | 노쇼 기록 deducted_credits=1 |
| T-10 | 하루 멀티 학생 | (`POST /students` → `POST /lessons`) ×3 → `PATCH status(completed)` ×2 → `PATCH status(cancelled)` ×1 → `PUT feedback` ×2 | 3개 레슨 생성, 2개 완료+피드백, 1개 취소 |
| T-11 | 수강권 만료 후 재등록 | `POST /subscriptions(4회)` → (`POST /lessons` → `PATCH use-lesson`) ×4 → remaining=0 확인 → `POST /proposals` → `PATCH accept` → `PATCH confirm` → `POST /subscriptions(8회)` → 첫 차감 → remaining=7 | 만료→재제안→수락→새 수강권 발급→사용 시작 |

### 학생 시나리오 (StudentActions 사용)

| ID | 시나리오 | API 호출 순서 | 검증 포인트 |
|----|---------|--------------|------------|
| S-01 | 연결 요청 | `POST /connection-requests` → 선생님 `PATCH accept` | 연결 생성 확인 |
| S-02 | 체험 예약 | `POST /bookings(trial)` → 선생님 `PATCH approve` | booking status=approved |
| S-03 | 제안 수락 | 선생님 `POST /proposals` → `PATCH respond(accept)` | status=paymentNotified |
| S-04 | 리뷰 작성 | `POST /reviews` → `GET /reviews/summary` | 평점 반영 확인 |

---

## 새 시나리오 작성 방법

### Step 1: 시나리오 설계

이 문서의 시나리오 목록에 새 항목을 추가합니다:

```markdown
| T-11 | 수강권 만료 후 재등록 | `POST /subscriptions` → use-lesson ×8 → 만료 확인 → 새 제안 → 수락 → 새 수강권 | 만료 후 재발급 흐름 |
```

### Step 2: 테스트 코드 작성

`test_scenarios_framework.py`에 새 함수를 추가합니다:

```python
@pytest.mark.asyncio
async def test_fw_subscription_renewal(teacher: TeacherActions, student: StudentActions):
    """수강권 만료 후 재등록 흐름."""
    # 1. 학생 + 수강권 생성
    sid = await teacher.create_student("재등록학생")
    sub_id = await teacher.create_subscription(sid, total_lessons=4, amount=160000)

    # 2. 4회 모두 사용 (만료)
    for i in range(4):
        lid = await teacher.create_lesson(sid, date=f"2026-04-{i+1:02d}")
        await teacher.complete_lesson(lid)
        await teacher.use_lesson(sub_id, lid)

    # 3. 잔여 0 확인
    sub = await teacher.get_subscription(sub_id)
    assert_subscription_remaining(sub, 0)

    # 4. 새 제안 → 수락 → 확인
    tmpl_id = await teacher.create_template("재등록 4회", lessons_count=4, amount=160000)
    proposal_id = await teacher.send_proposal(sid, tmpl_id)
    await student.accept_proposal(proposal_id, tmpl_id)
    await teacher.confirm_proposal(proposal_id)
```

### Step 3: 실행 및 검증

```bash
python -m pytest tests/test_scenarios_framework.py::test_fw_subscription_renewal -v
```

### Step 4: 이 문서 업데이트

시나리오 목록 테이블에 새 항목을 추가합니다.

---

## TeacherActions 메서드 레퍼런스

### 프로필 & 설정
| 메서드 | 반환 | 설명 |
|--------|------|------|
| `get_profile()` | dict | 내 프로필 조회 |
| `get_settings()` | dict | 선생님 설정 조회 (자동 생성) |
| `update_settings(**kwargs)` | dict | 설정 변경 |
| `get_dashboard(teacher_id)` | dict | 대시보드 조회 |

### 학생
| 메서드 | 반환 | 설명 |
|--------|------|------|
| `create_student(name, instrument, level)` | str (id) | 학생 등록 |
| `list_students(**params)` | dict | 학생 목록 |
| `get_student(student_id)` | dict | 학생 상세 |

### 레슨
| 메서드 | 반환 | 설명 |
|--------|------|------|
| `create_lesson(student_id, date, start_time, duration, ...)` | str (id) | 레슨 생성 |
| `get_lesson(lesson_id)` | dict | 레슨 상세 |
| `complete_lesson(lesson_id)` | dict | 레슨 완료 처리 |
| `cancel_lesson(lesson_id)` | dict | 레슨 취소 |
| `mark_no_show(lesson_id)` | dict | 노쇼 처리 |
| `write_feedback(lesson_id, feedback, key_points, practice_tips)` | dict | 피드백 작성 |
| `list_upcoming_lessons()` | list | 다가오는 레슨 |
| `list_recent_lessons()` | list | 최근 완료 레슨 |

### 수강권
| 메서드 | 반환 | 설명 |
|--------|------|------|
| `create_template(name, lessons_count, amount)` | str (id) | 템플릿 생성 |
| `create_subscription(student_id, total_lessons, amount)` | str (id) | 수강권 발급 |
| `get_subscription(sub_id)` | dict | 수강권 조회 |
| `use_lesson(sub_id, lesson_id)` | dict | 레슨 차감 |
| `confirm_payment(sub_id, method)` | dict | 결제 확인 |
| `send_proposal(student_id, template_id)` | str (id) | 제안 발송 |
| `confirm_proposal(proposal_id)` | dict | 제안 확인 |

### 초대 & 연결
| 메서드 | 반환 | 설명 |
|--------|------|------|
| `create_invite(**kwargs)` | dict | 초대 생성 |
| `list_pending_requests()` | dict | 대기 연결 요청 |
| `accept_connection(request_id)` | dict | 연결 수락 |
| `reject_connection(request_id, reason)` | dict | 연결 거절 |
| `list_connections()` | dict | 연결 목록 |
| `approve_booking(booking_id)` | dict | 예약 승인 |

### 그룹 수업
| 메서드 | 반환 | 설명 |
|--------|------|------|
| `create_group_schedule(group_class_id, start_time, end_time, max_capacity, waitlist_capacity)` | str (id) | 스케줄 생성 |
| `book_group_student(schedule_id, student_id)` | dict | 학생 예약 |
| `cancel_group_booking(booking_id, reason)` | dict | 예약 취소 |
| `mark_group_attendance(booking_id, attended)` | dict | 출석 체크 |

### 연습 & 게이미피케이션
| 메서드 | 반환 | 설명 |
|--------|------|------|
| `create_repertoire(student_id, name)` | str (id) | 레퍼토리 생성 |
| `create_practice_log(student_id, date, total_minutes)` | str (id) | 연습 기록 |
| `get_practice_stats(student_id, year, month)` | dict | 월간 통계 |
| `award_points(student_id, points, type, description)` | dict | 포인트 수여 |
| `get_gamification(student_id)` | dict | 게이미피케이션 조회 |

### 콘텐츠
| 메서드 | 반환 | 설명 |
|--------|------|------|
| `create_feedback_preset(text, sort_order)` | str (id) | 피드백 프리셋 |
| `create_teaching_resource(title, **kwargs)` | str (id) | 교육자료 |
| `record_no_show(lesson_id, student_id, date, policy, credits)` | dict | 노쇼 기록 |
| `get_review_summary(teacher_id)` | dict | 리뷰 요약 |

## StudentActions 메서드 레퍼런스

| 메서드 | 반환 | 설명 |
|--------|------|------|
| `get_profile()` | dict | 내 프로필 |
| `send_connection_request(target_id, method, **kwargs)` | str (id) | 연결 요청 |
| `book_trial(teacher_id, date, time, duration, instrument)` | str (id) | 체험 예약 |
| `accept_proposal(proposal_id, template_id)` | dict | 제안 수락 |
| `reject_proposal(proposal_id, reason)` | dict | 제안 거절 |
| `write_review(teacher_id, rating, content)` | str (id) | 리뷰 작성 |
| `get_practice_logs(student_id, year, month)` | list | 연습 기록 조회 |
| `get_gamification(student_id)` | dict | 게이미피케이션 조회 |

---

## Claude에게 시나리오 추가 요청하는 방법

다음과 같이 요청하면 됩니다:

```
"T-11 수강권 만료 후 재등록 시나리오를 추가해주세요"
```

또는 자연어로:

```
"학생이 수강권을 다 쓰고 나서 선생님이 다시 제안하고
학생이 수락하는 재등록 시나리오 테스트를 만들어주세요"
```

Claude가 이 가이드를 참조하여:
1. `test_scenarios_framework.py`에 테스트 함수 추가
2. 필요 시 `helpers.py`에 새 메서드 추가
3. 이 문서의 시나리오 목록 업데이트
4. 테스트 실행 후 통과 확인
