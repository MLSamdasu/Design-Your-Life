// C0.4-B: 탭 및 독립 라우트 정의
// StatefulShellRoute.indexedStack으로 8탭 하단 네비게이션을 구성한다.
// 업적/태그 관리 등 탭 바깥 독립 라우트도 포함한다.
// 입력: RoutePaths 상수, AppAnimation 토큰
// 출력: List<RouteBase> (탭 셸 + 독립 라우트 목록)
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../theme/animation_tokens.dart';
import 'route_paths.dart';

// 메인 7탭 화면
import '../../features/home/presentation/home_screen.dart';
import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/todo/presentation/todo_screen.dart';
import '../../features/habit/presentation/habit_screen.dart';
import '../../features/goal/presentation/goal_screen.dart';
import '../../features/timer/presentation/timer_screen.dart';
import '../../features/memo/presentation/memo_screen.dart';
import '../../features/book/presentation/book_screen.dart';

// 독립 라우트 화면
import '../../features/achievement/presentation/achievement_screen.dart';
import '../../features/settings/presentation/widgets/tag_management_screen.dart';

// Shell (레이아웃)
import '../../shared/widgets/main_shell.dart';

/// 독립 라우트 목록을 반환한다
/// 하단 탭 바 없이 표시되는 전체 화면 라우트 (업적, 태그 관리 등)
List<RouteBase> buildStandaloneRoutes() => [
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
];

/// 메인 8탭 StatefulShellRoute를 반환한다
/// 탭 전환 시 각 탭의 상태(스크롤 위치, 선택된 날짜)를 보존한다
StatefulShellRoute buildTabShellRoute() =>
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

        // 탭 6: 메모 드로잉 (F7)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.memo,
              builder: (context, state) => const MemoScreen(),
            ),
          ],
        ),

        // 탭 7: 독서 캘린더 (F9)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.book,
              builder: (context, state) => const BookScreen(),
            ),
          ],
        ),
      ],
    );
