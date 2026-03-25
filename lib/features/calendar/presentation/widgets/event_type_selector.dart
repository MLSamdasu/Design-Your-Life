// F2 위젯: EventTypeSelector - 이벤트 유형 선택 Pill 탭
// SRP 분리: event_form_fields.dart에서 유형 선택 UI만 추출
import 'package:flutter/material.dart';

import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../shared/models/event.dart';
import 'event_form_label.dart';

/// 이벤트 유형(일반/범위/반복/투두) Pill 탭 선택 위젯
class EventTypeSelector extends StatelessWidget {
  final EventType eventType;
  final ValueChanged<EventType> onTypeChanged;

  /// 유형별 한글 라벨
  static const Map<EventType, String> _typeLabels = {
    EventType.normal: '일반',
    EventType.range: '범위',
    EventType.recurring: '반복',
    EventType.todo: '투두',
  };

  const EventTypeSelector({
    super.key,
    required this.eventType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        eventFormLabel(context, '유형'),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.xxs),
          decoration: BoxDecoration(
            color: context.themeColors.textPrimaryWithAlpha(0.10),
            borderRadius: BorderRadius.circular(AppRadius.lgXl),
          ),
          child: Row(
            children: EventType.values.map((type) {
              final isActive = type == eventType;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTypeChanged(type),
                  child: AnimatedContainer(
                    duration: AppAnimation.normal,
                    curve: Curves.easeInOutCubic,
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isActive
                          ? context.themeColors
                              .textPrimaryWithAlpha(0.20)
                          : ColorTokens.transparent,
                      borderRadius:
                          BorderRadius.circular(AppRadius.md),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _typeLabels[type]!,
                      style: AppTypography.captionLg.copyWith(
                        color: isActive
                            ? context.themeColors.textPrimary
                            : context.themeColors
                                .textPrimaryWithAlpha(0.50),
                        fontWeight: isActive
                            ? AppTypography.weightBold
                            : AppTypography.weightRegular,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
