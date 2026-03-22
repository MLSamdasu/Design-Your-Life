// F4 위젯: RoutineFormWidgets - 루틴 폼 전용 UI 컴포넌트
// RoutineCreateDialog에서 사용하는 폼 필드 위젯들 (SRP 분리)
import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 폼 섹션 라벨
class RoutineFormLabel extends StatelessWidget {
  final String label;
  const RoutineFormLabel({required this.label, super.key});
  @override
  Widget build(BuildContext context) => Text(
        label,
        style: AppTypography.captionLg.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.65), letterSpacing: 0.4),
      );
}

/// 루틴 이름 글래스 텍스트 필드
class RoutineNameField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  const RoutineNameField(
      {required this.controller, required this.hint, this.onChanged, super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: AppLayout.routineNameMaxLength,
      onChanged: onChanged,
      style: AppTypography.bodyMd.copyWith(color: context.themeColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.bodyMd
            .copyWith(color: context.themeColors.textPrimaryWithAlpha(0.4)),
        counterStyle: AppTypography.captionSm
            .copyWith(color: context.themeColors.textPrimaryWithAlpha(0.4)),
        filled: true,
        fillColor: context.themeColors.textPrimaryWithAlpha(0.10),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.lgXl, vertical: AppSpacing.lg),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide(color: context.themeColors.textPrimaryWithAlpha(0.20)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide(color: context.themeColors.textPrimaryWithAlpha(0.20)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide(color: context.themeColors.textPrimaryWithAlpha(0.50)),
        ),
      ),
    );
  }
}

/// 요일 다중 선택 위젯 (월~일, 1~7)
class RoutineDaySelector extends StatelessWidget {
  final Set<int> selectedDays;
  final ValueChanged<int> onToggle;
  const RoutineDaySelector(
      {required this.selectedDays, required this.onToggle, super.key});
  @override
  Widget build(BuildContext context) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(AppLayout.daysInWeek, (i) {
        final day = i + 1;
        final sel = selectedDays.contains(day);
        return GestureDetector(
          onTap: () => onToggle(day),
          child: AnimatedContainer(
            duration: AppAnimation.fast,
            width: AppLayout.containerLg,
            height: AppLayout.containerLg,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // 선택된 요일: 배경 테마에 맞는 악센트 색상으로 표시한다
              color: sel
                  ? context.themeColors.accentWithAlpha(0.85)
                  : context.themeColors.textPrimaryWithAlpha(0.08),
              border: Border.all(
                color: sel
                    ? context.themeColors.accent
                    : context.themeColors.textPrimaryWithAlpha(0.18),
              ),
            ),
            child: Center(
              child: Text(
                labels[i],
                style: AppTypography.captionLg.copyWith(
                  // 요일 텍스트: 악센트 배경 위이므로 테마 인식 색상 사용
                  color: sel
                      ? context.themeColors.textPrimary
                      : i >= 5
                          ? context.themeColors.textPrimaryWithAlpha(0.5)
                          : context.themeColors.textPrimaryWithAlpha(0.7),
                  fontWeight: sel ? AppTypography.weightBold : AppTypography.weightRegular,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// 시작/종료 시간 선택 행
class RoutineTimeRow extends StatelessWidget {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  const RoutineTimeRow(
      {required this.startTime,
      required this.endTime,
      required this.onPickStart,
      required this.onPickEnd,
      super.key});
  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: RoutineTimeButton(label: _fmt(startTime), onTap: onPickStart)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text('~',
              style: AppTypography.bodyMd
                  .copyWith(color: context.themeColors.textPrimaryWithAlpha(0.6))),
        ),
        Expanded(child: RoutineTimeButton(label: _fmt(endTime), onTap: onPickEnd)),
      ],
    );
  }
}

/// 단일 시간 선택 버튼
class RoutineTimeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const RoutineTimeButton({required this.label, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.mdLg),
          decoration: BoxDecoration(
            color: context.themeColors.textPrimaryWithAlpha(0.10),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: context.themeColors.textPrimaryWithAlpha(0.20)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.access_time_rounded,
                  size: AppLayout.iconSm, color: context.themeColors.textPrimaryWithAlpha(0.6)),
              const SizedBox(width: AppSpacing.sm),
              Text(label, style: AppTypography.bodyMd.copyWith(color: context.themeColors.textPrimary)),
            ],
          ),
        ),
      );
}

/// 루틴 생성 완료 버튼
class RoutineSubmitButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  const RoutineSubmitButton({required this.enabled, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: AppAnimation.fast,
          height: AppLayout.formButtonHeight,
          decoration: BoxDecoration(
            color: enabled ? ColorTokens.main : context.themeColors.textPrimaryWithAlpha(0.12),
            borderRadius: BorderRadius.circular(AppRadius.xlLg),
            boxShadow: enabled
                ? [BoxShadow(color: ColorTokens.main.withValues(alpha: 0.4),
                    blurRadius: AppLayout.shadowBlurMd, offset: const Offset(0, AppLayout.shadowOffsetSm))]
                : null,
          ),
          child: Center(
            child: Text('루틴 만들기',
              style: AppTypography.titleMd.copyWith(
                // MAIN 컬러 배경(#7C3AED) 위이므로 활성 시 흰색이 적절하다
                color: enabled ? ColorTokens.white : context.themeColors.textPrimaryWithAlpha(0.35))),
          ),
        ),
      );
}
