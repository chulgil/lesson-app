# 레슨 장소 통합 관리 + 이동시간 시스템

> v1.0 | 2026-03-15 | Refs #177 확장

## 1. 개요

### 1.1 문제

음악 레슨 선생님은 하루에 여러 장소를 이동하며 레슨합니다:
- 학생 집 방문 → 다른 학생 집 → 학원으로 복귀
- 학원 레슨 → 외부 스튜디오 → 온라인 레슨

현재 시스템은 장소 유형(5종)과 이동시간 필드가 존재하지만, **장소와 이동시간이 유기적으로 연동되지 않고**, 학생 주소 수집 플로우가 없어 자동화가 불가능합니다.

비유: 쇼핑몰에서 배송지 없이 주문하는 것과 같습니다. 수강권(=주문)에 레슨 장소(=배송지)가 확정되어야 스케줄(=배송 일정)이 정확해집니다.

### 1.2 현재 상태

| 항목 | 상태 | 비고 |
|------|:----:|------|
| LessonLocation 엔티티 (5종 유형) | ✅ | academyRoom, teacherStudio, studentHome, externalPlace, online |
| ClassMembership.travelTimeMinutes | ✅ | 데이터 모델만 존재, 활용 미완 |
| ClassMembership.lessonLocationId | ✅ | 데이터 모델만 존재 |
| 학생 주소 수집 | ❌ | Student 엔티티에 주소 필드 없음 |
| 장소별 이동시간 자동 연동 | ❌ | 수기 입력만 가능 |
| 스케줄에 이동시간 "레슨 전" 표시 | ❌ | 현재 "레슨 후" 배치 (수정 필요) |

### 1.3 해결 방식

**수강권 = 주문(Order)** 모델을 적용합니다:

```
수강권 생성 시:
1. 레슨 장소 선택 (학생집 / 학원 / 스튜디오 / 온라인)
2. 장소에 따라 주소 자동입력 또는 수기입력
3. 이동시간 수기 입력 (선생님이 보통 걸리는 시간)
4. 정기권 = 매월 동일 설정 유지 (Autoship)
```

---

## 2. 경쟁사 분석

### 2.1 비교표

| 기능 | My Music Staff | Fons | MarketBox | Teachworks | **Lessonaza (제안)** |
|------|:---:|:---:|:---:|:---:|:---:|
| 레슨 장소 유형 | Studio/Home/Online | Studio/Online | 방문/고정/하이브리드 | 다중위치/Online | **5종 (이미 구현)** |
| 학생 주소 연동 | O (동적) | X | O (매칭) | X | **O (우편번호+자동입력)** |
| 이동시간 버퍼 | 간접 (마일리지) | O (수동) | O (자동 구역) | 간접 | **O (레슨 전 자동 배치)** |
| 주소 프라이버시 | 없음 (전체 저장) | N/A | 매칭 후 공개 | 없음 | **우편번호 기반 계층화** |
| 수강권-장소 연동 | X | X | X | X | **O (핵심 차별점)** |

### 2.2 핵심 인사이트

1. **어떤 경쟁사도 수강권(구독)과 장소를 직접 연결하지 않음** → Lessonaza의 차별점
2. **MarketBox**만 지도 기반 자동 이동시간 제공 (복잡, 비용 높음)
3. **My Music Staff**의 "Use Student Home Address" 패턴이 가장 실용적
4. **한국 시장**: 당근마켓식 동 단위 프라이버시가 사용자 기대에 부합

### 2.3 Lessonaza 포지셔닝

```
단순함 (Fons) ←――――→ 자동화 (MarketBox)
                 ↑
            Lessonaza
      (수강권 기반 장소 연동 + 수기 이동시간)
```

MarketBox의 지도 기반 자동화는 Phase 3 이후 고려. 현재는 **수기 입력 + 자동 연동**의 실용적 중간점.

---

## 3. 주소 프라이버시 모델

### 3.1 학생 주소 수집

