# 녹음 기능 요구사항

> 작성일: 2024-12-24
> 최종 수정: 2026-03-02
> 상태: Phase 1~1.5 구현 완료

## 개요

음악 레슨 앱의 녹음 기능은 크게 두 가지로 구분됩니다:
1. **레슨 피드백 녹음**: AI 음성→텍스트 변환 (파일 저장 없음)
2. **레퍼토리 곡 녹음**: 학생 연습 녹음 및 선생님 참고 음원

**관련 스펙 (상세 구현은 각 문서 참조)**:
| 스펙 | 설명 |
|------|------|
| [recording_player_ui.md](recording_player_ui.md) | 재생 플레이어 UI, 파형, A-B 루프, 공유 버튼 |
| [smart_recording_spec.md](smart_recording_spec.md) | 스마트 녹음 (무음 트리밍), `.trim` 메타데이터 |
| [backup_implementation_spec.md](backup_implementation_spec.md) | ZIP 백업/복원, iCloud/Google Drive 연동 |
| [practice_sharing_spec.md](practice_sharing_spec.md) | 선생님/학부모 공유 시스템 |

---

## 1. 레슨 피드백 녹음 (AI 음성 추출)

### 목적
레슨 종료 후 선생님이 피드백을 음성으로 녹음하면 AI가 텍스트로 변환하여 레슨 노트에 자동 추가

### 사용 흐름
```
[레슨 종료] → [선생님 피드백 녹음] → [AI 텍스트 변환] → [레슨 노트에 자동 추가]
```

### 상세 요구사항

| 항목 | 내용 |
|------|------|
| 녹음 주체 | 선생님 |
| 최대 길이 | 5분 이내 |
| 파일 저장 | 없음 (변환 후 삭제) |
| 결과물 | 레슨 노트에 텍스트로 자동 추가 |
| AI 엔진 | OpenAI Whisper 또는 Google STT |

---

## 2. 레퍼토리별 곡 녹음

### 2-1. 학생 연습 녹음

| 항목 | 내용 |
|------|------|
| 녹음 주체 | 학생 |
| 최대 길이 | 3분 이내 |
| 로컬 저장 | 무제한 (기기 용량 허용 범위) |
| 대표 녹음 | 레퍼토리당 1개 선택 가능 |
| 공유 방식 | 별도 공유 버튼 클릭 시 서버 업로드 |

**사용 흐름**
```
[학생 연습 화면]
├── 레퍼토리 선택 (예: "바흐 미뉴엣")
├── [녹음 시작] → 연주 → [녹음 종료]
├── 녹음 목록에 추가 (로컬 저장)
├── 잘 된 녹음을 [대표로 선택]
├── [외부 앱 공유] → 카카오톡/메시지 등으로 공유
└── [선생님께 공유] 버튼 → 서버 업로드
```

### 2-2. 선생님 참고 음원

| 유형 | 설명 | 저장 방식 |
|------|------|----------|
| 유튜브 링크 | 외부 연주 영상 | URL만 저장 |
| 선생님 녹음 | 선생님이 직접 연주 녹음 | 서버 업로드 |

### 2-3. 선생님 피드백 (학생 녹음에 대한)

- 텍스트 직접 입력 또는 음성 입력 → AI 텍스트 변환
- 공유된 녹음에 대해 선생님이 피드백 작성 → 학생에게 표시

### 2-4. 공유받은 녹음 다운로드 (선생님)

| 항목 | 내용 |
|------|------|
| 다운로드 대상 | 학생이 공유한 녹음 파일 |
| 저장 위치 | 선생님 기기 로컬 저장소 |
| 보관 기간 | 영구 (서버 보관 정책 무관) |

---

## 3. 데이터 모델

### Recording (녹음)
```dart
class Recording {
  String id;
  String pieceId;           // 레퍼토리 ID
  String studentId;
  RecordingType type;       // student, teacher, feedback
  String? localPath;        // 로컬 파일 경로
  String? serverUrl;        // 서버 업로드 URL (공유 시)
  int durationSeconds;
  bool isRepresentative;    // 대표 녹음 여부
  DateTime recordedAt;
  DateTime? sharedAt;       // 선생님께 공유한 시간
  StorageStatus storageStatus;
}
```

