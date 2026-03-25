// F3 위젯: TodoAnimatedCheckbox - 체크박스 bounce 래퍼
// AN-04: 체크 시 scale bounce 효과를 적용한 터치 타겟 래퍼
import 'package:flutter/material.dart';

import '../../../../core/theme/layout_tokens.dart';
import 'todo_checkbox_widget.dart';

/// 체크박스에 bounce 스케일 애니메이션과 터치 타겟을 적용하는 래퍼 위젯
/// WCAG 2.1 최소 터치 타겟 44x44px 적용
class TodoAnimatedCheckbox extends StatelessWidget {
  final bool isChecked;
  final AnimationController checkController;
  final VoidCallback onTap;

  const TodoAnimatedCheckbox({
    required this.isChecked,
    required this.checkController,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: AppLayout.minTouchTarget,
        height: AppLayout.minTouchTarget,
        child: Center(
          child: AnimatedBuilder(
            animation: checkController,
            builder: (context, _) {
              // 체크박스 탭 시 미세한 스케일 bounce 효과
              final scale = 1.0 +
                  (checkController.value > 0.5
                      ? (1 - checkController.value) *
                          EffectLayout.checkboxBounceScale
                      : -checkController.value *
                          EffectLayout.checkboxShrinkScale);
              return Transform.scale(
                scale: scale,
                child: TodoCheckboxWidget(isChecked: isChecked),
              );
            },
          ),
        ),
      ),
    );
  }
}