```
학생 가입/등록 시:
├── 우편번호 (5자리, 필수) → 대략적 위치 파악
├── 기본주소 (자동완성) → 구/동 수준
├── 상세주소 (선택) → 동/호수
└── 프라이버시 정책:
    ├── 공개: 구/동 이름만 (선생님 검색 시)
    ├── 제한 공개: 전체 주소 (연결된 선생님에게만, "학생 집" 레슨 시)
    └── 비공개: 상세주소 (학생/학부모만 확인 가능)
```

### 3.2 한국 우편번호 활용

| 자릿수 | 의미 | 활용 |
|--------|------|------|
| 앞 2자리 | 광역시/도 | 원거리 판별 |
| 앞 3자리 | 시/군/구 | **이동시간 자동제안** (같은 구 15분, 인접 구 30분) |
| 5자리 전체 | 기초구역 | 정확한 위치 (비공개) |

### 3.3 데이터 모델: Student 확장

```dart
// Student 엔티티에 추가
final String? postalCode;      // 우편번호 (5자리)
final String? address;          // 기본주소 (시/구/동)
final String? addressDetail;    // 상세주소 (비공개)
final String? district;         // 구/동 이름 (자동추출, 검색용)
```

---

## 4. 장소 유형별 UX 플로우

### 4.1 학생 집 방문 레슨

```
수강권 생성 → 장소: "학생 집" 선택
  ↓
학생 주소 자동입력 (Student.address에서)
  ↓
이동시간 입력: [20분 ▼] (선생님 수기)
  ↓
💡 "우편번호 기준 약 15-20분 거리입니다" (자동 제안)
  ↓
저장 → ClassMembership에 반영
```

**특징**: 학생 가입 시 입력한 주소가 자동으로 레슨 장소에 연동. 쇼핑몰의 "기본 배송지 사용"과 동일.

### 4.2 학원 레슨

```
수강권 생성 → 장소: "학원" 선택
  ↓
학원(LessonClass) 주소 자동입력
  ↓
이동시간 입력: [0분 ▼] (학원에서 레슨하므로 보통 0)
  ※ 학생 레슨 후 학원으로 이동하는 경우: 수기로 이동시간 입력
  ↓
저장
```

**특징**: 학원 주소는 LessonClass 엔티티에서 자동으로 가져옴. 선생님이 학생 집에서 학원으로 이동하는 경우만 이동시간 수기 입력.

### 4.3 외부 스튜디오 (대여)

```
수강권 생성 → 장소: "외부 스튜디오" 선택
  ↓
주소 수기 입력 (선생님이 직접 작성)
  ↓
이동시간 입력: [15분 ▼]
  ↓
💡 "보통 학생/선생님 역 근처 스튜디오를 이용합니다"
  ↓
저장
```

**특징**: 스튜디오 위치가 유동적(학생 역, 선생님 역 등)이므로 선생님이 수강권에 직접 기입. 불특정 장소이므로 자동화 불가.

### 4.4 선생님 스튜디오

```
수강권 생성 → 장소: "선생님 스튜디오" 선택
  ↓
선생님 프로필 주소 자동입력
  ↓
이동시간: 0분 (자동, 학생이 방문하므로)
  ↓
저장
```

### 4.5 온라인

```
수강권 생성 → 장소: "온라인" 선택
  ↓
이동시간: 0분 (자동)
  ↓
화상 플랫폼 선택 (Zoom/FaceTime/기타)
  ↓
저장
```

---

## 5. 이동시간 스케줄 연동

### 5.1 핵심 원칙: 이동시간은 레슨 "전"에 배치

```
이동시간은 선생님이 학생에게 "도착하기 위한" 시간입니다.
따라서 레슨 시작 전에 이동 블록이 표시되어야 합니다.

[ 이동 20분 ][ 학생A 레슨 60분 ][ 쉬는시간 ][ 이동 15분 ][ 학생B 레슨 60분 ]
```

### 5.2 스케줄 타임라인 표시

```
13:40 ░░░░░░░░░░░░░░░░  이동 (20분) → 김서연 (학생집)
14:00 ████████████████  김서연 바이올린 📍학생집
15:00                   쉬는시간 (10분)
15:10 ░░░░░░░░░░░░░░░░  이동 (20분) → 이하은 (학원)
15:30 ████████████████  이하은 피아노 📍학원
16:30                   예약 가능
```

### 5.3 충돌 검사 로직

