// 태그 색상 선택 위젯
// 8개 이벤트 색상 중 하나를 선택할 수 있는 원형 색상 팔레트를 렌더링한다.
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 태그 색상 선택 위젯 (8색 원형 팔레트)
class TagColorPicker extends StatelessWidget {
  /// 현재 선택된 색상 인덱스
  final int selectedIndex;

  /// 색상 선택 시 호출되는 콜백
  final ValueChanged<int> onColorSelected;

  const TagColorPicker({
    super.key,
    required this.selectedIndex,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '색상',
          style: AppTypography.captionLg.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.7),
          ),
        ),
        const SizedBox(height: AppSpacing.mdLg),
        // Wrap 사용으로 좁은 화면에서도 오버플로우 없이 색상 원을 배치한다
        Wrap(
          spacing: AppSpacing.mdLg,
          runSpacing: AppSpacing.md,
          children: List.generate(8, (i) {
            final color = ColorTokens.eventColor(i);
            final isSelected = i == selectedIndex;
            // WCAG 2.1: 터치 타겟 최소 44px 보장 (시각적 크기는 유지)
            return GestureDetector(
              onTap: () => onColorSelected(i),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: AppLayout.minTouchTarget,
                height: AppLayout.minTouchTarget,
                child: Center(
                  child: AnimatedContainer(
                    duration: AppAnimation.fast,
                    curve: Curves.easeOutCubic,
                    width: isSelected
                        ? AppLayout.colorPickerSize
                        : AppLayout.checkboxLg,
                    height: isSelected
                        ? AppLayout.colorPickerSize
                        : AppLayout.checkboxLg,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: context.themeColors.textPrimary,
                              width: AppLayout.borderAccent,
                            )
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: EffectLayout.colorPickerShadowBlur,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
