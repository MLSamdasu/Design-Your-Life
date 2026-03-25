// 습관 수정 다이얼로그: 이름 + 빈도(매일/특정요일) 편집
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../shared/models/habit.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../providers/habit_provider.dart';
import 'habit_frequency_widgets.dart';

/// 습관 수정 다이얼로그를 표시한다 (이름 + 빈도 수정 지원)
Future<void> showHabitEditDialog(
    BuildContext context, WidgetRef ref, Habit habit) async {
  final result = await showDialog<Habit>(
    context: context,
    builder: (ctx) => HabitEditDialog(habit: habit),
  );

  if (result != null && context.mounted) {
    try {
      await ref.read(updateHabitProvider).call(habit.id, result);
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(context, '습관 수정에 실패했습니다');
      }
    }
  }
}

/// 습관 수정 다이얼로그 (이름 + 빈도 편집)
class HabitEditDialog extends StatefulWidget {
  final Habit habit;
  const HabitEditDialog({super.key, required this.habit});

  @override
  State<HabitEditDialog> createState() => _HabitEditDialogState();
}

class _HabitEditDialogState extends State<HabitEditDialog> {
  late TextEditingController _nameCtrl;
  late bool _isCustomFrequency;
  late Set<int> _selectedDays;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.habit.name);
    _isCustomFrequency = widget.habit.frequency != HabitFrequency.daily;
    _selectedDays = Set<int>.from(widget.habit.repeatDays);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  /// 저장 가능 조건: 이름이 비어있지 않고, 특정 요일 선택 시 1개 이상
  bool get _canSubmit =>
      _nameCtrl.text.trim().isNotEmpty &&
      (!_isCustomFrequency || _selectedDays.isNotEmpty);

  void _submit() {
    if (!_canSubmit) return;
    final frequency =
        _isCustomFrequency ? HabitFrequency.weekly : HabitFrequency.daily;
    final repeatDays = _isCustomFrequency
        ? (_selectedDays.toList()..sort())
        : <int>[];
    Navigator.of(context).pop(widget.habit.copyWith(
      name: _nameCtrl.text.trim(),
      frequency: frequency,
      repeatDays: repeatDays,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.themeColors.dialogSurface,
      title: Text(
        '습관 수정',
        style: AppTypography.titleMd.copyWith(
          color: context.themeColors.textPrimary,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 습관 이름
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              maxLength: MiscLayout.habitNameMaxLength,
              onChanged: (_) => setState(() {}),
              style: AppTypography.bodyMd.copyWith(
                color: context.themeColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: '습관 이름',
                hintStyle: AppTypography.bodyMd.copyWith(
                  // WCAG 최소 대비를 충족하도록 알파값을 0.55로 상향 조정
                  color: context.themeColors.textPrimaryWithAlpha(0.55),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 빈도 라벨
            Text(
              '반복 빈도',
              style: AppTypography.captionLg.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.65),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 매일 / 특정 요일 토글
            Row(
              children: [
                Expanded(
                  child: FrequencyChip(
                    label: '매일',
                    isSelected: !_isCustomFrequency,
                    onTap: () => setState(() {
                      _isCustomFrequency = false;
                      _selectedDays.clear();
                    }),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FrequencyChip(
                    label: '특정 요일',
                    isSelected: _isCustomFrequency,
                    onTap: () => setState(() => _isCustomFrequency = true),
                  ),
                ),
              ],
            ),

            // 요일 선택기 (특정 요일인 경우만)
            if (_isCustomFrequency) ...[
              const SizedBox(height: AppSpacing.lg),
              DaySelectorRow(
                selectedDays: _selectedDays,
                onToggle: (day) => setState(() {
                  _selectedDays.contains(day)
                      ? _selectedDays.remove(day)
                      : _selectedDays.add(day);
                }),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            '취소',
            style: AppTypography.bodyMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.7),
            ),
          ),
        ),
        TextButton(
          onPressed: _canSubmit ? _submit : null,
          child: Text(
            '저장',
            style: AppTypography.bodyMd.copyWith(
              color: _canSubmit
                  ? ColorTokens.main
                  : context.themeColors.textPrimaryWithAlpha(0.3),
            ),
          ),
        ),
      ],
    );
  }
}
