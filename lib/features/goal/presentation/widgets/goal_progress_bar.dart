// F5 위젯: GoalProgressBar - 목표 진행률 바
// SRP 분리: goal_card.dart에서 진행률 바와 하위 목표 리스트를 추출한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../shared/models/goal.dart';
import '../../../../shared/models/sub_goal.dart';
import '../../../../shared/models/goal_task.dart';
import '../../providers/goal_provider.dart';
import 'sub_goal_card.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../shared/widgets/animated_strikethrough.dart';

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
        child: _AddCheckpointHint(goalId: goal.id),
      );
    }

    // tasks가 있는지 확인하여 만다라트 모드 vs 체크포인트 모드를 결정한다
    final hasTasks = subGoals.any(
      (sg) => tasks.any((t) => t.subGoalId == sg.id),
    );

    if (!hasTasks) {
      // 체크포인트 모드: 체크박스 리스트로 표시
      return _CheckpointList(
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

// ─── 체크포인트 위젯 ──────────────────────────────────────────────────────

/// 체크포인트 리스트 (체크박스 + 제목)
/// 만다라트가 아닌 일반 목표에서 SubGoal을 체크포인트로 표시한다
class _CheckpointList extends ConsumerWidget {
  final Goal goal;
  final List<SubGoal> checkpoints;

  const _CheckpointList({required this.goal, required this.checkpoints});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // orderIndex로 정렬
    final sorted = List<SubGoal>.from(checkpoints)
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal, 0,
        AppSpacing.pageHorizontal, AppSpacing.pageVertical,
      ),
      child: Column(
        children: [
          Container(
            height: AppLayout.dividerHeight,
            color: context.themeColors.textPrimaryWithAlpha(0.1),
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          ),
          ...sorted.map((checkpoint) {
            return _CheckpointItem(
              checkpoint: checkpoint,
              goalId: goal.id,
            );
          }),
          // 체크포인트 추가 버튼
          _AddCheckpointButton(goalId: goal.id),
        ],
      ),
    );
  }
}

/// 개별 체크포인트 아이템 (체크박스 + 제목 + 삭제)
/// 낙관적 UI: 로컬 상태를 즉시 토글하고 비동기 저장 후 실패 시 되돌린다
class _CheckpointItem extends ConsumerStatefulWidget {
  final SubGoal checkpoint;
  final String goalId;

  const _CheckpointItem({required this.checkpoint, required this.goalId});

  @override
  ConsumerState<_CheckpointItem> createState() => _CheckpointItemState();
}

