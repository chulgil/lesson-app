// Auth and onboarding route definitions

import 'package:go_router/go_router.dart';

import '../../../features/auth/presentation/screens/academy_invite_accept_screen.dart';
import '../../../features/auth/presentation/screens/login_screen.dart';
import '../../../features/auth/presentation/screens/parent_invite_code_screen.dart';
import '../../../features/auth/presentation/screens/role_select_screen.dart';
import '../../../features/auth/presentation/screens/student_invite_code_screen.dart';
import '../../../features/auth/presentation/screens/terms_agreement_screen.dart';
import '../../../features/onboarding/presentation/screens/phone_verification_screen.dart';
import '../../../features/onboarding/presentation/screens/profile_setup_screen.dart';
import '../../../features/onboarding/presentation/screens/student_profile_setup_screen.dart';
import '../../../features/onboarding/presentation/screens/student_tutorial_screen.dart';
import '../../../features/onboarding/presentation/screens/tutorial_screen.dart';
import '../app_routes.dart';

/// Auth and onboarding routes
List<GoRoute> authRoutes = [
  // Login
  GoRoute(
    path: AppRoutes.login,
    name: 'login',
    builder: (context, state) => const LoginScreen(),
  ),

  // Terms agreement (after first OAuth signup, before role selection)
  GoRoute(
    path: AppRoutes.termsAgreement,
    name: 'termsAgreement',
    builder: (context, state) => const TermsAgreementScreen(),
  ),

  // Role selection (after first OAuth signup)
  GoRoute(
    path: AppRoutes.roleSelect,
    name: 'roleSelect',
    builder: (context, state) => const RoleSelectScreen(),
  ),

  // Parent Invite Code
  GoRoute(
    path: AppRoutes.parentInviteCode,
    name: 'parentInviteCode',
    builder: (context, state) => const ParentInviteCodeScreen(),
  ),

  // Student Invite Code
  GoRoute(
    path: AppRoutes.studentInviteCode,
    name: 'studentInviteCode',
    builder: (context, state) => const StudentInviteCodeScreen(),
  ),

  // Teacher Onboarding - Phone Verification
  GoRoute(
    path: AppRoutes.teacherPhoneVerification,
    name: 'teacherPhoneVerification',
    builder: (context, state) => const PhoneVerificationScreen(),
  ),

  // Teacher Onboarding - Profile Setup
  GoRoute(
    path: AppRoutes.teacherProfileSetup,
    name: 'teacherProfileSetup',
    builder: (context, state) => const ProfileSetupScreen(),
  ),

  // Teacher Onboarding - Tutorial
  GoRoute(
    path: AppRoutes.teacherTutorial,
    name: 'teacherTutorial',
    builder: (context, state) => const TutorialScreen(),
  ),

  // Student Onboarding - Profile Setup
  GoRoute(
    path: AppRoutes.studentProfileSetup,
    name: 'studentProfileSetup',
    builder: (context, state) => const StudentProfileSetupScreen(),
  ),

  // Student Onboarding - Tutorial
  GoRoute(
    path: AppRoutes.studentTutorial,
    name: 'studentTutorial',
    builder: (context, state) => const StudentTutorialScreen(),
  ),

  // Academy Invite Accept
  GoRoute(
    path: AppRoutes.academyInviteAccept,
    name: 'academyInviteAccept',
    builder: (context, state) {
      final token = state.uri.queryParameters['token'];
      if (token == null) {
        return const Scaffold(
          body: Center(child: Text('Invalid invite token')),
        );
      }
      return AcademyInviteAcceptScreen(token: token);
    },
  ),
];