```dart
// 각 레슨의 실제 점유 시간 = 이동시간 + 레슨시간
// 레슨 A: 14:00-15:00, travelTime=20
// → 실제 점유: 13:40 ~ 15:00

// 다음 레슨 가능 시간 = 레슨 종료 + 쉬는시간
// = 15:00 + 10 = 15:10
// 레슨 B의 이동 시작 = 레슨B 시작 - travelTime
// 레슨 B at 15:30, travelTime=20 → 이동 시작 15:10 ✅ (겹치지 않음)

// 충돌 조건:
// 새 레슨의 (시작 - 이동시간) < 기존 레슨 종료 + 쉬는시간
```

### 5.4 버퍼 계산 규칙 (수정)

```
기존 (v1): 다음 예약 = 레슨 종료 + max(쉬는시간, 이동시간)
수정 (v2): 다음 예약 = 레슨 종료 + 쉬는시간

단, 다음 레슨의 실제 시작 = 예약 시작 - 이동시간
→ 이동 블록이 이전 레슨 + 쉬는시간과 겹치면 충돌

예) breakTime=10, 레슨A 15:00 종료
   → 다음 이동 가능: 15:10부터
   → 학생B travelTime=20 → 레슨B 시작 최소 15:30
   → 학생C travelTime=0 → 레슨C 시작 최소 15:10
```

---

## 6. 수강권(ClassMembership) 장소 설정 UI

### 6.1 수강권 생성/편집 시

```
┌─────────────────────────────────────┐
│ 레슨 장소 & 이동시간                  │
├─────────────────────────────────────┤
│                                     │
│  📍 레슨 장소 유형:                  │
│  ┌───────┐┌───────┐┌───────┐       │
│  │학생 집 ││ 학원  ││스튜디오│       │
│  └───────┘└───────┘└───────┘       │
│  ┌───────┐┌───────┐                │
│  │선생님집││온라인  │                │
│  └───────┘└───────┘                │
│                                     │
│  📌 레슨 장소:                       │
│  서울시 강남구 역삼동 123-45         │
│  (학생 등록 주소에서 자동입력)         │
│                                     │
│  🚗 이동시간: [20분 ▼]              │
│  (0 / 10 / 20 / 30 / 45 / 60분)    │
│                                     │
│  💡 이 시간은 스케줄에서 레슨 시작    │
│     전에 이동 블록으로 표시됩니다     │
│                                     │
└─────────────────────────────────────┘
```

### 6.2 자동입력 규칙

| 장소 유형 | 주소 소스 | 이동시간 기본값 |
|-----------|----------|---------------|
| 학생 집 | `Student.address` | 수기 (우편번호 기반 제안) |
| 학원 | `LessonClass.address` | 0분 (수기 변경 가능) |
| 외부 스튜디오 | 수기 입력 | 수기 |
| 선생님 스튜디오 | `TeacherProfile` 주소 | 0분 (고정) |
| 온라인 | N/A | 0분 (고정) |

---

## 7. 구현 단계

### Phase 1: 학생 주소 모델 + 입력 UI

| # | 작업 | 파일 | 복잡도 |
|---|------|------|:------:|
| 1-1 | Student 엔티티에 postalCode, address, addressDetail, district 추가 | student.dart, student.g.dart | M |
| 1-2 | 학생 등록 화면에 주소 입력 섹션 추가 (우편번호 → 주소 자동완성) | add_student_screen.dart | H |
| 1-3 | 학생 편집 화면에 주소 수정 지원 | edit_student_screen.dart | M |
| 1-4 | 우편번호 → 구/동 변환 유틸리티 | postal_code_utils.dart | L |
| 1-5 | Mock 학생 데이터에 주소 추가 | mock_student_repository.dart | L |

### Phase 2: 수강권 장소 선택 UX

| # | 작업 | 파일 | 복잡도 |
|---|------|------|:------:|
| 2-1 | 수강권 생성 시 장소 유형 선택 UI (5종 칩) | membership 화면 | H |
| 2-2 | 장소 유형별 주소 자동입력 로직 | location_providers.dart | M |
| 2-3 | 이동시간 드롭다운 (0/10/20/30/45/60분) | membership 화면 | L |
| 2-4 | 레슨 추가 시 수강권 기본 장소 자동 선택 | add_lesson_screen.dart | M |
| 2-5 | 레슨 카드에 장소 아이콘 표시 | lesson_card 관련 | L |

