// 공용 위젯: GlassInputDecoration (글래스 입력 필드 데코레이션 빌더)
// GlassInputField에서 사용하는 InputDecoration 생성 로직 (SRP 분리)
import 'package:flutter/material.dart';
import '../../core/theme/layout_tokens.dart';
import '../../core/theme/spacing_tokens.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/typography_tokens.dart';

/// GlassInputField용 InputDecoration을 빌드하는 헬퍼
/// 입력 필드의 장식(hint, icon, padding) 구성 책임을 분리한다
class GlassInputDecorationBuilder {
  const GlassInputDecorationBuilder._();

  /// GlassInputField에서 사용할 InputDecoration을 생성한다
  static InputDecoration build({
    required BuildContext context,
    String? hint,
    IconData? prefixIcon,
    IconData? suffixIcon,
    VoidCallback? onSuffixIconTap,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.bodyLg.copyWith(
        color: context.themeColors.hintColor,
      ),
      // Material 기본 border 제거 (커스텀 AnimatedContainer가 대체)
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lgXl,
      ),
      // 앞 아이콘 (선택)
      prefixIcon: prefixIcon != null
          ? Icon(
              prefixIcon,
              color: context.themeColors.textPrimaryWithAlpha(0.60),
              size: AppLayout.iconXl,
            )
          : null,
      // 뒤 아이콘 (선택, 탭 가능)
      suffixIcon: suffixIcon != null
          ? GestureDetector(
              onTap: onSuffixIconTap,
              child: Icon(
                suffixIcon,
                color: context.themeColors.textPrimaryWithAlpha(0.60),
                size: AppLayout.iconXl,
              ),
            )
          : null,
      // maxLength 카운터 숨김
      counterText: '',
    );
  }
}
