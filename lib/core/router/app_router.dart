// C0.4: GoRouter 설정
// 인증 상태를 감시하여 인증 가드(redirect)를 포함한 GoRouter를 생성한다.
// 라우트 정의는 auth_routes.dart와 tab_routes.dart로 분리하여 SRP를 준수한다.
// 입력: AuthState (C0.3의 출력), route_paths 상수
// 출력: GoRouter (인증 상태 기반 라우트 가드 포함)
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_provider.dart';
import 'not_found_screen.dart';
import 'route_paths.dart';
import 'auth_routes.dart';
import 'tab_routes.dart';

// 하위 모듈 배럴 export (기존 import 호환성 유지)
export 'route_paths.dart';
export 'auth_routes.dart';
export 'tab_routes.dart';

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
      // 인증 관련 라우트 (스플래시, 로그인, 온보딩)
      ...buildAuthRoutes(),

      // 독립 라우트 (업적, 태그 관리 등 — 하단 탭 바 없음)
      ...buildStandaloneRoutes(),

      // 메인 8탭 Shell (StatefulShellRoute.indexedStack)
      buildTabShellRoute(),
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
