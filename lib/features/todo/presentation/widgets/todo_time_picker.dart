// F3 위젯: TodoTimePicker - 투두 시간 선택 위젯 (SRP 분리)
// todo_create_dialog.dart에서 추출한다.
// 포함: TodoTimeSection(하위 호환), TodoTimeRangeSection(시작/종료 범위), TodoTimePickerButton
import 'package:flutter/material.dart';

import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 시간 지정 토글 + 단일 시간 선택 버튼 섹션 (하위 호환용)
class TodoTimeSection extends StatelessWidget {
  final bool hasTime;
  final TimeOfDay selectedTime;
  final ValueChanged<bool> onToggled;
  final VoidCallback onPickTime;

  const TodoTimeSection({
    super.key,
    required this.hasTime,
    required this.selectedTime,
    required this.onToggled,
    required this.onPickTime,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 시간 지정 토글 행
        _TimeToggleRow(hasTime: hasTime, onToggled: onToggled),
        // 시간 선택 버튼 (토글 활성화 시)
        if (hasTime) ...[
          const SizedBox(height: AppSpacing.md),
          TodoTimePickerButton(
            selectedTime: selectedTime,
            onTap: onPickTime,
          ),
        ],
      ],
    );
  }
}

/// 시간 범위 지정 섹션 (시작/종료 시간 + 빠른 지속 시간 버튼)
/// TodoCreateDialog에서 사용하는 주요 시간 입력 위젯이다
class TodoTimeRangeSection extends StatelessWidget {
  /// 시간 지정 여부
  final bool hasTime;

  /// 시작 시간
  final TimeOfDay startTime;

  /// 종료 시간
  final TimeOfDay endTime;

  /// 시간 지정 토글 콜백
  final ValueChanged<bool> onToggled;

  /// 시작 시간 선택 콜백
  final VoidCallback onPickStartTime;

  /// 종료 시간 선택 콜백
  final VoidCallback onPickEndTime;

  /// 빠른 지속 시간 설정 콜백 (분 단위)
  final ValueChanged<int> onQuickDuration;

  const TodoTimeRangeSection({
    super.key,
    required this.hasTime,
    required this.startTime,
    required this.endTime,
    required this.onToggled,
    required this.onPickStartTime,
    required this.onPickEndTime,
    required this.onQuickDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 시간 지정 토글 행
        _TimeToggleRow(hasTime: hasTime, onToggled: onToggled),
        // 시간 범위 선택 (토글 활성화 시)
        if (hasTime) ...[
          const SizedBox(height: AppSpacing.md),
          // 시작/종료 시간 행
          Row(
            children: [
              // 시작 시간
              Expanded(
                child: _LabeledTimePicker(
                  label: '시작',
                  time: startTime,
                  onTap: onPickStartTime,
                ),
              ),
              // 화살표 구분자
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: AppLayout.iconMd,
                  color: context.themeColors.textPrimaryWithAlpha(0.4),
                ),
              ),
              // 종료 시간
              Expanded(
                child: _LabeledTimePicker(
                  label: '종료',
                  time: endTime,
                  onTap: onPickEndTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // 빠른 지속 시간 버튼들
          _QuickDurationButtons(onDurationSelected: onQuickDuration),
        ],
      ],
    );
  }
}

/// 시간 지정 토글 행 (공통 추출)
class _TimeToggleRow extends StatelessWidget {
  final bool hasTime;
  final ValueChanged<bool> onToggled;

  const _TimeToggleRow({
    required this.hasTime,
    required this.onToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '시간 지정',
          style: AppTypography.bodyMd.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.8),
          ),
        ),
        const Spacer(),
        // 배경 테마에 맞는 악센트 색상으로 스위치를 표시한다
        Switch(
          value: hasTime,
          onChanged: onToggled,
          activeThumbColor: context.themeColors.accent,
          activeTrackColor: context.themeColors.accentWithAlpha(0.4),
          inactiveThumbColor:
              context.themeColors.textPrimaryWithAlpha(0.6),
          inactiveTrackColor:
              context.themeColors.textPrimaryWithAlpha(0.2),
        ),
      ],
    );
  }
}

/// 라벨 + 시간 선택 버튼 조합 위젯
class _LabeledTimePicker extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _LabeledTimePicker({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.captionMd.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.5),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TodoTimePickerButton(selectedTime: time, onTap: onTap),
      ],
    );
  }
}

/// 빠른 지속 시간 버튼 행
/// 30분, 1시간, 2시간, 3시간 중 선택한다
class _QuickDurationButtons extends StatelessWidget {
  final ValueChanged<int> onDurationSelected;

  const _QuickDurationButtons({required this.onDurationSelected});

  /// 빠른 지속 시간 옵션 목록
  static const _options = [
    (label: '30분', minutes: 30),
    (label: '1시간', minutes: 60),
    (label: '2시간', minutes: 120),
    (label: '3시간', minutes: 180),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.map((option) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: option == _options.last ? 0 : 6,
            ),
            child: GestureDetector(
              onTap: () => onDurationSelected(option.minutes),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                // 빠른 선택 버튼: 배경 테마에 맞는 악센트 색상으로 표시한다
                decoration: BoxDecoration(
                  color: context.themeColors.accentWithAlpha(0.08),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: context.themeColors.accentWithAlpha(0.15),
                  ),
                ),
                child: Center(
                  child: Text(
                    option.label,
                    style: AppTypography.captionLg.copyWith(
                      // 어두운 배경에서는 mainLight, 밝은 배경에서는 main을 사용한다
                      color: context.themeColors.accent,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 시간 선택 버튼 위젯
class TodoTimePickerButton extends StatelessWidget {
  final TimeOfDay selectedTime;
  final VoidCallback onTap;

  const TodoTimePickerButton({
    super.key,
    required this.selectedTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hourStr = selectedTime.hour.toString().padLeft(2, '0');
    final minStr = selectedTime.minute.toString().padLeft(2, '0');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.themeColors.textPrimaryWithAlpha(0.10),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: context.themeColors.textPrimaryWithAlpha(0.20),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              color: context.themeColors.textPrimaryWithAlpha(0.7),
              size: AppLayout.iconMd,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              '$hourStr:$minStr',
              style: AppTypography.bodyLg.copyWith(
                color: context.themeColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
