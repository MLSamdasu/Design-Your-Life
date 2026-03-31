// 세로 네비게이션 레일 위젯 (ConsumerWidget)
// 세로 캡슐 형태의 플로팅 글래스 네비게이션 바
// 콘텐츠 위에 반투명으로 떠 있어 뒤의 콘텐츠가 비쳐 보인다
// 좌/우 어느 쪽에든 배치 가능하며, 마진 방향이 자동으로 전환된다
// 사용자가 설정에서 크기(navSizeProvider)를 조절할 수 있다
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/global_providers.dart';
import '../../core/theme/layout_tokens.dart';
import '../../core/theme/radius_tokens.dart';
import '../../core/theme/spacing_tokens.dart';
import 'side_nav_item.dart';

/// 세로 네비게이션 레일 (ConsumerWidget)
/// 세로 캡슐 형태의 플로팅 글래스 네비게이션 바
/// 콘텐츠 위에 반투명으로 떠 있어 뒤의 콘텐츠가 비쳐 보인다
/// 좌/우 어느 쪽에든 배치 가능하며, 마진 방향이 자동으로 전환된다
/// 사용자가 설정에서 크기(navSizeProvider)를 조절할 수 있다
class SideNavRail extends ConsumerWidget {
  final int currentIndex;
  final void Function(int) onTabChange;

  /// 네비 레일이 왼쪽에 위치하는지 여부
  final bool isLeftSide;

  const SideNavRail({
    super.key,
    required this.currentIndex,
    required this.onTabChange,
    this.isLeftSide = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 테마 프리셋 데이터와 다크 모드 여부를 구독한다
    final presetData = ref.watch(themePresetDataProvider);
    final isDark = ref.watch(isDarkModeProvider);

    // 사용자가 설정한 네비 바 크기를 구독한다
    final navSize = ref.watch(navSizeProvider);

    // 기존 BottomNav 데코레이션을 재사용한다 (세로 배치에도 동일한 글래스 스타일)
    final navDecoration = isDark
        ? presetData.darkBottomNavDecoration()
        : presetData.bottomNavDecoration();

    // 좌/우에 따라 마진 방향을 전환한다
    final edgePadding = isLeftSide
        ? const EdgeInsets.only(left: AppSpacing.xs)
        : const EdgeInsets.only(right: AppSpacing.xs);

    return Padding(
      padding: edgePadding,
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.circle),
          child: BackdropFilter(
            // 모든 테마에서 글래스모피즘 블러 효과를 적용한다
            filter: ImageFilter.blur(
              sigmaX: EffectLayout.blurSigmaLg,
              sigmaY: EffectLayout.blurSigmaLg,
            ),
            child: Container(
              width: navSize,
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: AppSpacing.xs,
              ),
              decoration: navDecoration,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SideNavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: '홈',
                    index: 0,
                    currentIndex: currentIndex,
                    onTap: onTabChange,
                    navSize: navSize,
                  ),
                  SideNavItem(
                    icon: Icons.calendar_today_outlined,
                    activeIcon: Icons.calendar_today_rounded,
                    label: '캘린더',
                    index: 1,
                    currentIndex: currentIndex,
                    onTap: onTabChange,
                    navSize: navSize,
                  ),
                  SideNavItem(
                    icon: Icons.check_circle_outline,
                    activeIcon: Icons.check_circle_rounded,
                    label: '투두',
                    index: 2,
                    currentIndex: currentIndex,
                    onTap: onTabChange,
                    navSize: navSize,
                  ),
                  SideNavItem(
                    icon: Icons.loop_outlined,
                    activeIcon: Icons.loop_rounded,
                    label: '습관',
                    index: 3,
                    currentIndex: currentIndex,
                    onTap: onTabChange,
                    navSize: navSize,
                  ),
                  SideNavItem(
                    icon: Icons.flag_outlined,
                    activeIcon: Icons.flag_rounded,
                    label: '목표',
                    index: 4,
                    currentIndex: currentIndex,
                    onTap: onTabChange,
                    navSize: navSize,
                  ),
                  SideNavItem(
                    icon: Icons.timer_outlined,
                    activeIcon: Icons.timer_rounded,
                    label: '타이머',
                    index: 5,
                    currentIndex: currentIndex,
                    onTap: onTabChange,
                    navSize: navSize,
                  ),
                  SideNavItem(
                    icon: Icons.sticky_note_2_outlined,
                    activeIcon: Icons.sticky_note_2_rounded,
                    label: '메모',
                    index: 6,
                    currentIndex: currentIndex,
                    onTap: onTabChange,
                    navSize: navSize,
                  ),
                  SideNavItem(
                    icon: Icons.menu_book_outlined,
                    activeIcon: Icons.menu_book_rounded,
                    label: '독서',
                    index: 7,
                    currentIndex: currentIndex,
                    onTap: onTabChange,
                    navSize: navSize,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
