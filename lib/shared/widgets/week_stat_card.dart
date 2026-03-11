// 공용 위젯: WeekStatCard (주간 통계 카드)
// 수치, 레이블, 진행률 바를 포함한 주간 요약 통계 카드
// design-system.md Subtle Card + radius-xl(14px) 스타일
import 'package:flutter/material.dart';
import '../../core/theme/layout_tokens.dart';
import '../../core/theme/radius_tokens.dart';
import '../../core/theme/spacing_tokens.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/typography_tokens.dart';

/// 주간 통계 카드 위젯
/// 홈 대시보드 주간 요약 섹션의 2열 그리드 카드로 사용한다
class WeekStatCard extends StatelessWidget {
  /// 수치 표시 값 (예: "75%", "5/7")
  final String value;

  /// 레이블 텍스트 (예: "투두 완료율", "습관 달성률")
  final String label;

  /// 진행률 (0.0~1.0), null이면 바 숨김
  final double? progress;

  /// 진행바 색상 (기본: 흰색)
  final Color? progressColor;

  /// 왼쪽 아이콘 (선택)
  final IconData? icon;

  const WeekStatCard({
    super.key,
    required this.value,
    required this.label,
    this.progress,
    this.progressColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl), // space-4 (16px)
      decoration: BoxDecoration(
        color: context.themeColors.overlayMedium,
        borderRadius: BorderRadius.circular(AppRadius.xlLg), // radius-xl (14px)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 아이콘 + 레이블 행
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: context.themeColors.textPrimaryWithAlpha(0.60),
                  size: AppLayout.iconMd, // icon-md (16px)
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.captionMd.copyWith(
                    color: context.themeColors.textPrimaryWithAlpha(0.60),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // 수치 (display-md: 28px, ExtraBold)
          Text(
            value,
            style: AppTypography.headingMd.copyWith(
              color: context.themeColors.textPrimary,
            ),
          ),

          // 진행률 바 (선택)
          if (progress != null) ...[
            const SizedBox(height: AppSpacing.mdLg),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                backgroundColor: context.themeColors.textPrimaryWithAlpha(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(
                  progressColor ?? context.themeColors.textPrimaryWithAlpha(0.80),
                ),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
