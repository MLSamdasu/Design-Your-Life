// F3 위젯: TodoTimeSection - 시간 지정 토글 + 단일 시간 선택 버튼 섹션
// todo_time_picker.dart에서 SRP 분리한다.
import 'package:flutter/material.dart';

import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/spacing_tokens.dart';
import 'todo_time_picker_button.dart';

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
        TimeToggleRow(hasTime: hasTime, onToggled: onToggled),
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

/// 시간 지정 토글 행 (공통 추출)
/// TodoTimeSection, TodoTimeRangeSection 양쪽에서 사용한다.
class TimeToggleRow extends StatelessWidget {
  final bool hasTime;
  final ValueChanged<bool> onToggled;

  const TimeToggleRow({
    super.key,
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
