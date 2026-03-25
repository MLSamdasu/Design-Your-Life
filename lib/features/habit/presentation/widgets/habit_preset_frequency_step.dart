// F4 서브위젯: HabitPresetFrequencyStep - 빈도 설정 단계
// HabitPresetSheet에서 분리된 2단계 빈도 설정 위젯
import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../shared/models/habit.dart';
import 'routine_form_widgets.dart';
import 'habit_preset_frequency_toggle.dart';

/// 빈도 설정 단계 (단계 2) — 선택된 프리셋에 대해 매일/특정 요일을 선택한다
class HabitPresetFrequencyStep extends StatelessWidget {
  /// 선택된 프리셋 정보
  final HabitPreset preset;

  /// 특정 요일 모드 여부
  final bool isCustomFrequency;

  /// 선택된 요일 집합
  final Set<int> selectedDays;

  /// 완료 버튼 활성 여부
  final bool canSubmit;

  /// 뒤로가기 콜백
  final VoidCallback onBack;

  /// 매일 모드로 전환하는 콜백
  final VoidCallback onDailyTap;

  /// 특정 요일 모드로 전환하는 콜백
  final VoidCallback onCustomTap;

  /// 요일 토글 콜백
  final ValueChanged<int> onDayToggle;

  /// 완료 콜백
  final VoidCallback onSubmit;

  const HabitPresetFrequencyStep({
    required this.preset,
    required this.isCustomFrequency,
    required this.selectedDays,
    required this.canSubmit,
    required this.onBack,
    required this.onDailyTap,
    required this.onCustomTap,
    required this.onDayToggle,
    required this.onSubmit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('frequency_step'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: AppSpacing.xxl),
        RoutineFormLabel(label: '반복 빈도'),
        const SizedBox(height: AppSpacing.md),
        _buildFrequencyToggleRow(context),
        // 특정 요일 선택 시 요일 선택기 표시
        if (isCustomFrequency) ...[
          const SizedBox(height: AppSpacing.xl),
          RoutineFormLabel(label: '반복 요일'),
          const SizedBox(height: AppSpacing.md),
          RoutineDaySelector(
            selectedDays: selectedDays,
            onToggle: onDayToggle,
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
        _buildSubmitButton(context),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  /// 헤더: 뒤로가기 + 선택된 습관 이름
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: Icon(
            Icons.arrow_back_ios_rounded,
            color: context.themeColors.textPrimaryWithAlpha(0.6),
            size: AppLayout.iconMd,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        if (preset.icon.isNotEmpty) ...[
          Text(preset.icon, style: AppTypography.emojiLg),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: Text(
            preset.name,
            style: AppTypography.titleMd
                .copyWith(color: context.themeColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// 매일 / 특정 요일 토글 행
  Widget _buildFrequencyToggleRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FrequencyToggle(
            label: '매일',
            isSelected: !isCustomFrequency,
            onTap: onDailyTap,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: FrequencyToggle(
            label: '특정 요일',
            isSelected: isCustomFrequency,
            onTap: onCustomTap,
          ),
        ),
      ],
    );
  }

  /// 완료 버튼
  Widget _buildSubmitButton(BuildContext context) {
    return GestureDetector(
      onTap: canSubmit ? onSubmit : null,
      child: AnimatedContainer(
        duration: AppAnimation.fast,
        height: AppLayout.formButtonHeight,
        decoration: BoxDecoration(
          color: canSubmit
              ? ColorTokens.main
              : context.themeColors.textPrimaryWithAlpha(0.12),
          borderRadius: BorderRadius.circular(AppRadius.xlLg),
          boxShadow: canSubmit
              ? [
                  BoxShadow(
                    color: ColorTokens.main.withValues(alpha: 0.4),
                    blurRadius: EffectLayout.shadowBlurMd,
                    offset: const Offset(0, EffectLayout.shadowOffsetSm),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            '습관 추가하기',
            style: AppTypography.titleMd.copyWith(
              // MAIN 컬러 배경 위이므로 활성 시 흰색이 적절하다
              color: canSubmit
                  ? ColorTokens.white
                  : context.themeColors.textPrimaryWithAlpha(0.35),
            ),
          ),
        ),
      ),
    );
  }
}
