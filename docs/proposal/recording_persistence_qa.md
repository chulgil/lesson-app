# 녹음 파일 영속성 설계 Q&A

> 작성일: 2026-01-01
> 관련 스펙: [recording_requirement.md](../specs/practice/recording_requirement.md)

## 브레인스토밍 배경

**목표**: 앱을 삭제하더라도 녹음 파일이 사용자 기기에 남아있는 구조 설계

## 타사 분석 결과

### iOS 저장소 제약 사항
- iOS 앱은 **샌드박스** 환경에서 실행
- 기본적으로 **앱 삭제 시 모든 데이터 삭제**

### 타사 앱 저장 전략

| 앱 | 저장 전략 | 앱 삭제 후 유지 |
|---|---|---|
| Apple Voice Memos | iCloud 동기화 | ✅ iCloud에 남음 |
| Yousician | 앱 내 저장 + 서버 | ⚠️ 서버에만 남음 |
| ForScore | iCloud/Dropbox 연동 | ✅ 클라우드에 남음 |
| 일반 녹음 앱 | Files 앱 내보내기 | ✅ Files 앱에 남음 |

### iOS 영속성 옵션

1. **iCloud Drive**: 앱 삭제 후에도 유지, 기기 간 동기화
2. **Files 앱 통합**: UIFileSharingEnabled로 Documents 노출
3. **수동 내보내기**: UIDocumentPickerViewController 사용
4. **Keychain**: iOS 10.3 이후 앱 삭제 시 함께 삭제됨 (변경됨)
5. **Shared App Groups**: 다른 앱이 같은 그룹 사용 시에만 유지

---

## Q&A 세션

### Q1. 녹음 파일의 기본 저장 위치는 어디로 할까요?

**옵션**:
- A: iCloud Drive (권장) - 앱 삭제 후에도 유지, 기기 간 동기화
- B: Files 앱 노출 - 앱 Documents를 Files 앱에서 볼 수 있게
- C: 앱 내부만 - 현재 방식 유지
- D: 하이브리드 - 앱 내부 + iCloud 백업 + 수동 내보내기

**결정**: **D. 하이브리드**
- 기본: 앱 내부 저장 (현재 방식 유지)
- 선택: iCloud 자동 백업 옵션
- 선택: 수동 내보내기 기능

---

### Q2. 내보내기 기능은 어떤 수준으로 제공할까요?

**옵션**:
- A: 개별 녹음 내보내기 - 하나씩 선택해서 내보내기
- B: 일괄 내보내기 - 학생별/곡별 ZIP 압축
- C: 자동 백업 - 설정된 위치에 자동 복사
- D: 모두 제공

**결정**: **B. 일괄 내보내기**
- 학생별/곡별 녹음을 ZIP으로 압축하여 내보내기
- Files 앱, Dropbox, Google Drive 등에 저장 가능

---

### Q3. 녹음 파일 형식과 품질 옵션은?

**옵션**:
- A: M4A (현재) - 용량 효율적, iOS 호환
- B: WAV 옵션 추가 - 고품질 무압축
- C: MP3 옵션 추가 - 범용 호환성
- D: 사용자 선택 가능

**결정**: **A. M4A (현재)** 유지
- 용량 효율적이고 iOS 호환성 좋음
- 추후 필요시 다른 포맷 추가 가능

---

## 결정 요약

| 항목 | 결정 | 설명 |
|---|---|---|
| **저장 위치** | 하이브리드 | 앱 내부 + iCloud 백업 + 수동 내보내기 |
| **내보내기** | 일괄 내보내기 | 학생별/곡별 ZIP 압축 내보내기 |
| **파일 형식** | M4A 유지 | 현재 방식 유지 |

---

## 구현 우선순위

| 순위 | 기능 | 복잡도 | 설명 |
|:---:|------|:---:|---|
| 1 | Files 앱 노출 | 낮음 | Info.plist 설정만으로 구현 |
| 2 | 일괄 내보내기 | 중간 | ZIP 압축 + Document Picker |
| 3 | iCloud 백업 | 높음 | NSUbiquitousContainers 설정 필요 |
| 4 | iCloud 복원 | 높음 | 앱 재설치 시 복원 기능 |

---

## 참고 자료

- [UIDocumentPickerViewController - Apple Developer](https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller)
- [iOS File Provider Extension - Kodeco](https://www.kodeco.com/697468-ios-file-provider-extension-tutorial)
- [path_provider - Flutter](https://pub.dev/packages/path_provider)
- [Voice Memos Storage - Apple Community](https://discussions.apple.com/thread/253828075)
- [Shared App Group Container - Apple Forums](https://developer.apple.com/forums/thread/720458)
