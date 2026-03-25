// F4 위젯: RoutineCardDeleteBackground - 루틴 카드 스와이프 삭제 배경
// Dismissible 삭제 방향 스와이프 시 표시되는 빨간 배경을 렌더링한다.
import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/theme_colors.dart';

/// 루틴 카드 스와이프 삭제 배경 위젯
class RoutineCardDeleteBackground extends StatelessWidget {
  const RoutineCardDeleteBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.xxl),
      decoration: BoxDecoration(
        color: ColorTokens.error.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      child: Icon(
        Icons.delete_rounded,
        color: context.themeColors.textPrimary,
        size: AppLayout.iconNav,
      ),
    );
  }
}
