// F5 위젯: GoalProgressBar - 목표 진행률 바
// SRP 분리: goal_card.dart에서 진행률 바와 하위 목표 리스트를 추출한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/models/goal.dart';
import '../../../../shared/models/sub_goal.dart';
import '../../../../shared/models/goal_task.dart';
import 'sub_goal_card.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 진행률 바 위젯 (AN-F5: width 0% -> 목표% 600ms 애니메이션)
class GoalProgressBar extends StatelessWidget {
  final double progress;

  const GoalProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 6,
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
                return Container(
                  width: constraints.maxWidth * value,
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
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Text(
          '하위 목표를 추가해보세요',
          style: AppTypography.captionMd.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.4),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        children: [
          // 구분선
          Container(
            height: 1,
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
