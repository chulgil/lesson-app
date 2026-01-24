# 학생 클래스(소속) 시스템 설계

> 작성일: 2026-01-24
> 상태: 설계 완료

## 개요

선생님이 여러 학원과 개인레슨을 동시에 관리할 수 있도록, 학생 그룹화 및 소속 개념을 재설계합니다.

### 핵심 목표
1. 한 선생님이 **여러 학원 + 개인레슨** 동시 관리
2. **결제 주체** (학원결제 vs 학부모결제) 명확한 구분
3. 한 학생이 **여러 선생님에게 레슨** 받을 수 있는 구조
4. 기존 데이터와의 **하위 호환성** 유지

---

## 엔티티 설계

### 1. LessonClass (클래스/소속 그룹)

학원 또는 개인레슨 그룹을 나타내는 엔티티입니다.

```dart
/// 클래스 유형
enum LessonClassType {
  academy,   // 학원 (기관 소속)
  private,   // 개인레슨
}

/// 결제 유형
enum PaymentType {
  organization,  // 기관(학원)에서 일괄 결제 → 선생님은 급여
  parent,        // 학부모가 선생님에게 직접 결제
}

/// 클래스/소속 그룹
class LessonClass {
  final String id;
  final String teacherId;        // 소유 선생님 ID

  // 기본 정보
  final String name;             // "○○음악학원", "개인레슨" 등
  final LessonClassType type;    // academy | private
  final PaymentType paymentType; // organization | parent

  // 학원 정보 (type == academy인 경우)
  final String? contactPerson;   // 학원 담당자 이름
  final String? contactPhone;    // 학원 연락처
  final String? address;         // 학원 주소

  // 설정
  final int sortOrder;           // 표시 순서
  final bool isArchived;         // 보관 여부

  // 메타
  final DateTime createdAt;
  final DateTime? updatedAt;
}
```

### 2. ClassMembership (클래스 소속 관계)

학생이 특정 클래스에 소속된 관계와 해당 클래스에서의 레슨 정보입니다.

```dart
/// 학생의 클래스 소속 정보
class ClassMembership {
  final String id;
  final String lessonClassId;    // 소속 클래스 ID
  final String studentId;        // 학생 ID

  // 이 클래스에서의 레슨 정보
  final String instrument;       // 악기 (피아노, 바이올린 등)
  final StudentStatus status;    // 체험/정규/휴강/종료
  final StudentLevel level;      // 레벨 (입문/초급/중급/고급)

  // 수강료 정보
  final int monthlyFee;          // 월 수강료
  final int lessonsPerWeek;      // 주당 레슨 횟수 (1 or 2)

  // 레슨 스케줄
  final String? lessonDay;       // 레슨 요일 (월, 화, ...)
  final String? lessonTime;      // 레슨 시간 (14:00)
  final int lessonDuration;      // 레슨 시간(분) (기본 60)

  // 메모
  final String? notes;           // 특이사항

  // 메타
  final DateTime createdAt;
  final DateTime? updatedAt;

  // 계산 필드
  int get monthlyLessonCount => lessonsPerWeek * 4;
  int get lessonFee => (monthlyFee / monthlyLessonCount).round();
}
```

### 3. Student (학생) - 단순화

학생의 **기본 정보만** 포함합니다. 레슨/수강료 정보는 ClassMembership으로 이동합니다.

```dart
/// 학생 (플랫폼 사용자)
class Student {
  final String id;

  // 기본 정보
  final String name;
  final Color profileColor;
  final String? profileImageUrl;

  // 연락처 (개인레슨용, 학원 학생은 비워둘 수 있음)
  final String? phone;           // 학생 본인 연락처
  final String? parentPhone;     // 학부모 연락처
  final String? parentName;      // 학부모 이름
  final String? email;

  // 연령 정보
  final DateTime? birthDate;     // 생년월일 (연령 그룹 계산용)
  final AgeGroup? manualAgeGroup; // 수동 설정 연령 그룹

  // 앱 연결 상태
  final ConnectionStatus connectionStatus;
  final DateTime? connectedAt;

  // 메타
  final DateTime createdAt;
  final DateTime? updatedAt;

  // 계산 필드
  AgeGroup get effectiveAgeGroup =>
      AgeGroup.fromBirthDate(birthDate) ?? manualAgeGroup ?? AgeGroup.student;
}
```

