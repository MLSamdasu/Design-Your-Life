// F5 위젯: GoalListView - 목표 리스트 뷰
// 년간/월간 탭 전환 + 목표 카드 목록을 표시한다.
// SRP 분리: 애니메이션/빈상태/탭 위젯 → goal_list_helpers.dart
// 계층 구조: 년간 목표 → 월간 하위목표 → 실천 할일
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../shared/enums/goal_period.dart';
import '../../providers/goal_provider.dart';
import 'goal_stats_header.dart';
import 'goal_card.dart';
import 'goal_create_dialog.dart';
import 'goal_list_helpers.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/bottom_scroll_spacer.dart';

/// 목표 리스트 뷰
/// 상단: 년간/월간 탭 + 통계 바
/// 하단: 목표 카드 스크롤 목록
class GoalListView extends ConsumerWidget {
  const GoalListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(selectedGoalYearProvider);
    final period = ref.watch(selectedGoalPeriodProvider);
    // 동기 Provider이므로 직접 사용한다
    final goals = ref.watch(
      goalsByYearAndPeriodStreamProvider((year: year, period: period)),
    );
    final stats = ref.watch(goalStatsProvider);

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
              // goalStatsProvider는 동기 Provider이므로 직접 사용한다
              child: GoalStatsHeader(
                stats: stats,
                isLoading: false,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            // 목표 목록
            Expanded(
              // goalsByYearAndPeriodStreamProvider는 동기 Provider이므로 직접 사용한다
              child: () {
                if (goals.isEmpty) {
                  // 빈 상태 위젯 (goal_list_helpers.dart에서 분리)
                  return EmptyGoalState(period: period, year: year);
                }
                // 하단 여백: 마지막 콘텐츠를 화면 중앙까지 스크롤 가능하도록 화면 절반 높이
                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(AppSpacing.pageHorizontal, 0, AppSpacing.pageHorizontal, BottomScrollSpacer.height(context)),
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
              }(),
            ),
          ],
        ),
        // FAB: 새 목표 추가 — 하단 여백 기준 배치
        Positioned(
          right: AppSpacing.xxl,
          bottom: AppLayout.bottomNavArea + AppSpacing.xl,
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
      foregroundColor: ColorTokens.white,
      elevation: AppLayout.fabElevation,
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
        barrierColor: ColorTokens.barrierBase.withValues(alpha: AppAnimation.barrierAlpha),
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
            scale: Tween<double>(begin: AppAnimation.dialogScaleIn, end: 1.0).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        },
      );
    } catch (e) {
      // 다이얼로그 처리 중 예기치 않은 오류가 발생한 경우 사용자에게 알린다
      if (context.mounted) {
        AppSnackBar.showError(context, '목표 추가에 실패했습니다');
      }
    }
  }
}
