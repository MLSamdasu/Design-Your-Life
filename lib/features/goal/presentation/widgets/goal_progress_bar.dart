// F5 위젯: GoalProgressBar - 목표 진행률 바 + 하위 목표 목록
// SRP 분리: goal_card.dart에서 진행률 바와 하위 목표 리스트를 추출한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/models/goal.dart';
import '../../../../shared/models/sub_goal.dart';
import '../../../../shared/models/goal_task.dart';
import 'checkpoint_list.dart';
import 'sub_goal_card.dart';

/// 진행률 바 위젯 (AN-F5: width 0% -> 목표% 600ms 애니메이션)
class GoalProgressBar extends StatelessWidget {
  final double progress;

  const GoalProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: AppLayout.progressBarHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.themeColors.textPrimaryWithAlpha(0.15),
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: AppAnimation.dramatic,
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                // 0%일 때는 채움 바를 숨기고, 0% 초과 시 최소 4px 너비를 보장한다
                final fillWidth = value > 0
                    ? (constraints.maxWidth * value).clamp(4.0, constraints.maxWidth)
                    : 0.0;
                return Container(
                  width: fillWidth,
                  decoration: BoxDecoration(
                    // 배경 테마에 따라 진행률 그라디언트 색상을 결정한다.
                    // 어두운/그라디언트 배경에서는 mainLight 계열로, 밝은 배경에서는 main 계열로 표시한다.
                    gradient: LinearGradient(
                      colors: [
                        context.themeColors.accentWithAlpha(0.8),
                        context.themeColors.accent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// 하위 목표 목록 (확장 시 표시)
class GoalSubGoalList extends ConsumerWidget {
  final Goal goal;
  final List<SubGoal> subGoals;
  final List<GoalTask> tasks;

  const GoalSubGoalList({
    super.key,
    required this.goal,
    required this.subGoals,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (subGoals.isEmpty) {
      // 빈 상태: 체크포인트 추가 힌트를 표시한다
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal, 0,
          AppSpacing.pageHorizontal, AppSpacing.pageVertical,
        ),
        child: AddCheckpointHint(goalId: goal.id),
      );
    }

    // tasks가 있는지 확인하여 만다라트 모드 vs 체크포인트 모드를 결정한다
    final hasTasks = subGoals.any(
      (sg) => tasks.any((t) => t.subGoalId == sg.id),
    );

    if (!hasTasks) {
      // 체크포인트 모드: 체크박스 리스트로 표시
      return CheckpointList(
        goal: goal,
        checkpoints: subGoals,
      );
    }

    // 만다라트 모드: 기존 SubGoalCard 리스트
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal, 0,
        AppSpacing.pageHorizontal, AppSpacing.pageVertical,
      ),
      child: Column(
        children: [
          // 구분선
          Container(
            height: AppLayout.dividerHeight,
            color: context.themeColors.textPrimaryWithAlpha(0.1),
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          ),
          ...subGoals.map((subGoal) {
            final subGoalTasks =
                tasks.where((t) => t.subGoalId == subGoal.id).toList();
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: SubGoalCard(
                subGoal: subGoal,
                goalId: goal.id,
                tasks: subGoalTasks,
              ),
            );
          }),
        ],
      ),
    );
  }
}