### Phase 3: 이동시간 "레슨 전" 전환

| # | 작업 | 파일 | 복잡도 |
|---|------|------|:------:|
| 3-1 | _computeSlotsForDate: 이동시간을 레슨 전으로 계산 | mock_teacher_availability_repository.dart | H |
| 3-2 | _findConflictingSlot: 버퍼 방향 전환 (후→전) | mock_teacher_availability_repository.dart | H |
| 3-3 | 타임라인 뷰: 이동 블록을 레슨 "위"에 배치 | schedule_timeline_view.dart | M |
| 3-4 | 주간 그리드: 이동 블록을 레슨 "앞" 셀에 배치 | schedule_weekly_grid_view.dart | M |
| 3-5 | 레슨 추가 시 이동시간 충돌 경고 | add_lesson_screen.dart | M |

### Phase 4: 통합 + 고도화 (향후)

| # | 작업 | 파일 | 복잡도 |
|---|------|------|:------:|
| 4-1 | 우편번호 기반 이동시간 자동 제안 | postal_travel_estimator.dart | M |
| 4-2 | 학생 상세에서 레슨 장소 + 이동시간 요약 표시 | student_detail_screen.dart | L |
| 4-3 | 월간 이동 리포트 (시간/거리 합계) | analytics 관련 | M |

---

## 8. 기존 코드 수정 사항

### 8.1 이동시간 방향 전환 (Phase 3 핵심)

**현재 (v1) — 레슨 후 배치:**
```dart
// _findConflictingSlot에서:
effectiveBookedEnd = bookedEndMinutes + bufferAfter;
// → 이동 블록이 레슨 끝 뒤에 표시
```

**변경 (v2) — 레슨 전 배치:**
```dart
// 각 레슨의 점유 범위:
effectiveStart = lessonStartMinutes - travelTimeMinutes;
effectiveEnd = lessonEndMinutes;
// → 이동 블록이 레슨 시작 앞에 표시

// 충돌 조건:
// newEffectiveStart < existingEnd + breakTime
// newEnd > existingEffectiveStart - breakTime
```

### 8.2 시각화 변경

**현재**: `schedule_timeline_view.dart`에서 `_TravelTimeBlock`이 레슨 아래에 렌더링
**변경**: 레슨 위에 렌더링 (top = lessonTop - travelHeight)

---

## 9. 리스크 및 대응

| 리스크 | 수준 | 대응 |
|--------|:----:|------|
| 이동시간 방향 전환 시 기존 슬롯 로직 충돌 | HIGH | Phase 3 집중 테스트, 기존 breakTime 로직과 독립 검증 |
| Student 엔티티 변경 → Hive 마이그레이션 | MEDIUM | Mock 단계이므로 앱 삭제 후 재설치로 해결 |
| 우편번호 자동완성 API 선정 | MEDIUM | 카카오 주소 API (무료, 한국 특화) 사용 |
| 수강권 생성 플로우 복잡도 증가 | MEDIUM | 장소 유형별 스마트 기본값으로 입력 최소화 |

---

## 10. 용어 정리

| 용어 | 비유 | 설명 |
|------|------|------|
| 수강권 (ClassMembership) | 쇼핑몰 주문 | N회 레슨 패키지, 장소·이동시간 확정 |
| 정기권 | Autoship (정기배송) | 매월 자동 갱신, 동일 설정 유지 |
| 레슨 장소 (LessonLocation) | 배송지 | 레슨이 진행되는 물리적/온라인 장소 |
| 이동시간 (travelTimeMinutes) | 배송 소요시간 | 선생님이 장소에 도착하는 데 걸리는 시간 |
| 쉬는시간 (breakTime) | 상품 준비시간 | 레슨 간 선생님 휴식 |
| 우편번호 | 배송 구역 | 대략적 위치 판별용 (프라이버시 보호) |

---

## 11. 선생님 주소 (v2, 2026-05-07)

### 11.1 문제

