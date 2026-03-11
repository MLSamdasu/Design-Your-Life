// F5 위젯: SubGoalCard - 월간 하위 목표 카드
// 목표명, 진행률 바, 실천 할일 체크리스트를 표시한다.
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../../../shared/models/sub_goal.dart';
import '../../../../shared/models/goal_task.dart';
import '../../services/progress_calculator.dart';
import 'goal_task_item.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 월간 하위 목표 카드
/// 확장/축소 가능하며 실천 할일 체크리스트를 포함한다
class SubGoalCard extends ConsumerStatefulWidget {
  final SubGoal subGoal;
  final String goalId;
  final List<GoalTask> tasks;

  const SubGoalCard({
    required this.subGoal,
    required this.goalId,
    required this.tasks,
    super.key,
  });

  @override
  ConsumerState<SubGoalCard> createState() => _SubGoalCardState();
}

class _SubGoalCardState extends ConsumerState<SubGoalCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // 진행률: 완료된 tasks / 전체 tasks
    final progress = ProgressCalculator.calcSubGoalProgress(
      widget.subGoal.id,
      widget.tasks,
    );
    final completedCount = widget.tasks.where((t) => t.isCompleted).length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: GlassDecoration.subtleBlurSigma,
          sigmaY: GlassDecoration.subtleBlurSigma,
        ),
        child: Container(
          decoration: GlassDecoration.subtleCard(radius: 16),
          child: Column(
            children: [
              // 헤더
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 하위 목표 제목 — 긴 텍스트 말줄임 처리
                            Text(
                              widget.subGoal.title,
                              style: AppTypography.bodyMd.copyWith(
                    color: context.themeColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            // 미니 진행률 바
                            _MiniProgressBar(progress: progress),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      // 진행률 텍스트
                      Text(
                        '$completedCount/${widget.tasks.length}',
                        style: AppTypography.captionMd.copyWith(
                          color: context.themeColors.textPrimaryWithAlpha(0.6),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: AppAnimation.normal,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: AppLayout.iconMd,
                          color: context.themeColors.textPrimaryWithAlpha(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 실천 할일 목록 (확장 시)
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _TaskList(
                  goalId: widget.goalId,
                  tasks: widget.tasks,
                ),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: AppAnimation.normal,
                firstCurve: Curves.easeInCubic,
                secondCurve: Curves.easeOutCubic,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 미니 진행률 바 (SubGoalCard 내부용)
class _MiniProgressBar extends StatelessWidget {
  final double progress;

  const _MiniProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 4,
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.themeColors.textPrimaryWithAlpha(0.1),
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: AppAnimation.emphasis,
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Container(
                  width: constraints.maxWidth * value,
                  // 진행률 바: 배경 테마에 맞는 악센트 색상으로 표시한다
                  decoration: BoxDecoration(
                    color: context.themeColors.accent,
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

/// 실천 할일 목록
class _TaskList extends ConsumerWidget {
  final String goalId;
  final List<GoalTask> tasks;

  const _TaskList({required this.goalId, required this.tasks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Text(
          '실천 과제를 추가해보세요',
          style: AppTypography.captionMd.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.4),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
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
