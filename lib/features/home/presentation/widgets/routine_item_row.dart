// F1: 루틴 아이템 행 위젯 (공유)
// 체크박스(빨간 스타일) + 색상 인디케이터 + 루틴명 + 시간 범위를 표시한다
// HabitRoutineSummaryCard, RoutineSummaryCard 등에서 재사용한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../shared/widgets/animated_strikethrough.dart';
import '../../../habit/providers/routine_log_provider.dart';
import '../../providers/home_provider.dart';

/// 루틴 아이템 행 위젯
/// 체크박스(빨간 스타일) + 색상 인디케이터 + 루틴명 + 시간 범위를 표시한다
/// 탭 시 routineCompletionProvider를 참조하여 완료 토글을 수행한다
/// 스케일 바운스 애니메이션으로 탭 피드백을 제공한다
class RoutineItemRow extends ConsumerStatefulWidget {
  final RoutinePreviewItem item;

  /// 완료 상태 조회/토글에 사용할 날짜 (보통 오늘)
  final DateTime date;

  const RoutineItemRow({
    super.key,
    required this.item,
    required this.date,
  });

  @override
  ConsumerState<RoutineItemRow> createState() => _RoutineItemRowState();
}

class _RoutineItemRowState extends ConsumerState<RoutineItemRow>
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

  @override
  Widget build(BuildContext context) {
    final color = ColorTokens.eventColor(widget.item.colorIndex);
    final isCompleted = ref.watch(
      routineCompletionProvider((routineId: widget.item.id, date: widget.date)),
    );

    return GestureDetector(
      onTap: () {
        // Reduced Motion 확인: 접근성 설정 시 바운스 생략
        final reduceMotion = MediaQuery.disableAnimationsOf(context);
        if (!reduceMotion) {
          _bounceController.forward(from: 0.0);
        }
        // 완료 상태를 반전하여 토글한다
        ref.read(toggleRoutineLogProvider)(
          widget.item.id,
          widget.date,
          !isCompleted,
        );
      },
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _bounceAnimation,
        child: AnimatedOpacity(
          opacity: isCompleted ? 0.50 : 1.0,
          duration: AppAnimation.textFade,
          curve: Curves.easeInOut,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.mdLg),
            child: Row(
              children: [
                // 완료 체크박스 (빨간색 스타일, CheckItem과 동일한 애니메이션 파라미터)
                _buildCheckbox(context, isCompleted),
                const SizedBox(width: AppSpacing.md),

                // 색상 인디케이터 바
                _buildColorBar(color),
                const SizedBox(width: AppSpacing.lg),

                // 루틴명 (완료 시 빨간펜 취소선 애니메이션 적용)
                Expanded(
                  child: AnimatedStrikethrough(
                    text: widget.item.name,
                    style: AppTypography.bodyMd.copyWith(
                      color: context.themeColors.textPrimary,
                    ),
                    isActive: isCompleted,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // 시간 범위 표시
                _buildTimeRange(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 완료 체크박스 (빨간색 스타일)
  Widget _buildCheckbox(BuildContext context, bool isCompleted) {
    return AnimatedContainer(
      duration: AppAnimation.slow,
      curve: Curves.easeInOut,
      width: AppLayout.checkboxMd,
      height: AppLayout.checkboxMd,
      decoration: BoxDecoration(
        color: isCompleted
            ? ColorTokens.error.withValues(alpha: 0.20)
            : ColorTokens.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isCompleted
              ? ColorTokens.error
              : context.themeColors.textPrimaryWithAlpha(0.50),
          width: AppLayout.borderThick,
        ),
      ),
      // 체크 아이콘: 조건부 렌더링 대신 AnimatedOpacity로 부드럽게 전환
      child: AnimatedOpacity(
        opacity: isCompleted ? 1.0 : 0.0,
        duration: AppAnimation.slow,
        curve: Curves.easeInOut,
        child: Icon(
          Icons.check,
          color: ColorTokens.error,
          size: AppSpacing.lg,
        ),
      ),
    );
  }

  /// 색상 인디케이터 바
  Widget _buildColorBar(Color color) {
    return Container(
      width: AppLayout.colorBarWidth,
      height: AppLayout.colorBarHeight,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
    );
  }

  /// 시간 범위 표시 (시작~종료) — 오버플로 가드 적용
  Widget _buildTimeRange(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.access_time_rounded,
          size: AppLayout.iconSm,
          color: context.themeColors.textPrimaryWithAlpha(0.55),
        ),
        const SizedBox(width: AppSpacing.xxs),
        Flexible(
          child: Text(
            '${widget.item.startTime} ~ ${widget.item.endTime}',
            style: AppTypography.captionMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.55),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
