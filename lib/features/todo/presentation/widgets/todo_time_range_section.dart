// F3 위젯: TodoTimeRangeSection - 시작/종료 시간 범위 선택 섹션
// todo_time_picker.dart에서 SRP 분리한다.
import 'package:flutter/material.dart';

import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import 'todo_time_section.dart';
import 'todo_time_picker_button.dart';

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
        TimeToggleRow(hasTime: hasTime, onToggled: onToggled),
        // 시간 범위 선택 (토글 활성화 시)
        if (hasTime) ...[
          const SizedBox(height: AppSpacing.md),
          // 시작/종료 시간 행
          Row(
            children: [
              // 시작 시간
              Expanded(
                child: LabeledTimePicker(
                  label: '시작',
                  time: startTime,
                  onTap: onPickStartTime,
                ),
              ),
              // 화살표 구분자
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: AppLayout.iconMd,
                  // WCAG: 화살표 아이콘 알파 0.50 이상으로 가독성 보장
                  color: context.themeColors.textPrimaryWithAlpha(0.50),
                ),
              ),
              // 종료 시간
              Expanded(
                child: LabeledTimePicker(
                  label: '종료',
                  time: endTime,
                  onTap: onPickEndTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // 빠른 지속 시간 버튼들
          QuickDurationButtons(onDurationSelected: onQuickDuration),
        ],
      ],
    );
  }
}

/// 라벨 + 시간 선택 버튼 조합 위젯
class LabeledTimePicker extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const LabeledTimePicker({
    super.key,
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
            // WCAG: 라벨 텍스트 알파 0.55 이상으로 가독성 보장
            color: context.themeColors.textPrimaryWithAlpha(0.55),
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
class QuickDurationButtons extends StatelessWidget {
  final ValueChanged<int> onDurationSelected;

  const QuickDurationButtons({
    super.key,
    required this.onDurationSelected,
  });

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
              right:
                  option == _options.last ? 0 : MiscLayout.quickDurationGap,
            ),
            child: GestureDetector(
              onTap: () => onDurationSelected(option.minutes),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
