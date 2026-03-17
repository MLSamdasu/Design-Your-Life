// F5: 목표·만다라트 화면 컨테이너
// "목표 리스트"/"만다라트" 서브탭 전환을 goalSubTabProvider로 관리한다.
// 각 탭은 GoalListView / MandalartView로 전환된다 (AN-F5: 슬라이드 전환).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/theme/theme_colors.dart';
import '../providers/goal_provider.dart';
import 'widgets/goal_list_view.dart';
import 'widgets/mandalart_view.dart';
import '../../../core/theme/animation_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../shared/widgets/global_action_bar.dart';
import '../../../shared/widgets/segmented_control.dart';

/// 목표 화면 메인 컨테이너
/// 상단 서브탭 전환기 + 콘텐츠 영역으로 구성된다
/// SafeArea + 일관된 수평 패딩(20px)으로 다른 화면과 레이아웃을 통일한다
class GoalScreen extends ConsumerWidget {
  const GoalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(goalSubTabProvider);

    // Scaffold를 제공하여 ScaffoldMessenger.of(context)가 정상 동작하도록 한다
    // GoalCreateDialog, MandalartWizard 등에서 SnackBar 표시 시 필요하다
    return Scaffold(
      backgroundColor: ColorTokens.transparent,
      body: SafeArea(
      top: false,
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 화면 제목 + 서브탭 전환기 (다른 화면과 동일한 상단 패딩 16px)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.pageHorizontal, AppSpacing.pageVertical, AppSpacing.pageHorizontal, 0),
            child: _GoalScreenHeader(activeTab: activeTab),
          ),
          const SizedBox(height: AppSpacing.xl),
          // 탭별 콘텐츠 (AN-F5: AnimatedSwitcher 슬라이드)
          Expanded(
            child: _TabContent(activeTab: activeTab),
          ),
        ],
      ),
      ),
    );
  }
}

// ─── 헤더 영역 ──────────────────────────────────────────────────────────────

/// 화면 제목 + 서브탭 전환기 헤더
/// 다른 화면(습관, 투두)과 동일한 headingSm 토큰을 사용하여 일관성을 유지한다
class _GoalScreenHeader extends ConsumerWidget {
  final GoalSubTab activeTab;

  const _GoalScreenHeader({required this.activeTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 화면 제목 + 업적/설정 아이콘 (headingSm: 습관/투두 화면과 동일 토큰)
        Row(
          children: [
            Expanded(
              child: Text(
                activeTab == GoalSubTab.goalList ? '목표 관리' : '만다라트',
                style: AppTypography.headingSm.copyWith(
                    color: context.themeColors.textPrimary,
                ),
              ),
            ),
            // 업적 + 설정 아이콘 버튼
            const GlobalActionBar(),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        // 서브탭 전환기 (공유 SegmentedControl 사용)
        SegmentedControl<GoalSubTab>(
          values: GoalSubTab.values,
          selected: activeTab,
          labelBuilder: (tab) => switch (tab) {
            GoalSubTab.goalList => '목표 리스트',
            GoalSubTab.mandalart => '만다라트',
          },
          onChanged: (tab) => ref.read(goalSubTabProvider.notifier).state = tab,
        ),
      ],
    );
  }
}

// ─── 탭 콘텐츠 ──────────────────────────────────────────────────────────────

/// 서브탭에 따라 콘텐츠를 전환하는 위젯
/// AN-F5: AnimatedSwitcher + 슬라이드 전환 애니메이션
class _TabContent extends StatefulWidget {
  final GoalSubTab activeTab;

  const _TabContent({required this.activeTab});

  @override
  State<_TabContent> createState() => _TabContentState();
}

class _TabContentState extends State<_TabContent> {
  /// 이전 탭을 추적하여 슬라이드 방향 결정
  late GoalSubTab _previousTab;

  @override
  void initState() {
    super.initState();
    _previousTab = widget.activeTab;
  }

  @override
  void didUpdateWidget(_TabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeTab != widget.activeTab) {
      _previousTab = oldWidget.activeTab;
    }
  }

  /// 탭 인덱스: goalList=0, mandalart=1
  int _tabIndex(GoalSubTab tab) {
    return tab == GoalSubTab.goalList ? 0 : 1;
  }

  @override
  Widget build(BuildContext context) {
    // 슬라이드 방향: goalList→mandalart는 왼쪽, 반대는 오른쪽
    final isForward =
        _tabIndex(widget.activeTab) > _tabIndex(_previousTab);

    return AnimatedSwitcher(
      duration: AppAnimation.medium,
      transitionBuilder: (child, animation) {
        // 전환 방향에 따라 슬라이드 오프셋 결정
        final slideBegin =
            isForward ? const Offset(AppAnimation.tabSlideOffset, 0) : const Offset(-AppAnimation.tabSlideOffset, 0);

        final slideAnim = Tween<Offset>(
          begin: slideBegin,
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slideAnim, child: child),
        );
      },
      child: KeyedSubtree(
        // AnimatedSwitcher가 탭 변경을 감지하도록 키 지정
        key: ValueKey(widget.activeTab),
        child: _buildTabContent(widget.activeTab),
      ),
    );
  }

  Widget _buildTabContent(GoalSubTab tab) {
    switch (tab) {
      case GoalSubTab.goalList:
        return const GoalListView();
      case GoalSubTab.mandalart:
        return const MandalartView();
    }
  }
}
