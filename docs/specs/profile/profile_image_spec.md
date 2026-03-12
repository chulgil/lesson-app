# 프로필 이미지 선택 스펙

> 작성일: 2026-03-12
> 상태: 미구현

---

## 1. 개요

현재 프로필 이미지 선택은 mock 구현(하드코딩 URL 할당)으로, 실제 카메라/갤러리 연동이 없다. 선생님·학생 모두 자신의 프로필 사진을 설정할 수 있어야 신뢰감 있는 커뮤니케이션이 가능하다.

**비유**: 명함에 사진이 있으면 상대방이 더 친근하게 느끼는 것처럼, 앱 내 프로필 이미지는 선생님-학생 관계의 첫인상을 결정한다.

**핵심 가치**: 3탭 이내에 프로필 사진 설정 완료

---

## 2. 현재 상태 (AS-IS)

| 항목 | 상태 |
|------|------|
| 선생님 프로필 | `TeacherProfile.profileImageUrl: String?` — mock URL 할당 |
| 학생 프로필 | `Student.profileImageUrl: String?` — 미사용 (이니셜 아바타) |
| 온보딩 | `ProfileSetupScreen`에서 "사진 선택" 터치 → 하드코딩 URL 할당 |
| 이미지 피커 | `file_picker: ^8.0.0+1` 존재, `image_picker` 미추가 |
| 학생 폼 | `showImagePickerOptions()` 패턴 존재 (카메라/갤러리/삭제) |
| 실제 업로드 | 미구현 (백엔드 없음) |

---

## 3. 목표 상태 (TO-BE)

### 3.1 UX 원칙

- **OS 네이티브 느낌**: iOS 사진 라이브러리·카메라 네이티브 UI 활용
- **즉시 반영**: 선택 즉시 프로필에 반영 (업로드 대기 없음 — 로컬 우선)
- **안전한 폴백**: 이미지 미설정 시 이니셜 + 색상 아바타 유지

### 3.2 기능 범위

| 기능 | 우선순위 | 설명 |
|------|----------|------|
| 갤러리에서 선택 | HIGH | 기기 사진첩에서 이미지 선택 |
| 카메라 촬영 | HIGH | 카메라로 직접 촬영 |
| 이미지 크롭 | HIGH | 원형 영역 크롭 (1:1) |
| 이미지 삭제 | HIGH | 이니셜 아바타로 복원 |
| 로컬 저장 | HIGH | 앱 Documents 디렉토리에 저장 |
| 이미지 압축 | MEDIUM | 리사이즈 + 압축 (500x500, 80%) |
| 기본 아바타 선택 | LOW | 미리 제공된 일러스트 아바타 |
| 클라우드 동기화 | LOW (백엔드 의존) | Supabase Storage 업로드 |

---

## 4. 상세 설계

### 4.1 진입점

| 화면 | 위치 | 설명 |
|------|------|------|
| 온보딩 | ProfileSetupScreen | 프로필 설정 단계 |
| 프로필 탭 | TeacherProfileScreen | 프로필 이미지 영역 터치 |
| 학생 편집 | EditStudentScreen | 학생 아바타 영역 터치 |

### 4.2 UI 플로우

#### 이미지 선택 바텀시트

```
┌─────────────────────────────────┐
│                                 │
│  📷  카메라로 촬영                │
│  🖼  갤러리에서 선택              │
│  🗑  사진 삭제                   │ ← 기존 이미지 있을 때만
│  ✕  취소                        │
│                                 │
└─────────────────────────────────┘
```

#### 크롭 화면

```
┌─────────────────────────────────┐
│ 프로필 사진 편집                  │
│                                 │
│    ┌───────────────────┐        │
│    │    ╭─────╮        │        │
│    │    │     │        │        │
│    │    │  😊 │        │        │
│    │    │     │        │        │
│    │    ╰─────╯        │        │
│    └───────────────────┘        │
│    ← 핀치 줌 / 드래그 →         │
│                                 │
│     [취소]        [적용]         │
└─────────────────────────────────┘
```

- 원형 오버레이 가이드
- 핀치 줌 + 드래그로 영역 조정
- `image_cropper` 패키지 활용

### 4.3 이미지 처리 파이프라인

```
1. 원본 선택 (카메라/갤러리)
2. 크롭 (1:1, 원형 가이드)
3. 리사이즈 (500x500px)
4. 압축 (JPEG 80%)
5. 로컬 저장 (Documents/profile_images/{userId}.jpg)
6. 경로를 엔티티 profileImageUrl에 저장
7. UI 즉시 반영 (FileImage)
```

### 4.4 데이터 모델

```dart
// 기존 필드 활용 — 스키마 변경 없음
// TeacherProfile.profileImageUrl → 로컬 파일 경로 또는 URL
// Student.profileImageUrl → 로컬 파일 경로 또는 URL

// 이미지 표시 유틸
Widget buildProfileImage(String? imageUrl, String initial, Color color) {
  if (imageUrl != null && imageUrl.startsWith('/')) {
    return CircleAvatar(backgroundImage: FileImage(File(imageUrl)));
  } else if (imageUrl != null && imageUrl.startsWith('http')) {
    return CircleAvatar(backgroundImage: NetworkImage(imageUrl));
  } else {
    return CircleAvatar(child: Text(initial), backgroundColor: color);
  }
}
```

### 4.5 패키지 의존성

| 패키지 | 용도 | 비고 |
|--------|------|------|
| `image_picker` | 카메라/갤러리 접근 | 신규 추가 |
| `image_cropper` | 원형 크롭 UI | 신규 추가 |
| `path_provider` | Documents 디렉토리 | 이미 의존성 존재 |

### 4.6 권한

| 플랫폼 | 권한 | 설정 |
|--------|------|------|
| iOS | 카메라 | `NSCameraUsageDescription` in Info.plist |
| iOS | 사진 라이브러리 | `NSPhotoLibraryUsageDescription` in Info.plist |
| Android | 카메라 | `android.permission.CAMERA` in AndroidManifest |
| Android | 저장소 | 스코프드 스토리지 (API 29+) — 별도 권한 불필요 |

---

## 5. 관련 파일

| 파일 | 변경 |
|------|------|
| `pubspec.yaml` | `image_picker`, `image_cropper` 추가 |
| `ios/Runner/Info.plist` | 카메라/사진 권한 문구 추가 |
| `core/widgets/profile_image_widget.dart` | 신규 — 공통 프로필 이미지 위젯 |
| `core/utils/image_utils.dart` | 신규 — 리사이즈/압축/저장 유틸 |
| `features/onboarding/presentation/screens/profile_setup_screen.dart` | 수정 — 실제 이미지 피커 연동 |
| `features/profile/presentation/screens/teacher_profile_screen.dart` | 수정 — 이미지 변경 기능 |
| `features/students/presentation/widgets/student_form_dialogs.dart` | 수정 — 이미지 피커 실제 연동 |

---

## 6. 예외 처리

| 상황 | 처리 |
|------|------|
| 카메라 권한 거부 | 설정 앱으로 안내 다이얼로그 |
| 갤러리 권한 거부 | 설정 앱으로 안내 다이얼로그 |
| 파일 저장 실패 | "사진 저장에 실패했습니다" 토스트 + 기존 이미지 유지 |
| 로컬 파일 삭제됨 | 이니셜 아바타 폴백 (FileImage 로드 실패 시) |
| 이미지 용량 초과 (10MB+) | 자동 압축 후 저장 |

---

## 변경 이력

| 날짜 | 내용 |
|------|------|
| 2026-03-12 | 초안 작성 |
