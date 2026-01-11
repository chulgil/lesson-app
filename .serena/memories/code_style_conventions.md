# Lesson App - Code Style & Conventions

## Language Rules
- **Claude responses**: Always in Korean
- **Code comments**: English
- **Commit messages**: Korean (Conventional Commits format)
  - Example: `feat: 사용자 인증 기능 추가`

## Dart Coding Style
- Follow Dart Style Guide
- `flutter analyze` must pass with no warnings
- Large widgets: Split into separate files (avoid >500 lines)

## Provider Rules
- Use `@riverpod` annotation for all providers
- Location: `features/[domain]/presentation/providers/`
- Run `dart run build_runner build` after creating providers

### Provider Naming
```
[domain]_repository_provider.dart   # Repository instance
[domain]_providers.dart             # Query providers
[domain]_crud_provider.dart         # CRUD Notifier
[domain]_[action]_provider.dart     # Specific features
```

### Provider Example
```dart
@riverpod
Future<List<Lesson>> allLessons(Ref ref) async {
  final repository = ref.watch(lessonRepositoryProvider);
  return repository.getAllLessons();
}
```

## Model Rules
- Location: `features/[domain]/domain/entities/`
- Shared types: `lib/core/models/`
- Use `@JsonSerializable()` for JSON serialization
- Use re-export pattern for backward compatibility

## Design Rules
- **Colors**: Always use `AppColors` class (no hardcoding)
  - Primary: #6B5B95
  - Secondary: #F4A460
  - Background: #FFFAF5

## Architecture Rules
- **New code**: Always in `features/` directory (not legacy locations)
- **Repository pattern**: Interface + Mock implementation
- **Re-export pattern**: Maintain backward compatibility

## File Organization
| Type | Location |
|------|----------|
| Models/Entities | `features/[domain]/domain/entities/` |
| Providers | `features/[domain]/presentation/providers/` |
| Screens | `features/[domain]/presentation/screens/` |
| Widgets | `features/[domain]/presentation/widgets/` |
| Routes | `core/router/routes/` |
| Shared types | `core/models/` |
