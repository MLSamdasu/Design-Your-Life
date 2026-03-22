// 공용 위젯: MainShell - 6탭 메인 레이아웃 쉘
// 콘텐츠가 전체 화면을 차지하고, 반투명 글래스 네비 레일이 플로팅된다.
// 네비 레일 위치(좌/우)와 수직 높낮이는 설정에서 조절 가능하다.
// StatefulShellRoute.indexedStack에서 builder로 사용한다.
// SRP: app_router.dart에서 Shell/SideNavRail/SideNavItem 관심사를 분리한다.
// AN-SWIPE: 수평 스와이프로 탭 전환을 지원한다.
// AN-SLIDE: 탭 전환 시 방향성 슬라이드 + 페이드 애니메이션을 적용한다.
// IN: StatefulNavigationShell (GoRouter)
// OUT: Scaffold (네비게이션 포함 레이아웃)
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/route_paths.dart';
import '../../core/providers/global_providers.dart';
import '../../core/theme/animation_tokens.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/layout_tokens.dart';
import '../../core/theme/radius_tokens.dart';
import '../../core/theme/spacing_tokens.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/typography_tokens.dart';
import '../../features/achievement/models/achievement.dart';
import '../../features/achievement/presentation/widgets/achievement_unlock_dialog.dart';
import '../../features/achievement/providers/achievement_provider.dart';
import '../providers/tutorial_provider.dart';
import 'tutorial_overlay.dart';