선생님 프로필에 주소가 없어 이동시간 자동 측정이 불가능. 학생 주소와 대조할 기준점이 없음.

### 11.2 TeacherProfile 확장

```dart
// 선생님 프로필에 추가
final String? postalCode;        // 우편번호 (5자리)
final String? address;            // 기본주소 (시/구/동)
final String? addressDetail;      // 상세주소 (비공개)
final String? studioName;         // 스튜디오 이름 (있으면)
```

- 가입/프로필 편집 시 입력 (필수 아님)
- "학생 집 방문" 레슨 시 이동시간 자동 측정의 출발지로 사용
- 프라이버시: 학생에게 구/동까지만 노출 (상세주소 비공개)

---

## 12. 이동시간 자동 측정 API (v2, 2026-05-07)

### 12.1 유사 서비스 분석

| 서비스 | 이동시간 처리 | 배울 점 |
|--------|-------------|---------|
| **MarketBox** | 지도 기반 자동 계산 (구글 Distance Matrix) | 완전 자동화, 비용 높음 |
| **배달의민족** | 가게↔고객 거리 기반 배달 시간 자동 | 한국 지도 API (카카오) 활용 |
| **카카오택시** | 출발지↔도착지 예상 소요시간 | Kakao Mobility API |
| **당근마켓** | 동 단위 거리 표시 (km) | 간단한 직선 거리 |
| **Fons (미국)** | 수동 입력 | 자동화 없음 |

### 12.2 API 선정

| 국가 | API | 비용 | 정확도 |
|------|-----|------|--------|
| **한국** | Kakao Mobility 길찾기 API | 무료 (일 10만건) | 실제 도로 기반 (높음) |
| **한국 대안** | Naver Directions API | 무료 (일 4만건) | 실제 도로 기반 (높음) |
| **글로벌** | Google Distance Matrix API | $5/1000건 | 높음 |

**결정: Kakao Mobility 우선 → 실패 시 직선 거리 기반 추정 → 최종 fallback은 수기 입력**

### 12.3 자동 측정 플로우

```
수강권 생성 → 장소: "학생 집" 선택
  ↓
학생 주소 자동입력 (Student.address)
  ↓
선생님 주소 존재?
  ├─ YES → API 호출 (백그라운드)
  │   ├─ 성공: 이동시간 입력박스에 제안값 자동기입 (예: "약 25분")
  │   │   └─ 선생님이 수정 가능 (제안값은 참고용)
  │   └─ 실패: 아무 표시 안 함 (에러 메시지 없음, 수기 입력으로)
  └─ NO → 수기 입력 (제안 없음)
```

**핵심 원칙:**
- API 실패 시 **에러 메시지 없음** — 그냥 제안시간을 기입 안 하면 됨
- 성공 시 입력박스에 **제안시간으로 자동기입** — 선생님이 수정 가능
- 제안값은 "약 N분" 형태로 5분 단위 올림

### 12.4 백엔드 API

```
GET /api/v1/travel-time/estimate
  ?origin_address=서울시 강남구 역삼동
  &destination_address=서울시 서초구 반포동
```

**처리 로직:**
1. 캐시 확인 (동일 출발지-도착지 조합, 24시간 유효)
2. 캐시 없으면 → Kakao Mobility API 호출
3. 응답에서 `duration` (분) 추출
4. 5분 단위 올림 (예: 23분 → 25분)
5. 캐시 저장

**Response:**
```json
{
  "estimated_minutes": 25,
  "source": "kakao",        // "kakao" | "naver" | "google" | "estimate"
  "distance_km": 8.3
}
```

**실패 시:**
```json
{
  "estimated_minutes": null,
  "source": "unavailable",
  "distance_km": null
}
```

### 12.5 프론트엔드 통합

```dart
/// 이동시간 자동 제안 호출 (LocationTravelSelector에서 사용)
@riverpod
Future<int?> estimatedTravelTime(
  Ref ref, {
  required String teacherId,
  required String studentAddress,
}) async {
  // 선생님 주소 조회
  final teacher = await ref.watch(teacherProfileProvider(teacherId).future);
  if (teacher?.address == null) return null;

  // 백엔드 API 호출
  try {
    final result = await ref.read(travelTimeApiProvider).estimate(
      originAddress: teacher!.address!,
      destinationAddress: studentAddress,
    );
    return result.estimatedMinutes;
  } catch (_) {
    return null;  // 실패 시 null → UI에서 무시
  }
}
```

