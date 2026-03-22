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
import '../../../../core/providers/global_providers.dart';
import '../../../../shared/models/goal.dart';
import '../../../../shared/providers/tag_provider.dart';
import '../../providers/goal_provider.dart';
import '../../services/progress_calculator.dart';
import 'goal_progress_bar.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import 'goal_create_dialog.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../shared/widgets/animated_strikethrough.dart';

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
    // 스케일 바운스: CheckItem 패턴과 동일한 TweenSequence (500ms)
    _checkController = AnimationController(
      vsync: this,
      duration: AppAnimation.slow,
    );
    _checkScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.95), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.02), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.02, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  Future<void> _toggleCompletion() async {
    // 스케일 바운스 애니메이션 실행 (TweenSequence가 자동으로 1.0으로 복귀)
    _checkController.forward(from: 0.0);
    // 목표 완료 상태 토글 실패 시 SnackBar로 사용자에게 오류를 알린다
    try {
      await ref
          .read(goalNotifierProvider.notifier)
          .toggleGoalCompletion(widget.goal.id, !widget.goal.isCompleted);
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, '목표 상태 변경에 실패했습니다');
      }
    }
  }

  /// 목표 수정 다이얼로그를 열어 기존 목표를 편집한다
  Future<void> _editGoal() async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: ColorTokens.barrierBase.withValues(alpha: AppAnimation.barrierAlpha),
      transitionDuration: AppAnimation.standard,
      pageBuilder: (_, __, ___) => GoalCreateDialog(
        defaultPeriod: widget.goal.period,
        defaultYear: widget.goal.year,
        existingGoal: widget.goal,
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
  }

  /// 목표 삭제 확인 다이얼로그를 표시한다
  Future<void> _deleteGoal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.themeColors.dialogSurface,
        title: Text(
          '목표 삭제',
          style: AppTypography.titleMd.copyWith(
            color: context.themeColors.textPrimary,
          ),
        ),
        content: Text(
          '이 목표와 관련된 하위 목표, 실천 과제가 모두 삭제됩니다.\n정말 삭제하시겠습니까?',
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
      try {
        await ref
            .read(goalNotifierProvider.notifier)
            .deleteGoal(widget.goal.id);
      } catch (e) {
        if (mounted) {
          AppSnackBar.showError(context, '목표 삭제에 실패했습니다');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 동기 Provider이므로 직접 사용한다
    final subGoals =
        ref.watch(subGoalsStreamProvider(widget.goal.id));
    final tasks =
        ref.watch(tasksByGoalStreamProvider(widget.goal.id));

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
                onEdit: _editGoal,
                onDelete: _deleteGoal,
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

/// 목표 카드 헤더 (제목, 설명, 태그 칩, 체크박스, 진행률, 수정/삭제 메뉴)
class _GoalCardHeader extends ConsumerWidget {
  final Goal goal;
  final double progress;
  final bool isExpanded;
  final Animation<double> checkScale;
  final VoidCallback onExpandToggle;
  final VoidCallback onCompletionToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GoalCardHeader({
    required this.goal,
    required this.progress,
    required this.isExpanded,
    required this.checkScale,
    required this.onExpandToggle,
    required this.onCompletionToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);

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
                // WCAG 2.1 터치 타겟 44px 이상 확보를 위해 SizedBox로 감싼다
                ScaleTransition(
                  scale: checkScale,
                  child: GestureDetector(
                    onTap: onCompletionToggle,
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: AppLayout.minTouchTarget,
                      height: AppLayout.minTouchTarget,
                      child: Center(
                        // slow + easeInOut로 부드러운 체크박스 전환
                        child: AnimatedContainer(
                          duration: AppAnimation.slow,
                          curve: Curves.easeInOut,
                          width: AppLayout.checkboxMd,
                          height: AppLayout.checkboxMd,
                          decoration: BoxDecoration(
                            color: goal.isCompleted
                                ? context.themeColors.textPrimaryWithAlpha(0.3)
                                : ColorTokens.transparent,
                            border: Border.all(
                              color: goal.isCompleted
                                  ? context.themeColors.textPrimaryWithAlpha(0.6)
                                  : context.themeColors.textPrimaryWithAlpha(0.4),
                              width: AppLayout.borderThick,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          // 체크 아이콘 페이드 인/아웃 (abrupt 전환 방지)
                          child: AnimatedOpacity(
                            opacity: goal.isCompleted ? 1.0 : 0.0,
                            duration: AppAnimation.slow,
                            curve: Curves.easeInOut,
                            child: Icon(Icons.check_rounded,
                                size: AppLayout.iconXxxs, color: context.themeColors.textPrimary),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                // 제목 + 설명 + 태그
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 목표 제목 (완료 시 빨간펜 취소선 애니메이션 적용)
                      AnimatedStrikethrough(
                        text: goal.title,
                        style: AppTypography.titleLg.copyWith(
                          color: goal.isCompleted
                              ? context.themeColors.textPrimaryWithAlpha(0.5)
                              : context.themeColors.textPrimary,
                        ),
                        isActive: goal.isCompleted,
                        maxLines: 2,
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
                      // 태그 칩 표시 (tagIds가 비어있지 않을 때만)
                      if (goal.tagIds.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: goal.tagIds.map((tagId) {
                            final tag = ref.watch(tagByIdProvider(tagId));
                            if (tag == null) return const SizedBox.shrink();
                            final tagColor = ColorTokens.eventColor(
                              tag.colorIndex,
                              isDark: isDark,
                            );
                            // WCAG 대비: 태그 배경(tagColor alpha 0.2) 위에서
                            // 기본 텍스트 색상을 사용하여 충분한 명도 대비를 확보한다
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xxs,
                              ),
                              decoration: BoxDecoration(
                                color: tagColor.withValues(alpha: 0.2),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.huge),
                                border: Border.all(
                                  color: tagColor.withValues(alpha: 0.4),
                                  width: AppLayout.borderThin,
                                ),
                              ),
                              child: Text(
                                tag.name,
                                style: AppTypography.captionSm.copyWith(
                                  color: context.themeColors.textPrimaryWithAlpha(0.85),
                                  fontWeight: AppTypography.weightMedium,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // 진행률 + 확장 아이콘 + 메뉴를 축소 가능한 Row로 묶어 오버플로우 방지
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${(progress * 100).round()}%',
                          style: AppTypography.captionLg.copyWith(
                            color: context.themeColors.textPrimaryWithAlpha(0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                    // 수정/삭제 메뉴 버튼
                    _GoalPopupMenu(
                      onEdit: onEdit,
                      onDelete: onDelete,
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

/// 목표 카드 팝업 메뉴 (수정/삭제)
class _GoalPopupMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GoalPopupMenu({
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppLayout.iconHuge,
      height: AppLayout.iconHuge,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        iconSize: AppLayout.iconMd,
        icon: Icon(
          Icons.more_vert_rounded,
          color: context.themeColors.textPrimaryWithAlpha(0.5),
          size: AppLayout.iconMd,
        ),
        color: context.themeColors.dialogSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        onSelected: (value) {
          if (value == 'edit') onEdit();
          if (value == 'delete') onDelete();
        },
        itemBuilder: (context) => [
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
    );
  }
}
