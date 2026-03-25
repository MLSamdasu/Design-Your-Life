// F2 위젯: EventTimeSection - 시간 선택 섹션
// SRP 분리: event_form_fields.dart에서 시간 선택 UI만 추출
import 'package:flutter/material.dart';

import '../../../../core/theme/spacing_tokens.dart';
import 'date_time_picker_button.dart';
import 'event_form_label.dart';

/// 시간 선택 섹션 (시작~종료 시간)
class EventTimeSection extends StatelessWidget {
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final ValueChanged<TimeOfDay> onStartTimeChanged;
  final ValueChanged<TimeOfDay> onEndTimeChanged;

  const EventTimeSection({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        eventFormLabel(context, '시간 (선택)'),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: TimePickerButton(
                time: startTime,
                hint: '시작 시간',
                onTap: () async {
                  final picked = await showGlassTimePicker(
                      context, startTime ?? TimeOfDay.now());
                  if (picked != null) onStartTimeChanged(picked);
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TimePickerButton(
                time: endTime,
                hint: '종료 시간',
                onTap: () async {
                  final picked = await showGlassTimePicker(
                      context,
                      endTime ?? (startTime ?? TimeOfDay.now()));
                  if (picked != null) onEndTimeChanged(picked);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
