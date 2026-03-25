// F4 위젯: TimetableZoomToggle — 시간표 확대/축소 토글 버튼
import 'package:flutter/material.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';

/// 확대/축소 토글 버튼
class TimetableZoomToggle extends StatelessWidget {
  final bool isZoomed;
  final VoidCallback onToggle;

  const TimetableZoomToggle({
    required this.isZoomed,
    required this.onToggle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: context.themeColors.accentWithAlpha(isZoomed ? 0.5 : 0.25),
            borderRadius: BorderRadius.circular(AppRadius.huge),
            border: Border.all(
              color: context.themeColors.accentWithAlpha(0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isZoomed ? Icons.zoom_out_rounded : Icons.zoom_in_rounded,
                size: AppLayout.iconSm,
                color: context.themeColors.textPrimary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                isZoomed ? '축소' : '확대',
                style: AppTypography.captionLg.copyWith(
                  color: context.themeColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
