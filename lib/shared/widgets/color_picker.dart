// 공용 위젯: ColorPicker (8색 컬러 피커)
// colorIndex 0~7에 대응하는 색상 원을 수평으로 나열한다.
// 일정 생성 다이얼로그, 투두 생성, 습관 생성, 루틴 생성에서 공통 사용한다.
import 'package:flutter/material.dart';
import '../../core/theme/animation_tokens.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/layout_tokens.dart';
import '../../core/theme/theme_colors.dart';

/// 8색 컬러 피커 위젯
/// 선택된 colorIndex에 흰색 테두리와 체크마크를 표시한다
class ColorPickerWidget extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onColorSelected;

  const ColorPickerWidget({
    required this.selectedIndex,
    required this.onColorSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(8, (index) {
        final color = ColorTokens.eventColor(index);
        final isSelected = selectedIndex == index;
        return GestureDetector(
          onTap: () => onColorSelected(index),
          child: AnimatedContainer(
            duration: AppAnimation.fast,
            width: isSelected ? 32 : AppLayout.minButtonSize,
            height: isSelected ? 32 : AppLayout.minButtonSize,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: context.themeColors.textPrimary, width: 2.5)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? Icon(
                    Icons.check_rounded,
                    size: AppLayout.iconMd,
                    color: context.themeColors.textPrimary,
                  )
                : null,
          ),
        );
      }),
    );
  }
}
