// C0.5: 테마 프리셋 색상 헬퍼 확장
// BuildContext에서 현재 테마 프리셋의 텍스트/아이콘/힌트 색상을 간편하게 접근한다.
// 하드코딩된 ColorTokens.white 대신 이 확장을 통해 테마 인식 색상을 사용한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/global_providers.dart';
import 'color_tokens.dart';
import 'theme_preset_data.dart';

/// 현재 테마 프리셋의 해석된 색상 집합
/// isDark 여부에 따라 적절한 라이트/다크 색상을 자동으로 선택한다
/// 어두운 배경 테마(Glassmorphism/Neon)에서는 WCAG 고대비를 위해
/// alpha 값을 자동 보정한다
class ResolvedThemeColors {
  /// 해석 기반이 되는 프리셋 데이터
  final ThemePresetData presetData;

  /// 다크 모드 여부
  final bool isDark;

  const ResolvedThemeColors({
    required this.presetData,
    required this.isDark,
  });

  /// 기본 텍스트 색상 (제목, 주요 콘텐츠)
  Color get textPrimary => presetData.resolveTextPrimary(isDark: isDark);

  /// 보조 텍스트 색상 (캡션, 타임스탬프)
  Color get textSecondary => presetData.resolveTextSecondary(isDark: isDark);

  /// 어두운 배경 테마(Glassmorphism/Neon)에서 WCAG 고대비를 충족하도록
  /// alpha 값을 자동 보정한다.
  /// 밝은 배경 테마(Minimal/Clean/Soft/Retro)에서는 원래 값 그대로 사용한다.
  /// 보정 공식: alpha * 1.35 + 0.08 (최대 1.0)
  /// 예시: 0.40 → 0.62, 0.55 → 0.82, 0.65 → 0.96
  /// 어두운 배경에서 텍스트/아이콘이 더 선명하게 보이도록 보정 강도를 높였다
  double _contrastAlpha(double alpha) {
    if (!isOnDarkBackground) return alpha;
    if (alpha <= 0.0) return 0.0;
    if (alpha >= 0.80) return alpha;
    return (alpha * 1.35 + 0.08).clamp(0.0, 1.0);
  }

  /// 투명도가 적용된 기본 텍스트 색상
  /// 어두운 배경 테마에서는 고대비 보정이 자동 적용된다
  Color textPrimaryWithAlpha(double alpha) =>
      textPrimary.withValues(alpha: _contrastAlpha(alpha));

  /// 투명도가 적용된 보조 텍스트 색상
  /// 어두운 배경 테마에서는 고대비 보정이 자동 적용된다
  Color textSecondaryWithAlpha(double alpha) =>
      textSecondary.withValues(alpha: _contrastAlpha(alpha));

  /// 아이콘 기본 색상 (텍스트 기본 색상과 동일)
  Color get iconColor => textPrimary;

  /// 비활성 아이콘 색상 (WCAG 3:1 비텍스트 대비 준수)
  /// alpha 0.65: 파스텔 배경(Refined Glass)에서도 3:1 이상 보장
  Color get iconInactive => textPrimaryWithAlpha(0.65);

  /// 힌트 텍스트 색상 (플레이스홀더, WCAG 4.5:1 준수)
  /// alpha 0.65: 파스텔/흰 배경 모두에서 4.5:1 이상 보장
  Color get hintColor => textPrimaryWithAlpha(0.65);

  /// 디바이더/구분선 색상 (선명도 향상)
  Color get dividerColor => textPrimaryWithAlpha(0.20);

  /// 반투명 오버레이 배경 색상 (서브틀 카드 등, 선명도 향상)
  Color get overlayLight => textPrimaryWithAlpha(0.12);

  /// 중간 강도 오버레이 배경 색상 (선명도 향상)
  Color get overlayMedium => textPrimaryWithAlpha(0.18);

  /// 강한 오버레이 배경 색상 (선명도 향상)
  Color get overlayStrong => textPrimaryWithAlpha(0.28);

  /// 보더 색상 (연한, 선명도 향상)
  Color get borderLight => textPrimaryWithAlpha(0.20);

  /// 보더 색상 (중간, 선명도 향상)
  Color get borderMedium => textPrimaryWithAlpha(0.32);

  /// 보더 색상 (강한, 선명도 향상)
  Color get borderStrong => textPrimaryWithAlpha(0.45);

  /// 배경이 어두운(그라디언트/다크) 테마 여부를 판단한다.
  /// textPrimary의 밝기(luminance)를 기준으로 판단한다:
  /// luminance > 0.5 → 밝은 텍스트 = 어두운 배경 (Glassmorphism, Neon, + 모든 테마 다크 모드)
  /// luminance <= 0.5 → 어두운 텍스트 = 밝은 배경 (Minimal, Clean, Soft, Retro 라이트 모드)
  /// 기존 == ColorTokens.white 비교는 Glassmorphism/Neon만 감지했으므로
  /// 다크 모드의 gray50/F5EDE3 등 밝은 비-흰색 텍스트도 정확히 감지한다.
  bool get isOnDarkBackground => textPrimary.computeLuminance() > 0.5;

  /// 배경 위에서 보이는 악센트 색상 (테마 인식)
  /// Glassmorphism/Neon처럼 어두운/그라디언트 배경 → mainLight (#A78BFA, 밝은 보라)
  /// Minimal/Clean/Soft/Retro처럼 밝은 배경 → main (#7C3AED, 진한 보라)
  /// 진행률 바, 인디케이터, 선택 표시 등 전경 요소에 사용한다.
  Color get accent => isOnDarkBackground ? ColorTokens.mainLight : ColorTokens.main;

  /// 악센트 색상에 투명도를 적용한다
  Color accentWithAlpha(double alpha) => accent.withValues(alpha: alpha);

  /// AlertDialog 전용 배경 색상 (테마 인식, 고불투명)
  /// AlertDialog는 BackdropFilter 없이 단독 사용되므로 충분히 불투명해야 한다.
  /// 어두운 배경 테마: gray800 + alpha 0.95 (거의 불투명한 다크 서피스)
  /// 밝은 배경 테마: modalDecoration의 원래 색상 (이미 불투명)
  Color get dialogSurface {
    if (isOnDarkBackground) {
      return ColorTokens.gray800.withValues(alpha: 0.95);
    }
    return presetData.modalDecoration().color ?? ColorTokens.gray800;
  }
}

/// BuildContext 확장: 테마 프리셋 색상에 간편하게 접근한다
/// 사용법: context.themeColors.textPrimary
extension ThemeColorsExtension on BuildContext {
  /// 현재 테마 프리셋의 해석된 색상 집합을 반환한다
  /// ProviderScope에서 themePresetDataProvider와 isDarkModeProvider를 읽는다
  ResolvedThemeColors get themeColors {
    final container = ProviderScope.containerOf(this);
    final presetData = container.read(themePresetDataProvider);
    final isDark = container.read(isDarkModeProvider);
    return ResolvedThemeColors(presetData: presetData, isDark: isDark);
  }
}
