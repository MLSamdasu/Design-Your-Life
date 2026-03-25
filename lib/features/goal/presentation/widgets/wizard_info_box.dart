// F5 위젯: WizardInfoBox - 위저드 각 단계 상단에 표시되는 안내 박스
// SRP 분리: 아이콘 + 설명 텍스트를 담은 안내 박스 UI만 담당한다.
import 'package:flutter/material.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 설명/안내 박스 위젯 (각 단계 상단에 표시)
class WizardInfoBox extends StatelessWidget {
  final IconData icon;
  final String text;

  const WizardInfoBox({required this.icon, required this.text, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.themeColors.textPrimaryWithAlpha(0.08),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: AppLayout.iconMd,
            color: context.themeColors.accent,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: AppTypography.captionMd.copyWith(
                color:
                    context.themeColors.textPrimaryWithAlpha(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