---

## 관계도

```
┌─────────────────────────────────────────────────────────────────┐
│                        Teacher                                   │
│                     (선생님 계정)                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ 1:N (선생님은 여러 클래스 소유)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      LessonClass                                 │
│   ┌─────────────────┐  ┌─────────────────┐  ┌───────────────┐   │
│   │ ○○음악학원       │  │ △△학원          │  │ 개인레슨       │   │
│   │ type: academy   │  │ type: academy   │  │ type: private │   │
│   │ payment: org    │  │ payment: org    │  │ payment: parent│  │
│   └─────────────────┘  └─────────────────┘  └───────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ N:M (ClassMembership으로 연결)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    ClassMembership                               │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │ studentId: s1, classId: c1                               │   │
│   │ instrument: 피아노, level: 중급, monthlyFee: 200000     │   │
│   │ lessonDay: 화, lessonTime: 15:00, duration: 60         │   │
│   └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ N:1 (멤버십은 하나의 학생에 연결)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Student                                   │
│   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│   │ 김민수        │  │ 이서연        │  │ 박지훈        │         │
│   │ 앱 연결됨     │  │ 앱 연결됨     │  │ 앱 미연결     │         │
│   └──────────────┘  └──────────────┘  └──────────────┘         │
└─────────────────────────────────────────────────────────────────┘
```

---

## 사용 시나리오

### 시나리오 1: 한 선생님이 여러 학원 + 개인레슨 관리

```
박선생님 (Teacher)
│
├── ○○음악학원 (LessonClass: academy, org-payment)
│   ├── 김민수 - 피아노 중급, 월 20만원, 화 15:00
│   ├── 이서연 - 피아노 초급, 월 18만원, 화 16:00
│   └── 박지훈 - 피아노 입문, 월 16만원, 수 14:00
│
├── △△학원 (LessonClass: academy, org-payment)
│   ├── 최유진 - 바이올린 중급, 월 22만원, 목 15:00
│   └── 정하늘 - 바이올린 초급, 월 20만원, 목 16:00
│
└── 개인레슨 (LessonClass: private, parent-payment)
    ├── 강서윤 - 피아노 고급, 월 30만원, 금 17:00
    │   └── 학부모: 강○○ (010-1234-5678)
    └── 한도윤 - 바이올린 중급, 월 28만원, 토 10:00
        └── 학부모: 한○○ (010-8765-4321)
```

### 시나리오 2: 한 학생이 여러 선생님에게 레슨

```
김민수 (Student)
│
├── 박선생님 / ○○음악학원 → 피아노 레슨
│   └── ClassMembership: instrument=피아노, level=중급
│
└── 이선생님 / 개인레슨 → 바이올린 레슨
    └── ClassMembership: instrument=바이올린, level=초급
```

### 시나리오 3: 학생이 학원 이동

```
이서연 (Student)
│
├── [종료] 박선생님 / ○○음악학원 (status: inactive)
│
└── [현재] 김선생님 / ◇◇음악교실 (status: active)
```

---

## UI 설계

### 선생님 앱: 학생 목록 화면

