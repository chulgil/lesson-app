/// Academy feature public provider boundary.
library;

export 'domain/repositories/academy_visibility_repository.dart'
    show AcademyVisibilityRepository, TeacherAcademyMembership;
export 'presentation/providers/academy_visibility_provider.dart'
    show
        academyVisibilityNotifierProvider,
        academyVisibilityRepositoryProvider,
        teacherAcademiesProvider;
