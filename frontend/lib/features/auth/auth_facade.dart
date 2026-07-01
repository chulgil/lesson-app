export 'domain/entities/user_role.dart' show UserRole;
export 'domain/repositories/context_switch_repository.dart'
    show AvailableContext, ContextInfo, ContextSwitchResult;
export 'presentation/extensions/user_role_visuals.dart' show UserRoleVisuals;
export 'presentation/providers/auth_provider.dart'
    show authNotifierProvider, authRepositoryProvider;
export 'presentation/providers/context_switch_provider.dart'
    show contextSwitchRepositoryProvider, currentContextProvider;
export 'presentation/providers/user_role_provider.dart'
    show
        CurrentUserRoleProviderNotifierCompat,
        currentUserIdProvider,
        currentUserRoleProvider;
export 'presentation/widgets/phone_verification_gate_modal.dart'
    show PhoneVerificationGate;
export 'presentation/providers/active_discipline_provider.dart'
    show activeDisciplineProvider;