### 12.6 LocationTravelSelector UI 변경

```
기존:
  🚗 이동시간: [20분 ▼] (드롭다운)

변경:
  🚗 이동시간: [  25  ] 분  ← 자유 입력 (API 성공 시 자동기입)
               약 25분 (카카오 기준)  ← 제안 라벨 (있으면)
```

- 드롭다운 → **자유 입력** (숫자 TextField, 분 단위)
- API 제안값이 있으면 자동기입 + 하단에 "(카카오 기준)" 라벨
- 선생님이 자유롭게 수정 가능

---

## 13. 이동거리 기반 추가 과금 (v2, 2026-05-07)

### 13.1 문제

방문 레슨 선생님은 이동시간이 곧 비용. 이동 거리/시간에 따라 레슨비에 추가 과금이 필요.

### 13.2 유사 서비스 분석

| 서비스 | 이동비 처리 | 배울 점 |
|--------|-----------|---------|
| **MarketBox** | 지역별 요금표 (zone pricing) | 구역 단위 과금 |
| **배달의민족** | 거리별 배달비 (기본+추가) | 기본 거리 무료 + 초과 km당 과금 |
| **카카오택시** | 거리+시간 기반 요금 | 실시간 요금 |
| **우버** | Surge pricing (수요 기반) | 동적 가격 |
| **방문 과외** | 교통비 별도 or 레슨비에 포함 | **선생님이 결정** (우리 모델) |

### 13.3 설계: 선생님이 수강권 발급 시 결정

> **원칙:** 이동비는 선생님이 수강권 금액에 포함하여 결정. 별도 "이동비" 항목이 아니라 **레슨비에 반영**.

```
수강권 발급 화면:
┌─────────────────────────────────────┐
│ 수강권 금액                          │
│                                     │
│  기본 레슨비: 50,000원/회            │
│  이동시간: 25분                      │
│                                     │
│  💡 이동시간 25분 기준               │
│     참고 추가금: +10,000원/회        │
│     (선생님 시급 기준 자동 계산)      │
│                                     │
│  최종 레슨비: [  60,000  ] 원/회     │
│  (선생님이 자유롭게 결정)            │
│                                     │
└─────────────────────────────────────┘
```

### 13.4 추가금 자동 계산 (참고용)

```dart
/// 이동시간 기반 추가금 제안 (참고용, 강제 아님)
int suggestedTravelSurcharge({
  required int travelTimeMinutes,
  required int baseLessonFee,
  required int lessonDurationMinutes,
}) {
  if (travelTimeMinutes <= 0) return 0;

  // 선생님 시급 = 기본 레슨비 / 레슨시간(시간)
  final hourlyRate = baseLessonFee / (lessonDurationMinutes / 60);

  // 이동시간 비용 = 시급 × (이동시간/60)
  final travelCost = hourlyRate * (travelTimeMinutes / 60);

  // 1,000원 단위 올림
  return ((travelCost / 1000).ceil() * 1000).toInt();
}

// 예: 레슨비 50,000원/60분, 이동 25분
// 시급 = 50,000
// 이동비 = 50,000 × (25/60) = 20,833 → 21,000원
// 제안: "+21,000원/회"
```

**핵심:** 이 금액은 **참고용 제안**. 선생님이 최종 레슨비를 자유롭게 결정. "참고 추가금"으로 표시.

### 13.5 데이터 모델

```dart
// Subscription/수강권에 추가
final int? travelSurcharge;  // 이동 추가금 (원, 참고용 기록)
```

- 별도 필드로 기록하되, 실제 청구는 `amount`(총 수강권 금액)에 포함
- 학생에게는 총 금액만 노출, 이동 추가금은 선생님만 확인 가능

---

## 14. 스케줄 이동시간 표기 (v2, 2026-05-07)

### 14.1 선생님 스케줄 타임라인

