// F4: 습관·루틴 화면 컨테이너
// "습관 트래커"/"내 루틴" 서브탭 전환을 habitSubTabProvider로 관리한다.
// AN-09: 서브탭 전환 시 CrossFade 300ms 애니메이션 적용
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/theme/theme_colors.dart';
import '../providers/habit_provider.dart';
import 'widgets/habit_tracker_view.dart';
import 'widgets/routine_list_view.dart';
import '../../../core/theme/animation_tokens.dart';
import '../../../core/theme/radius_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/layout_tokens.dart';

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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 화면 타이틀
          Text(
            '습관 & 루틴',
            style: AppTypography.headingSm.copyWith(color: context.themeColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.lg),
          // 서브탭 전환 (Glass Pill 스타일)
          _SubTabSwitcher(
            currentTab: currentTab,
            onTabChanged: (tab) {
              ref.read(habitSubTabProvider.notifier).state = tab;
            },
          ),
        ],
      ),
    );
  }
}

/// 서브탭 전환 위젯 (Glass Pill 스타일)
/// 습관 트래커 / 내 루틴 탭 전환
class _SubTabSwitcher extends StatelessWidget {
  final HabitSubTab currentTab;
  final ValueChanged<HabitSubTab> onTabChanged;

  const _SubTabSwitcher({
    required this.currentTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: context.themeColors.textPrimaryWithAlpha(0.12),
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(
              color: context.themeColors.textPrimaryWithAlpha(0.15),
            ),
          ),
          child: Row(
            children: HabitSubTab.values.map((tab) {
              final isActive = tab == currentTab;
              final label = tab == HabitSubTab.tracker ? '습관 트래커' : '내 루틴';
              final icon = tab == HabitSubTab.tracker
                  ? Icons.track_changes_rounded
                  : Icons.repeat_rounded;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTabChanged(tab),
                  child: AnimatedContainer(
                    duration: AppAnimation.standard,
                    curve: Curves.easeInOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.mdLg),
                    decoration: isActive
                        ? BoxDecoration(
                            color: context.themeColors.textPrimaryWithAlpha(0.25),
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                          )
                        : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: AppLayout.iconSm,
                          color: isActive
                              ? context.themeColors.textPrimary
                              : context.themeColors.textPrimaryWithAlpha(0.5),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          label,
                          style: AppTypography.bodyMd.copyWith(
                            color: isActive
                                ? context.themeColors.textPrimary
                                : context.themeColors.textPrimaryWithAlpha(0.55),
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
