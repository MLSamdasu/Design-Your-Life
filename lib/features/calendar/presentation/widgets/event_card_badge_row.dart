// F2 위젯: EventCardBadgeRow - 이벤트 카드 뱃지 영역
// 범위 태그 뱃지와 Google Calendar 출처 뱃지를 표시한다
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 이벤트 카드 중간 뱃지 영역
/// 범위 일정 태그와 Google Calendar 출처 뱃지를 표시한다
class EventCardBadgeRow extends StatelessWidget {
  /// 범위 태그 텍스트 (null이면 표시 안 함)
  final String? rangeTag;

  /// Google Calendar 이벤트 여부
  final bool isGoogleEvent;

  /// 카드 색상 (뱃지 배경에 사용)
  final Color cardColor;

  const EventCardBadgeRow({
    super.key,
    required this.rangeTag,
    required this.isGoogleEvent,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 이벤트 유형 뱃지 (범위 일정: 태그 표시)
          if (rangeTag != null) ...[
            const SizedBox(width: AppSpacing.md),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.40),
                  borderRadius: BorderRadius.circular(AppRadius.huge),
                ),
                child: Text(
                  rangeTag!,
                  style: AppTypography.captionMd.copyWith(
                    color: context.themeColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],

          // Google Calendar 출처 뱃지
          if (isGoogleEvent) ...[
            const SizedBox(width: AppSpacing.md),
            Container(
              width: AppLayout.checkboxMd,
              height: AppLayout.checkboxMd,
              decoration: BoxDecoration(
                color: ColorTokens.googleBrand.withValues(alpha: 0.30),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Center(
                child: Text(
                  'G',
                  style: AppTypography.captionMd.copyWith(
                    color: ColorTokens.googleBrand,
                    fontWeight: AppTypography.weightBold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
