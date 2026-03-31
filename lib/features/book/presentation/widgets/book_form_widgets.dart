// F-Book: 책 폼 보조 위젯 — 추적 모드 토글, 분배 모드, 날짜 선택, 시험 토글
import 'package:flutter/material.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import 'book_create_form_fields.dart';

/// 추적 모드 토글 (페이지/챕터)
class TrackingModeToggle extends StatelessWidget {
  final TrackingMode mode;
  final ValueChanged<TrackingMode> onChanged;
  const TrackingModeToggle({super.key, required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('추적 방식', style: AppTypography.captionLg
          .copyWith(color: context.themeColors.textPrimaryWithAlpha(0.70))),
      const SizedBox(height: AppSpacing.sm),
      Row(children: [
        _Chip(label: '페이지', isActive: mode == TrackingMode.pages,
            onTap: () => onChanged(TrackingMode.pages)),
        const SizedBox(width: AppSpacing.md),
        _Chip(label: '챕터', isActive: mode == TrackingMode.chapters,
            onTap: () => onChanged(TrackingMode.chapters)),
      ]),
    ]);
  }
}

/// 분배 모드 토글 (자동/수동)
class DistributionModeToggle extends StatelessWidget {
  final DistributionMode mode;
  final ValueChanged<DistributionMode> onChanged;
  const DistributionModeToggle({super.key, required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('분배 방식', style: AppTypography.captionLg
          .copyWith(color: context.themeColors.textPrimaryWithAlpha(0.70))),
      const SizedBox(height: AppSpacing.sm),
      Row(children: [
        _Chip(label: '자동 분배', isActive: mode == DistributionMode.auto,
            onTap: () => onChanged(DistributionMode.auto)),
        const SizedBox(width: AppSpacing.md),
        _Chip(label: '수동 분배', isActive: mode == DistributionMode.manual,
            onTap: () => onChanged(DistributionMode.manual)),
      ]),
    ]);
  }
}

/// 공용 모드 선택 칩
class _Chip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimation.fast,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.mdLg),
        decoration: BoxDecoration(
          color: isActive ? ColorTokens.main.withValues(alpha: 0.2)
              : context.themeColors.textPrimaryWithAlpha(0.08),
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(color: isActive ? ColorTokens.main
              : context.themeColors.textPrimaryWithAlpha(0.20)),
        ),
        child: Text(label, style: AppTypography.bodyMd.copyWith(
          color: isActive ? ColorTokens.main : context.themeColors.textPrimaryWithAlpha(0.7),
          fontWeight: isActive ? AppTypography.weightSemiBold : AppTypography.weightRegular,
        )),
      ),
    );
  }
}

/// 날짜 선택 행
class DatePickerRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const DatePickerRow({super.key, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTypography.captionLg
            .copyWith(color: context.themeColors.textPrimaryWithAlpha(0.70))),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.inputPadding),
          decoration: BoxDecoration(
            color: context.themeColors.overlayLight,
            borderRadius: BorderRadius.circular(AppRadius.input),
            border: Border.all(color: context.themeColors.textPrimaryWithAlpha(0.20)),
          ),
          child: Row(children: [
            Expanded(child: Text(value, style: AppTypography.bodyLg
                .copyWith(color: context.themeColors.textPrimary))),
            Icon(Icons.calendar_today_rounded, size: AppLayout.iconMd,
                color: context.themeColors.textPrimaryWithAlpha(0.55)),
          ]),
        ),
      ]),
    );
  }
}

/// 시험 있음 토글
class ExamToggle extends StatelessWidget {
  final bool hasExam;
  final ValueChanged<bool> onChanged;
  const ExamToggle({super.key, required this.hasExam, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text('시험 있음', style: AppTypography.bodyMd
          .copyWith(color: context.themeColors.textPrimary)),
      const Spacer(),
      Switch(value: hasExam, onChanged: onChanged,
          activeTrackColor: ColorTokens.main.withValues(alpha: 0.5),
          activeThumbColor: ColorTokens.main),
    ]);
  }
}
