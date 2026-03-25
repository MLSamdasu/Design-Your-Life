// F2 위젯: EventDateSection - 날짜 선택 섹션
// SRP 분리: event_form_fields.dart에서 날짜 선택 UI만 추출
import 'package:flutter/material.dart';

import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../shared/models/event.dart';
import 'date_time_picker_button.dart';
import 'event_form_label.dart';

/// 날짜 선택 섹션 (범위 일정이면 시작~종료 표시)
class EventDateSection extends StatelessWidget {
  final EventType eventType;
  final DateTime startDate;
  final DateTime? endDate;
  final ValueChanged<DateTime> onStartDateChanged;
  final ValueChanged<DateTime> onEndDateChanged;

  const EventDateSection({
    super.key,
    required this.eventType,
    required this.startDate,
    required this.endDate,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isRange = eventType == EventType.range;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        eventFormLabel(context, isRange ? '시작일 ~ 종료일' : '날짜'),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: DatePickerButton(
                date: startDate,
                onTap: () async {
                  final picked =
                      await showGlassDatePicker(context, startDate);
                  if (picked != null) onStartDateChanged(picked);
                },
              ),
            ),
            if (isRange) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md),
                child: Text(
                  '~',
                  style: AppTypography.bodyMd.copyWith(
                    color: context.themeColors
                        .textPrimaryWithAlpha(0.60),
                  ),
                ),
              ),
              Expanded(
                child: DatePickerButton(
                  date: endDate ?? startDate,
                  onTap: () async {
                    final picked = await showGlassDatePicker(
                        context, endDate ?? startDate);
                    if (picked != null) onEndDateChanged(picked);
                  },
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
