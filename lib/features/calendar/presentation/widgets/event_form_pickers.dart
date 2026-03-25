// F2 위젯: EventFormPickers - 이벤트 폼 색상 팔레트 + 반복 요일 선택
// SRP 분리: event_form_fields.dart에서 피커 위젯을 추출한다
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 이벤트 색상 선택 피커 위젯 (8색 팔레트)
class EventColorPicker extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const EventColorPicker({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(8, (index) {
        final color = ColorTokens.eventColor(index);
        final isSelected = selectedIndex == index;
        return GestureDetector(
          onTap: () => onChanged(index),
          child: AnimatedContainer(
            duration: AppAnimation.fast,
            width: isSelected ? AppLayout.colorPickerSelectedSize : AppLayout.colorPickerSize,
            height: isSelected ? AppLayout.colorPickerSelectedSize : AppLayout.colorPickerSize,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                // 선택된 색상 원의 외곽선: 테마 기본 텍스트 색상으로 표시한다
                color: isSelected ? context.themeColors.textPrimary : ColorTokens.transparent,
                width: AppLayout.borderAccent,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.50),
                        blurRadius: EffectLayout.colorPickerShadowBlur,
                        spreadRadius: EffectLayout.colorPickerShadowSpread,
                      )
                    ]
                  : null,
            ),
            child: isSelected
                ? Icon(Icons.check_rounded,
                    color: context.themeColors.textPrimary, size: AppLayout.iconMd)
                : null,
          ),
        );
      }),
    );
  }
}

/// 반복 요일 선택 위젯 (월~일 7개 원형 버튼)
class RepeatDaySelector extends StatelessWidget {
  final Set<int> selectedDays;
  final ValueChanged<Set<int>> onChanged;

  static const List<String> _weekdayLabels = [
    '월', '화', '수', '목', '금', '토', '일'
  ];

  const RepeatDaySelector({
    super.key,
    required this.selectedDays,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(AppLayout.daysInWeek, (i) {
        final weekday = i + 1;
        final isSelected = selectedDays.contains(weekday);
        return GestureDetector(
          onTap: () {
            final newDays = Set<int>.from(selectedDays);
            if (isSelected) {
              newDays.remove(weekday);
            } else {
              newDays.add(weekday);
            }
            onChanged(newDays);
          },
          child: AnimatedContainer(
            duration: AppAnimation.fast,
            width: AppLayout.containerLg,
            height: AppLayout.containerLg,
            decoration: BoxDecoration(
              // 선택된 요일: 배경 테마에 맞는 악센트 색상으로 표시한다
              color: isSelected
                  ? context.themeColors.accent
                  : context.themeColors.textPrimaryWithAlpha(0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _weekdayLabels[i],
              // 요일 텍스트: 악센트 배경 위이므로 테마 인식 색상 사용
              style: AppTypography.captionLg.copyWith(
                color: isSelected
                    ? context.themeColors.textPrimary
                    : context.themeColors.textPrimaryWithAlpha(0.60),
                fontWeight:
                    isSelected ? AppTypography.weightBold : AppTypography.weightRegular,
              ),
            ),
          ),
        );
      }),
    );
  }
}