```
13:40 ┌──────────────────┐
      │ 🚗 이동 (25분)    │ ← 빗금(hatched) 패턴 배경
      │ → 김서연 (강남구)  │
14:00 ├──────────────────┤
      │ ■ 김서연 바이올린  │ ← 실선 배경 (악기 색상)
      │   📍 학생 집       │
15:00 └──────────────────┘
      ⸻ 쉬는시간 (10분) ⸻
15:10 ┌──────────────────┐
      │ 🚗 이동 (15분)    │
      │ → 이하은 (서초구)  │
15:25 ├──────────────────┤
      │ ■ 이하은 피아노    │
      │   📍 학원          │
16:25 └──────────────────┘
```

### 14.2 선생님 주간 그리드

```
           월     화     수     목     금
13:00           ░░░░          ░░░░
13:30           ░이동░          ░이동░
14:00           ████          ████
14:30           █김민█          █박지█
15:00           ████          ████
```

- `░` = 이동 블록 (hatched/striped 패턴)
- `█` = 레슨 블록 (악기 색상)
- 이동 블록 높이 = `travelTimeMinutes / 30 * cellHeight`

---

## 15. 주소 검색 API — 서버 경유 설계 (v3, 2026-05-07)

### 15.1 핵심 원칙

> **프론트엔드는 외부 주소 API를 직접 호출하지 않는다.**
> 우리 서버가 외부 API를 래핑하여 통일된 응답을 제공.
> API 키는 백엔드 환경변수에서 관리 → 프론트에 키 노출 없음.

### 15.2 프론트엔드 ↔ 백엔드 계약

```
[프론트: AddressSearchField]
    │
    └── GET /api/v1/address/search?query=역삼동+123
              │
[백엔드: AddressRouter → AddressService]
    │
    └── AddressProvider.search(query)
              │
    ┌─── 외부 API (의존성 주입) ────┐
    │                              │
    ├── KakaoAddressProvider       │  ← 한국 기본 (Kakao 주소 검색 API)
    ├── NaverAddressProvider       │  ← 한국 대안
    └── GoogleAddressProvider      │  ← 글로벌
```

### 15.3 프론트엔드 API 호출

```dart
/// 프론트에서 호출하는 유일한 주소 검색 메서드.
/// 외부 API 키 불필요 — 서버가 처리.
Future<List<AddressSearchResult>> searchAddress(String query) async {
  final response = await dio.get('/api/v1/address/search', queryParameters: {
    'query': query,
    'page': 1,
    'size': 10,
  });
  return (response.data['results'] as List)
      .map((e) => AddressSearchResult.fromJson(e))
      .toList();
}
```

### 15.4 응답 모델 (프론트+백엔드 공유)

```dart
class AddressSearchResult {
  final String postalCode;      // "06241"
  final String address;          // "서울특별시 강남구 역삼동 123-45"
  final String? roadAddress;     // "서울특별시 강남구 테헤란로 123"
  final String district;         // "강남구 역삼동"
  final double? latitude;
  final double? longitude;
}
```

### 15.5 백엔드 의존성 주입 설계

```python
# backend/app/services/address_service.py

class AddressProvider(ABC):
    """외부 주소 API 추상 인터페이스."""
    @abstractmethod
    async def search(self, query: str, page: int, size: int) -> AddressSearchResponse:
        ...

class KakaoAddressProvider(AddressProvider):
    """카카오 주소 검색 API (https://developers.kakao.com/docs/latest/ko/local/dev-guide)."""
    def __init__(self, api_key: str):
        self._api_key = api_key  # KAKAO_REST_API_KEY

    async def search(self, query, page, size):
        # GET https://dapi.kakao.com/v2/local/search/address
        # Authorization: KakaoAK {api_key}
        ...

class NaverAddressProvider(AddressProvider):
    """네이버 지역 검색 API (대안)."""
    ...

class GoogleAddressProvider(AddressProvider):
    """Google Geocoding API (글로벌)."""
    ...

class AddressService:
    """주소 검색 서비스 — provider 체인으로 fallback."""
    def __init__(self, providers: list[AddressProvider]):
        self._providers = providers

    async def search(self, query: str, page: int = 1, size: int = 10):
        for provider in self._providers:
            try:
                return await provider.search(query, page, size)
            except Exception:
                continue
        return AddressSearchResponse(results=[], total_count=0, page=page)
```

