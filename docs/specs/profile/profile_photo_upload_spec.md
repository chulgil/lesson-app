# 프로필 사진 & 배경 사진 업로드 스펙

> 작성일: 2026-03-17
> 상태: 설계 완료, 사용자 승인 대기

---

## 1. 개요

선생님·학생 프로필 편집 화면에서 **프로필 사진**과 **배경 사진**을 설정하는 기능.

**비유**: 카카오톡 프로필처럼 원형 프로필 사진과 그 뒤의 넓은 배경 사진을 설정할 수 있다. 프로필 사진은 명함 사진, 배경 사진은 명함 뒤 디자인과 같다.

**핵심 가치**: 3탭 이내에 사진 설정 완료, 즉시 반영(로컬 우선)

---

## 2. 현재 상태 (AS-IS)

| 항목 | 상태 | 비고 |
|------|------|------|
| 선생님 프로필사진 | ⚠️ 부분 구현 | ProfileTab에서 선택 가능, BasicInfoEditScreen 미연동 |
| 선생님 배경사진 | ❌ 미구현 | 엔티티 필드 없음 |
| 학생 프로필사진 | ❌ 미구현 | 필드 존재(`profileImageUrl`) 하지만 UI 미연동 |
| 학생 배경사진 | ❌ 미구현 | 엔티티 필드 없음 |
| ImageUtils | ✅ 구현 완료 | pick/crop(원형)/save/delete |
| ProfileImageProvider | ✅ 구현 완료 | 선생님 프로필사진 전용 |
| ProfileImageWidget | ✅ 구현 완료 | 원형 아바타 + 편집 아이콘 |

### 기존 인프라 (재사용)

- `core/utils/image_utils.dart`: pickImage, cropProfileImage, saveProfileImage, deleteProfileImage
- `core/widgets/profile_image_widget.dart`: ProfileImageWidget
- `features/profile/presentation/providers/profile_image_provider.dart`: ProfileImageNotifier
- 패키지: `image_picker: ^1.1.2`, `image_cropper: ^8.0.2`, `path_provider: ^2.1.3`

---

## 3. 목표 상태 (TO-BE)

### 3.1 기능 범위

| 기능 | 우선순위 | 대상 | 설명 |
|------|----------|------|------|
| 선생님 프로필사진 설정 | HIGH | BasicInfoEditScreen | 프로필 편집에서 원형 사진 설정 |
| 선생님 배경사진 설정 | HIGH | BasicInfoEditScreen | 프로필 편집에서 배경 사진 설정 |
| 학생 프로필사진 설정 | HIGH | EditStudentScreen | 학생 편집에서 원형 사진 설정 |
| 학생 배경사진 설정 | HIGH | EditStudentScreen | 학생 편집에서 배경 사진 설정 |
| 프로필 탭 배경사진 표시 | HIGH | ProfileTab | 선생님 프로필 탭 헤더에 배경 표시 |
| 학생 상세 배경사진 표시 | HIGH | StudentDetailScreen | 학생 상세 헤더에 배경 표시 |
| 사진 삭제 | HIGH | 공통 | 기본 아바타/기본 배경으로 복원 |

### 3.2 UX 원칙

- **즉시 반영**: 선택 즉시 로컬 저장 후 UI 반영 (네트워크 대기 없음)
- **안전한 폴백**: 프로필사진 미설정 → 이니셜 아바타, 배경사진 미설정 → 그라데이션 기본 배경
- **분리된 크롭**: 프로필 = 원형(1:1), 배경 = 직사각형(16:9)

---

## 4. 상세 설계

### 4.1 엔티티 변경

#### TeacherProfile (기존 필드 + 신규 1개)

```dart
// 기존
final String? profileImage;     // 프로필 사진 경로/URL

// 신규 추가
final String? backgroundImage;  // 배경 사진 경로/URL
```

#### Student (기존 필드 + 신규 1개)

```dart
// 기존
final String? profileImageUrl;   // 프로필 사진 경로/URL

// 신규 추가
final String? backgroundImageUrl; // 배경 사진 경로/URL
```

### 4.2 ImageUtils 확장

```dart
// 신규: 배경 이미지 크롭 (16:9 비율)
Future<String?> cropBackgroundImage(String sourcePath, BuildContext context);

// 상수 추가
const int kBackgroundImageWidth = 1080;
const int kBackgroundImageHeight = 608;  // 16:9
const String kBackgroundImageDir = 'background_images';
```

### 4.3 Provider 확장

#### 신규: BackgroundImageNotifier

