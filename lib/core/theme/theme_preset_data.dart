// C0.5: 테마 프리셋 시각 데이터 클래스
// 각 프리셋의 배경 그라디언트, 카드 데코레이션, 텍스트 색상, 블러 설정을 담는다.
// ColorTokens(MAIN/SUB)는 변경하지 않고 시각 처리만 프리셋별로 분기한다.
import 'package:flutter/material.dart';

/// 테마 프리셋별 시각 데이터 묶음
/// GlassDecoration/ColorTokens를 직접 수정하지 않고 프리셋 레이어에서 오버라이드한다
class ThemePresetData {
  /// 배경 그라디언트 (라이트 모드)
  final LinearGradient backgroundGradient;

  /// 배경 그라디언트 (다크 모드)
  final LinearGradient darkBackgroundGradient;

  /// 기본 카드 데코레이션 (GlassDecoration.defaultCard() 대체)
  final BoxDecoration Function() cardDecoration;

  /// 다크 모드 기본 카드 데코레이션
  final BoxDecoration Function() darkCardDecoration;

  /// 강조 카드 데코레이션 (GlassDecoration.elevatedCard() 대체)
  final BoxDecoration Function() elevatedCardDecoration;

  /// 다크 모드 강조 카드 데코레이션
  final BoxDecoration Function() darkElevatedCardDecoration;

  /// 보조 카드 데코레이션 (GlassDecoration.subtleCard() 대체)
  /// radius 파라미터를 통해 모서리 반경을 지정한다
  final BoxDecoration Function({double radius}) subtleCardDecoration;

  /// 모달 데코레이션 (GlassDecoration.modal() 대체)
  final BoxDecoration Function() modalDecoration;

  /// Bottom Nav 데코레이션 (라이트 모드)
  final BoxDecoration Function() bottomNavDecoration;

  /// Bottom Nav 데코레이션 (다크 모드)
  final BoxDecoration Function() darkBottomNavDecoration;

  /// 카드 블러 사용 여부 (false면 BackdropFilter 생략하여 성능 향상)
  final bool useBlur;

  /// 카드 블러 강도 (useBlur=true일 때만 유효)
  final double blurSigma;

  /// 기본 텍스트 색상 (라이트 모드)
  final Color textPrimary;

  /// 보조 텍스트 색상 (라이트 모드)
  final Color textSecondary;

  /// 기본 텍스트 색상 (다크 모드)
  final Color darkTextPrimary;

  /// 보조 텍스트 색상 (다크 모드)
  final Color darkTextSecondary;

  const ThemePresetData({
    required this.backgroundGradient,
    required this.darkBackgroundGradient,
    required this.cardDecoration,
    required this.darkCardDecoration,
    required this.elevatedCardDecoration,
    required this.darkElevatedCardDecoration,
    required this.subtleCardDecoration,
    required this.modalDecoration,
    required this.bottomNavDecoration,
    required this.darkBottomNavDecoration,
    required this.useBlur,
    required this.blurSigma,
    required this.textPrimary,
    required this.textSecondary,
    required this.darkTextPrimary,
    required this.darkTextSecondary,
  });

  /// isDarkMode에 따른 적절한 기본 카드 데코레이션을 반환한다
  BoxDecoration resolveCardDecoration({required bool isDark}) {
    return isDark ? darkCardDecoration() : cardDecoration();
  }

  /// isDarkMode에 따른 적절한 강조 카드 데코레이션을 반환한다
  BoxDecoration resolveElevatedDecoration({required bool isDark}) {
    return isDark ? darkElevatedCardDecoration() : elevatedCardDecoration();
  }

  /// isDarkMode에 따른 기본 텍스트 색상을 반환한다
  Color resolveTextPrimary({required bool isDark}) {
    return isDark ? darkTextPrimary : textPrimary;
  }

  /// isDarkMode에 따른 보조 텍스트 색상을 반환한다
  Color resolveTextSecondary({required bool isDark}) {
    return isDark ? darkTextSecondary : textSecondary;
  }
}