### 15.6 환경변수

```bash
# .env
ADDRESS_PROVIDER=kakao            # 기본 provider (kakao | naver | google)
KAKAO_REST_API_KEY=your_key_here  # 카카오 REST API 키
NAVER_CLIENT_ID=your_id           # 네이버 (대안)
NAVER_CLIENT_SECRET=your_secret
GOOGLE_MAPS_API_KEY=your_key      # 구글 (글로벌)
```

### 15.7 이동시간 API도 동일 패턴

```
GET /api/v1/travel-time/estimate
    → TravelTimeService → DirectionsProvider (interface)
        ├── KakaoDirectionsProvider   ← 카카오 길찾기 API
        ├── NaverDirectionsProvider   ← 네이버 Directions
        └── GoogleDirectionsProvider  ← 구글 Distance Matrix
```

- 주소 검색과 **동일한 API 키** 공유 (카카오 REST API 키로 주소+길찾기 모두 가능)
- provider 실패 시 fallback chain 동일

### 15.8 주소 검색 UI (프론트엔드)

> **원칙**: 주소 검색은 고정 UI. 우편번호는 검색 시 백그라운드 자동 저장 (수기 입력 불필요).

`AddressSearchField` UI:

```
┌──────────────────────────────┐
│ 📍 서울시 강남구 역삼동 123   [검색] │
└──────────────────────────────┘
│ 상세주소 (동/호수)              │
└──────────────────────────────┘
```

- 검색 버튼 → 바텀시트에서 주소 검색 → 선택 시 postalCode + address 자동 채움
- 우편번호는 UI에 노출하지 않고 백그라운드 저장 (이동시간 API 출발지 좌표 계산용)
- 상세주소는 자유 입력

검색 바텀시트에서 결과가 없을 때:
```
검색 결과가 없습니다
[주소를 직접 입력하려면 닫아주세요 →]
```

### 15.8.1 선생님 프로필 — "기본 레슨 장소"

위치: 선생님 기본정보수정 > 활동 지역 아래

```
[기본 레슨 장소]
학생 방문 시 위치 안내, 출장 레슨 이동시간 자동 계산,
수강권 발급 시 이동비 산정에 활용됩니다

📍 [서울시 강남구 역삼동 123-45    ] [검색]
   [상세주소 (동/호수)              ]
```

활용처:
- 학생이 선생님에게 방문할 때 위치 안내
- 선생님 출장 레슨 시 이동시간 API의 출발지 (선생님 주소 → 학생 주소)
- 수강권 발급 시 이동비 참고 금액 자동 산정

이동시간 자동 제안도 동일:
- API 성공 → 입력박스에 자동기입 (선생님 수정 가능)
- API 실패 → 아무 표시 없음, 선생님이 수기 입력
- 에러 메시지 노출 안 함

### 15.9 프론트엔드 AddressSearchField Remote 전환

현재 `core/widgets/address_search_field.dart`는 mock 데이터 사용.
백엔드 API 준비 후:

```dart
// Mock → Remote 전환
class RemoteAddressSearchApi implements AddressSearchApi {
  final Dio _dio;

  @override
  Future<List<AddressSearchResult>> search(String query) async {
    final response = await _dio.get('/api/v1/address/search',
      queryParameters: {'query': query});
    return (response.data['results'] as List)
        .map((e) => AddressSearchResult.fromJson(e)).toList();
  }
}
```

환경변수 `USE_MOCK_DATA=true` 시 mock, `false` 시 remote 자동 전환 (기존 패턴).

---

## 16. 변경 이력

| 날짜 | 내용 |
|------|------|
| 2026-05-07 | v3 추가: §15 주소 검색 API 서버 경유 설계 (의존성 주입, 환경변수, fallback chain) |
| 2026-05-07 | v2 추가: §11 선생님 주소, §12 이동시간 자동 측정 API, §13 추가 과금, §14 스케줄 표기 |
| 2026-03-15 | v1 초판 작성 — 레슨 장소 5종, 학생 주소, 이동시간 수기, 경쟁사 분석 |
