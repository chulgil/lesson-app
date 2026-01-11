# Lesson App - Task Completion Checklist

## Before Starting Work
1. Read `docs/architecture.md` - Understand folder structure
2. Check `docs/requirement/` - Review requirements
3. Check `docs/specs/[domain]/` - Review relevant specs
4. Check `docs/refactoring_tasks.md` - Check ongoing work

## After Completing Work

### Required Checks
- [ ] `flutter analyze` - No warnings or errors
- [ ] `dart run build_runner build` - Run code generation (Provider, JSON)

### Documentation Updates
- [ ] Update related `docs/specs/` documents if needed
- [ ] Update `docs/refactoring_tasks.md` for structural changes

### Commit Message Format
- Use Korean language
- Use Conventional Commits format:
  - `feat:` - New feature
  - `fix:` - Bug fix
  - `docs:` - Documentation
  - `refactor:` - Code refactoring
  - `test:` - Tests
  - `chore:` - Maintenance

### GitHub Issue Workflow
1. Create issue with proper labels (type, domain, priority)
2. Work on feature/fix
3. Commit with `Refs #<issue-number>` or `Closes #<issue-number>`
4. Wait for user verification before closing issue

### Labels
| Category | Labels |
|----------|--------|
| Type | `bug`, `feature`, `enhancement`, `refactor` |
| Priority | `priority: critical/high/medium/low` |
| Domain | `domain: lesson/student/practice/recording/...` |
| Status | `status: todo/in-progress/review/done` |
