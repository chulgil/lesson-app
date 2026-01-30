# 통합 테스트 데이터

> 작성일: 2026-01-27
> 상태: 구현 완료

---

## 개요

개발 및 테스트를 위한 통합 Mock 데이터입니다.
**선생님 1명 + 학생 1명**에 모든 주요 케이스가 포함되어 있습니다.

---

## 핵심 테스트 계정

### 메인 선생님: 김지수 (학원 소속)

| 필드 | 값 |
|------|-----|
| id | `teacher_1` |
| userId | `user_teacher_1` |
| organizationId | `academy_1` |
| organizationName | `김지수 음악학원` |
| name | `김지수` |
| instruments | `['피아노', '작곡']` |
| experienceYears | 15 |
| lessonAreas | `['서울 강남', '서울 서초', '온라인']` |
| lessonTypes | `[inPerson, online]` |
| feeRange | 60,000 ~ 80,000원 (60분) |
| completionLevel | complete (100%) |
| badges | phoneVerified, certified, premium |

### 메인 학생: 이민준

| 필드 | 값 |
|------|-----|
| id | `student_1` |
| userId | `user_student_1` |
| name | `이민준` |
| instrument | `피아노` |
| level | `intermediate` |
| lessonDay | `수요일` |
| lessonTime | `16:00` |
| teacherId | `teacher_1` |

---

## 수강권 테스트 케이스

선생님 `teacher_1` → 학생 `student_1`

| 수강권 ID | 상태 | 회차 | 사용 | 남은 | 유효기간 | 케이스 |
|-----------|------|:----:|:----:|:----:|----------|--------|
| `sub_active` | active | 12 | 4 | 8 | 30일 남음 | 정상 사용중 |
| `sub_expiring` | active | 12 | 10 | 2 | 7일 남음 | 곧 만료 (회차+기간) |
| `sub_exhausted` | exhausted | 4 | 4 | 0 | 60일 남음 | 회차 소진 |
| `sub_expired` | expired | 12 | 6 | 6 | -5일 | 기간 만료 |
| `sub_paused` | paused | 24 | 12 | 12 | 중단중 | 일시 중단 |

### 수강권 발급 옵션 테스트

| 옵션 | 값 |
|------|-----|
| 회차 프리셋 | 4, 12, 24, 48 + 직접입력 |
| 유효기간 프리셋 | 1개월(30일), 3개월(90일), 6개월(180일), 1년(365일) + 직접입력 |
| 자동 매핑 | 4회→30일, 12회→90일, 24회→180일, 48회→365일 |

---

## 레슨 예약 테스트 케이스

| 예약 ID | 상태 | 타입 | 날짜 | 시간 | 케이스 |
|---------|------|------|------|------|--------|
| `booking_pending` | pending | regular | 다음주 수요일 | 16:00 | 승인 대기 |
| `booking_confirmed` | confirmed | regular | 이번주 수요일 | 16:00 | 확정됨 |
| `booking_completed` | completed | regular | 지난주 수요일 | 16:00 | 완료 (출석) |
| `booking_cancelled` | cancelled | regular | 지난주 금요일 | 14:00 | 학생 취소 |
| `booking_noshow` | noshow | regular | 지난주 월요일 | 10:00 | 노쇼 |
| `booking_trial` | confirmed | trial | 내일 | 15:00 | 체험 레슨 |

---

## 선생님 검색 테스트 케이스

### 학원 탭 (academy)

| ID | 이름 | 학원명 | 악기 | 지역 | 경력 |
|----|------|--------|------|------|:----:|
| `teacher_1` | 김지수 | 김지수 음악학원 | 피아노, 작곡 | 서울 강남, 서초 | 15년 |
| `teacher_3` | 이서연 | 하모니 음악학원 | 첼로 | 서울 송파, 강동 | 10년 |
| `teacher_4` | 정민호 | 정민호 기타 스튜디오 | 기타, 베이스 | 서울 홍대, 신촌 | 12년 |

### 개인 선생님 탭 (individual)

| ID | 이름 | 악기 | 지역 | 경력 |
|----|------|------|------|:----:|
| `teacher_2` | 박현우 | 바이올린, 비올라 | 서울 마포, 용산 | 8년 |
| `teacher_5` | 최유진 | 플룻, 리코더 | 경기 분당, 수원 | 6년 |

### 검색 필터 테스트

| 필터 | 테스트 값 | 예상 결과 |
|------|----------|----------|
| teacherType | academy | 3명 |
| teacherType | individual | 2명 |
| instruments | ['피아노'] | 1명 (김지수) |
| areas | ['서울 강남'] | 1명 (김지수) |
| minExperience | 10 | 3명 |
| hasVerifiedCertificate | true | 3명 |

---

## 가용 시간 테스트 케이스

선생님 `teacher_1`의 주간 스케줄

### WeeklySchedule

