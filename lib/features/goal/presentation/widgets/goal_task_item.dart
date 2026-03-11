// F5 위젯: GoalTaskItem - 실천 할일 체크리스트 아이템
// 체크박스 + 할일 제목 + 완료 애니메이션 (AN-04)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/models/goal_task.dart';
import '../../providers/goal_provider.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 실천 할일 체크리스트 아이템
/// 완료 시 AN-04 체크박스 bounce 애니메이션을 적용한다
class GoalTaskItem extends ConsumerStatefulWidget {
  final GoalTask task;
  final String goalId;

  const GoalTaskItem({
    required this.task,
    required this.goalId,
    super.key,
  });

  @override
  ConsumerState<GoalTaskItem> createState() => _GoalTaskItemState();
}

class _GoalTaskItemState extends ConsumerState<GoalTaskItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _bounceScale;

  @override
  void initState() {
    super.initState();
    // AN-04: 체크박스 bounce 애니메이션
    _bounceController = AnimationController(
      vsync: this,
      duration: AppAnimation.medium,
    );
    _bounceScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    // bounce 애니메이션 실행
    _bounceController
        .forward()
        .then((_) => _bounceController.reverse());
    await ref.read(goalNotifierProvider.notifier).toggleTaskCompletion(
          widget.goalId,
          widget.task.id,
          !widget.task.isCompleted,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: GestureDetector(
        onTap: _toggle,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            // 체크박스 (AN-04 bounce)
            ScaleTransition(
              scale: _bounceScale,
              child: AnimatedContainer(
                duration: AppAnimation.normal,
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: widget.task.isCompleted
                      ? context.themeColors.textPrimaryWithAlpha(0.3)
                      : ColorTokens.transparent,
                  border: Border.all(
                    color: widget.task.isCompleted
                        ? context.themeColors.textPrimaryWithAlpha(0.6)
                        : context.themeColors.textPrimaryWithAlpha(0.3),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: widget.task.isCompleted
                    ? Icon(
                        Icons.check_rounded,
                        size: 11,
                        color: context.themeColors.textPrimary,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.mdLg),
            // 할일 제목 — 긴 텍스트 오버플로우 방지
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: AppAnimation.normal,
                style: AppTypography.bodyLg.copyWith(
                  color: widget.task.isCompleted
                      ? context.themeColors.textPrimaryWithAlpha(0.4)
                      : context.themeColors.textPrimaryWithAlpha(0.85),
                  decoration: widget.task.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  decorationColor: context.themeColors.textPrimaryWithAlpha(0.4),
                ),
                child: Text(
                  widget.task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
