// C0.4-A: 인증 관련 라우트 정의
// 스플래시, 로그인, 온보딩 화면의 GoRoute를 정의한다.
// Apple 스타일 페이지 전환 애니메이션을 각 라우트에 적용한다.
// 입력: RoutePaths 상수, AppAnimation 토큰
// 출력: List<RouteBase> (인증 라우트 목록)
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../theme/animation_tokens.dart';
import 'route_paths.dart';

import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';

/// 인증 관련 라우트 목록을 반환한다
/// 스플래시, 로그인, 온보딩 화면을 포함한다
List<RouteBase> buildAuthRoutes() => [
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
];