```
┌────────────────────────────────────────┐
│ ← 내 학생들                    [+ 추가] │
├────────────────────────────────────────┤
│                                        │
│ ▼ ○○음악학원 (3명)            [설정 ⚙️] │
│   ┌────────────────────────────────┐  │
│   │ 👤 김민수  피아노 중급  화 15:00 │  │
│   │    상태: 정규  │  월 200,000원  │  │
│   ├────────────────────────────────┤  │
│   │ 👤 이서연  피아노 초급  화 16:00 │  │
│   │    상태: 정규  │  월 180,000원  │  │
│   ├────────────────────────────────┤  │
│   │ 👤 박지훈  피아노 입문  수 14:00 │  │
│   │    상태: 체험  │  월 160,000원  │  │
│   └────────────────────────────────┘  │
│                                        │
│ ▶ △△학원 (2명)                [접힘]  │
│                                        │
│ ▼ 개인레슨 (2명)              [설정 ⚙️] │
│   ┌────────────────────────────────┐  │
│   │ 👤 강서윤  피아노 고급  금 17:00 │  │
│   │    📱 학부모: 010-1234-5678    │  │ ← 개인레슨만 표시
│   │    상태: 정규  │  월 300,000원  │  │
│   └────────────────────────────────┘  │
│                                        │
└────────────────────────────────────────┘
```

### 학생 추가 플로우

```
1단계: 클래스 선택
┌────────────────────────────────────────┐
│ 어느 클래스에 추가할까요?               │
├────────────────────────────────────────┤
│ ○ ○○음악학원                          │
│ ○ △△학원                              │
│ ● 개인레슨                             │
│                                        │
│ [+ 새 클래스 만들기]                    │
└────────────────────────────────────────┘

2단계: 학생 정보 (기존 학생 선택 또는 신규)
┌────────────────────────────────────────┐
│ 학생 정보                               │
├────────────────────────────────────────┤
│ [기존 학생 검색] 또는 [신규 등록]        │
│                                        │
│ 이름 *: [_______________]              │
│ 학부모 연락처: [_______________]        │ ← 개인레슨만
└────────────────────────────────────────┘

3단계: 레슨 정보 (ClassMembership)
┌────────────────────────────────────────┐
│ 레슨 정보                               │
├────────────────────────────────────────┤
│ 악기 *: [피아노 ▼]                      │
│ 레벨: [중급 ▼]                          │
│ 월 수강료 *: [200,000]원                │
│ 레슨 요일: [화 ▼]                       │
│ 레슨 시간: [15:00]                      │
│ 레슨 시간(분): [60]                     │
└────────────────────────────────────────┘
```

### 클래스 설정 화면

```
┌────────────────────────────────────────┐
│ ← ○○음악학원 설정                       │
├────────────────────────────────────────┤
│                                        │
│ 클래스명                                │
│ [○○음악학원________________]            │
│                                        │
│ 유형: 학원                              │
│ 결제 방식: 학원에서 일괄 처리            │
│                                        │
│ ── 학원 정보 ──                         │
│ 담당자: [홍길동______________]          │
│ 연락처: [02-1234-5678________]         │
│ 주소:   [서울시 강남구 ...]             │
│                                        │
│ ── 위험 구역 ──                         │
│ [클래스 보관하기]                       │
│ [클래스 삭제하기]                       │
│                                        │
└────────────────────────────────────────┘
```

---

## 데이터 마이그레이션

### 마이그레이션 전략

기존 Student 데이터를 새 구조로 변환합니다.