/// 6탭 메인 레이아웃 Shell
/// 콘텐츠가 전체 화면을 채우고, 반투명 글래스 네비 레일이 플로팅된다
/// 네비 레일 위치(좌/우)와 수직 높이는 사용자 설정에 따라 조절된다
/// AN-SWIPE: 수평 스와이프로 탭 전환 지원
/// AN-SLIDE: 방향성 슬라이드 + 페이드 전환 애니메이션
class MainShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({required this.navigationShell, super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with SingleTickerProviderStateMixin {
  /// 탭 전환 애니메이션 컨트롤러
  late AnimationController _tabAnimController;

  /// 슬라이드 방향 (1: 앞으로, -1: 뒤로)
  int _slideDirection = 1;

  /// 네비 바 드래그 모드 활성화 여부
  bool _isDraggingNav = false;

  /// 드래그 시작 시 초기 수직 위치 값 (Alignment.y)
  double _dragStartVerticalPos = 0.0;

  /// 드래그 시작 시 초기 글로벌 Y 좌표
  double _dragStartGlobalY = 0.0;

  /// 스와이프 최소 속도 임계값 (px/s) — 너무 느린 스와이프를 무시한다
  static const double _swipeVelocityThreshold = 400;

  /// 탭 전환 슬라이드 거리 (px) — 미세한 수평 이동 효과
  static const double _slideDistance = 24;

  @override
  void initState() {
    super.initState();
    _tabAnimController = AnimationController(
      duration: AppAnimation.medium,
      vsync: this,
    )..value = 1.0; // 초기 상태: 완전히 표시된 상태
  }

  @override
  void didUpdateWidget(MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 탭 인덱스가 변경되면 방향성 슬라이드 전환 애니메이션을 재생한다
    if (oldWidget.navigationShell.currentIndex !=
        widget.navigationShell.currentIndex) {
      // 새 인덱스가 이전보다 크면 앞으로(1), 작으면 뒤로(-1)
      _slideDirection =
          widget.navigationShell.currentIndex >
                  oldWidget.navigationShell.currentIndex
              ? 1
              : -1;
      // 접근성: 모션 축소 설정 시 애니메이션 생략
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

  /// 수평 스와이프로 탭을 전환한다
  /// 왼쪽 스와이프 → 다음 탭, 오른쪽 스와이프 → 이전 탭
  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    // 최소 속도 미만의 느린 스와이프는 무시한다
    if (velocity.abs() < _swipeVelocityThreshold) return;

    final current = widget.navigationShell.currentIndex;

    int newIndex;
    if (velocity < 0) {
      // 왼쪽으로 스와이프 → 다음 탭
      newIndex = (current + 1).clamp(TabIndex.home, TabIndex.timer);
    } else {
      // 오른쪽으로 스와이프 → 이전 탭
      newIndex = (current - 1).clamp(TabIndex.home, TabIndex.timer);
    }

    if (newIndex != current) {
      widget.navigationShell.goBranch(newIndex, initialLocation: false);
    }
  }

  /// P1-10: 업적 다이얼로그를 큐에서 하나씩 순차적으로 표시한다
  /// 현재 다이얼로그가 닫힌 후에만 다음 다이얼로그를 표시하여 중첩을 방지한다
  /// while 루프로 처리하여 재귀 호출에 의한 스택 오버플로를 방지한다
  Future<void> _showNextAchievementDialog(WidgetRef ref) async {
    // 이미 다이얼로그가 표시 중이면 추가로 열지 않는다
    if (ref.read(isShowingAchievementDialogProvider)) return;

    ref.read(isShowingAchievementDialogProvider.notifier).state = true;

    while (mounted) {
      final pending = ref.read(pendingAchievementProvider);
      if (pending.isEmpty) break;

      // 큐에서 첫 번째 업적을 꺼낸다
      final achievement = pending.first;
      ref.read(pendingAchievementProvider.notifier).state =
          pending.sublist(1);

      // 다이얼로그가 닫힐 때까지 대기한다
      await AchievementUnlockDialog.show(context, achievement);
    }

    // 다이얼로그 표시 완료 플래그를 해제한다
    ref.read(isShowingAchievementDialogProvider.notifier).state = false;
  }

  @override
  Widget build(BuildContext context) {
    // 네비 바 위치 설정 구독 (좌/우, 수직 위치)
    final isNavLeft = ref.watch(navSideLeftProvider);
    final navVerticalPos = ref.watch(navVerticalPosProvider);

    // 튜토리얼 표시 요청 감시 (설정에서 "튜토리얼 보기" 탭 시 true로 변경됨)
    final showTutorial = ref.watch(showTutorialProvider);

    // P1-10: 새로 달성된 업적을 순차적으로 표시한다 (다이얼로그 중첩 방지)
    // isShowingAchievementDialogProvider 플래그로 현재 다이얼로그 표시 중이면
    // 추가 다이얼로그를 열지 않고, 현재 다이얼로그가 닫힌 후 다음 업적을 표시한다
    ref.listen<List<Achievement>>(pendingAchievementProvider, (prev, next) {
      if (next.isNotEmpty && mounted) {
        _showNextAchievementDialog(ref);
      }
    });

    return Scaffold(
      // 배경: 테마 프리셋 그라디언트 (app.dart의 _AppBackground에서 설정)
      backgroundColor: ColorTokens.transparent,
      body: Stack(
        children: [
          // 콘텐츠 영역: 전체 화면을 채운다 (네비 레일 뒤까지 확장)
          // 반투명 글래스 레일이 위에 플로팅되므로 콘텐츠가 비쳐 보인다
          SafeArea(
            bottom: false,
            child: GestureDetector(
              onHorizontalDragEnd: _onHorizontalDragEnd,
              behavior: HitTestBehavior.translucent,
              // AN-SLIDE: 방향성 슬라이드 + 페이드 전환
              child: AnimatedBuilder(
                animation: _tabAnimController,
                builder: (context, child) {
                  final progress = Curves.easeInOutCubic
                      .transform(_tabAnimController.value);
                  return Transform.translate(
                    offset: Offset(
                      (1 - progress) * _slideDirection * _slideDistance,
                      0,
                    ),
                    child: Opacity(
                      opacity: progress.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: widget.navigationShell,
              ),
            ),
          ),

          // 플로팅 세로 네비게이션 레일: 설정에 따라 좌/우 + 높낮이 배치
          // 롱프레스 후 드래그로 수직 위치를 실시간 조절할 수 있다
          Positioned(
            // 좌/우 위치: 설정값에 따라 동적으로 결정된다
            left: isNavLeft ? 0 : null,
            right: isNavLeft ? null : 0,
            top: 0,
            bottom: 0,
            child: SafeArea(
              // 반대쪽 SafeArea 여백을 비활성화한다
              left: !isNavLeft,
              right: isNavLeft,
              child: GestureDetector(
                onLongPressStart: (details) {
                  // 드래그 모드 진입: 초기 위치를 기록한다
                  setState(() => _isDraggingNav = true);
                  _dragStartVerticalPos = ref.read(navVerticalPosProvider);
                  _dragStartGlobalY = details.globalPosition.dy;
                  // 햅틱 피드백으로 드래그 모드 진입을 알린다
                  HapticFeedback.mediumImpact();
                },
                onLongPressMoveUpdate: (details) {
                  if (!_isDraggingNav) return;
                  // 글로벌 Y 좌표의 변화량을 사용 가능 높이 기준으로 정규화한다
                  final screenHeight = MediaQuery.of(context).size.height;
                  final safeArea = MediaQuery.of(context).padding;
                  final usableHeight =
                      screenHeight - safeArea.top - safeArea.bottom;
                  // 드래그 delta를 -1.0 ~ 1.0 범위로 매핑한다
                  final deltaY =
                      details.globalPosition.dy - _dragStartGlobalY;
                  final normalizedDelta = (deltaY / usableHeight) * 2.0;
                  final newPos = (_dragStartVerticalPos + normalizedDelta)
                      .clamp(-1.0, 1.0);
                  ref.read(navVerticalPosProvider.notifier).state = newPos;
                },
                onLongPressEnd: (_) {
                  // 드래그 종료: 위치를 Hive에 영속 저장한다
                  setState(() => _isDraggingNav = false);
                  final pos = ref.read(navVerticalPosProvider);
                  ref.read(hiveCacheServiceProvider).saveSetting(
                        AppConstants.settingsKeyNavVerticalPos,
                        pos,
                      );
                },
                child: Align(
                  // 수직 위치: 설정값(-1.0=상단, 0.0=중앙, 1.0=하단)에 따라 배치
                  alignment: Alignment(0, navVerticalPos),
                  child: AnimatedScale(
                    // 드래그 모드 시 1.08배 확대로 시각적 피드백을 제공한다
                    scale: _isDraggingNav ? 1.08 : 1.0,
                    duration: AppAnimation.standard,
                    child: AnimatedContainer(
                      duration: AppAnimation.standard,
                      decoration: _isDraggingNav
                          ? BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.circle),
                              boxShadow: [
                                BoxShadow(
                                  // 악센트 색상 글로우로 드래그 모드를 시각적으로 표현한다
                                  color: context.themeColors
                                      .accentWithAlpha(0.3),
                                  blurRadius: AppLayout.blurRadiusMd,
                                ),
                              ],
                            )
                          : null,
                      child: SideNavRail(
                        currentIndex: widget.navigationShell.currentIndex,
                        isLeftSide: isNavLeft,
                        onTabChange: (index) =>
                            widget.navigationShell.goBranch(
                          index,
                          // 현재 탭 재탭 시 스크롤 최상단으로 이동한다
                          initialLocation:
                              index == widget.navigationShell.currentIndex,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 튜토리얼 오버레이: 설정에서 "튜토리얼 보기" 탭 시 표시된다
          if (showTutorial)
            Positioned.fill(
              child: TutorialOverlay(
                onComplete: () {
                  // 표시 요청 플래그를 리셋한다
                  ref.read(showTutorialProvider.notifier).state = false;
                },
              ),
            ),
        ],
      ),
    );
  }
}

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
              sigmaX: AppLayout.blurSigmaLg,
              sigmaY: AppLayout.blurSigmaLg,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 세로 네비게이션 개별 아이템
/// 최소 터치 타겟 44x44px 보장 (WCAG 2.1 기준)
/// 활성 상태: 아이콘 + 라벨 (강조 배경) / 비활성: 아이콘만 (페이드)
/// navSize에 따라 아이콘 크기/패딩이 비례 스케일링된다
class SideNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final void Function(int) onTap;

  /// 부모 SideNavRail에서 전달받는 캡슐 너비
  final double navSize;

  const SideNavItem({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    required this.navSize,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;

    // navSize를 기본값(56px) 대비 비율로 환산하여 아이콘/패딩을 비례 스케일링한다
    final sizeRatio = navSize / AppLayout.sideNavWidth;
    final iconSize = AppLayout.iconNav * sizeRatio;
    // 아이템 너비: 캡슐 너비에서 좌우 패딩을 뺀 값
    final itemWidth = navSize - AppSpacing.md;

    // 접근성: 탭 이름 + 선택 상태를 스크린 리더에 전달한다
    return Semantics(
      label: '$label 탭',
      selected: isActive,
      button: true,
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppAnimation.standard,
          curve: Curves.easeInOutCubic,
          // 캡슐 내부 폭에 맞춘다 (navSize - 좌우 패딩)
          width: itemWidth,
          padding: EdgeInsets.symmetric(
            vertical: isActive
                ? AppSpacing.mdLg * sizeRatio
                : AppSpacing.md * sizeRatio,
          ),
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
          decoration: BoxDecoration(
            color: isActive
                ? context.themeColors.textPrimaryWithAlpha(0.25)
                : ColorTokens.transparent,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 아이콘 (활성 시 풀 스케일, 비활성 시 축소)
              AnimatedScale(
                scale: isActive ? 1.0 : 0.85,
                duration: AppAnimation.normal,
                child: Icon(
                  isActive ? activeIcon : icon,
                  color: context.themeColors.textPrimaryWithAlpha(
                      isActive ? 1.0 : 0.45),
                  size: iconSize,
                ),
              ),
              // 활성 탭만 라벨을 표시한다 (AnimatedSize로 부드럽게 전환)
              AnimatedSize(
                duration: AppAnimation.standard,
                curve: Curves.easeInOutCubic,
                child: isActive
                    ? Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xxs),
                        child: Text(
                          label,
                          // captionSm 토큰 사용 (네비게이션 라벨)
                          style: AppTypography.captionSm.copyWith(
                            color: context.themeColors.textPrimary,
                            fontWeight: AppTypography.weightSemiBold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
