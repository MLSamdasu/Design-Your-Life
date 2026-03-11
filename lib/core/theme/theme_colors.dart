// C0.5: 테마 프리셋 색상 헬퍼 확장
// BuildContext에서 현재 테마 프리셋의 텍스트/아이콘/힌트 색상을 간편하게 접근한다.
// 하드코딩된 Colors.white 대신 이 확장을 통해 테마 인식 색상을 사용한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/global_providers.dart';
import 'color_tokens.dart';
import 'theme_preset_data.dart';

/// 현재 테마 프리셋의 해석된 색상 집합
/// isDark 여부에 따라 적절한 라이트/다크 색상을 자동으로 선택한다
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

  /// 투명도가 적용된 기본 텍스트 색상
  Color textPrimaryWithAlpha(double alpha) =>
      textPrimary.withValues(alpha: alpha);

  /// 투명도가 적용된 보조 텍스트 색상
  Color textSecondaryWithAlpha(double alpha) =>
      textSecondary.withValues(alpha: alpha);

  /// 아이콘 기본 색상 (텍스트 기본 색상과 동일)
  Color get iconColor => textPrimary;

  /// 비활성 아이콘 색상
  Color get iconInactive => textPrimary.withValues(alpha: 0.45);

  /// 힌트 텍스트 색상 (플레이스홀더)
  Color get hintColor => textPrimary.withValues(alpha: 0.40);

  /// 디바이더/구분선 색상
  Color get dividerColor => textPrimary.withValues(alpha: 0.15);

  /// 반투명 오버레이 배경 색상 (서브틀 카드 등)
  Color get overlayLight => textPrimary.withValues(alpha: 0.08);

  /// 중간 강도 오버레이 배경 색상
  Color get overlayMedium => textPrimary.withValues(alpha: 0.12);

  /// 강한 오버레이 배경 색상
  Color get overlayStrong => textPrimary.withValues(alpha: 0.20);

  /// 보더 색상 (연한)
  Color get borderLight => textPrimary.withValues(alpha: 0.15);

  /// 보더 색상 (중간)
  Color get borderMedium => textPrimary.withValues(alpha: 0.25);

  /// 보더 색상 (강한)
  Color get borderStrong => textPrimary.withValues(alpha: 0.35);

  /// 배경이 어두운(그라디언트/다크) 테마 여부를 판단한다.
  /// Glassmorphism/Neon 테마는 textPrimary가 흰색이므로 이를 기준으로 구분한다.
  bool get _isOnDarkBackground => textPrimary == Colors.white;

  /// 배경 위에서 보이는 악센트 색상 (테마 인식)
  /// Glassmorphism/Neon처럼 어두운/그라디언트 배경 → mainLight (#A78BFA, 밝은 보라)
  /// Minimal/Clean/Soft/Retro처럼 밝은 배경 → main (#7C3AED, 진한 보라)
  /// 진행률 바, 인디케이터, 선택 표시 등 전경 요소에 사용한다.
  Color get accent => _isOnDarkBackground ? ColorTokens.mainLight : ColorTokens.main;

  /// 악센트 색상에 투명도를 적용한다
  Color accentWithAlpha(double alpha) => accent.withValues(alpha: alpha);

  /// 다이얼로그/모달 배경 색상 (테마 인식)
  /// modalDecoration의 color를 추출하여 AlertDialog.backgroundColor에 사용한다.
  /// 각 테마별로 적절한 표면 색상을 반환하므로 텍스트 가독성이 보장된다.
  Color get dialogSurface =>
      presetData.modalDecoration().color ?? ColorTokens.gray800;
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
