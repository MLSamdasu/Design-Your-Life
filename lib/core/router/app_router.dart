// C0.4: GoRouter 설정
// 인증 상태를 감시하여 인증 가드(redirect)를 포함한 GoRouter를 생성한다.
// StatefulShellRoute.indexedStack으로 6탭 상태 보존을 구현한다.
// SRP 분리: Shell/BottomNav/NavItem → shared/widgets/main_shell.dart
//           Auth 화면 → features/auth/presentation/
// IN: AuthState (C0.3의 OUT), route_paths 상수
// OUT: GoRouter (인증 상태 기반 라우트 가드 포함)
// AN-APPLE: 모든 페이지 전환에 Apple 스타일 CupertinoPageTransition 적용
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_provider.dart';
import '../theme/animation_tokens.dart';
import 'not_found_screen.dart';
import 'route_paths.dart';

// 인증 화면
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';

// 메인 6탭 화면
import '../../features/home/presentation/home_screen.dart';
import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/todo/presentation/todo_screen.dart';
import '../../features/habit/presentation/habit_screen.dart';
import '../../features/goal/presentation/goal_screen.dart';

// Shell (레이아웃)
import '../../shared/widgets/main_shell.dart';

// 타이머 화면 (F6)
import '../../features/timer/presentation/timer_screen.dart';

// 업적 화면 (F8)
import '../../features/achievement/presentation/achievement_screen.dart';

// 태그 관리 화면 (F16)
import '../../features/settings/presentation/widgets/tag_management_screen.dart';

/// GoRouter Provider
/// 인증 상태에 따라 리다이렉트 가드를 적용한 GoRouter를 반환한다
final routerProvider = Provider<GoRouter>((ref) {
  // 인증 상태 변경 감지를 위한 Listenable 생성
  final authNotifier = _AuthStateNotifier(ref);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: authNotifier,

    // 존재하지 않는 경로 접근 시 커스텀 404 화면을 표시한다
    errorBuilder: (context, state) => NotFoundScreen(error: state.error),

    // 로컬 퍼스트 아키텍처 기반 리다이렉트 가드
    // 인증 없이도 앱을 사용할 수 있다. 로그인은 선택 사항(백업 활성화용)이다.
    redirect: (BuildContext context, GoRouterState state) {
      final authAsync = ref.read(authStateProvider);
      final authState = ref.read(currentAuthStateProvider);
      final isLoggedIn = authState.isAuthenticated;
      final currentPath = state.matchedLocation;

      final isSplash = currentPath == RoutePaths.splash;
      final isLogin = currentPath == RoutePaths.login;
      final isOnboarding = currentPath == RoutePaths.onboarding;

      // 스플래시 화면: Auth 상태 로딩 완료 후 항상 홈으로 이동한다
      // 로컬 퍼스트: 인증 여부와 무관하게 홈 화면에서 앱을 시작한다
      if (isSplash) {
        // Auth 상태가 아직 로딩 중이면 스플래시에서 대기한다
        if (authAsync.isLoading) return null;
        // Auth 로드 완료: 인증 여부와 무관하게 홈으로 이동한다
        return RoutePaths.home;
      }

      // 온보딩 화면은 인증된 상태에서만 접근 가능 (미인증 시 홈으로)
      if (isOnboarding && !isLoggedIn) return RoutePaths.home;
      if (isOnboarding) return null;

      // 로그인 화면: 인증된 상태에서 접근 시 홈으로 리다이렉트
      // 미인증 상태에서는 로그인 화면을 정상 표시한다 (선택적 로그인)
      if (isLoggedIn && isLogin) return RoutePaths.home;

      // 그 외 모든 경로는 인증 없이 접근 가능하다 (로컬 퍼스트)
      return null;
    },

    routes: [
      // AN-APPLE: 스플래시 화면 (세션 복원 대기)
      // 부드러운 페이드 인/아웃 (Apple 앱 첫 로딩 스타일)
      GoRoute(
        path: RoutePaths.splash,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              ),
              child: child,
            );
          },
          transitionDuration: AppAnimation.slower,
          reverseTransitionDuration: AppAnimation.slow,
        ),
      ),

      // AN-APPLE: 로그인 화면 (Google OAuth)
      // 부드러운 스케일 + 페이드 (iOS 모달 프레젠테이션 스타일)
      GoRoute(
        path: RoutePaths.login,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            );
            return FadeTransition(
              opacity: curve,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1.0).animate(curve),
                child: child,
              ),
            );
          },
          transitionDuration: AppAnimation.slower,
          reverseTransitionDuration: AppAnimation.slow,
        ),
      ),

      // AN-APPLE: 온보딩 화면 (신규 사용자: 개인정보 동의 + 이름 입력)
      // iOS 스타일 슬라이드 업 (시트 프레젠테이션)
      GoRoute(
        path: RoutePaths.onboarding,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(curve),
              child: FadeTransition(
                opacity: curve,
                child: child,
              ),
            );
          },
          transitionDuration: AppAnimation.slower,
          reverseTransitionDuration: AppAnimation.slow,
        ),
      ),

      // AN-APPLE: 업적/배지 화면 (F8)
      // CupertinoPageTransition 스타일 오른쪽에서 슬라이드 인 (네비게이션 푸시)
      GoRoute(
        path: RoutePaths.achievements,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AchievementScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return CupertinoPageTransition(
              primaryRouteAnimation: animation,
              secondaryRouteAnimation: secondaryAnimation,
              linearTransition: false,
              child: child,
            );
          },
          transitionDuration: AppAnimation.slow,
          reverseTransitionDuration: AppAnimation.slow,
        ),
      ),

      // AN-APPLE: 태그 관리 화면 (F16)
      // CupertinoPageTransition 스타일 오른쪽에서 슬라이드 인 (네비게이션 푸시)
      GoRoute(
        path: RoutePaths.tagManagement,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const TagManagementScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return CupertinoPageTransition(
              primaryRouteAnimation: animation,
              secondaryRouteAnimation: secondaryAnimation,
              linearTransition: false,
              child: child,
            );
          },
          transitionDuration: AppAnimation.slow,
          reverseTransitionDuration: AppAnimation.slow,
        ),
      ),

      // 메인 6탭 Shell (StatefulShellRoute.indexedStack)
      // 탭 전환 시 각 탭의 상태(스크롤 위치, 선택된 날짜)를 보존한다
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          // 탭 0: 홈 대시보드 (F1)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // 탭 1: 캘린더 (F2)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.calendar,
                builder: (context, state) => const CalendarScreen(),
              ),
            ],
          ),

          // 탭 2: 투두 (F3)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.todo,
                builder: (context, state) => const TodoScreen(),
              ),
            ],
          ),

          // 탭 3: 습관/루틴 (F4)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.habit,
                builder: (context, state) => const HabitScreen(),
              ),
            ],
          ),

          // 탭 4: 목표/만다라트 (F5)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.goal,
                builder: (context, state) => const GoalScreen(),
              ),
            ],
          ),

          // 탭 5: 포모도로 타이머 (F6)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.timer,
                builder: (context, state) => const TimerScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

// ─── 인증 상태 Listenable ─────────────────────────────────────────────────
/// GoRouter의 refreshListenable로 사용하는 인증 상태 Notifier
/// Riverpod authStateProvider를 구독하여
/// 인증 상태 변경 시 GoRouter의 리다이렉트 로직을 재실행한다
class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier(Ref ref) {
    // Riverpod authStateProvider 변경 감지 시 GoRouter redirect를 재실행한다
    ref.listen(authStateProvider, (_, __) {
      notifyListeners();
    });
  }
}
