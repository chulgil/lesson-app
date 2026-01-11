# Lesson App - Development Commands

## Essential Commands

### Dependencies
```bash
flutter pub get
```

### Run Application
```bash
# Quick test on macOS
flutter run -d macos

# Run on iPhone (release mode, preserves data)
flutter run -d <device_id> --release
```

### Code Generation (Riverpod, JSON, Hive)
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Static Analysis
```bash
flutter analyze
```

### iPhone Deployment
```bash
# Preserves app data (recommended)
flutter run -d <device_id> --release

# Clean install (deletes app data including recordings!)
flutter install -d <device_id>
```

## Troubleshooting

### iOS Build Errors
```bash
cd ios && pod install && cd .. && flutter clean && flutter pub get
```

### Android Build Errors
```bash
cd android && ./gradlew clean && cd .. && flutter clean && flutter pub get
```

### Provider Code Generation Errors
```bash
dart run build_runner build --delete-conflicting-outputs
```

## Testing Flow
1. Develop and test on macOS first (`flutter run -d macos`)
2. Deploy to iPhone for user verification when needed

## System Commands (Darwin/macOS)
- `ls` - List files
- `cd` - Change directory
- `find` - Find files
- `grep` - Search text
- `git` - Version control
