// 공용 위젯: MainShell - 7탭 메인 레이아웃 쉘
// SRP 분리: SideNavRail→side_nav_rail.dart, SideNavItem→side_nav_item.dart,
//      FloatingNavRail→floating_nav_rail.dart
// 입력: StatefulNavigationShell / 출력: Scaffold
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/global_providers.dart';
import '../../core/router/route_paths.dart';
import '../../core/theme/animation_tokens.dart';
import '../../core/theme/color_tokens.dart';
import '../../features/achievement/models/achievement.dart';
import '../../features/achievement/presentation/widgets/achievement_unlock_dialog.dart';
import '../../features/achievement/providers/achievement_provider.dart';
import '../../features/ritual/presentation/daily_ritual_screen.dart';
import '../../features/ritual/providers/ritual_provider.dart';
import '../providers/tutorial_provider.dart';
import 'floating_nav_rail.dart';
import 'tutorial_overlay.dart';

/// 7탭 메인 레이아웃 Shell — 전체 화면 콘텐츠 + 플로팅 글래스 네비 레일
class MainShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({required this.navigationShell, super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with SingleTickerProviderStateMixin {
  late AnimationController _tabAnimController;
  int _slideDirection = 1;
  static const double _swipeVelocityThreshold = 400;
  static const double _slideDistance = 24;

  /// 리추얼 체크를 한 번만 실행하기 위한 플래그 (핫 리로드/탭 전환 시 재실행 방지)
  bool _ritualChecked = false;

  @override
  void initState() {
    super.initState();
    _tabAnimController = AnimationController(
      duration: AppAnimation.medium,
      vsync: this,
    )..value = 1.0;
    // 앱 첫 진입 시 데일리 리추얼 완료 여부를 체크하고 미완료 시 표시한다
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkDailyRitual());
  }

  /// 오늘의 데일리 리추얼 완료 여부를 확인하고, 미완료 시 리추얼 화면을 표시한다
  /// 앱 런치 당 한 번만 실행된다 (_ritualChecked 플래그로 제어)
  Future<void> _checkDailyRitual() async {
    if (_ritualChecked || !mounted) return;
    _ritualChecked = true;

    // 설정에서 데일리 리추얼이 비활성화되었으면 표시하지 않는다
    final enabled = ref.read(dailyRitualEnabledProvider);
    if (!enabled) return;

    final completed = ref.read(hasCompletedTodayProvider);
    if (!completed && mounted) {
      await Navigator.of(context).push(
        PageRouteBuilder(
          opaque: true,
          pageBuilder: (_, __, ___) => const DailyRitualScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: AppAnimation.medium,
        ),
      );
    }
  }

  @override
  void didUpdateWidget(MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigationShell.currentIndex !=
        widget.navigationShell.currentIndex) {
      _slideDirection =
          widget.navigationShell.currentIndex >
                  oldWidget.navigationShell.currentIndex
              ? 1
              : -1;
      if (!MediaQuery.disableAnimationsOf(context)) {
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

  /// 수평 스와이프로 탭 전환 (왼쪽→다음, 오른쪽→이전)
  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < _swipeVelocityThreshold) return;

    final current = widget.navigationShell.currentIndex;
    final newIndex = velocity < 0
        ? (current + 1).clamp(TabIndex.home, TabIndex.memo)
        : (current - 1).clamp(TabIndex.home, TabIndex.memo);

    if (newIndex != current) {
      widget.navigationShell.goBranch(newIndex, initialLocation: false);
    }
  }

  /// 업적 다이얼로그를 큐에서 하나씩 순차 표시 (중첩 방지)
  Future<void> _showNextAchievementDialog(WidgetRef ref) async {
    if (ref.read(isShowingAchievementDialogProvider)) return;
    ref.read(isShowingAchievementDialogProvider.notifier).state = true;

    while (mounted) {
      final pending = ref.read(pendingAchievementProvider);
      if (pending.isEmpty) break;
      final achievement = pending.first;
      ref.read(pendingAchievementProvider.notifier).state =
          pending.sublist(1);
      await AchievementUnlockDialog.show(context, achievement);
    }

    ref.read(isShowingAchievementDialogProvider.notifier).state = false;
  }

  @override
  Widget build(BuildContext context) {
    final isNavLeft = ref.watch(navSideLeftProvider);
    final navVerticalPos = ref.watch(navVerticalPosProvider);
    final showTutorial = ref.watch(showTutorialProvider);

    // 새로 달성된 업적을 순차 표시한다
    ref.listen<List<Achievement>>(pendingAchievementProvider, (prev, next) {
      if (next.isNotEmpty && mounted) {
        _showNextAchievementDialog(ref);
      }
    });

    return Scaffold(
      backgroundColor: ColorTokens.transparent,
      body: Stack(
        children: [
          // 콘텐츠 영역 (네비 레일 뒤까지 확장)
          SafeArea(
            bottom: false,
            child: GestureDetector(
              onHorizontalDragEnd: _onHorizontalDragEnd,
              behavior: HitTestBehavior.translucent,
              child: AnimatedBuilder(
                animation: _tabAnimController,
                builder: (context, child) {
                  final p = Curves.easeInOutCubic
                      .transform(_tabAnimController.value);
                  return Transform.translate(
                    offset: Offset(
                      (1 - p) * _slideDirection * _slideDistance,
                      0,
                    ),
                    child: Opacity(
                      opacity: p.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: widget.navigationShell,
              ),
            ),
          ),

          // 플로팅 네비 레일
          FloatingNavRail(
            currentIndex: widget.navigationShell.currentIndex,
            isLeftSide: isNavLeft,
            verticalPos: navVerticalPos,
            onTabChange: (index) => widget.navigationShell.goBranch(
              index,
              initialLocation: index == widget.navigationShell.currentIndex,
            ),
          ),

          // 튜토리얼 오버레이
          if (showTutorial)
            Positioned.fill(
              child: TutorialOverlay(
                onComplete: () {
                  ref.read(showTutorialProvider.notifier).state = false;
                },
              ),
            ),
        ],
      ),
    );
  }
}
