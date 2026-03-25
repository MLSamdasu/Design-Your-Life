// F2 위젯: EventFormSection - 제목 입력 + EventFormFields를 조합한 폼 영역
// SRP 분리: 다이얼로그 내부의 폼 위젯 배치만 담당한다
import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../shared/models/event.dart';
import '../../../../shared/widgets/glass_input_field.dart';
import 'event_form_fields.dart';

/// 일정 다이얼로그의 폼 영역 (제목 입력 + 타입/날짜/색상/위치/메모 필드)
class EventFormSection extends StatelessWidget {
  final TextEditingController titleController;
  final String? titleError;
  final ValueChanged<String> onTitleChanged;

  final EventType eventType;
  final DateTime startDate;
  final DateTime? endDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final int selectedColorIndex;
  final Set<int> repeatDays;
  final TextEditingController rangeTagController;
  final TextEditingController locationController;
  final TextEditingController memoController;

  final ValueChanged<EventType> onTypeChanged;
  final ValueChanged<DateTime> onStartDateChanged;
  final ValueChanged<DateTime> onEndDateChanged;
  final ValueChanged<TimeOfDay> onStartTimeChanged;
  final ValueChanged<TimeOfDay> onEndTimeChanged;
  final ValueChanged<int> onColorChanged;
  final ValueChanged<Set<int>> onRepeatDaysChanged;

  const EventFormSection({
    super.key,
    required this.titleController,
    required this.titleError,
    required this.onTitleChanged,
    required this.eventType,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.selectedColorIndex,
    required this.repeatDays,
    required this.rangeTagController,
    required this.locationController,
    required this.memoController,
    required this.onTypeChanged,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
    required this.onColorChanged,
    required this.onRepeatDaysChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassInputField(
          controller: titleController,
          label: '제목',
          hint: '일정 제목을 입력하세요',
          maxLength: AppConstants.maxTitleLength,
          errorText: titleError,
          onChanged: onTitleChanged,
        ),
        const SizedBox(height: AppSpacing.xl),
        EventFormFields(
          eventType: eventType,
          startDate: startDate,
          endDate: endDate,
          startTime: startTime,
          endTime: endTime,
          selectedColorIndex: selectedColorIndex,
          repeatDays: repeatDays,
          rangeTagController: rangeTagController,
          locationController: locationController,
          memoController: memoController,
          onTypeChanged: onTypeChanged,
          onStartDateChanged: onStartDateChanged,
          onEndDateChanged: onEndDateChanged,
          onStartTimeChanged: onStartTimeChanged,
          onEndTimeChanged: onEndTimeChanged,
          onColorChanged: onColorChanged,
          onRepeatDaysChanged: onRepeatDaysChanged,
        ),
      ],
    );
  }
}
