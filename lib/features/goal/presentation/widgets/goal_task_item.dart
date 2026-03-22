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
import '../../../../core/theme/layout_tokens.dart';
import '../../../../shared/widgets/animated_strikethrough.dart';
import '../../../../shared/widgets/app_snack_bar.dart';

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

  /// 토글 디바운스 플래그: 연속 탭으로 인한 중복 호출을 방지한다
  bool _isDebouncePending = false;

  @override
  void initState() {
    super.initState();
    // 스케일 바운스: CheckItem 패턴과 동일한 TweenSequence (500ms)
    _bounceController = AnimationController(
      vsync: this,
      duration: AppAnimation.slow,
    );
    _bounceScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.95), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.02), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.02, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    // 연속 탭 방지: 500ms 디바운스로 중복 토글을 차단한다
    if (_isDebouncePending) return;
    _isDebouncePending = true;
    Future.delayed(const Duration(milliseconds: 500), () {
      _isDebouncePending = false;
    });

    // 스케일 바운스 애니메이션 실행 (TweenSequence가 자동으로 1.0으로 복귀)
    _bounceController.forward(from: 0.0);
    // 실천 할일 완료 상태 토글 실패 시 SnackBar로 사용자에게 오류를 알린다
    try {
      await ref.read(goalNotifierProvider.notifier).toggleTaskCompletion(
            widget.goalId,
            widget.task.id,
            !widget.task.isCompleted,
          );
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, '할일 상태 변경에 실패했습니다');
      }
    }
  }

  /// 실천 할일 제목 수정 다이얼로그를 표시한다 (sub_goal_card 패턴)
  Future<void> _editTask() async {
    final controller = TextEditingController(text: widget.task.title);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.themeColors.dialogSurface,
        title: Text(
          '실천 과제 수정',
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
            hintText: '실천 과제 제목',
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
      try {
        final updated = widget.task.copyWith(title: result);
        await ref.read(goalNotifierProvider.notifier).updateTask(
              widget.goalId,
              widget.task.id,
              updated,
            );
      } catch (e) {
        if (mounted) {
          AppSnackBar.showError(context, '실천 과제 수정에 실패했습니다');
        }
      }
    }
  }

  /// 실천 할일을 삭제한다
  Future<void> _delete() async {
    try {
      await ref.read(goalNotifierProvider.notifier).deleteTask(
            widget.goalId,
            widget.task.id,
          );
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, '할일 삭제에 실패했습니다');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(widget.task.id),
      direction: DismissDirection.endToStart,
      // _delete()가 Future<void>를 반환하므로 async 콜백으로 감싸
      // Hive 삭제 완료를 대기한다. fire-and-forget 시 상태 불일치 위험이 있다
      onDismissed: (_) async => _delete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        decoration: BoxDecoration(
          color: ColorTokens.error.withValues(alpha: AppAnimation.dimmedAlpha),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: context.themeColors.textPrimary,
          size: AppLayout.iconMd,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: GestureDetector(
          onTap: _toggle,
          onLongPress: _editTask,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              // 체크박스 (AN-04 bounce)
              // 체크박스 (AN-04 bounce) — slow + easeInOut로 부드러운 전환
              ScaleTransition(
                scale: _bounceScale,
                child: AnimatedContainer(
                  duration: AppAnimation.slow,
                  curve: Curves.easeInOut,
                  width: AppLayout.iconLg,
                  height: AppLayout.iconLg,
                  decoration: BoxDecoration(
                    color: widget.task.isCompleted
                        ? context.themeColors.textPrimaryWithAlpha(0.3)
                        : ColorTokens.transparent,
                    border: Border.all(
                      color: widget.task.isCompleted
                          ? context.themeColors.textPrimaryWithAlpha(0.6)
                          : context.themeColors.textPrimaryWithAlpha(0.3),
                      width: AppLayout.borderMedium,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  // 체크 아이콘 페이드 인/아웃 (abrupt 전환 방지)
                  child: AnimatedOpacity(
                    opacity: widget.task.isCompleted ? 1.0 : 0.0,
                    duration: AppAnimation.slow,
                    curve: Curves.easeInOut,
                    child: Icon(
                      Icons.check_rounded,
                      size: AppLayout.iconXxs,
                      color: context.themeColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.mdLg),
              // 할일 제목 (완료 시 빨간펜 취소선 애니메이션 적용)
              Expanded(
                child: AnimatedStrikethrough(
                  text: widget.task.title,
                  style: AppTypography.bodyLg.copyWith(
                    color: widget.task.isCompleted
                        ? context.themeColors.textPrimaryWithAlpha(0.4)
                        : context.themeColors.textPrimaryWithAlpha(0.85),
                  ),
                  isActive: widget.task.isCompleted,
                  maxLines: 2,
                ),
              ),
              // 투두로 변환 버튼
              IconButton(
                icon: Icon(
                  Icons.add_task_rounded,
                  size: AppLayout.iconMd,
                  color: context.themeColors.textPrimaryWithAlpha(0.4),
                ),
                tooltip: '투두로 변환',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: AppLayout.iconLg,
                  minHeight: AppLayout.iconLg,
                ),
                onPressed: () async {
                  try {
                    await ref.read(exportGoalTaskAsTodoProvider)(widget.task);
                    if (context.mounted) {
                      AppSnackBar.showSuccess(context, '투두로 내보내기 완료');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      AppSnackBar.showError(context, '내보내기 실패: $e');
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
