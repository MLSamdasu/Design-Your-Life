// F5 위젯: GoalCard - 목표 카드
// 목표명, 설명, 진행률 바(ProgressCalculator 결과 기반), 완료 체크를 표시한다.
// 진행률 바와 하위 목표 리스트는 goal_progress_bar.dart로 분리한다
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../../../shared/models/goal.dart';
import '../../../../shared/models/sub_goal.dart';
import '../../../../shared/models/goal_task.dart';
import '../../providers/goal_provider.dart';
import '../../services/progress_calculator.dart';
import 'goal_progress_bar.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 년간 목표 카드
/// 확장/축소 가능하며 하위 月간 목표 리스트를 포함한다
class GoalCard extends ConsumerStatefulWidget {
  final Goal goal;

  const GoalCard({required this.goal, super.key});

  @override
  ConsumerState<GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends ConsumerState<GoalCard>
    with SingleTickerProviderStateMixin {
  /// 카드 확장 상태
  bool _isExpanded = false;

  /// 완료 체크 스케일 애니메이션 컨트롤러 (AN-04)
  late final AnimationController _checkController;
  late final Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: AppAnimation.medium,
    );
    _checkScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  Future<void> _toggleCompletion() async {
    // 완료 bounce 애니메이션 실행
    _checkController.forward().then((_) => _checkController.reverse());
    // 목표 완료 상태 토글 실패 시 SnackBar로 사용자에게 오류를 알린다
    try {
      await ref
          .read(goalNotifierProvider.notifier)
          .toggleGoalCompletion(widget.goal.id, !widget.goal.isCompleted);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('목표 상태 변경에 실패했습니다'),
            backgroundColor: ColorTokens.infoHintBg,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subGoalsAsync =
        ref.watch(subGoalsStreamProvider(widget.goal.id));
    final tasksAsync =
        ref.watch(tasksByGoalStreamProvider(widget.goal.id));

    final subGoals = subGoalsAsync.valueOrNull ?? <SubGoal>[];
    final tasks = tasksAsync.valueOrNull ?? <GoalTask>[];

    // 진행률 자동 계산
    final progress = ProgressCalculator.calcGoalProgress(
      widget.goal.id,
      subGoals,
      tasks,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.huge),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: GlassDecoration.defaultBlurSigma,
          sigmaY: GlassDecoration.defaultBlurSigma,
        ),
        child: Container(
          decoration: GlassDecoration.defaultCard(),
          child: Column(
            children: [
              // 카드 헤더
              _GoalCardHeader(
                goal: widget.goal,
                progress: progress,
                isExpanded: _isExpanded,
                checkScale: _checkScale,
                onExpandToggle: () =>
                    setState(() => _isExpanded = !_isExpanded),
                onCompletionToggle: _toggleCompletion,
              ),
              // 확장 시 하위 목표 목록
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: GoalSubGoalList(
                  goal: widget.goal,
                  subGoals: subGoals,
                  tasks: tasks,
                ),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: AppAnimation.standard,
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

/// 목표 카드 헤더 (제목, 설명, 체크박스, 진행률)
class _GoalCardHeader extends StatelessWidget {
  final Goal goal;
  final double progress;
  final bool isExpanded;
  final Animation<double> checkScale;
  final VoidCallback onExpandToggle;
  final VoidCallback onCompletionToggle;

  const _GoalCardHeader({
    required this.goal,
    required this.progress,
    required this.isExpanded,
    required this.checkScale,
    required this.onExpandToggle,
    required this.onCompletionToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onExpandToggle,
      borderRadius: BorderRadius.circular(AppRadius.huge),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 목표 제목 + 완료 체크박스
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 완료 체크박스 (AN-04 bounce)
                ScaleTransition(
                  scale: checkScale,
                  child: GestureDetector(
                    onTap: onCompletionToggle,
                    child: AnimatedContainer(
                      duration: AppAnimation.normal,
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: goal.isCompleted
                            ? context.themeColors.textPrimaryWithAlpha(0.3)
                            : ColorTokens.transparent,
                        border: Border.all(
                          color: goal.isCompleted
                              ? context.themeColors.textPrimaryWithAlpha(0.6)
                              : context.themeColors.textPrimaryWithAlpha(0.4),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: goal.isCompleted
                          ? Icon(Icons.check_rounded,
                              size: 12, color: context.themeColors.textPrimary)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                // 제목 + 설명
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: AppTypography.titleLg.copyWith(
                    color: context.themeColors.textPrimary,
                          decoration: goal.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor:
                              context.themeColors.textPrimaryWithAlpha(0.5),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (goal.description != null &&
                          goal.description!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          goal.description!,
                          style: AppTypography.bodySm.copyWith(
                            color: context.themeColors.textPrimaryWithAlpha(0.6),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // 진행률 + 확장 아이콘
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(progress * 100).round()}%',
                      style: AppTypography.captionLg.copyWith(
                        color: context.themeColors.textPrimaryWithAlpha(0.8),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: AppAnimation.normal,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: AppLayout.iconXl,
                        color: context.themeColors.textPrimaryWithAlpha(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // 진행률 바 (goal_progress_bar.dart로 분리)
            GoalProgressBar(progress: progress),
          ],
        ),
      ),
    );
  }
}