```dart
Future<void> migrateToClassSystem() async {
  // 1. 기본 "개인레슨" 클래스 생성
  final defaultClass = LessonClass(
    id: uuid.v4(),
    teacherId: currentTeacherId,
    name: '개인레슨',
    type: LessonClassType.private,
    paymentType: PaymentType.parent,
    createdAt: DateTime.now(),
  );
  await lessonClassRepository.create(defaultClass);

  // 2. 기존 학생 데이터 분리
  final oldStudents = await oldStudentRepository.getAll();

  for (final oldStudent in oldStudents) {
    // 2a. Student 엔티티 생성 (기본 정보만)
    final newStudent = Student(
      id: oldStudent.id,
      name: oldStudent.name,
      phone: oldStudent.phone,
      parentPhone: oldStudent.parentPhone,
      profileColor: oldStudent.profileColor,
      birthDate: oldStudent.birthDate,
      connectionStatus: oldStudent.connectionStatus,
      connectedAt: oldStudent.connectedAt,
      createdAt: oldStudent.createdAt,
    );
    await studentRepository.create(newStudent);

    // 2b. ClassMembership 생성 (레슨 정보)
    final membership = ClassMembership(
      id: uuid.v4(),
      lessonClassId: defaultClass.id,
      studentId: newStudent.id,
      instrument: oldStudent.instrument,
      status: oldStudent.status,
      level: oldStudent.level,
      monthlyFee: oldStudent.monthlyFee,
      lessonsPerWeek: oldStudent.lessonsPerWeek,
      lessonDay: oldStudent.lessonDay,
      lessonTime: oldStudent.lessonTime,
      lessonDuration: oldStudent.lessonDuration,
      createdAt: DateTime.now(),
    );
    await membershipRepository.create(membership);
  }
}
```

### 하위 호환성

기존 코드와의 호환을 위해 확장 메서드를 제공합니다.

```dart
/// 기존 코드 호환을 위한 확장
extension StudentWithMembershipX on Student {
  /// 특정 클래스에서의 멤버십 정보와 결합
  StudentWithMembership withMembership(ClassMembership membership) {
    return StudentWithMembership(
      student: this,
      membership: membership,
    );
  }
}

/// 기존 Student 형태로 사용할 수 있는 결합 클래스
class StudentWithMembership {
  final Student student;
  final ClassMembership membership;

  // 기존 필드 접근 (하위 호환)
  String get id => student.id;
  String get name => student.name;
  String get instrument => membership.instrument;
  int get monthlyFee => membership.monthlyFee;
  StudentStatus get status => membership.status;
  // ... 기타 필드
}
```

---

## Provider 설계

```dart
// 클래스 목록
@riverpod
Future<List<LessonClass>> teacherClasses(Ref ref, String teacherId) async {
  final repository = ref.watch(lessonClassRepositoryProvider);
  return repository.getClassesByTeacher(teacherId);
}

// 특정 클래스의 멤버십 목록 (학생 정보 포함)
@riverpod
Future<List<StudentWithMembership>> classMemberships(
  Ref ref,
  String classId,
) async {
  final membershipRepo = ref.watch(membershipRepositoryProvider);
  final studentRepo = ref.watch(studentRepositoryProvider);

  final memberships = await membershipRepo.getByClassId(classId);

  return Future.wait(memberships.map((m) async {
    final student = await studentRepo.getById(m.studentId);
    return student!.withMembership(m);
  }));
}

// 선생님의 모든 학생 (클래스별 그룹화)
@riverpod
Future<Map<LessonClass, List<StudentWithMembership>>> groupedStudents(
  Ref ref,
  String teacherId,
) async {
  final classes = await ref.watch(teacherClassesProvider(teacherId).future);

  final result = <LessonClass, List<StudentWithMembership>>{};
  for (final cls in classes) {
    final members = await ref.watch(classMembershipsProvider(cls.id).future);
    result[cls] = members;
  }
  return result;
}
```

---

## 구현 우선순위

### Phase 1: 기반 작업
- [ ] LessonClass 엔티티 생성
- [ ] ClassMembership 엔티티 생성
- [ ] Student 엔티티 단순화
- [ ] Repository 인터페이스 정의
- [ ] Mock Repository 구현

### Phase 2: 데이터 마이그레이션
- [ ] 마이그레이션 스크립트 작성
- [ ] 하위 호환성 확장 메서드
- [ ] 기존 Provider 업데이트

### Phase 3: UI 업데이트
- [ ] 학생 목록 화면 (그룹화)
- [ ] 클래스 관리 화면
- [ ] 학생 추가 플로우 변경
- [ ] 클래스 설정 화면

