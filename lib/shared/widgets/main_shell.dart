// 공용 위젯: MainShell - 5탭 메인 레이아웃 쉘
// 플로팅 캡슐 하단 네비게이션 + 콘텐츠 영역으로 구성된다.
// StatefulShellRoute.indexedStack에서 builder로 사용한다.
// SRP: app_router.dart에서 Shell/BottomNav/NavItem 관심사를 분리한다.
// AN-APPLE: 탭 전환 시 부드러운 페이드 크로스페이드 애니메이션을 적용한다.
// IN: StatefulNavigationShell (GoRouter)
// OUT: Scaffold (네비게이션 포함 레이아웃)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/global_providers.dart';
import '../../core/theme/animation_tokens.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/layout_tokens.dart';
import '../../core/theme/radius_tokens.dart';
import '../../core/theme/spacing_tokens.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/typography_tokens.dart';

/// 5탭 메인 레이아웃 Shell
/// 플로팅 캡슐 하단 네비게이션 + 콘텐츠 영역으로 구성한다
/// AN-APPLE: 탭 전환 시 Apple 스타일 페이드 + 미세 스케일 애니메이션 적용
class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({required this.navigationShell, super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  /// 탭 전환 애니메이션 컨트롤러 (Apple 스타일 페이드 크로스페이드)
  late AnimationController _tabAnimController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _tabAnimController = AnimationController(
      duration: AppAnimation.medium,
      vsync: this,
    )..value = 1.0; // 초기 상태: 완전히 표시된 상태

    _fadeAnimation = CurvedAnimation(
      parent: _tabAnimController,
      curve: Curves.easeInOutCubic,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.97,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _tabAnimController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didUpdateWidget(MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 탭 인덱스가 변경되면 페이드 인 애니메이션을 재생한다
    if (oldWidget.navigationShell.currentIndex !=
        widget.navigationShell.currentIndex) {
      // 감소 모션 설정 확인
      final reduceMotion = MediaQuery.disableAnimationsOf(context);
      if (!reduceMotion) {
        _tabAnimController.value = 0.0;
        _tabAnimController.forward();
      }
    }
  }

  @override
  void dispose() {
    _tabAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 배경: 테마 프리셋 그라디언트 (app.dart의 _AppBackground에서 설정)
      backgroundColor: ColorTokens.transparent,
      body: Stack(
        children: [
          // 콘텐츠 영역 (탭별 화면)
          // SafeArea로 상단 상태바 영역을 보호한다 (하단은 bottomNavArea 패딩으로 처리)
          // 그라디언트 배경은 상태바 뒤까지 확장되지만 콘텐츠는 안전 영역 내에 배치된다
          // AN-APPLE: 탭 전환 시 페이드 + 미세 스케일 애니메이션 적용
          SafeArea(
            // 하단은 플로팅 네비게이션 바 패딩으로 별도 처리하므로 SafeArea 적용 제외
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppLayout.bottomNavArea),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: widget.navigationShell,
                ),
              ),
            ),
          ),

          // 플로팅 캡슐 하단 네비게이션 바 (프리셋 인식 ConsumerWidget)
          Positioned(
            left: 0,
            right: 0,
            bottom: AppSpacing.lg,
            child: BottomNavBar(
              currentIndex: widget.navigationShell.currentIndex,
              onTabChange: (index) => widget.navigationShell.goBranch(
                index,
                // 현재 탭 재탭 시 스크롤 최상단으로 이동한다
                initialLocation:
                    index == widget.navigationShell.currentIndex,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 플로팅 캡슐 하단 네비게이션 바 (ConsumerWidget)
/// 테마 프리셋에 따라 데코레이션을 동적으로 적용한다
class BottomNavBar extends ConsumerWidget {
  final int currentIndex;
  final void Function(int) onTabChange;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 테마 프리셋 데이터와 다크 모드 여부를 구독한다
    final presetData = ref.watch(themePresetDataProvider);
    final isDark = ref.watch(isDarkModeProvider);

    // 다크 모드에 따라 적절한 Bottom Nav 데코레이션을 선택한다
    final navDecoration = isDark
        ? presetData.darkBottomNavDecoration()
        : presetData.bottomNavDecoration();

    return Center(
      child: Container(
        height: AppLayout.bottomNavHeight,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.huge),
        decoration: navDecoration,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            NavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: '홈',
              index: 0,
              currentIndex: currentIndex,
              onTap: onTabChange,
              isDark: isDark,
            ),
            NavItem(
              icon: Icons.calendar_today_outlined,
              activeIcon: Icons.calendar_today_rounded,
              label: '캘린더',
              index: 1,
              currentIndex: currentIndex,
              onTap: onTabChange,
              isDark: isDark,
            ),
            NavItem(
              icon: Icons.check_circle_outline,
              activeIcon: Icons.check_circle_rounded,
              label: '투두',
              index: 2,
              currentIndex: currentIndex,
              onTap: onTabChange,
              isDark: isDark,
            ),
            NavItem(
              icon: Icons.loop_outlined,
              activeIcon: Icons.loop_rounded,
              label: '습관',
              index: 3,
              currentIndex: currentIndex,
              onTap: onTabChange,
              isDark: isDark,
            ),
            NavItem(
              icon: Icons.flag_outlined,
              activeIcon: Icons.flag_rounded,
              label: '목표',
              index: 4,
              currentIndex: currentIndex,
              onTap: onTabChange,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

/// 하단 네비게이션 개별 아이템
/// 최소 터치 타겟 44x44px 보장 (WCAG 2.1 기준)
class NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final void Function(int) onTap;
  // 다크 모드 여부를 받아 아이콘/텍스트 색상을 결정한다
  final bool isDark;

  const NavItem({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;

    // minimal/retro 프리셋에서는 텍스트가 어두울 수 있으므로
    // NavItem 색상은 프리셋에 관계없이 흰색을 유지한다
    // (BottomNavBar 배경이 항상 충분한 대비를 제공함)
    // 접근성: 탭 이름 + 선택 상태를 스크린 리더에 전달한다
    return Semantics(
      label: '$label 탭',
      selected: isActive,
      button: true,
      child: SizedBox(
        height: AppLayout.minTouchTarget,
        child: GestureDetector(
          onTap: () => onTap(index),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: AppAnimation.standard,
            curve: Curves.easeInOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: isActive ? AppSpacing.xl : AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? context.themeColors.textPrimaryWithAlpha(0.25)
                  : ColorTokens.transparent,
              borderRadius: BorderRadius.circular(AppRadius.circle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: isActive ? 1.0 : 0.9,
                  duration: AppAnimation.normal,
                  child: Icon(
                    isActive ? activeIcon : icon,
                    color: context.themeColors.textPrimaryWithAlpha(
                        isActive ? 1.0 : 0.45),
                    size: AppLayout.iconNav,
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    label,
                    // captionMd 토큰 사용 (네비게이션 라벨)
                    style: AppTypography.captionMd.copyWith(
                      color: context.themeColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
