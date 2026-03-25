// F4 위젯: RoutineDialogHelpers - 루틴 다이얼로그 헬퍼 위젯/함수
// 다이얼로그 헤더 행, TimePicker 테마 빌더, 글래스모픽 다이얼로그 셸을 제공한다.
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 루틴 다이얼로그 헤더 행 (제목 + 닫기 버튼)
class RoutineDialogHeader extends StatelessWidget {
  /// true이면 '루틴 수정', false이면 '새 루틴 만들기' 제목을 표시한다
  final bool isEditMode;

  const RoutineDialogHeader({super.key, required this.isEditMode});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          isEditMode ? '루틴 수정' : '새 루틴 만들기',
          style: AppTypography.titleLg
              .copyWith(color: context.themeColors.textPrimary),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Icon(
            Icons.close_rounded,
            color: context.themeColors.textPrimaryWithAlpha(0.6),
            size: AppLayout.iconNav,
          ),
        ),
      ],
    );
  }
}

/// TimePicker 다이얼로그에 테마 인식 배경색을 적용하는 빌더
/// 어두운 배경 테마(Glassmorphism/Neon)에서도 가독성을 보장한다
Widget buildRoutinePickerTheme(BuildContext context, Widget? child) {
  final dialogBg = context.themeColors.dialogSurface;
  final isOnDark = context.themeColors.isOnDarkBackground;
  return Theme(
    data: (isOnDark ? ThemeData.dark() : ThemeData.light()).copyWith(
      colorScheme: (isOnDark
              ? const ColorScheme.dark(primary: ColorTokens.main)
              : const ColorScheme.light(primary: ColorTokens.main))
          .copyWith(surface: dialogBg),
    ),
    child: MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
      child: child!,
    ),
  );
}

/// 글래스모픽 다이얼로그 셸 — 블러 배경 + 반투명 컨테이너
/// 다이얼로그 공통 외곽 레이아웃을 재사용한다
class GlassmorphicDialogShell extends StatelessWidget {
  final Widget child;
  const GlassmorphicDialogShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final maxDialogHeight =
        MediaQuery.of(context).size.height * AppLayout.dialogMaxHeightRatio;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxDialogHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxxl,
            vertical: AppSpacing.huge,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.massive),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: EffectLayout.modalBlurSigma,
                sigmaY: EffectLayout.modalBlurSigma,
              ),
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xxxl),
                  decoration: BoxDecoration(
                    color: context.themeColors.textPrimaryWithAlpha(0.15),
                    borderRadius: BorderRadius.circular(AppRadius.massive),
                    border: Border.all(
                      color: context.themeColors.textPrimaryWithAlpha(0.25),
                    ),
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
