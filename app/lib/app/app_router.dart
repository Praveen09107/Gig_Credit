import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/auth_provider.dart';
import '../app/app_shell.dart';

// ── Placeholder screens ──────────────────────────────────────
// These will be replaced phase by phase.
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/auth/screens/otp_verification_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/home/screens/about_screen.dart';
import '../features/home/screens/schemes_screen.dart';
import '../features/score/screens/score_intro_screen.dart';
import '../features/score/screens/input_guidance_screen.dart';
import '../features/score/screens/show_me_how_screen.dart';
import '../features/score/screens/score_generating_screen.dart';
import '../features/score/flow/step1_personal_screen.dart';
import '../features/score/flow/step2_kyc_screen.dart';
import '../features/score/flow/step3_bank_screen.dart';
import '../features/score/flow/step4_utility_screen.dart';
import '../features/score/flow/step5_work_screen.dart';
import '../features/score/flow/step6_gov_schemes_screen.dart';
import '../features/score/flow/step7_insurance_screen.dart';
import '../features/score/flow/step8_tax_screen.dart';
import '../features/score/flow/step9_emi_loans_screen.dart';
import '../features/report/screens/score_report_screen.dart';
import '../features/report/screens/certificate_screen.dart';
import '../features/loans/screens/loan_detail_screen.dart';
import '../features/loans/screens/loan_application_screen.dart';
import '../features/loans/screens/xai_report_screen.dart';
import '../features/applications/screens/applications_screen.dart';
import '../features/applications/screens/application_detail_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/report_history_screen.dart';
import '../features/credits/screens/buy_credits_screen.dart';

// ── Route names (string constants) ───────────────────────────
class AppRoutes {
  AppRoutes._();
  static const String splash = '/';
  static const String login = '/auth/login';
  static const String signup = '/auth/signup';
  static const String otp = '/auth/otp';
  static const String shell = '/app';
  static const String home = '/app/home';
  static const String about = '/app/about';
  static const String schemes = '/app/schemes';
  static const String score = '/app/score';
  static const String scoreHowItWorks = '/app/score/how-it-works';
  static const String scoreGenerating = '/app/score/generating';
  static const String scoreReport = '/app/score/report';
  static const String certificate = '/app/score/report/certificate';
  static const String loans = '/app/loans';
  static const String loanDetail = '/app/loans/detail';
  static const String applications = '/app/applications';
  static const String applicationDetail = '/app/applications/detail';
  static const String profile = '/app/profile';
  static const String buyCredits = '/app/profile/buy-credits';
  static const String reportHistory = '/app/profile/reports';
  static const String loanApply = '/app/loans/apply';
  static const String loanDecisionReport = '/app/loans/apply/report';

  // Step flow — dynamic
  static String scoreStep(int step) => '/app/score/flow/$step';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<bool>(ref.read(authProvider).isAuthenticated);
  
  ref.listen(authProvider, (_, next) {
    authNotifier.value = next.isAuthenticated;
  });

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authNotifier,
    debugLogDiagnostics: false,
    routes: AppRouter._routes,
    redirect: (context, state) {
      final isAuthenticated = ref.read(authProvider).isAuthenticated;
      final onAuthRoute = state.fullPath?.startsWith('/auth') ?? false;
      final onSplash = state.fullPath == '/';

      if (onSplash) return null;
      if (!isAuthenticated && !onAuthRoute) return AppRoutes.login;
      if (isAuthenticated && onAuthRoute) return AppRoutes.home;
      return null;
    },
    errorBuilder: (context, state) => const _NotFoundScreen(),
  );
});

class AppRouter {
  AppRouter._();

