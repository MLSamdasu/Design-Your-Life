// F4 위젯: HabitPresetSheet - 인기 습관 프리셋 선택 바텀 시트
// 미리 정의된 인기 습관 중 선택 후 빈도(매일/특정 요일)를 설정한다.
// 프리셋 목록과 빈도 설정 단계는 각각 별도 파일로 분리되어 있다.
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../shared/models/habit.dart';
import 'habit_preset_list.dart';
import 'habit_preset_frequency_step.dart';

/// 습관 생성 결과 (프리셋 + 빈도 정보)
class HabitCreateResult {
  final HabitPreset preset;
  final HabitFrequency frequency;
  final List<int> repeatDays;

  const HabitCreateResult({
    required this.preset,
    required this.frequency,
    required this.repeatDays,
  });
}

/// 인기 습관 프리셋 선택 + 빈도 설정 바텀 시트
class HabitPresetSheet extends StatefulWidget {
  final ValueChanged<HabitCreateResult> onSelected;

  const HabitPresetSheet({required this.onSelected, super.key});

  @override
  State<HabitPresetSheet> createState() => _HabitPresetSheetState();
}

class _HabitPresetSheetState extends State<HabitPresetSheet> {
  /// 선택된 프리셋 (null이면 프리셋 선택 단계)
  HabitPreset? _selectedPreset;

  /// 빈도가 '특정 요일'인지 여부 (false면 매일)
  bool _isCustomFrequency = false;

  /// 선택된 요일 집합 (1=월 ... 7=일)
  final Set<int> _selectedDays = {};

  /// 프리셋 선택 시 빈도 설정 단계로 전환한다
  void _onPresetTap(HabitPreset preset) {
    setState(() {
      _selectedPreset = preset;
      _isCustomFrequency = false;
      _selectedDays.clear();
    });
  }

  /// 프리셋 선택 단계로 되돌아간다
  void _goBack() {
    setState(() {
      _selectedPreset = null;
      _isCustomFrequency = false;
      _selectedDays.clear();
    });
  }

  /// 습관 생성을 완료한다
  void _submit() {
    if (_selectedPreset == null) return;
    // 특정 요일 선택 시 요일이 하나 이상 필요하다
    if (_isCustomFrequency && _selectedDays.isEmpty) return;

    final frequency =
        _isCustomFrequency ? HabitFrequency.weekly : HabitFrequency.daily;
    final repeatDays = _isCustomFrequency
        ? (_selectedDays.toList()..sort())
        : <int>[];

    widget.onSelected(HabitCreateResult(
      preset: _selectedPreset!,
      frequency: frequency,
      repeatDays: repeatDays,
    ));
  }

  /// 완료 버튼 활성화 조건: 매일이거나, 특정 요일에서 1개 이상 선택
  bool get _canSubmit =>
      !_isCustomFrequency || _selectedDays.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(AppRadius.massive)),
      child: BackdropFilter(
        filter: ImageFilter.blur(
            sigmaX: EffectLayout.modalBlurSigma,
            sigmaY: EffectLayout.modalBlurSigma),
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            decoration: BoxDecoration(
              color: context.themeColors.textPrimaryWithAlpha(0.15),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.massive)),
              border: Border.all(
                  color: context.themeColors.textPrimaryWithAlpha(0.2)),
            ),
            child: AnimatedSwitcher(
              duration: AppAnimation.normal,
              child: _selectedPreset == null
                  ? HabitPresetList(onPresetTap: _onPresetTap)
                  : HabitPresetFrequencyStep(
                      preset: _selectedPreset!,
                      isCustomFrequency: _isCustomFrequency,
                      selectedDays: _selectedDays,
                      canSubmit: _canSubmit,
                      onBack: _goBack,
                      onDailyTap: () => setState(() {
                        _isCustomFrequency = false;
                        _selectedDays.clear();
                      }),
                      onCustomTap: () =>
                          setState(() => _isCustomFrequency = true),
                      onDayToggle: (day) => setState(() {
                        _selectedDays.contains(day)
                            ? _selectedDays.remove(day)
                            : _selectedDays.add(day);
                      }),
                      onSubmit: _submit,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