```dart
@riverpod
class BackgroundImageNotifier extends _$BackgroundImageNotifier {
  // 선생님/학생 공용 — userId + imageType으로 구분
  Future<String?> build(String userId) async { ... }
  Future<void> pickAndSaveImage(ImageSource source, BuildContext context) async { ... }
  Future<void> removeImage() async { ... }
}
```

#### 신규: StudentProfileImageNotifier

```dart
@riverpod
class StudentProfileImageNotifier extends _$StudentProfileImageNotifier {
  Future<String?> build(String studentId) async { ... }
  Future<void> pickAndSaveImage(ImageSource source, BuildContext context) async { ... }
  Future<void> removeImage() async { ... }
}
```

### 4.4 UI 구조

#### 선생님 BasicInfoEditScreen 상단 영역

```
┌───────────────────────────────────────┐
│ ← 기본 정보 수정              [저장]  │
├───────────────────────────────────────┤
│ ╔═══════════════════════════════════╗ │
│ ║  배경 사진 (16:9)           📷   ║ │
│ ║                                   ║ │
│ ║      ╭───────╮                    ║ │
│ ║      │ 프로필 │                    ║ │
│ ║      │  사진  │                    ║ │
│ ╚══════╰───────╯════════════════════╝ │
│            📷                         │
│                                       │
│  이름: [_______________]              │
│  한 줄 소개: [_______________]        │
│  ...                                  │
└───────────────────────────────────────┘
```

- 배경 사진 영역: 높이 180px, 우측 하단에 카메라 아이콘
- 프로필 사진: 배경 하단에 절반 겹치는 원형 (반지름 50), 우측 하단 카메라 아이콘
- 둘 다 탭하면 바텀시트(카메라/갤러리/삭제)

#### 학생 EditStudentScreen 상단 영역

```
┌───────────────────────────────────────┐
│ ← 학생 정보 수정              [저장]  │
├───────────────────────────────────────┤
│ ╔═══════════════════════════════════╗ │
│ ║  배경 사진 (16:9)           📷   ║ │
│ ║                                   ║ │
│ ║      ╭───────╮                    ║ │
│ ║      │ 프로필 │                    ║ │
│ ║      │  사진  │                    ║ │
│ ╚══════╰───────╯════════════════════╝ │
│            📷                         │
│                                       │
│  이름: [_______________]              │
│  악기: [바이올린 ▾]                   │
│  ...                                  │
└───────────────────────────────────────┘
```

동일한 레이아웃 구조 (공통 위젯으로 추출)

### 4.5 공통 위젯: ProfilePhotoHeader

```dart
/// 프로필사진 + 배경사진을 표시하는 헤더 위젯
/// BasicInfoEditScreen, EditStudentScreen, ProfileTab, StudentDetailScreen에서 공통 사용
class ProfilePhotoHeader extends StatelessWidget {
  final String? profileImagePath;
  final String? backgroundImagePath;
  final String initial;          // 이니셜 아바타 폴백
  final Color avatarColor;       // 아바타 배경색
  final VoidCallback? onTapProfile;
  final VoidCallback? onTapBackground;
  final bool editable;           // 편집 모드 (카메라 아이콘 표시)
  final double backgroundHeight; // 기본 180
  final double avatarRadius;     // 기본 50
}
```

### 4.6 이미지 선택 바텀시트

기존 `showImagePickerFlow()` 재사용 (student_form_dialogs.dart):

```
┌─────────────────────────────────┐
│  프로필 사진 / 배경 사진          │
│                                 │
│  📷  카메라로 촬영                │
│  🖼  갤러리에서 선택              │
│  🗑  사진 삭제                   │ ← 기존 이미지 있을 때만
│                                 │
│  취소                            │
└─────────────────────────────────┘
```

### 4.7 이미지 처리 파이프라인

#### 프로필 사진 (기존과 동일)
```
선택(카메라/갤러리) → 크롭(1:1 원형) → 리사이즈(500×500) → JPEG 80% → 저장(profile_images/{id}.jpg)
```

#### 배경 사진 (신규)
```
선택(카메라/갤러리) → 크롭(16:9) → 리사이즈(1080×608) → JPEG 80% → 저장(background_images/{id}.jpg)
```

### 4.8 저장 경로

| 타입 | 경로 | 파일명 |
|------|------|--------|
| 선생님 프로필 | `Documents/profile_images/` | `{userId}.jpg` |
| 선생님 배경 | `Documents/background_images/` | `{userId}.jpg` |
| 학생 프로필 | `Documents/profile_images/` | `student_{studentId}.jpg` |
| 학생 배경 | `Documents/background_images/` | `student_{studentId}.jpg` |

