// F6: 미니 카드 샘플 위젯
// 프리셋 카드 스타일을 미니어처로 보여주는 위젯이다.
// 각 프리셋의 카드 색상/보더/그림자를 축소하여 시각적으로 구분한다.
import 'package:flutter/material.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/theme_preset.dart';
import '../../../core/theme/radius_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/layout_tokens.dart';

/// 프리셋 카드 스타일을 미니어처로 보여주는 위젯
/// 각 프리셋의 카드 색상/보더/그림자를 축소하여 시각적으로 구분한다
class MiniCardSample extends StatelessWidget {
  /// 표시할 테마 프리셋
  final ThemePreset preset;

  const MiniCardSample({super.key, required this.preset});

  @override
  Widget build(BuildContext context) {
    // 프리셋별 미니 카드 색상/보더를 직접 정의한다 (미리보기 전용)
    final BoxDecoration decoration;
    switch (preset) {
      case ThemePreset.refinedGlass:
        // 반투명 흰색 + 흰색 보더 (밝은 글라스 효과)
        decoration = BoxDecoration(
          color: ColorTokens.white.withValues(alpha: 0.60),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: ColorTokens.white.withValues(alpha: 0.50),
            width: AppLayout.borderThin,
          ),
        );
      case ThemePreset.cleanMinimal:
        // 불투명 흰색 + 회색 보더 (깔끔한 미니멀)
        decoration = BoxDecoration(
          color: ColorTokens.white,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: ColorTokens.previewCleanBorder,
            width: AppLayout.borderThin,
          ),
        );
      case ThemePreset.darkGlass:
        // 반투명 다크 + MAIN 색상 네온 보더
        decoration = BoxDecoration(
          color: ColorTokens.previewDarkGlassBg.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: ColorTokens.main.withValues(alpha: 0.60),
            width: AppLayout.borderThin,
          ),
        );
    }

    // 미니 카드: 가로 막대 2줄로 카드 내용을 암시한다
    return Container(
      width: MiscLayout.miniCardWidth,
      height: MiscLayout.miniCardHeight,
      decoration: decoration,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 타이틀 줄 암시 (짧은 막대)
          Container(
            height: MiscLayout.miniLineHeightLg,
            width: MiscLayout.miniLineTitleWidth,
            decoration: BoxDecoration(
              color: _lineColor,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
          ),
          SizedBox(height: MiscLayout.miniLineHeightLg),
          // 본문 줄 암시 (긴 막대)
          Container(
            height: MiscLayout.miniLineHeightSm,
            width: MiscLayout.miniLineBodyWidth,
            decoration: BoxDecoration(
              color: _lineColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
          ),
        ],
      ),
    );
  }

  /// 프리셋별 미니 카드 내부 선 색상
  Color get _lineColor {
    switch (preset) {
      case ThemePreset.refinedGlass:
        return ColorTokens.gray800;
      case ThemePreset.cleanMinimal:
        return ColorTokens.previewCleanLine;
      case ThemePreset.darkGlass:
        return ColorTokens.white;
    }
  }
}
