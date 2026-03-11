// F2 위젯: EventFormFields - 이벤트 폼 입력 필드 집합
// SRP 분리: EventCreateDialog의 폼 필드 렌더링만 담당
// 색상 팔레트와 반복 요일 선택은 event_form_pickers.dart로 분리한다
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/models/event.dart';
import '../../../../shared/widgets/glass_input_field.dart';
import 'date_time_picker_button.dart';
import 'event_form_pickers.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';

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

  static const Map<EventType, String> _typeLabels = {
    EventType.normal: '일반',
    EventType.range: '범위',
    EventType.recurring: '반복',
    EventType.todo: '투두',
  };

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
        _buildTypeSelector(context),
        const SizedBox(height: AppSpacing.xl),
        _buildDateSection(context),
        const SizedBox(height: AppSpacing.xl),
        _buildTimeSection(context),
        const SizedBox(height: AppSpacing.xl),
        // 색상 피커 (event_form_pickers.dart로 분리)
        _label(context, '색상'),
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
          // 반복 요일 선택 (event_form_pickers.dart로 분리)
          _label(context, '반복 요일'),
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

  /// 이벤트 유형 선택 Pill 탭
  Widget _buildTypeSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(context, '유형'),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(3),
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
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: isActive
                          ? context.themeColors.textPrimaryWithAlpha(0.20)
                          : ColorTokens.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _typeLabels[type]!,
                      style: AppTypography.captionLg.copyWith(
                        color: isActive
                            ? context.themeColors.textPrimary
                            : context.themeColors.textPrimaryWithAlpha(0.50),
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w400,
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

  /// 날짜 선택 섹션 (범위 일정이면 시작~종료 표시)
  Widget _buildDateSection(BuildContext context) {
    final isRange = eventType == EventType.range;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(context, isRange ? '시작일 ~ 종료일' : '날짜'),
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
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  '~',
                  style: AppTypography.bodyMd
                      .copyWith(color: context.themeColors.textPrimaryWithAlpha(0.60)),
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

  /// 시간 선택 섹션 (시작~종료)
  Widget _buildTimeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(context, '시간 (선택)'),
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
                      context, endTime ?? (startTime ?? TimeOfDay.now()));
                  if (picked != null) onEndTimeChanged(picked);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 라벨 공통 스타일
  Widget _label(BuildContext context, String text) => Text(
        text,
        style: AppTypography.captionLg.copyWith(
          color: context.themeColors.textPrimaryWithAlpha(0.70),
        ),
      );
}