### Phase 4: 기능 확장
- [ ] 결제/정산 기능 클래스별 분리
- [ ] 레슨 기록 클래스별 필터링
- [ ] 통계/리포트 클래스별 집계

---

## 레슨 장소 시스템

LessonClass와 연계하여 레슨 장소를 체계적으로 관리합니다.

### 장소 유형

| 유형 | 아이콘 | 설명 | 예시 |
|------|:-----:|------|------|
| **학원 레슨실** | 🏫 | 학원 내 지정 공간 | 레슨실 1, 그랜드피아노실 |
| **선생님 스튜디오** | 🏠 | 선생님 개인 공간 | 홈스튜디오 |
| **학생 집 방문** | 🚗 | 출장 레슨 | 학생 자택 |
| **외부 장소** | 📍 | 대여 연습실 등 | 연습실 카페 |
| **온라인** | 💻 | 화상 레슨 | Zoom, 구글 미트 |

### LessonLocation 엔티티

```dart
/// 레슨 장소 유형
enum LocationType {
  academyRoom,     // 🏫 학원 레슨실
  teacherStudio,   // 🏠 선생님 스튜디오
  studentHome,     // 🚗 학생 집 방문
  externalPlace,   // 📍 외부 장소
  online,          // 💻 온라인
}

/// 레슨 장소
class LessonLocation {
  final String id;
  final String name;                    // "레슨실 1", "홈스튜디오"
  final LocationType type;
  final String? lessonClassId;          // 소속 클래스 (학원 레슨실인 경우)
  final String? ownerId;                // 소유자 (선생님 ID)

  // 주소 정보
  final String? address;                // 전체 주소
  final String? addressDetail;          // 상세 주소 (동/호수)

  // 온라인 정보
  final String? onlinePlatform;         // "zoom", "google_meet", "facetime"
  final String? onlineLink;             // 미팅 링크 (선택)

  // 메타
  final String? notes;                  // 찾아오는 길, 주차 정보 등
  final bool isDefault;                 // 기본 장소 여부
  final bool isActive;                  // 활성 상태
  final DateTime createdAt;
}
```

### LessonClass와 LessonLocation 관계

