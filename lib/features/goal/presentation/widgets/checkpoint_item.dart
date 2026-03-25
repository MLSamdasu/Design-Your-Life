// F5 위젯: CheckpointItem - 개별 체크포인트 아이템 (체크박스 + 제목 + 삭제)
// SRP 분리: goal_progress_bar.dart에서 체크포인트 아이템 위젯을 추출한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../shared/models/sub_goal.dart';
import '../../../../shared/widgets/animated_strikethrough.dart';
import '../../providers/goal_provider.dart';

/// 개별 체크포인트 아이템 (체크박스 + 제목 + 삭제)
/// 낙관적 UI: 로컬 상태를 즉시 토글하고 비동기 저장 후 실패 시 되돌린다
class CheckpointItem extends ConsumerStatefulWidget {
  final SubGoal checkpoint;
  final String goalId;

  const CheckpointItem({
    super.key,
    required this.checkpoint,
    required this.goalId,
  });

  @override
  ConsumerState<CheckpointItem> createState() => _CheckpointItemState();
}

class _CheckpointItemState extends ConsumerState<CheckpointItem>
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
  void didUpdateWidget(covariant CheckpointItem oldWidget) {
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
