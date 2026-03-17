// 공유 위젯: SegmentedControl<T>
// 투두/습관/목표 화면의 서브탭 스위처를 통일하는 Glass Pill 스타일 세그먼트 컨트롤이다.
// 기존 각 화면의 _SubTabSwitcher를 대체한다.
import 'dart:ui';
import 'package:flutter/material.dart';

import '../../core/theme/animation_tokens.dart';
import '../../core/theme/glassmorphism.dart';
import '../../core/theme/radius_tokens.dart';
import '../../core/theme/spacing_tokens.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/typography_tokens.dart';

/// 범용 세그먼트 컨트롤 위젯
/// Glass Pill 스타일로 서브탭 전환을 표시한다
class SegmentedControl<T> extends StatelessWidget {
  /// 표시할 값 목록
  final List<T> values;

  /// 현재 선택된 값
  final T selected;

  /// 각 값의 라벨 문자열을 반환하는 빌더
  final String Function(T) labelBuilder;

  /// 선택 변경 콜백
  final ValueChanged<T> onChanged;

  const SegmentedControl({
    super.key,
    required this.values,
    required this.selected,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: GlassDecoration.subtleBlurSigma,
          sigmaY: GlassDecoration.subtleBlurSigma,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: context.themeColors.textPrimaryWithAlpha(0.12),
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(
              color: context.themeColors.textPrimaryWithAlpha(0.15),
            ),
          ),
          child: Row(
            children: values.map((tab) {
              final isActive = tab == selected;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(tab),
                  child: AnimatedContainer(
                    duration: AppAnimation.standard,
                    curve: Curves.easeInOutCubic,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.mdLg,
                    ),
                    decoration: isActive
                        ? BoxDecoration(
                            color: context.themeColors
                                .textPrimaryWithAlpha(0.25),
                            borderRadius:
                                BorderRadius.circular(AppRadius.xl),
                          )
                        : null,
                    child: Center(
                      child: Text(
                        labelBuilder(tab),
                        style: AppTypography.bodyMd.copyWith(
                          color: isActive
                              ? context.themeColors.textPrimary
                              : context.themeColors
                                  .textPrimaryWithAlpha(0.55),
                          fontWeight: isActive
                              ? AppTypography.weightSemiBold
                              : AppTypography.weightRegular,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
