/// Invite feature public entry point.
///
/// Cross-feature consumers (e.g. the onboarding invite-code screen in the
/// auth feature) must import this facade instead of reaching into
/// `presentation/screens` or `presentation/widgets` directly — see
/// `.claude/rules/flutter-architecture.md` §Feature Facade 기준.
library;

export 'presentation/screens/invite_confirm_screen.dart'
    show InviteConfirmScreen;
export 'presentation/widgets/invite_code_digit_input.dart'
    show InviteCodeDigitInput;
