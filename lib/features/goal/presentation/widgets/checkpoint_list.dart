// F5 위젯: CheckpointList - 체크포인트 리스트 + 추가 버튼 + 빈 상태 힌트
// SRP 분리: goal_progress_bar.dart에서 체크포인트 관련 위젯을 추출한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../shared/models/goal.dart';
import '../../../../shared/models/sub_goal.dart';
import '../../providers/goal_provider.dart';
import 'add_checkpoint_dialog.dart';
import 'checkpoint_item.dart';

/// 체크포인트 리스트 (체크박스 + 제목)
/// 만다라트가 아닌 일반 목표에서 SubGoal을 체크포인트로 표시한다
class CheckpointList extends ConsumerWidget {
  final Goal goal;
  final List<SubGoal> checkpoints;

  const CheckpointList({
    super.key,
    required this.goal,
    required this.checkpoints,
  });

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
            return CheckpointItem(
              checkpoint: checkpoint,
              goalId: goal.id,
            );
          }),
          // 체크포인트 추가 버튼
          AddCheckpointButton(goalId: goal.id),
        ],
      ),
    );
  }
}

/// 체크포인트 추가 버튼
class AddCheckpointButton extends ConsumerWidget {
  final String goalId;
  const AddCheckpointButton({super.key, required this.goalId});

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
    // StatefulBuilder로 controller 수명주기를 다이얼로그 내부에서 관리한다
    // 다이얼로그가 닫히면 StatefulBuilder.dispose에서 controller를 해제하므로
    // 외부에서 수동 dispose 시 발생하는 "used after disposed" 오류를 방지한다
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AddCheckpointDialog(parentContext: context);
      },
    );

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
class AddCheckpointHint extends ConsumerWidget {
  final String goalId;
  const AddCheckpointHint({super.key, required this.goalId});

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
        AddCheckpointButton(goalId: goalId),
      ],
    );
  }
}