> Hive DB 모델, 파일 저장 경로/포맷 상세는 → [recording_player_ui.md](recording_player_ui.md#2-file-storage)

### ReferenceAudio (참고 음원)
```dart
class ReferenceAudio {
  String id;
  String pieceId;
  ReferenceType type;       // youtube, recording
  String? youtubeUrl;
  String? recordingUrl;
  String? title;
  DateTime createdAt;
}
```

### RecordingFeedback (녹음 피드백)
```dart
class RecordingFeedback {
  String id;
  String recordingId;
  String teacherId;
  String content;
  DateTime createdAt;
}
```

### DownloadedRecording (다운로드된 녹음 - 선생님용)
```dart
class DownloadedRecording {
  String id;
  String originalRecordingId;
  String studentId;
  String studentName;
  String pieceId;
  String pieceName;
  String localPath;
  int durationSeconds;
  DateTime originalRecordedAt;
  DateTime downloadedAt;
}
```

---

## 4. 서버 보관 정책

공유된 녹음은 녹음 시작일 기준으로 보관 정책이 적용됩니다:

| 기간 | 저장소 | 설명 |
|------|--------|------|
| 0~30일 | 활성 저장소 | 빠른 스트리밍 재생 가능 |
| 31~180일 | S3 아카이브 | 저비용 보관, 재생 시 지연 가능 |
| 180일 이후 | 삭제 | 자동 영구 삭제 |

> 로컬 백업/영속성 전략 → [backup_implementation_spec.md](backup_implementation_spec.md)

---

## 5. 프로 구독 모델 (Pro Subscription)

| 기능 | 무료 | 프로 |
|------|:----:|:----:|
| 일반 녹음 | ✅ | ✅ |
| 재생/삭제/A-B 루프/속도 조절 | ✅ | ✅ |
| 대표 녹음 선택 | ✅ | ✅ |
| **스마트 녹음** (무음 트리밍) | ❌ | ✅ |
| **중간 무음 스킵** | ❌ | ✅ |

**구독 해지 후**: 기존 스마트 녹음 파일은 정상 재생 (`.trim` 메타데이터 유지). 새 녹음만 일반 녹음으로 제한.

---

## 6. iOS 녹음 경로 복구 (Issue #9) ✅

iOS에서 앱 재배포 시 컨테이너 UUID가 변경되어 Hive DB의 녹음 경로가 무효화되는 문제.

### 복구 전략 (우선순위)

| 순서 | 전략 | 설명 |
|:---:|------|------|
| 1 | 상대 경로 재구성 | `/Documents/` 이후 경로 추출 → 현재 base path와 결합 |
| 2 | 파일명 검색 | 파일명으로 파일 맵에서 검색 |
| 3 | ID 패턴 검색 | 녹음 ID 앞 8자리로 파일명 패턴 매칭 |

- 앱 시작 시(`main.dart`) 자동 실행
- 복구 불가능한 고아 기록은 DB에서 자동 삭제

---

## 7. 녹음 완전 삭제 ✅

녹음 삭제 시 **오디오 파일 + .trim 메타데이터 + DB 기록** 모두 삭제:

| 삭제 대상 | 설명 |
|------|------|
| `*.m4a` | 오디오 파일 |
| `*.m4a.trim` | 스마트 녹음 트림 메타데이터 |
| Hive DB 기록 | PracticeRecording 엔트리 |

---

## 8. 녹음 진단 화면 (디버그 모드) ✅

디버그 FAB 길게 누르기 → 개발자 옵션 → "녹음 파일 진단"

| 진단 항목 | 설명 |
|------|------|
| 기본 경로 | 현재 Documents 디렉토리 경로 |
| 실제 파일 수 | recordings/ 폴더 내 오디오 파일 수 |
| DB 기록 수 | Hive practice_recordings box 기록 수 |
| 매칭됨 | DB 기록 중 파일이 존재하는 수 |
| DB 불일치 | DB 기록 중 파일이 없는 수 |
| 고아 파일 | 파일은 있으나 DB에 없는 수 (개별/전체 삭제 가능) |

---

## 9. 구현 로드맵

### Phase 1 (MVP) ✅
- [x] 학생 연습 녹음 (로컬 저장), 재생/삭제
- [x] 대표 녹음 선택, 스마트 녹음
- [x] A-B 루프, 속도 조절, 핀치 줌, 파형 시각화

### Phase 1.5 (버그 수정/개선) ✅
- [x] iOS 컨테이너 UUID 경로 복구, 녹음 완전 삭제, 진단 화면
- [ ] 트림 후 실제 재생 시간 표시 (Issue #7)
- [ ] 연습완료 날짜별 동기화 (Issue #8)

### Phase 2
- [ ] 대표 녹음 서버 업로드, 선생님 주차 요약 표시, 텍스트 피드백

### Phase 3
- [ ] 레슨 피드백 AI 음성→텍스트, 선생님 참고 음원

### Phase 4
- [ ] 선생님 음성 피드백 (AI 변환), 선생님 직접 참고 녹음

### Phase 5 (데이터 영속성)
- [ ] iCloud/ZIP 백업 → [backup_implementation_spec.md](backup_implementation_spec.md)

### Phase 6 (프로 구독)
- [ ] 구독 상태 관리, 스마트 녹음 버튼 구독 체크

---

## 10. 관련 파일

```
frontend/lib/
├── core/widgets/
│   ├── debug_role_switcher.dart        # 디버그 옵션 시트
│   └── recording_diagnostic_screen.dart # 녹음 진단 화면
├── models/
│   ├── recording.dart
│   ├── practice_repertoire.dart        # PracticeRecording 모델
│   ├── downloaded_recording.dart
│   └── reference_audio.dart
├── services/
│   ├── audio_recorder_service.dart
│   ├── audio_player_service.dart
│   └── audio_trimmer_service.dart      # 스마트 녹음 트리밍
├── features/practice/presentation/
│   ├── screens/
│   │   └── practice_recording_screen.dart
│   └── widgets/
│       ├── recording_player_sheet.dart
│       ├── recording_waveform.dart
│       └── section_detail/
│           └── section_recording_list_item.dart
└── main.dart                           # 앱 시작 시 경로 복구 로직
```
