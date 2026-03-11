# Flutter 배포 및 테스트 가이드

> Lessonaza 앱을 macOS / iPhone(iPad)에 배포하여 테스트하는 방법

---

## 사전 준비

### 환경 확인

```bash
flutter doctor          # 전체 환경 진단
flutter devices         # 연결된 디바이스 목록
flutter --version       # Flutter 버전 확인
```

### 프로젝트 클린 빌드 (문제 발생 시)

```bash
cd frontend
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

---

## 1. macOS 배포

macOS는 별도 서명 없이 바로 실행 가능하여 가장 간편합니다.

### Debug 모드 (개발 중)

```bash
cd frontend
flutter run -d macos
```

- Hot Reload (`r`) / Hot Restart (`R`) 지원
- DevTools 연결 가능
- 성능은 Release보다 느림

### Release 모드 (성능 테스트)

```bash
cd frontend
flutter run -d macos --release
```

### 빌드만 생성 (앱 파일)

```bash
cd frontend
flutter build macos --release
```

빌드 결과: `frontend/build/macos/Build/Products/Release/lessonaza.app`

직접 실행:

```bash
open build/macos/Build/Products/Release/lessonaza.app
```

---

## 2. iPhone / iPad 배포

### 2-1. USB 유선 연결

1. iPhone/iPad를 Mac에 USB로 연결
2. "이 컴퓨터를 신뢰하시겠습니까?" → **신뢰**
3. 디바이스 확인:

```bash
flutter devices
# 예: iPad CG (mobile) • 00008027-XXXX • ios • iOS 26.3.1
```

### 2-2. Xcode 서명 설정 (최초 1회)

> 이 단계를 건너뛰면 빌드 시 provisioning profile 에러가 발생합니다.

1. Xcode에서 프로젝트 열기:

```bash
open frontend/ios/Runner.xcworkspace
```

2. 좌측 Navigator에서 **Runner** 프로젝트 선택
3. **Signing & Capabilities** 탭 이동
4. 설정 확인:

| 항목 | 값 |
|------|-----|
| Team | 본인 Apple Developer 계정 선택 |
| Bundle Identifier | `app.lessonaza` |
| Automatically manage signing | ✅ 체크 |

5. **Runner Tests** 타겟도 동일하게 설정

> **Tip**: 무료 Apple ID로도 개발 테스트 가능 (7일 제한, 디바이스 3대까지)

### 2-3. 개발자 모드 활성화 (iOS 16+)

iPhone/iPad에서:
- **설정 → 개인정보 보호 및 보안 → 개발자 모드** → 켜기
- 재시작 후 확인 팝업에서 **켜기** 선택

### 2-4. Debug 모드 실행

```bash
cd frontend
flutter run -d <device_id>
```

`<device_id>`는 `flutter devices`에서 확인한 ID (예: `00008027-001D38A80C39002E`)

- 첫 실행 시 Xcode가 자동으로 서명 + 프로비저닝 처리
- iPhone에서 "신뢰할 수 없는 개발자" 경고 시:
  - **설정 → 일반 → VPN 및 기기 관리** → 개발자 앱 → **신뢰**

### 2-5. Release 모드 실행

```bash
cd frontend
flutter run -d <device_id> --release
```

- Hot Reload 불가, 실제 성능으로 테스트
- 프로비저닝 에러 시 아래 "문제 해결" 참조

### 2-6. 무선 배포 (Wi-Fi)

USB 연결 없이 배포하려면:

1. 먼저 USB로 한 번 연결
2. Xcode → **Window → Devices and Simulators**
3. 디바이스 선택 → **Connect via network** ✅ 체크
4. USB 분리 후 같은 Wi-Fi에서:

```bash
flutter run -d <device_id>
```

> 무선 연결이 불안정하면 "Browsing on the local area network" 에러 발생 → USB 재연결

---

## 3. 시뮬레이터 (디바이스 없을 때)

### iOS 시뮬레이터

```bash
# 사용 가능한 시뮬레이터 목록
flutter emulators

# 시뮬레이터 시작
open -a Simulator

# 실행
flutter run -d <simulator_id>
```

> 시뮬레이터에서는 카메라, 마이크 등 하드웨어 기능이 제한됩니다.
> Lessonaza의 녹음/튜너 기능은 실제 디바이스에서만 테스트 가능합니다.

---

## 4. 빌드 타입 비교

| 항목 | Debug | Profile | Release |
|------|-------|---------|---------|
| 용도 | 개발 | 성능 분석 | 최종 테스트 |
| Hot Reload | ✅ | ❌ | ❌ |
| DevTools | ✅ | ✅ | ❌ |
| 성능 | 느림 | 중간 | 최적 |
| 앱 크기 | 큼 | 중간 | 작음 |
| 명령어 | `flutter run` | `flutter run --profile` | `flutter run --release` |

---

## 5. 자주 쓰는 명령어 모음

```bash
# 기본 실행 (자동 디바이스 선택)
flutter run

# 특정 디바이스 지정
flutter run -d macos
flutter run -d <iphone_id>
flutter run -d chrome

# Release 빌드
flutter run -d <device_id> --release

# 빌드만 (설치 없이)
flutter build ios --release
flutter build macos --release

# 로그 확인
flutter logs

# 앱 정리 후 재빌드
flutter clean && flutter pub get && flutter run
```

---

## 문제 해결

### Provisioning Profile 에러

```
Error: No signing certificate "iOS Development" found
```

**해결**:
1. Xcode에서 Runner.xcworkspace 열기
2. Signing & Capabilities → Team 재선택
3. Xcode에서 직접 빌드 (▶ 버튼) → 성공 확인 후 Flutter CLI 재시도

또는 xcodebuild 직접 사용:

```bash
cd frontend/ios
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -destination 'id=<device_id>' \
  -allowProvisioningUpdates
```

### CocoaPods 에러

```
Error running pod install
```

**해결**:

```bash
cd frontend/ios
pod deintegrate
pod install
cd .. && flutter clean && flutter pub get
```

### 앱 크래시 (Hive 캐시 충돌)

Mock 데이터나 enum 변경 후 크래시 발생 시:

```bash
# 방법 1: 앱 삭제 후 재설치
flutter clean
flutter run  # Debug로 먼저 확인

# 방법 2: 디바이스에서 앱 직접 삭제 후 재실행
# iPhone에서 앱 아이콘 길게 눌러 삭제 → flutter run
```

### "신뢰할 수 없는 개발자" 에러 (iPhone)

iPhone에서:
- **설정 → 일반 → VPN 및 기기 관리** → 본인 Apple ID → **신뢰**

### flutter install vs flutter run 차이

| 명령어 | 동작 | 주의사항 |
|--------|------|----------|
| `flutter run` | 빌드 + 설치 + 실행 | 기존 데이터 유지 ✅ |
| `flutter install` | 앱 삭제 후 재설치 | **녹음 파일 등 로컬 데이터 삭제** ⚠️ |

> **권장**: 항상 `flutter run` 사용. `flutter install`은 데이터 초기화가 필요할 때만 사용.

---

## 테스트 체크리스트

배포 후 확인할 핵심 항목:

- [ ] 앱 정상 실행 (크래시 없음)
- [ ] 화면 전환 정상 (뒤로가기 포함)
- [ ] 데이터 저장/불러오기 정상
- [ ] 녹음/재생 동작 확인 (실제 디바이스)
- [ ] 메트로놈 정확한 타이밍 (실제 디바이스)
- [ ] 튜너 음 감지 정상 (실제 디바이스)
- [ ] 다크모드 / 라이트모드 전환
- [ ] 다양한 화면 크기 대응 (iPad 포함)
