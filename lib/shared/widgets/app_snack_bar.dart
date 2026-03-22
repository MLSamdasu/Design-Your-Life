// C0.5: 앱 공통 SnackBar 헬퍼
// 전체 앱에서 동일한 스타일의 SnackBar를 표시하기 위한 정적 유틸리티이다.
import 'package:flutter/material.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/typography_tokens.dart';
import '../../core/theme/spacing_tokens.dart';
import '../../core/theme/radius_tokens.dart';

/// 앱 전역 SnackBar 유틸리티
/// 일관된 스타일과 동작으로 SnackBar를 표시한다
abstract class AppSnackBar {
  /// 정보성 메시지 (초록 배경 — infoHintBg)
  static void showInfo(BuildContext context, String message) {
    _show(context, message, ColorTokens.infoHintBg);
  }

  /// 에러 메시지 (빨간 배경)
  static void showError(BuildContext context, String message) {
    _show(context, message, ColorTokens.error);
  }

  /// 성공 메시지 (초록 배경 — success)
  static void showSuccess(BuildContext context, String message) {
    _show(context, message, ColorTokens.success);
  }

  /// 경고 메시지 (어두운 주황 배경 — WCAG AA 대비율 준수)
  static void showWarning(BuildContext context, String message) {
    _show(context, message, ColorTokens.warningDark);
  }

  /// 공통 SnackBar 표시 로직
  /// 기존 SnackBar를 닫고 새로운 SnackBar를 플로팅 형태로 표시한다
  static void _show(
    BuildContext context,
    String message,
    Color backgroundColor, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: AppTypography.bodyMd.copyWith(color: ColorTokens.white),
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.lg,
          ),
          duration: duration,
        ),
      );
  }
}
