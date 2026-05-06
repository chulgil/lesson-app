import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/search_filter.dart';

extension SearchScopeVisuals on SearchScope {
  String get label {
    switch (this) {
      case SearchScope.all:
        return AppStrings.searchScopeAll;
      case SearchScope.teachers:
        return AppStrings.searchScopeTeachers;
      case SearchScope.students:
        return AppStrings.searchScopeStudents;
      case SearchScope.lessons:
        return AppStrings.searchScopeLessons;
    }
  }
}

extension SearchResultTypeVisuals on SearchResultType {
  String get label {
    switch (this) {
      case SearchResultType.teacher:
        return AppStrings.searchResultTeacher;
      case SearchResultType.student:
        return AppStrings.searchResultStudent;
      case SearchResultType.lesson:
        return AppStrings.searchResultLesson;
      case SearchResultType.practice:
        return AppStrings.searchResultPractice;
    }
  }
}