```
┌───────────────────────────────────────────────────────────────┐
│                      LessonClass (클래스)                       │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│  ○○음악학원 (academy)              개인레슨 (private)          │
│      │                                  │                     │
│      ├── 레슨실 1 (academyRoom)         ├── 홈스튜디오 (teacherStudio)
│      ├── 레슨실 2 (academyRoom)         ├── 온라인 (online)
│      └── 그랜드피아노실 (academyRoom)    └── 학생 집 방문 (studentHome)
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

### 레슨 기록 시 장소 선택 UI

```
┌────────────────────────────────────────┐
│ 레슨 기록                               │
├────────────────────────────────────────┤
│                                        │
│ 학생: 김민수 (○○음악학원)               │
│ 날짜: 2025-01-25 (토) 14:00            │
│                                        │
│ 레슨 장소                               │
│ ┌────────────────────────────────┐    │
│ │ ● 🏫 레슨실 1              기본  │    │
│ │ ○ 🏫 레슨실 2                   │    │
│ │ ○ 💻 온라인 (Zoom)              │    │
│ └────────────────────────────────┘    │
│                                        │
└────────────────────────────────────────┘
```

---

## 학생 앱 화면 설계

학생이 앱에서 보는 화면에 학원/수강권 정보가 어떻게 표시되는지 설계합니다.

### 학생 홈 화면

```
┌─────────────────────────────────────────┐
│ 🎵 내 레슨                       [설정] │
├─────────────────────────────────────────┤
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ 🎻 바이올린                          │ │
│ │ 김선생님                             │ │
│ │ 🏫 ○○음악학원                       │ │ ← 학원 배지
│ │                                     │ │
│ │ 📋 수강권: 8회권 (잔여 5회)          │ │ ← 수강권 표시
│ │ 📅 다음 레슨: 1/25 (토) 14:00       │ │
│ │ 📍 레슨실 2                          │ │ ← 장소 표시
│ │                                     │ │
│ │ [레슨 상세]                          │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ 🎹 피아노                            │ │
│ │ 박선생님                             │ │
│ │ 👤 개인 레슨                         │ │ ← 개인 배지
│ │                                     │ │
│ │ 📋 수강권: 월정액 (1/31까지)         │ │
│ │ 📅 다음 레슨: 1/27 (월) 16:00       │ │
│ │ 💻 온라인 (Zoom)                     │ │
│ │                                     │ │
│ │ [레슨 상세]                          │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ─────────────────────────────────────── │
│                                         │
│ 🎵 연습하기                             │
│ ┌────────┬────────┬────────┐          │
│ │ 🎤     │ 🎵     │ 🎸     │          │
│ │ 녹음   │메트로놈 │ 튜너   │          │
│ └────────┴────────┴────────┘          │
│                                         │
└─────────────────────────────────────────┘
```

### 수강권 상세 화면

```
┌─────────────────────────────────────────┐
│ ← 수강권 현황                            │
├─────────────────────────────────────────┤
│                                         │
│ 🎻 바이올린 · 김선생님                   │
│ 🏫 ○○음악학원                           │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │                                     │ │
│ │        ╭──────────────────╮        │ │
│ │        │                  │        │ │
│ │        │    잔여 5회      │        │ │
│ │        │    ────────      │        │ │
│ │        │    총 8회        │        │ │
│ │        │                  │        │ │
│ │        ╰──────────────────╯        │ │
│ │                                     │ │
│ │  ■■■■■□□□  62%                      │ │
│ │                                     │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ 수강권 정보                              │
│ ┌─────────────────────────────────────┐ │
│ │ 유형        8회권                   │ │
│ │ 시작일      2025.01.01              │ │
│ │ 유효기한    2025.02.28              │ │
│ │ 사용        3회                     │ │
│ │ 잔여        5회                     │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ 사용 내역                                │
│ ┌─────────────────────────────────────┐ │
│ │ 1/20 (월) 14:00  바이올린 레슨  -1회 │ │
│ │ 1/13 (월) 14:00  바이올린 레슨  -1회 │ │
│ │ 1/06 (월) 14:00  바이올린 레슨  -1회 │ │
│ └─────────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

### 레슨 장소 안내 화면

