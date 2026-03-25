// F5 위젯: GoalCard - 목표 카드
// 목표명, 설명, 진행률 바(ProgressCalculator 결과 기반), 완료 체크를 표시한다.
// 헤더 → goal_card_header.dart, 팝업 메뉴 → goal_popup_menu.dart,
// 삭제 확인 → goal_delete_dialog.dart로 분리한다.
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../../../shared/models/goal.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../providers/goal_provider.dart';
import '../../services/progress_calculator.dart';
import 'goal_card_header.dart';
import 'goal_create_dialog.dart';
import 'goal_delete_dialog.dart';
import 'goal_progress_bar.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';

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

  /// 완료 상태 토글 + 체크포인트 연쇄 변경 (실패 시 SnackBar로 오류를 알린다)
  Future<void> _toggleCompletion() async {
    _checkController.forward(from: 0.0);
    final willComplete = !widget.goal.isCompleted;
    try {
      await ref
          .read(goalNotifierProvider.notifier)
          .toggleGoalCompletion(widget.goal.id, willComplete);
      if (mounted) {
        AppSnackBar.showInfo(
          context,
          willComplete ? '모든 체크포인트를 완료했습니다' : '체크포인트를 초기화했습니다',
        );
      }
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
      barrierColor:
          ColorTokens.barrierBase.withValues(alpha: AppAnimation.barrierAlpha),
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
          scale: Tween<double>(begin: AppAnimation.dialogScaleIn, end: 1.0)
              .animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }

  /// 목표 삭제 확인 후 삭제를 실행한다
  Future<void> _deleteGoal() async {
    final confirmed = await showGoalDeleteDialog(context);
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
    final subGoals = ref.watch(subGoalsStreamProvider(widget.goal.id));
    final tasks = ref.watch(tasksByGoalStreamProvider(widget.goal.id));
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
              GoalCardHeader(
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
