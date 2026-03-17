// F4: 습관·루틴 화면 컨테이너
// "습관 트래커"/"내 루틴" 서브탭 전환을 habitSubTabProvider로 관리한다.
// AN-09: 서브탭 전환 시 CrossFade 300ms 애니메이션 적용
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/theme/theme_colors.dart';
import '../providers/habit_provider.dart';
import 'widgets/habit_tracker_view.dart';
import 'widgets/routine_list_view.dart';
import '../../../core/theme/animation_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../shared/widgets/global_action_bar.dart';
import '../../../shared/widgets/segmented_control.dart';

/// 습관·루틴 메인 화면 (F4)
/// 하단 네비게이션 탭 4 (습관)
class HabitScreen extends ConsumerWidget {
  const HabitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subTab = ref.watch(habitSubTabProvider);

    return Scaffold(
      backgroundColor: ColorTokens.transparent,
      // 상단 SafeArea는 MainShell에서 처리하므로 top: false로 중복 적용을 방지한다
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상단 헤더: 화면 타이틀 + 서브탭 전환
            _HabitHeader(currentTab: subTab),
            const SizedBox(height: AppSpacing.xl),
            // 서브탭 콘텐츠 (AN-09: CrossFade 전환)
            Expanded(
              child: AnimatedSwitcher(
                duration: AppAnimation.medium,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: subTab == HabitSubTab.tracker
                    ? const HabitTrackerView(key: ValueKey('tracker'))
                    : const RoutineListView(key: ValueKey('routine')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 습관 화면 상단 헤더
/// 화면 타이틀 + Glass Pill 서브탭 전환
class _HabitHeader extends ConsumerWidget {
  final HabitSubTab currentTab;

  const _HabitHeader({required this.currentTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.pageHorizontal, AppSpacing.pageVertical, AppSpacing.pageHorizontal, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 화면 타이틀 + 업적/설정 아이콘
          Row(
            children: [
              Expanded(
                child: Text(
                  '습관 & 루틴',
                  style: AppTypography.headingSm.copyWith(color: context.themeColors.textPrimary),
                ),
              ),
              // 업적 + 설정 아이콘 버튼
              const GlobalActionBar(),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // 서브탭 전환 (공유 SegmentedControl 사용)
          SegmentedControl<HabitSubTab>(
            values: HabitSubTab.values,
            selected: currentTab,
            labelBuilder: (tab) => switch (tab) {
              HabitSubTab.tracker => '습관 트래커',
              HabitSubTab.routine => '내 루틴',
            },
            onChanged: (tab) => ref.read(habitSubTabProvider.notifier).state = tab,
          ),
        ],
      ),
    );
  }
}

