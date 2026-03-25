// F2 위젯: EventCardTodoCheckbox - 투두 이벤트 체크박스
// bounce 스케일 + 아이콘 전환(fade+scale) 애니메이션을 포함한다
import 'package:flutter/material.dart';

import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 투두 이벤트 체크박스 위젯
/// 체크 상태 전환 시 bounce 스케일과 아이콘 fade+scale 전환을 동시에 재생한다
class EventCardTodoCheckbox extends StatelessWidget {
  /// 완료 여부
  final bool isCompleted;

  /// bounce 스케일 애니메이션
  final Animation<double> bounceAnimation;

  /// 체크박스 탭 핸들러
  final VoidCallback onTap;

  const EventCardTodoCheckbox({
    super.key,
    required this.isCompleted,
    required this.bounceAnimation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.md),
      child: ScaleTransition(
        scale: bounceAnimation,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: AppLayout.containerMd,
            height: AppLayout.containerMd,
            child: Center(
              // AnimatedSwitcher: 아이콘 전환 시 fade+scale 효과
              child: AnimatedSwitcher(
                duration: AppAnimation.slower,
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  isCompleted
                      ? Icons.check_circle
                      : Icons.check_circle_outline,
                  key: ValueKey<bool>(isCompleted),
                  size: AppLayout.iconLg,
                  color: isCompleted
                      ? ColorTokens.error
                      : context.themeColors.textPrimaryWithAlpha(0.50),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
