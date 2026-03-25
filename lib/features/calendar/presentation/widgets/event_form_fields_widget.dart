// F2 위젯: EventFormFields - 이벤트 폼 입력 필드 집합
// SRP 분리: 하위 섹션 위젯을 조합하여 전체 폼을 구성한다
import 'package:flutter/material.dart';

import '../../../../core/theme/spacing_tokens.dart';
import '../../../../shared/models/event.dart';
import '../../../../shared/widgets/glass_input_field.dart';
import 'event_form_label.dart';
import 'event_form_pickers.dart';
import 'event_type_selector.dart';
import 'event_date_section.dart';
import 'event_time_section.dart';

/// 이벤트 생성 폼 필드 집합 위젯 (SRP: UI 렌더링만, 로직은 상위로 콜백)
class EventFormFields extends StatelessWidget {
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

  const EventFormFields({
    super.key,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 이벤트 유형 선택 Pill 탭
        EventTypeSelector(
          eventType: eventType,
          onTypeChanged: onTypeChanged,
        ),
        const SizedBox(height: AppSpacing.xl),
        // 날짜 선택 섹션
        EventDateSection(
          eventType: eventType,
          startDate: startDate,
          endDate: endDate,
          onStartDateChanged: onStartDateChanged,
          onEndDateChanged: onEndDateChanged,
        ),
        const SizedBox(height: AppSpacing.xl),
        // 시간 선택 섹션
        EventTimeSection(
          startTime: startTime,
          endTime: endTime,
          onStartTimeChanged: onStartTimeChanged,
          onEndTimeChanged: onEndTimeChanged,
        ),
        const SizedBox(height: AppSpacing.xl),
        // 색상 피커 (event_form_pickers.dart)
        eventFormLabel(context, '색상'),
        const SizedBox(height: AppSpacing.mdLg),
        EventColorPicker(
          selectedIndex: selectedColorIndex,
          onChanged: onColorChanged,
        ),
        if (eventType == EventType.range) ...[
          const SizedBox(height: AppSpacing.xl),
          GlassInputField(
            controller: rangeTagController,
            label: '범위 태그 (선택)',
            hint: '예: D-Day, 프로젝트 A',
          ),
        ],
        if (eventType == EventType.recurring) ...[
          const SizedBox(height: AppSpacing.xl),
          // 반복 요일 선택 (event_form_pickers.dart)
          eventFormLabel(context, '반복 요일'),
          const SizedBox(height: AppSpacing.mdLg),
          RepeatDaySelector(
            selectedDays: repeatDays,
            onChanged: onRepeatDaysChanged,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        GlassInputField(
          controller: locationController,
          label: '위치 (선택)',
          hint: '장소를 입력하세요',
          prefixIcon: Icons.location_on_outlined,
        ),
        const SizedBox(height: AppSpacing.xl),
        GlassInputField(
          controller: memoController,
          label: '메모 (선택)',
          hint: '메모를 입력하세요',
          maxLines: 3,
        ),
      ],
    );
  }
}