class _CheckpointItemState extends ConsumerState<_CheckpointItem>
    with SingleTickerProviderStateMixin {
  /// 낙관적 UI를 위한 로컬 완료 상태
  late bool _isCompleted;

  /// 체크 아이콘 애니메이션 컨트롤러
  late AnimationController _checkAnimController;
  late Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.checkpoint.isCompleted;
    // 체크 아이콘 스케일 애니메이션 (탄성 있는 바운스 효과)
    _checkAnimController = AnimationController(
      vsync: this,
      duration: AppAnimation.normal,
    );
    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkAnimController,
        curve: Curves.elasticOut,
      ),
    );
    // 이미 완료 상태면 애니메이션 완료 위치로 설정한다
    if (_isCompleted) {
      _checkAnimController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _CheckpointItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 외부에서 상태가 변경된 경우(다른 화면에서 변경 등) 로컬 상태를 동기화한다
    if (oldWidget.checkpoint.isCompleted != widget.checkpoint.isCompleted) {
      _isCompleted = widget.checkpoint.isCompleted;
      if (_isCompleted) {
        _checkAnimController.forward();
      } else {
        _checkAnimController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _checkAnimController.dispose();
    super.dispose();
  }

  /// 체크 상태를 토글한다 (낙관적 UI + 비동기 저장)
  Future<void> _toggle() async {
    final newValue = !_isCompleted;
    // 1. 로컬 상태를 즉시 변경하여 사용자에게 즉각적인 피드백을 준다
    setState(() => _isCompleted = newValue);
    if (newValue) {
      _checkAnimController.forward();
    } else {
      _checkAnimController.reverse();
    }

    // 2. 비동기로 Hive에 저장한다 (최소 버전 카운터만 갱신)
    final success = await ref
        .read(goalNotifierProvider.notifier)
        .toggleSubGoalCompletion(
          widget.goalId,
          widget.checkpoint.id,
          newValue,
        );

    // 3. 저장 실패 시 로컬 상태를 원래대로 되돌린다
    if (!success && mounted) {
      setState(() => _isCompleted = !newValue);
      if (!newValue) {
        _checkAnimController.forward();
      } else {
        _checkAnimController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          // 체크박스
          GestureDetector(
            onTap: _toggle,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: AppLayout.minTouchTarget,
              height: AppLayout.minTouchTarget,
              child: Center(
                child: AnimatedContainer(
                  duration: AppAnimation.normal,
                  curve: Curves.easeOutCubic,
                  width: AppLayout.checkboxMd,
                  height: AppLayout.checkboxMd,
                  decoration: BoxDecoration(
                    color: _isCompleted
                        ? context.themeColors.accentWithAlpha(0.3)
                        : ColorTokens.transparent,
                    border: Border.all(
                      color: _isCompleted
                          ? context.themeColors.accent
                          : context.themeColors.textPrimaryWithAlpha(0.3),
                      width: AppLayout.borderMedium,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: ScaleTransition(
                    scale: _checkScale,
                    child: Icon(
                      Icons.check_rounded,
                      size: AppLayout.iconXxxs,
                      color: context.themeColors.accent,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // 체크포인트 제목 (색상 + 빨간펜 취소선 애니메이션)
          Expanded(
            child: AnimatedStrikethrough(
              text: widget.checkpoint.title,
              style: AppTypography.bodyMd.copyWith(
                color: _isCompleted
                    ? context.themeColors.textPrimaryWithAlpha(0.5)
                    : context.themeColors.textPrimary,
              ),
              isActive: _isCompleted,
            ),
          ),
          // 삭제 버튼
          GestureDetector(
            onTap: () async {
              await ref
                  .read(goalNotifierProvider.notifier)
                  .deleteSubGoal(widget.goalId, widget.checkpoint.id);
            },
            child: SizedBox(
              width: AppLayout.minTouchTarget,
              height: AppLayout.minTouchTarget,
              child: Center(
                child: Icon(
                  Icons.close_rounded,
                  size: AppLayout.iconSm,
                  color: context.themeColors.textPrimaryWithAlpha(0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 체크포인트 추가 버튼
class _AddCheckpointButton extends ConsumerWidget {
  final String goalId;
  const _AddCheckpointButton({required this.goalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _addCheckpoint(context, ref),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              size: AppLayout.iconSm,
              color: context.themeColors.accentWithAlpha(0.6),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '체크포인트 추가',
              style: AppTypography.captionLg.copyWith(
                color: context.themeColors.accentWithAlpha(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 체크포인트 추가 다이얼로그를 표시한다
  Future<void> _addCheckpoint(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.themeColors.dialogSurface,
        title: Text(
          '체크포인트 추가',
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
            hintText: '체크포인트 제목을 입력해주세요',
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

    if (result != null && result.isNotEmpty) {
      // 기존 체크포인트 수를 조회하여 orderIndex를 결정한다
      final existing =
          ref.read(subGoalsStreamProvider(goalId));
      final subGoal = SubGoal(
        id: '',
        goalId: goalId,
        title: result,
        isCompleted: false,
        orderIndex: existing.length,
        createdAt: DateTime.now(),
      );
      await ref
          .read(goalNotifierProvider.notifier)
          .createSubGoal(goalId, subGoal);
    }
  }
}

/// 빈 상태 힌트 + 추가 버튼
class _AddCheckpointHint extends ConsumerWidget {
  final String goalId;
  const _AddCheckpointHint({required this.goalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Text(
          '체크포인트를 추가하면 진행률이 자동 계산됩니다',
          style: AppTypography.captionMd.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.4),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _AddCheckpointButton(goalId: goalId),
      ],
    );
  }
}
