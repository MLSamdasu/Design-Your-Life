// 태그 생성용 8색 색상 도트 피커 위젯
// TagCreateInlineForm 내부에서 태그 색상을 선택할 때 사용한다.
// ColorTokens.eventColor 팔레트를 재사용하여 일관된 색상 체계를 유지한다.
import 'package:flutter/material.dart';

import '../../core/theme/animation_tokens.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/layout_tokens.dart';
import '../../core/theme/spacing_tokens.dart';
import '../../core/theme/theme_colors.dart';

/// 태그 생성용 8색 색상 도트 피커
/// settings/TagColorPicker와 구분하기 위해 별도 이름을 사용한다.
class TagColorDotPicker extends StatelessWidget {
  /// 현재 선택된 색상 인덱스
  final int selectedIndex;

  /// 색상 선택 콜백
  final ValueChanged<int> onSelected;

  const TagColorDotPicker({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Wrap으로 변경하여 좁은 화면에서도 오버플로우를 방지한다
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: List.generate(8, (i) {
        final color = ColorTokens.eventColor(i);
        final isSelected = i == selectedIndex;
        // WCAG 2.1 터치 타겟 44px 이상 확보: GestureDetector 영역을 확장한다
        return GestureDetector(
          onTap: () => onSelected(i),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: AppLayout.minTouchTarget,
            height: AppLayout.minTouchTarget,
            child: Center(
              child: AnimatedContainer(
                duration: AppAnimation.fast,
                curve: Curves.easeOutCubic,
                width: isSelected ? AppLayout.iconXxl : AppLayout.iconXl,
                height: isSelected ? AppLayout.iconXxl : AppLayout.iconXl,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(
                          color: context.themeColors.textPrimary,
                          width: AppLayout.borderThick,
                        )
                      : null,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