| 요일 | 가용 시간 | 레슨 시간 |
|------|----------|----------|
| 월 | 10:00-12:00, 14:00-18:00 | 60분 |
| 화 | 10:00-12:00, 14:00-18:00 | 60분 |
| 수 | 10:00-12:00, 14:00-18:00 | 60분 |
| 목 | 10:00-12:00, 14:00-18:00 | 60분 |
| 금 | 10:00-12:00, 14:00-18:00 | 60분 |
| 토 | 10:00-14:00 | 60분 |
| 일 | 휴무 | - |

### TimeException (휴무/예외)

| ID | 타입 | 날짜 | 사유 |
|----|------|------|------|
| `exc_holiday` | holiday | 2026-02-01 | 설날 연휴 |
| `exc_vacation` | vacation | 2026-02-15 ~ 2026-02-20 | 개인 휴가 |
| `exc_extra` | extraAvailable | 2026-01-31 (일) | 특별 오픈 |

### AvailabilitySlot 상태

| 상태 | 설명 | 색상 |
|------|------|------|
| available | 예약 가능 | 초록 |
| booked | 다른 학생 예약 | 회색 |
| myBooking | 내 예약 | 파랑 |
| unavailable | 예약 불가 | 빨강 |
| recommended | 추천 슬롯 | 초록+별 |

---

## 연습 기록 테스트 케이스

학생 `student_1`의 연습 데이터

### 레퍼토리

| ID | 곡명 | 작곡가 | 상태 | 섹션 수 |
|----|------|--------|------|:------:|
| `rep_active` | 체르니 30번 1번 | Czerny | active | 3 |
| `rep_completed` | 소나타 K.545 1악장 | Mozart | completed | 4 |
| `rep_archived` | 인벤션 1번 | Bach | archived | 2 |

### 연습 기록 (rep_active)

| 날짜 | 연습 시간 | 메트로놈 | 녹음 |
|------|:--------:|:--------:|:----:|
| 오늘 | 45분 | 80 BPM | ✓ |
| 어제 | 30분 | 76 BPM | ✓ |
| 3일 전 | 60분 | 72 BPM | - |

### 녹음 파일

| ID | 섹션 | 날짜 | 길이 | 대표 |
|----|------|------|:----:|:----:|
| `rec_1` | 전체 | 오늘 | 2:30 | ✓ |
| `rec_2` | 1-8마디 | 오늘 | 0:45 | - |
| `rec_3` | 전체 | 어제 | 2:15 | - |

---

## 알림 테스트 케이스

| ID | 타입 | 제목 | 읽음 |
|----|------|------|:----:|
| `noti_1` | lesson_reminder | 내일 레슨이 있습니다 | - |
| `noti_2` | subscription_expiring | 수강권이 곧 만료됩니다 | - |
| `noti_3` | booking_confirmed | 예약이 확정되었습니다 | ✓ |
| `noti_4` | practice_reminder | 오늘 연습을 시작해보세요 | ✓ |

---

## Mock Repository 파일 위치

| Repository | 파일 |
|------------|------|
| TeacherSearchRepository | `lib/repositories/teacher_search_repository.dart` |
| TeacherAvailabilityRepository | `lib/features/schedule/data/repositories/mock_teacher_availability_repository.dart` |
| SubscriptionRepository | `lib/features/subscription/data/repositories/mock_subscription_repository.dart` |
| BookingRepository | `lib/features/schedule/data/repositories/mock_booking_repository.dart` |
| PracticeRepository | `lib/features/practice/data/repositories/mock_practice_repository.dart` |
| StudentRepository | `lib/features/students/data/repositories/mock_student_repository.dart` |

---

## 테스트 시나리오 체크리스트

### 수강권 발급

- [ ] 프리셋 4회 선택 → 유효기간 30일 자동 설정
- [ ] 프리셋 12회 선택 → 유효기간 90일 자동 설정
- [ ] 직접입력으로 회차 10회 입력
- [ ] 직접입력으로 유효기간 45일 입력

### 선생님 검색

- [ ] 학원 탭 선택 → 학원 소속 선생님만 표시
- [ ] 개인 탭 선택 → 개인 선생님만 표시
- [ ] 학원 뱃지가 카드에 표시됨
- [ ] 필터 적용 후 결과 확인

### 레슨 예약

- [ ] 가용 슬롯 칩 버튼 표시
- [ ] 슬롯 선택 → 예약 미리보기
- [ ] 예약 확정 → 수강권 차감
- [ ] 예약 취소 → 수강권 복원

### 연습 기록

- [ ] 레퍼토리별 연습 기록 표시
- [ ] 녹음 재생 (웨이브폼, A-B 루프)
- [ ] 메트로놈 BPM 기록
- [ ] 대표 녹음 설정

---

## 관련 문서

| 문서 | 설명 |
|------|------|
| [test_scenarios.md](test_scenarios.md) | 로그인 테스트 시나리오 |
| [teacher_registration.md](../../specs/user/teacher_registration.md) | 선생님 등록 스펙 |
| [subscription_system_spec.md](../../specs/subscription/subscription_system_spec.md) | 수강권 시스템 스펙 |
| [teacher_availability_spec.md](../../specs/schedule/teacher_availability_spec.md) | 가용 시간 시스템 스펙 |
