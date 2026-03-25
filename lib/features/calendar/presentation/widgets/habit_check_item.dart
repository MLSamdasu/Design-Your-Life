// F2 위젯: HabitCheckItem - 월간 뷰의 습관 체크 아이템
// 스케일 바운스 애니메이션으로 탭 피드백을 제공한다
// 완료 시 빨간펜 취소선 + 투명도 애니메이션 적용
import 'package:flutter/material.dart';

import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/models/habit.dart';
import '../../../../shared/widgets/animated_strikethrough.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 습관 체크 아이템 위젯 (월간 뷰의 선택된 날짜 목록에서 사용)
/// 스케일 바운스 애니메이션으로 탭 피드백을 제공한다
class HabitCheckItem extends StatefulWidget {
  final Habit habit;
  final bool isCompleted;
  final VoidCallback onToggle;

  const HabitCheckItem({
    super.key,
    required this.habit,
    required this.isCompleted,
    required this.onToggle,
  });

  @override
  State<HabitCheckItem> createState() => _HabitCheckItemState();
}

class _HabitCheckItemState extends State<HabitCheckItem>
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
    return GestureDetector(
      onTap: () {
        // Reduced Motion 확인: 접근성 설정 시 바운스 생략
        final reduceMotion = MediaQuery.disableAnimationsOf(context);
        if (!reduceMotion) {
          _bounceController.forward(from: 0.0);
        }
        widget.onToggle();
      },
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _bounceAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
          child: Row(
            children: [
              // 체크박스 (CheckItem과 동일한 애니메이션 파라미터)
              AnimatedContainer(
                duration: AppAnimation.slow,
                curve: Curves.easeInOut,
                width: AppLayout.iconMd,
                height: AppLayout.iconMd,
                decoration: BoxDecoration(
                  color: widget.isCompleted
                      ? context.themeColors.accent
                      : ColorTokens.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(
                    color: widget.isCompleted
                        ? context.themeColors.accent
                        : context.themeColors.textPrimaryWithAlpha(0.3),
                    width: AppLayout.borderMedium,
                  ),
                ),
                // 체크 아이콘: 조건부 렌더링 대신 AnimatedOpacity로 부드럽게 전환
                child: AnimatedOpacity(
                  opacity: widget.isCompleted ? 1.0 : 0.0,
                  duration: AppAnimation.slow,
                  curve: Curves.easeInOut,
                  child: Icon(
                    Icons.check,
                    size: AppLayout.iconSm,
                    color: context.themeColors.dialogSurface,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // 습관 아이콘
              if (widget.habit.icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: Text(widget.habit.icon!, style: AppTypography.bodyMd),
                ),
              // 습관 이름 (완료 시 빨간펜 취소선 애니메이션 + 행 전체 투명도 적용)
              Expanded(
                child: AnimatedOpacity(
                  opacity: widget.isCompleted ? 0.50 : 1.0,
                  duration: AppAnimation.textFade,
                  curve: Curves.easeInOut,
                  child: AnimatedStrikethrough(
                    text: widget.habit.name,
                    style: AppTypography.bodySm.copyWith(
                      color: context.themeColors.textPrimary,
                    ),
                    isActive: widget.isCompleted,
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
