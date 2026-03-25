// F5 위젯: SubGoalCard - 월간 하위 목표 카드
// 목표명, 진행률 바, 실천 할일 체크리스트를 표시한다.
// 수정/삭제 팝업 메뉴와 실천과제 추가 버튼을 포함한다.
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../../../shared/models/sub_goal.dart';
import '../../../../shared/models/goal_task.dart';
import '../../providers/goal_provider.dart';
import '../../services/progress_calculator.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import 'sub_goal_card_dialogs.dart';
import 'sub_goal_mini_progress_bar.dart';
import 'sub_goal_task_list.dart';
import 'sub_goal_popup_menu.dart';

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

  /// 하위 목표 제목 수정 다이얼로그를 호출하고 결과를 저장한다
  Future<void> _editSubGoal() async {
    final result = await showEditSubGoalDialog(
      context,
      widget.subGoal.title,
    );

    if (result != null && result.isNotEmpty && mounted) {
      final updated = widget.subGoal.copyWith(title: result);
      await ref.read(goalNotifierProvider.notifier).updateSubGoal(
            widget.goalId,
            widget.subGoal.id,
            updated,
          );
    }
  }

  /// 하위 목표 삭제 확인 후 삭제를 수행한다
  Future<void> _deleteSubGoal() async {
    final confirmed = await showDeleteSubGoalDialog(context);

    if (confirmed && mounted) {
      await ref.read(goalNotifierProvider.notifier).deleteSubGoal(
            widget.goalId,
            widget.subGoal.id,
          );
    }
  }

  /// 실천 과제 추가 다이얼로그를 호출하고 결과를 저장한다
  Future<void> _addTask() async {
    final result = await showAddTaskDialog(context);

    if (result != null && result.isNotEmpty && mounted) {
      final task = GoalTask(
        id: '',
        subGoalId: widget.subGoal.id,
        title: result,
        orderIndex: widget.tasks.length,
        createdAt: DateTime.now(),
      );
      await ref.read(goalNotifierProvider.notifier).createTask(
            widget.goalId,
            task,
          );
    }
  }

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
          // 서브 카드와 동일한 xxl(16px) 반지름을 사용한다
          decoration: GlassDecoration.subtleCard(radius: AppRadius.xxl),
          child: Column(
            children: [
              // 헤더 — 탭하면 확장/축소를 토글한다
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      // 제목 + 미니 진행률 바
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.subGoal.title,
                              style: AppTypography.bodyMd.copyWith(
                                color: context.themeColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            SubGoalMiniProgressBar(progress: progress),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      // 진행률 텍스트 + 확장 아이콘 + 메뉴
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$completedCount/${widget.tasks.length}',
                            style: AppTypography.captionMd.copyWith(
                              color: context.themeColors
                                  .textPrimaryWithAlpha(0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          AnimatedRotation(
                            turns: _isExpanded ? 0.5 : 0,
                            duration: AppAnimation.normal,
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: AppLayout.iconMd,
                              color: context.themeColors
                                  .textPrimaryWithAlpha(0.5),
                            ),
                          ),
                          SubGoalPopupMenu(
                            onEdit: _editSubGoal,
                            onDelete: _deleteSubGoal,
                            onAddTask: _addTask,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // 실천 할일 목록 (확장 시)
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: SubGoalTaskList(
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
