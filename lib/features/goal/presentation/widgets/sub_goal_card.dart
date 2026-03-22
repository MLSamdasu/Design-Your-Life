// F5 위젯: SubGoalCard - 월간 하위 목표 카드
// 목표명, 진행률 바, 실천 할일 체크리스트를 표시한다.
// 수정/삭제 팝업 메뉴와 실천과제 추가 버튼을 포함한다.
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../../../shared/models/sub_goal.dart';
import '../../../../shared/models/goal_task.dart';
import '../../providers/goal_provider.dart';
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

  /// 하위 목표 제목 수정 다이얼로그를 표시한다
  Future<void> _editSubGoal() async {
    final controller = TextEditingController(text: widget.subGoal.title);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.themeColors.dialogSurface,
        title: Text(
          '하위 목표 수정',
          style: AppTypography.titleMd.copyWith(
            color: context.themeColors.textPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 200,
          style: AppTypography.bodyMd.copyWith(
            color: context.themeColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: '하위 목표 제목',
            hintStyle: AppTypography.bodyMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.4),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              '취소',
              style: AppTypography.bodyMd.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.7),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(
              '저장',
              style: AppTypography.bodyMd.copyWith(
                // 테마 인식: 다크 모드 dialogSurface 위에서도 고대비를 보장한다
                color: context.themeColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result != null && result.isNotEmpty && mounted) {
      final updated = widget.subGoal.copyWith(title: result);
      await ref.read(goalNotifierProvider.notifier).updateSubGoal(
            widget.goalId,
            widget.subGoal.id,
            updated,
          );
    }
  }

  /// 하위 목표 삭제 확인 다이얼로그를 표시한다
  Future<void> _deleteSubGoal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.themeColors.dialogSurface,
        title: Text(
          '하위 목표 삭제',
          style: AppTypography.titleMd.copyWith(
            color: context.themeColors.textPrimary,
          ),
        ),
        content: Text(
          '이 하위 목표와 관련된 실천 과제가 모두 삭제됩니다.\n정말 삭제하시겠습니까?',
          style: AppTypography.bodyMd.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              '취소',
              style: AppTypography.bodyMd.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.7),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              '삭제',
              style: AppTypography.bodyMd.copyWith(
                color: ColorTokens.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(goalNotifierProvider.notifier).deleteSubGoal(
            widget.goalId,
            widget.subGoal.id,
          );
    }
  }

  /// 실천 과제 추가 다이얼로그를 표시한다
  Future<void> _addTask() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.themeColors.dialogSurface,
        title: Text(
          '실천 과제 추가',
          style: AppTypography.titleMd.copyWith(
            color: context.themeColors.textPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 200,
          style: AppTypography.bodyMd.copyWith(
            color: context.themeColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: '실천 과제 제목을 입력해주세요',
            hintStyle: AppTypography.bodyMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.4),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              '취소',
              style: AppTypography.bodyMd.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.7),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(
              '추가',
              style: AppTypography.bodyMd.copyWith(
                // 테마 인식: 다크 모드 dialogSurface 위에서도 고대비를 보장한다
                color: context.themeColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
    controller.dispose();

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
                      // 진행률 + 확장 아이콘 + 메뉴를 축소 가능한 Row로 묶어 오버플로우 방지
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 진행률 텍스트
                          Text(
                            '$completedCount/${widget.tasks.length}',
                            style: AppTypography.captionMd.copyWith(
                              color: context.themeColors.textPrimaryWithAlpha(0.6),
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
                              color: context.themeColors.textPrimaryWithAlpha(0.5),
                            ),
                          ),
                          // 수정/삭제/실천과제 추가 메뉴
                          SizedBox(
                            width: AppLayout.iconXxl,
                            height: AppLayout.iconXxl,
                            child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          iconSize: AppLayout.iconSm,
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: context.themeColors.textPrimaryWithAlpha(0.5),
                            size: AppLayout.iconSm,
                          ),
                          color: context.themeColors.dialogSurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                          ),
                          // 각 액션이 Future<void>를 반환하므로 반드시 await 해야
                          // Hive 쓰기 완료 전에 위젯이 언마운트되는 크래시를 방지한다
                          onSelected: (value) async {
                            if (value == 'edit') await _editSubGoal();
                            if (value == 'delete') await _deleteSubGoal();
                            if (value == 'addTask') await _addTask();
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem<String>(
                              value: 'addTask',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.add_rounded,
                                    size: AppLayout.iconSm,
                                    color: context.themeColors.textPrimary,
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Text(
                                    '실천과제 추가',
                                    style: AppTypography.bodyMd.copyWith(
                                      color: context.themeColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_rounded,
                                    size: AppLayout.iconSm,
                                    color: context.themeColors.textPrimary,
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Text(
                                    '수정',
                                    style: AppTypography.bodyMd.copyWith(
                                      color: context.themeColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline_rounded,
                                    size: AppLayout.iconSm,
                                    color: ColorTokens.error,
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Text(
                                    '삭제',
                                    style: AppTypography.bodyMd.copyWith(
                                      color: ColorTokens.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
          height: AppLayout.progressBarHeightSm,
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
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
        child: Text(
          '실천 과제를 추가해보세요',
          style: AppTypography.captionMd.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.4),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
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
