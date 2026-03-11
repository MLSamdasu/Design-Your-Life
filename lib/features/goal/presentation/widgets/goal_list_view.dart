// F5 위젯: GoalListView - 목표 리스트 뷰
// 년간/월간 탭 전환 + 목표 카드 목록을 표시한다.
// SRP 분리: 애니메이션/빈상태/탭 위젯 → goal_list_helpers.dart
// 계층 구조: 년간 목표 → 월간 하위목표 → 실천 할일
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/enums/goal_period.dart';
import '../../providers/goal_provider.dart';
import '../../services/progress_calculator.dart';
import 'goal_stats_header.dart';
import 'goal_card.dart';
import 'goal_create_dialog.dart';
import 'goal_list_helpers.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 목표 리스트 뷰
/// 상단: 년간/월간 탭 + 통계 바
/// 하단: 목표 카드 스크롤 목록
class GoalListView extends ConsumerWidget {
  const GoalListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(selectedGoalYearProvider);
    final period = ref.watch(selectedGoalPeriodProvider);
    final goalsAsync = ref.watch(
      goalsByYearAndPeriodStreamProvider((year: year, period: period)),
    );
    final statsAsync = ref.watch(goalStatsProvider);

    return Stack(
      children: [
        Column(
          children: [
            // 년간/월간 탭 + 연도 선택 — 수평 패딩 20px로 다른 화면과 통일
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: _YearPeriodHeader(year: year, period: period),
            ),
            const SizedBox(height: AppSpacing.xl),
            // 통계 헤더 (3개 스탯 카드) — 수평 패딩 20px
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: statsAsync.when(
                data: (stats) => GoalStatsHeader(stats: stats, isLoading: false),
                loading: () => GoalStatsHeader(
                  stats: const GoalStats(
                    achievementRate: 0,
                    avgProgress: 0,
                    totalGoalCount: 0,
                  ),
                  isLoading: true,
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            // 목표 목록
            Expanded(
              child: goalsAsync.when(
                data: (goals) {
                  if (goals.isEmpty) {
                    // 빈 상태 위젯 (goal_list_helpers.dart에서 분리)
                    return EmptyGoalState(period: period, year: year);
                  }
                  // 카드 좌우 20px, 하단 100px 여백으로 FAB 가림 방지
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: goals.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xl),
                    itemBuilder: (context, index) {
                      // AN-02: Staggered 카드 등장 (goal_list_helpers.dart)
                      return StaggeredCard(
                        index: index,
                        child: GoalCard(goal: goals[index]),
                      );
                    },
                  );
                },
                loading: () => Center(
                  child: CircularProgressIndicator(color: context.themeColors.textPrimary),
                ),
                error: (e, _) => Center(
                  child: Text(
                    '목표를 불러올 수 없어요',
                    style: AppTypography.bodyLg.copyWith(
                      color: context.themeColors.textPrimaryWithAlpha(0.6),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        // FAB: 새 목표 추가 — right 20px로 화면 가장자리에서 적절히 이격
        Positioned(
          right: AppSpacing.xxl,
          bottom: AppSpacing.xl,
          child: _AddGoalFab(period: period, year: year),
        ),
      ],
    );
  }
}

// ─── 년간/월간 탭 헤더 ────────────────────────────────────────────────────

/// 연도/기간 헤더 (년간/월간 탭 + 연도 선택)
/// PeriodTabRow, YearSelector는 goal_list_helpers.dart에 정의되어 있다
class _YearPeriodHeader extends ConsumerWidget {
  final int year;
  final GoalPeriod period;

  const _YearPeriodHeader({required this.year, required this.period});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // 년간/월간 탭 (goal_list_helpers.dart)
        PeriodTabRow(
          selected: period,
          onChanged: (p) =>
              ref.read(selectedGoalPeriodProvider.notifier).state = p,
        ),
        const Spacer(),
        // 연도 선택 버튼 (goal_list_helpers.dart)
        YearSelector(
          year: year,
          onChanged: (y) =>
              ref.read(selectedGoalYearProvider.notifier).state = y,
        ),
      ],
    );
  }
}

// ─── 목표 추가 FAB ─────────────────────────────────────────────────────────

/// 목표 추가 FAB (Floating Action Button)
class _AddGoalFab extends ConsumerWidget {
  final GoalPeriod period;
  final int year;

  const _AddGoalFab({required this.period, required this.year});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () => _showCreateDialog(context),
      backgroundColor: ColorTokens.main,
      foregroundColor: Colors.white,
      elevation: 4,
      child: const Icon(Icons.add_rounded),
    );
  }

  /// GoalCreateDialog를 Scale+Fade 애니메이션으로 열어 새 목표를 생성한다
  /// 생성 실패 시 SnackBar로 사용자에게 오류를 알린다
  Future<void> _showCreateDialog(BuildContext context) async {
    try {
      await showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Close',
        barrierColor: ColorTokens.barrierBase.withValues(alpha: 0.4),
        transitionDuration: AppAnimation.standard,
        pageBuilder: (_, __, ___) => GoalCreateDialog(
          defaultPeriod: period,
          defaultYear: year,
        ),
        transitionBuilder: (context, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        },
      );
    } catch (e) {
      // 다이얼로그 처리 중 예기치 않은 오류가 발생한 경우 사용자에게 알린다
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('목표 추가에 실패했습니다'),
            backgroundColor: ColorTokens.infoHintBg,
          ),
        );
      }
    }
  }
}