  static final List<RouteBase> _routes = [
    // ── Pre-auth ─────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.splash,
      name: 'splash',
      builder: (ctx, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (ctx, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.signup,
      name: 'signup',
      builder: (ctx, state) => const SignupScreen(),
    ),
    GoRoute(
      path: AppRoutes.otp,
      name: 'otp',
      builder: (ctx, state) => OtpVerificationScreen(
        mobile: state.uri.queryParameters['mobile'] ?? '',
        isSignup: state.uri.queryParameters['isSignup'] == 'true',
      ),
    ),

    // ── App Shell (5-tab bottom nav) ─────────────────────────
    ShellRoute(
      builder: (ctx, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          name: 'home',
          builder: (ctx, state) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.about,
          name: 'about',
          builder: (ctx, state) => const AboutScreen(),
        ),
        GoRoute(
          path: AppRoutes.schemes,
          name: 'schemes',
          builder: (ctx, state) => const SchemesScreen(),
        ),

        // Score flow
        GoRoute(
          path: '/app/guidance',
          name: 'guidance',
          builder: (ctx, state) => const InputGuidanceScreen(),
        ),
        GoRoute(
          path: AppRoutes.score,
          name: 'score',
          builder: (ctx, state) => const ScoreIntroScreen(),
          routes: [
            GoRoute(
              path: 'how-it-works',
              name: 'scoreHowItWorks',
              builder: (ctx, state) => const ShowMeHowScreen(),
            ),
            GoRoute(
              path: 'flow/1',
              name: 'step1',
              builder: (ctx, state) => const Step1PersonalScreen(),
            ),
            GoRoute(
              path: 'flow/2',
              name: 'step2',
              builder: (ctx, state) => const Step2KycScreen(),
            ),
            GoRoute(
              path: 'flow/3',
              name: 'step3',
              builder: (ctx, state) => const Step3BankScreen(),
            ),
            GoRoute(
              path: 'flow/4',
              name: 'step4',
              builder: (ctx, state) => const Step4UtilityScreen(),
            ),
            GoRoute(
              path: 'flow/5',
              name: 'step5',
              builder: (ctx, state) => const Step5WorkScreen(),
            ),
            GoRoute(
              path: 'flow/6',
              name: 'step6',
              builder: (ctx, state) => const Step6GovSchemesScreen(),
            ),
            GoRoute(
              path: 'flow/7',
              name: 'step7',
              builder: (ctx, state) => const Step7InsuranceScreen(),
            ),
            GoRoute(
              path: 'flow/8',
              name: 'step8',
              builder: (ctx, state) => const Step8TaxScreen(),
            ),
            GoRoute(
              path: 'flow/9',
              name: 'step9',
              builder: (ctx, state) => const Step9EmiLoansScreen(),
            ),
            GoRoute(
              path: 'generating',
              name: 'generating',
              builder: (ctx, state) => const ScoreGeneratingScreen(),
            ),
            GoRoute(
              path: 'report',
              name: 'report',
              builder: (ctx, state) => const ScoreReportScreen(),
              routes: [
                GoRoute(
                  path: 'certificate',
                  name: 'certificate',
                  builder: (ctx, state) => const CertificateScreen(),
                ),
              ],
            ),
          ],
        ),

        // Loans
        GoRoute(
          path: AppRoutes.loans,
          name: 'loans',
          builder: (ctx, state) => const LoanApplicationScreen(),
          routes: [
            GoRoute(
              path: 'detail/:offerId',
              name: 'loanDetail',
              builder: (ctx, state) => LoanDetailScreen(
                offerId: state.pathParameters['offerId'] ?? '',
              ),
            ),
            GoRoute(
              path: 'apply',
              name: 'loanApply',
              builder: (ctx, state) => const LoanApplicationScreen(),
              routes: [
                GoRoute(
                  path: 'report',
                  name: 'loanDecisionReport',
                  builder: (ctx, state) => XaiReportScreen(
                    decisionData: state.extra as Map<String, dynamic>? ?? {},
                    onBack: () => ctx.pop(),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Applications
        GoRoute(
          path: AppRoutes.applications,
          name: 'applications',
          builder: (ctx, state) => const ApplicationsScreen(),
          routes: [
            GoRoute(
              path: 'detail/:appId',
              name: 'applicationDetail',
              builder: (ctx, state) => ApplicationDetailScreen(
                applicationId: state.pathParameters['appId'] ?? '',
              ),
            ),
          ],
        ),

        // Profile
        GoRoute(
          path: AppRoutes.profile,
          name: 'profile',
          builder: (ctx, state) => const ProfileScreen(),
          routes: [
            GoRoute(
              path: 'buy-credits',
              name: 'buyCredits',
              builder: (ctx, state) => const BuyCreditsScreen(),
            ),
            GoRoute(
              path: 'reports',
              name: 'reportHistory',
              builder: (ctx, state) => const ReportHistoryScreen(),
            ),
          ],
        ),
      ],
    ),
  ];
}

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Page not found', style: TextStyle(color: Colors.white))),
    );
  }
}