---

## 5. 파일 변경 목록

### 신규 파일

| 파일 | 설명 |
|------|------|
| `core/widgets/profile_photo_header.dart` | 프로필+배경 사진 헤더 공통 위젯 |
| `features/profile/presentation/providers/background_image_provider.dart` | 배경 이미지 상태 관리 |
| `features/students/presentation/providers/student_image_provider.dart` | 학생 이미지 상태 관리 |

### 수정 파일

| 파일 | 변경 내용 |
|------|-----------|
| `features/profile/domain/entities/teacher_profile.dart` | `backgroundImage` 필드 추가 |
| `features/students/domain/entities/student.dart` | `backgroundImageUrl` 필드 추가 |
| `core/utils/image_utils.dart` | `cropBackgroundImage()`, 배경 상수 추가 |
| `features/profile/presentation/screens/basic_info_edit_screen.dart` | 상단에 ProfilePhotoHeader 추가 |
| `features/students/presentation/screens/edit_student_screen.dart` | 상단에 ProfilePhotoHeader 추가 |
| `features/profile/presentation/screens/profile_tab.dart` | 배경사진 표시 |
| `features/students/presentation/screens/student_detail_screen.dart` | 배경사진 표시 |

### 코드 생성 필요

| 파일 | 이유 |
|------|------|
| `teacher_profile.g.dart` | backgroundImage 필드 추가 |
| `student.g.dart` | backgroundImageUrl 필드 추가 |
| `background_image_provider.g.dart` | 신규 Provider |
| `student_image_provider.g.dart` | 신규 Provider |

---

## 6. 구현 Phase

### Phase 1: 인프라 (엔티티 + 유틸 + Provider)

1. TeacherProfile에 `backgroundImage` 필드 추가
2. Student에 `backgroundImageUrl` 필드 추가
3. ImageUtils에 `cropBackgroundImage()` + 배경 상수 추가
4. BackgroundImageNotifier 생성
5. StudentProfileImageNotifier 생성
6. `build_runner build` 실행

### Phase 2: 공통 위젯

1. `ProfilePhotoHeader` 위젯 구현
2. 이미지 선택 바텀시트 공통화 (기존 showImagePickerFlow 확장)

### Phase 3: 선생님 프로필 편집 연동

1. BasicInfoEditScreen 상단에 ProfilePhotoHeader 배치
2. ProfileTab 헤더에 배경사진 표시
3. ProfilePreviewScreen에 배경사진 표시

### Phase 4: 학생 프로필 편집 연동

1. EditStudentScreen 상단에 ProfilePhotoHeader 배치
2. StudentDetailScreen 헤더에 배경사진 표시

---

## 7. 수락 기준

- [ ] 선생님 BasicInfoEditScreen에서 프로필사진 선택/크롭/저장 가능
- [ ] 선생님 BasicInfoEditScreen에서 배경사진 선택/크롭/저장 가능
- [ ] 학생 EditStudentScreen에서 프로필사진 선택/크롭/저장 가능
- [ ] 학생 EditStudentScreen에서 배경사진 선택/크롭/저장 가능
- [ ] 설정한 사진이 프로필 탭/학생 상세 화면에 표시됨
- [ ] 사진 삭제 시 기본 아바타/기본 배경으로 복원
- [ ] 프로필사진: 원형 크롭(1:1), 배경사진: 직사각형 크롭(16:9)
- [ ] `flutter analyze` 경고 없음
- [ ] `build_runner build` 성공

---

## 8. 엣지 케이스

| 상황 | 처리 |
|------|------|
| 카메라 권한 거부 | 설정 앱 안내 다이얼로그 |
| 갤러리 권한 거부 | 설정 앱 안내 다이얼로그 |
| 파일 저장 실패 | "사진 저장에 실패했습니다" 스낵바 + 기존 이미지 유지 |
| 로컬 파일 삭제됨 | 이니셜 아바타 / 그라데이션 배경 폴백 |
| 이미지 크기 10MB 초과 | ImagePicker maxWidth/maxHeight + 압축으로 자동 축소 |
| 크롭 취소 | 이전 상태 유지 |
| 편집 화면에서 저장 않고 뒤로 가기 | 변경사항 폐기 확인 다이얼로그 |

---

## 변경 이력

| 날짜 | 내용 |
|------|------|
| 2026-03-17 | 초안 작성 — 프로필사진 + 배경사진 통합 스펙 |