```
┌─────────────────────────────────────────┐
│ ← 레슨 장소                              │
├─────────────────────────────────────────┤
│                                         │
│ 📅 다음 레슨                             │
│ 1/25 (토) 14:00 ~ 15:00                 │
│ 🎻 바이올린 · 김선생님                   │
│                                         │
│ ─────────────────────────────────────── │
│                                         │
│ 📍 레슨 장소                             │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ 🏫 ○○음악학원 - 레슨실 2             │ │
│ │                                     │ │
│ │ 서울시 강남구 테헤란로 123           │ │
│ │ ○○빌딩 3층                          │ │
│ │                                     │ │
│ │ ┌─────────────────────────────────┐ │ │
│ │ │                                 │ │ │
│ │ │         [ 지도 미리보기 ]        │ │ │
│ │ │                                 │ │ │
│ │ └─────────────────────────────────┘ │ │
│ │                                     │ │
│ │ [🗺️ 지도 앱에서 열기]  [📋 주소 복사] │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ 💡 찾아오는 길                           │
│ ┌─────────────────────────────────────┐ │
│ │ • 2번 출구에서 도보 5분              │ │
│ │ • 1층 편의점 옆 엘리베이터 이용       │ │
│ │ • 주차 가능 (1시간 무료)             │ │
│ └─────────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

### 온라인 레슨 화면

```
┌─────────────────────────────────────────┐
│ ← 온라인 레슨                            │
├─────────────────────────────────────────┤
│                                         │
│ 📅 다음 레슨                             │
│ 1/27 (월) 16:00 ~ 17:00                 │
│ 🎹 피아노 · 박선생님                     │
│                                         │
│ ─────────────────────────────────────── │
│                                         │
│ 💻 온라인 레슨 (Zoom)                    │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │                                     │ │
│ │         ╭──────────────╮            │ │
│ │         │              │            │ │
│ │         │     Zoom     │            │ │
│ │         │              │            │ │
│ │         ╰──────────────╯            │ │
│ │                                     │ │
│ │      레슨 시작 10분 전부터           │ │
│ │      참여 버튼이 활성화됩니다         │ │
│ │                                     │ │
│ └─────────────────────────────────────┘ │
│                                         │
│        [🔗 미팅 참여하기]                │ ← 버튼 (시간 되면 활성화)
│                                         │
│ ─────────────────────────────────────── │
│                                         │
│ 💡 온라인 레슨 준비                      │
│ ┌─────────────────────────────────────┐ │
│ │ • 조용한 환경에서 접속해주세요        │ │
│ │ • 악기와 악보를 준비해주세요          │ │
│ │ • 카메라가 잘 보이는지 확인해주세요    │ │
│ └─────────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

### 다중 레슨 관리 (여러 선생님)

학생이 여러 선생님에게 레슨을 받는 경우:

```
┌─────────────────────────────────────────┐
│ 🎵 내 레슨                       [설정] │
├─────────────────────────────────────────┤
│                                         │
│ ┌────────┬────────┬────────┐          │
│ │  전체  │바이올린 │ 피아노  │          │ ← 악기별 탭
│ └────────┴────────┴────────┘          │
│                                         │
│ [전체 탭 선택 시]                        │
│                                         │
│ 📅 이번 주 레슨                          │
│ ┌─────────────────────────────────────┐ │
│ │ 1/25 (토) 14:00                     │ │
│ │ 🎻 바이올린 · 김선생님               │ │
│ │ 🏫 ○○음악학원 · 레슨실 2            │ │
│ ├─────────────────────────────────────┤ │
│ │ 1/27 (월) 16:00                     │ │
│ │ 🎹 피아노 · 박선생님                 │ │
│ │ 💻 온라인 (Zoom)                    │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ 📋 수강권 현황                           │
│ ┌─────────────────────────────────────┐ │
│ │ 🎻 바이올린  8회권 잔여 5회          │ │
│ │ 🎹 피아노   월정액 1/31까지          │ │
│ └─────────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

### Context 배지 디자인 (학생 앱)

| Context | 아이콘 | 배경색 | 텍스트 |
|---------|:-----:|--------|--------|
| 학원 레슨 | 🏫 | `#EDE7F6` (연보라) | 학원명 |
| 개인 레슨 | 👤 | `#F5F5F5` (회색) | "개인 레슨" |
| 온라인 | 💻 | `#E3F2FD` (연파랑) | 플랫폼명 |

---

## 관련 문서

- [three_party_relationship_spec.md](../lesson/three_party_relationship_spec.md) - 3자 관계 상세 UI/UX 설계
- [invite_system_v2.md](../invite/invite_system_v2.md) - 양방향 초대 시스템
- [parent_system.md](../user/parent_system.md) - 학부모 시스템

---

## 참고 서비스

- [클래스팅](https://www.classting.com/) - 학교/학원 클래스 관리
- [학원조아](https://hakwonjoa.com/) - 학원 운영 관리
- [어나더클래스](https://www.anotherclass.co.kr/) - 학원 관리 프로그램
- [레슨노트](https://apps.apple.com/kr/app/레슨노트-과외-선생님을-위한-학생-관리-앱/id6470158318) - 과외 학생 관리
