// 투두 탭: 주간 루틴 개별 아이템 위젯
// 체크박스 + 색상 바 + 이름 + 시간 (SRP 분리)
// CheckItem 위젯과 동일한 빨간색 취소선 + scale bounce 동작을 적용한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../shared/widgets/animated_strikethrough.dart';
import '../../../../shared/models/todo.dart';
import '../../../habit/providers/routine_log_provider.dart';

/// 루틴 아이템 (체크박스 + 색상 바 + 이름 + 시간)
class RoutineWeeklyItem extends ConsumerStatefulWidget {
  final Todo routineTodo;
  final DateTime date;

  const RoutineWeeklyItem({required this.routineTodo, required this.date, super.key});

  @override
  ConsumerState<RoutineWeeklyItem> createState() => _RoutineWeeklyItemState();
}

class _RoutineWeeklyItemState extends ConsumerState<RoutineWeeklyItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    // 스케일 바운스: CheckItem 패턴과 동일한 TweenSequence (500ms)
    _bounceController = AnimationController(
      duration: AppAnimation.slow,
      vsync: this,
    );
    _bounceAnimation = TweenSequence<double>([
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

  /// 체크박스 토글: bounce 애니메이션 후 상태 변경
  void _handleToggle(String routineId, DateTime date, bool isCompleted) {
    // Reduced Motion 확인: 접근성 설정 시 바운스 생략
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (!reduceMotion) {
      _bounceController.forward(from: 0.0);
    }
    ref.read(toggleRoutineLogProvider)(routineId, date, !isCompleted);
  }

  @override
  Widget build(BuildContext context) {
    // 원본 루틴 ID 추출 (todo.id에서 'routine_' 접두사 제거)
    final routineId = widget.routineTodo.id.startsWith('routine_')
        ? widget.routineTodo.id.substring(8)
        : widget.routineTodo.id;

    final isCompleted = ref.watch(
      routineCompletionProvider((routineId: routineId, date: widget.date)),
    );

    return GestureDetector(
      onTap: () => _handleToggle(routineId, widget.date, isCompleted),
      child: ScaleTransition(
        scale: _bounceAnimation,
        child: AnimatedContainer(
        duration: AppAnimation.medium,
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.themeColors.textPrimaryWithAlpha(
            isCompleted ? 0.06 : 0.10,
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Row(
          children: [
            // 완료 체크박스 (빨간색 스타일)
            AnimatedContainer(
              duration: AppAnimation.slow,
              curve: Curves.easeInOut,
              width: AppLayout.iconMd,
              height: AppLayout.iconMd,
              decoration: BoxDecoration(
                color: isCompleted
                    ? ColorTokens.error.withValues(alpha: 0.20)
                    : ColorTokens.transparent,
                borderRadius: BorderRadius.circular(AppRadius.xs),
                border: Border.all(
                  color: isCompleted
                      ? ColorTokens.error
                      : context.themeColors.textPrimaryWithAlpha(0.3),
                  width: AppLayout.borderMedium,
                ),
              ),
              child: AnimatedOpacity(
                opacity: isCompleted ? 1.0 : 0.0,
                duration: AppAnimation.slow,
                child: Icon(Icons.check,
                    size: AppLayout.iconSm,
                    color: ColorTokens.error),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            // 색상 인디케이터
            Container(
              width: 4,
              height: AppLayout.iconXl,
              decoration: BoxDecoration(
                color: ColorTokens.main,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // 루틴 이름 + 시간 (완료 시 opacity 0.50 + 취소선)
            Expanded(
              child: AnimatedOpacity(
                opacity: isCompleted ? 0.50 : 1.0,
                duration: AppAnimation.slow,
                curve: Curves.easeInOut,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 루틴 제목 (완료 시 빨간펜 취소선 애니메이션 적용)
                    AnimatedStrikethrough(
                      text: widget.routineTodo.title,
                      style: AppTypography.bodyMd.copyWith(
                        color: context.themeColors.textPrimary,
                      ),
                      isActive: isCompleted,
                    ),
                    if (widget.routineTodo.startTime != null)
                      Text(
                        '${widget.routineTodo.startTime!.hour.toString().padLeft(2, '0')}:${widget.routineTodo.startTime!.minute.toString().padLeft(2, '0')}'
                        '${widget.routineTodo.endTime != null ? ' ~ ${widget.routineTodo.endTime!.hour.toString().padLeft(2, '0')}:${widget.routineTodo.endTime!.minute.toString().padLeft(2, '0')}' : ''}',
                        style: AppTypography.bodySm.copyWith(
                          color: context.themeColors
                              .textPrimaryWithAlpha(0.6),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
