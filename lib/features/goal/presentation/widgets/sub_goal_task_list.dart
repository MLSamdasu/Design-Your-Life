// F5 위젯: SubGoalTaskList - 하위 목표의 실천 할일 목록
// SubGoalCard 확장 시 표시되는 GoalTaskItem 목록이다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../shared/models/goal_task.dart';
import 'goal_task_item.dart';

/// 실천 할일 목록 위젯
/// 할일이 없으면 안내 메시지를 표시하고,
/// 있으면 [GoalTaskItem] 목록을 렌더링한다.
class SubGoalTaskList extends ConsumerWidget {
  final String goalId;
  final List<GoalTask> tasks;

  const SubGoalTaskList({
    required this.goalId,
    required this.tasks,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 할일이 없으면 힌트 메시지를 표시한다
    if (tasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md,
        ),
        child: Text(
          '실천 과제를 추가해보세요',
          style: AppTypography.captionMd.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.4),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md,
      ),
      child: Column(
        children: tasks.map((task) {
          return GoalTaskItem(
            task: task,
            goalId: goalId,
          );
        }).toList(),
      ),
    );
  }
}
