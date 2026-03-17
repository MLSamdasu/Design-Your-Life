// F6: 테마 프리셋 미리보기 카드 위젯
// 개별 프리셋의 배경 그라디언트와 카드 스타일을 축소 표시한다.
// 선택 상태를 MAIN 보더 + 체크마크로 시각적으로 표시한다.
import 'package:flutter/material.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/theme_preset.dart';
import '../../../core/theme/theme_preset_registry.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/theme/animation_tokens.dart';
import '../../../core/theme/radius_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/layout_tokens.dart';

/// 테마 프리셋 미리보기 카드
/// 각 프리셋의 배경/카드 스타일을 미니어처로 시각화한다
class ThemePreviewCard extends StatelessWidget {
  /// 표시할 테마 프리셋
  final ThemePreset preset;

  /// 현재 선택 여부 (true: MAIN 색상 보더 + 체크마크 표시)
  final bool isSelected;

  /// 탭 시 호출되는 콜백
  final VoidCallback onTap;

  const ThemePreviewCard({
    super.key,
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  // ─── 프리셋 한국어 이름 매핑 ─────────────────────────────────────────────
  static const Map<ThemePreset, String> _presetNames = {
    ThemePreset.refinedGlass: '기본',
    ThemePreset.cleanMinimal: '깔끔함',
    ThemePreset.darkGlass: '다크',
  };

  // ─── 프리셋 설명 매핑 ────────────────────────────────────────────────────
  static const Map<ThemePreset, String> _presetDescriptions = {
    ThemePreset.refinedGlass: '글라스 효과',
    ThemePreset.cleanMinimal: '미니멀 디자인',
    ThemePreset.darkGlass: '다크 글라스',
  };

  @override
  Widget build(BuildContext context) {
    // 프리셋 데이터에서 배경 그라디언트를 가져온다 (라이트 모드 기준으로 표시)
    final presetData = ThemePresetRegistry.dataFor(preset);
    final name = _presetNames[preset] ?? preset.name;
    final description = _presetDescriptions[preset] ?? '';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppAnimation.normal,
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          // 미리보기 카드 외곽: 선택 시 MAIN 색상 보더, 미선택 시 투명 보더
          borderRadius: BorderRadius.circular(AppRadius.xl),
          // 선택된 테마 카드 보더: 배경 테마에 맞는 악센트 색상을 사용한다
          border: Border.all(
            color: isSelected
                ? context.themeColors.accent
                : ColorTokens.white.withValues(alpha: 0.15),
            width: isSelected ? AppLayout.borderThick : AppLayout.borderThin,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    // 선택된 카드에 배경 테마 악센트 색상 글로우 효과를 적용한다
                    color: context.themeColors.accentWithAlpha(0.30),
                    blurRadius: AppLayout.colorPickerShadowBlur,
                    spreadRadius: -AppLayout.gridCellSpacing,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lgXl),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 배경: 프리셋의 실제 배경 그라디언트를 표시한다
              Container(
                decoration: BoxDecoration(
                  gradient: presetData.backgroundGradient,
                ),
              ),

              // 미니 카드 샘플: 카드 스타일을 미니어처로 표시한다
              Center(
                child: _MiniCardSample(preset: preset),
              ),

              // 하단 텍스트 레이블 (그라디언트 오버레이 위에 표시)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    // 텍스트 가독성을 위한 반투명 오버레이
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        ColorTokens.black.withValues(alpha: 0.0),
                        ColorTokens.black.withValues(alpha: 0.45),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: AppTypography.captionLg.copyWith(
                          color: ColorTokens.white,
                          fontWeight: AppTypography.weightBold,
                        ),
                      ),
                      Text(
                        description,
                        style: AppTypography.captionSm.copyWith(
                          color: ColorTokens.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 선택 체크마크: 선택된 프리셋에만 표시한다
              if (isSelected)
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: Container(
                    width: AppLayout.checkboxMd,
                    height: AppLayout.checkboxMd,
                    // 선택 체크마크 배경: 배경 테마에 맞는 악센트 색상을 사용한다
                    decoration: BoxDecoration(
                      color: context.themeColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: ColorTokens.white,
                      size: AppLayout.iconCheckSm,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 미니 카드 샘플 ──────────────────────────────────────────────────────────

/// 프리셋 카드 스타일을 미니어처로 보여주는 내부 위젯
/// 각 프리셋의 카드 색상/보더/그림자를 축소하여 시각적으로 구분한다
class _MiniCardSample extends StatelessWidget {
  final ThemePreset preset;

  const _MiniCardSample({required this.preset});

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
      width: AppLayout.miniCardWidth,
      height: AppLayout.miniCardHeight,
      decoration: decoration,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 타이틀 줄 암시 (짧은 막대)
          Container(
            height: AppLayout.miniLineHeightLg,
            width: AppLayout.miniLineTitleWidth,
            decoration: BoxDecoration(
              color: _lineColor,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
          ),
          SizedBox(height: AppLayout.miniLineHeightLg),
          // 본문 줄 암시 (긴 막대)
          Container(
            height: AppLayout.miniLineHeightSm,
            width: AppLayout.miniLineBodyWidth,
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
