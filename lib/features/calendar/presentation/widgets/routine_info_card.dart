// F2 위젯: RoutineInfoCard - 월간 뷰의 루틴 정보 카드
// 루틴 이름 + 시간 범위 + 완료 체크박스를 표시한다
// CheckItem 위젯과 동일한 빨간색 취소선 + scale bounce 동작을 적용한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../providers/event_models.dart';
import '../../../../shared/widgets/animated_strikethrough.dart';
import '../../../habit/providers/routine_log_provider.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 루틴 정보 카드 (월간 뷰의 선택된 날짜 목록에서 사용)
/// 루틴 이름 + 시간 범위 + 완료 체크박스를 표시한다
/// CheckItem 위젯과 동일한 빨간색 취소선 + scale bounce 동작을 적용한다
class RoutineInfoCard extends ConsumerStatefulWidget {
  final RoutineEntry routine;
  final DateTime selectedDate;

  const RoutineInfoCard({
    super.key,
    required this.routine,
    required this.selectedDate,
  });

  @override
  ConsumerState<RoutineInfoCard> createState() => _RoutineInfoCardState();
}

class _RoutineInfoCardState extends ConsumerState<RoutineInfoCard>
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
  void _handleToggle(bool isCompleted) {
    // Reduced Motion 확인: 접근성 설정 시 바운스 생략
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (!reduceMotion) {
      _bounceController.forward(from: 0.0);
    }
    ref.read(toggleRoutineLogProvider)(
      widget.routine.id,
      widget.selectedDate,
      !isCompleted,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = ColorTokens.eventColor(widget.routine.colorIndex);
    final startStr =
        '${widget.routine.startHour.toString().padLeft(2, '0')}:${widget.routine.startMinute.toString().padLeft(2, '0')}';
    final endStr =
        '${widget.routine.endHour.toString().padLeft(2, '0')}:${widget.routine.endMinute.toString().padLeft(2, '0')}';

    // 루틴 완료 상태를 Provider에서 읽는다
    final isCompleted = ref.watch(
      routineCompletionProvider(
          (routineId: widget.routine.id, date: widget.selectedDate)),
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border(
          left: BorderSide(color: color, width: AppSpacing.xxs),
        ),
      ),
      child: ScaleTransition(
        scale: _bounceAnimation,
        child: Row(
        children: [
          // 완료 체크박스 (빨간색 스타일 + scale bounce)
          GestureDetector(
            onTap: () => _handleToggle(isCompleted),
            child: AnimatedContainer(
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
              // 체크 아이콘: 조건부 렌더링 대신 AnimatedOpacity로 부드럽게 전환
              child: AnimatedOpacity(
                opacity: isCompleted ? 1.0 : 0.0,
                duration: AppAnimation.slow,
                curve: Curves.easeInOut,
                child: Icon(Icons.check,
                    size: AppLayout.iconSm,
                    color: ColorTokens.error),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Icon(
            Icons.repeat_rounded,
            color: context.themeColors.textPrimaryWithAlpha(0.60),
            size: AppLayout.iconMd,
          ),
          const SizedBox(width: AppSpacing.md),
          // 루틴 이름 (완료 시 opacity 0.50 + 빨간펜 취소선 애니메이션)
          Expanded(
            child: AnimatedOpacity(
              opacity: isCompleted ? 0.50 : 1.0,
              duration: AppAnimation.textFade,
              curve: Curves.easeInOut,
              child: AnimatedStrikethrough(
                text: widget.routine.name,
                style: AppTypography.bodyMd.copyWith(
                  color: context.themeColors.textPrimary,
                ),
                isActive: isCompleted,
              ),
            ),
          ),
          Text(
            '$startStr - $endStr',
            style: AppTypography.captionMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.55),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
