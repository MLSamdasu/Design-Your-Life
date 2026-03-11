// C0.4/C0.7: 앱 루트 위젯
// MaterialApp.router(GoRouter)를 설정하고 라이트/다크 ThemeData를 적용한다.
// ProviderScope는 main.dart에서 이미 씌워졌으므로 여기서 중복 추가하지 않는다.
// IN: ProviderScope
// OUT: MaterialApp.router (GoRouter + AppTheme 적용)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/global_providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
// 배경 그라디언트는 themePresetDataProvider에서 가져오므로
// ColorTokens 직접 참조 없이 global_providers.dart에서 간접 사용한다

/// 앱 루트 위젯 (C0.4 + C0.7)
/// ConsumerWidget으로 isDarkModeProvider와 routerProvider를 구독한다.
/// 테마 변경 및 인증 상태 변경 시 전체 앱이 재빌드되지 않도록 watch 범위를 최소화한다.
class DesignYourLifeApp extends ConsumerWidget {
  const DesignYourLifeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 다크 모드 여부를 구독한다 (Hive 설정에서 초기값 읽음)
    final isDarkMode = ref.watch(isDarkModeProvider);

    // GoRouter 인스턴스를 구독한다 (인증 가드 포함)
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      // 앱 제목: 디버그 배너 및 태스크 스위처에 표시
      title: 'Design Your Life',

      // 디버그 배너 비활성화
      debugShowCheckedModeBanner: false,

      // 라이트/다크 테마 적용
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // GoRouter 라우터 설정
      routerConfig: router,

      // 글래스모피즘 배경을 위해 투명 배경 설정
      // 실제 그라디언트 배경은 각 Screen의 Scaffold 위에서 Stack으로 구현한다
      builder: (context, child) {
        return _AppBackground(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

/// 앱 전체 배경 위젯
/// 글래스모피즘 디자인의 그라디언트 배경을 항상 표시한다.
/// 모든 화면 위에 공통으로 깔리므로 각 Screen에서 배경을 별도 구현할 필요가 없다.
class _AppBackground extends ConsumerWidget {
  final Widget child;

  const _AppBackground({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    // 테마 프리셋 데이터를 구독하여 프리셋별 배경 그라디언트를 적용한다
    final presetData = ref.watch(themePresetDataProvider);

    // 배경 그라디언트는 테마 변경 시에만 재빌드되므로 RepaintBoundary로 감싸
    // 자식 위젯 리페인트가 배경까지 전파되는 것을 방지한다
    return RepaintBoundary(
      child: Container(
        // 그라디언트 배경: 프리셋별 배경 그라디언트를 사용한다
        // glassmorphism 프리셋은 기존 동작과 동일하다
        decoration: BoxDecoration(
          gradient: isDarkMode
              ? presetData.darkBackgroundGradient
              : presetData.backgroundGradient,
        ),
        child: child,
      ),
    );
  }
}
