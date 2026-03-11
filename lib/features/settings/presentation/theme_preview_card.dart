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
    ThemePreset.glassmorphism: '글래스모피즘',
    ThemePreset.minimal: '미니멀',
    ThemePreset.retro: '레트로',
    ThemePreset.neon: '네온',
    ThemePreset.clean: '깔끔한',
    ThemePreset.soft: '부드러운',
  };

  // ─── 프리셋 설명 매핑 ────────────────────────────────────────────────────
  static const Map<ThemePreset, String> _presetDescriptions = {
    ThemePreset.glassmorphism: '유리 효과',
    ThemePreset.minimal: '플랫 디자인',
    ThemePreset.retro: '크림 톤',
    ThemePreset.neon: '네온 글로우',
    ThemePreset.clean: '클린 블루',
    ThemePreset.soft: '소프트 파스텔',
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
                : Colors.white.withValues(alpha: 0.15),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    // 선택된 카드에 배경 테마 악센트 색상 글로우 효과를 적용한다
                    color: context.themeColors.accentWithAlpha(0.30),
                    blurRadius: 8,
                    spreadRadius: -2,
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
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    // 텍스트 가독성을 위한 반투명 오버레이
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.45),
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
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        description,
                        style: AppTypography.captionSm.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
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
                    width: 20,
                    height: 20,
                    // 선택 체크마크 배경: 배경 테마에 맞는 악센트 색상을 사용한다
                    decoration: BoxDecoration(
                      color: context.themeColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 13,
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
      case ThemePreset.glassmorphism:
        // 반투명 흰색 + 흰색 보더
        decoration = BoxDecoration(
          color: Colors.white.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 1,
          ),
        );
      case ThemePreset.minimal:
        // 불투명 흰색 + 회색 보더 + 미세 그림자
        decoration = BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: ColorTokens.gray200,
            width: 1,
          ),
        );
      case ThemePreset.retro:
        // 크림색 + 두꺼운 크림 보더
        decoration = BoxDecoration(
          color: const Color(0xFFFFFCF7),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: const Color(0xFFE8DFD0),
            width: 1.5,
          ),
        );
      case ThemePreset.neon:
        // 반투명 다크 + MAIN 색상 네온 보더
        decoration = BoxDecoration(
          color: const Color(0xFF1C1530).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: ColorTokens.main.withValues(alpha: 0.60),
            width: 1,
          ),
        );
      case ThemePreset.clean:
        // 순백 배경 + 얇은 보더 (깔끔한 테마 미리보기)
        decoration = BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: const Color(0xFFE8ECF0),
            width: 1,
          ),
        );
      case ThemePreset.soft:
        // 아이보리 배경 + 소프트 보더 (부드러운 테마 미리보기)
        decoration = BoxDecoration(
          color: const Color(0xFFFFFDF9),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: const Color(0xFFF0E6D8),
            width: 1,
          ),
        );
    }

    // 미니 카드: 가로 막대 2줄로 카드 내용을 암시한다
    return Container(
      width: 50,
      height: 28,
      decoration: decoration,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 타이틀 줄 암시 (짧은 막대)
          Container(
            height: 3,
            width: 24,
            decoration: BoxDecoration(
              color: _lineColor,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
          ),
          const SizedBox(height: 3),
          // 본문 줄 암시 (긴 막대)
          Container(
            height: 2,
            width: 36,
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
      case ThemePreset.glassmorphism:
        return Colors.white;
      case ThemePreset.minimal:
        return ColorTokens.gray800;
      case ThemePreset.retro:
        return const Color(0xFF4A3F33);
      case ThemePreset.neon:
        return Colors.white;
      case ThemePreset.clean:
        return const Color(0xFF1A1A2E);
      case ThemePreset.soft:
        return const Color(0xFF3D2C2E);
    }
  }
}
