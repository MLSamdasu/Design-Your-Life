// 공용 위젯: DdayCard (D-Day 카드)
// D-day 숫자, 이벤트 제목, 날짜를 표시하는 카드 위젯
// D-3 이하(critical): 빨간색 강조 배경 적용 (AC-HM-05 수락 기준)
// design-system.md Subtle Card 스타일 사용 (radius-2xl: 16px)
import 'package:flutter/material.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/layout_tokens.dart';
import '../../core/theme/radius_tokens.dart';
import '../../core/theme/spacing_tokens.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/typography_tokens.dart';
import '../../shared/enums/urgency_level.dart';

/// D-Day 카드 위젯
/// 홈 대시보드 D-day 섹션의 수평 스크롤 카드로 사용한다
class DdayCard extends StatelessWidget {
  /// 이벤트 이름
  final String eventName;

  /// 남은 일수 (0 = D-Day, 양수 = D-n, 음수 = n일 지남)
  final int daysRemaining;

  /// 날짜 문자열 표시용 (예: "3월 15일")
  final String dateLabel;

  /// 긴급도 (critical: D-3 이하, warning: D-7 이하, normal: 그 외)
  final UrgencyLevel urgencyLevel;

  /// 탭 콜백 (선택)
  final VoidCallback? onTap;

  const DdayCard({
    super.key,
    required this.eventName,
    required this.daysRemaining,
    required this.dateLabel,
    required this.urgencyLevel,
    this.onTap,
  });

  /// D-day 표시 텍스트 ("D-3", "D-Day", "D+2")
  String get _ddayText {
    if (daysRemaining == 0) return 'D-Day';
    if (daysRemaining > 0) return 'D-$daysRemaining';
    return 'D+${daysRemaining.abs()}';
  }

  /// 긴급도에 따른 카드 배경색 (테마 인식)
  Color _cardBackground(ResolvedThemeColors tc) {
    switch (urgencyLevel) {
      case UrgencyLevel.critical:
        // D-3 이하: 빨간색 강조 (AC-HM-05)
        return ColorTokens.error.withValues(alpha: 0.25);
      case UrgencyLevel.warning:
        // D-7 이하: 경고 노란색
        return ColorTokens.warning.withValues(alpha: 0.20);
      case UrgencyLevel.normal:
        // 일반: 테마 텍스트 색상 기반 반투명 배경
        return tc.overlayLight;
    }
  }

  /// 긴급도에 따른 테두리 색상
  Color get _borderColor {
    switch (urgencyLevel) {
      case UrgencyLevel.critical:
        return ColorTokens.error.withValues(alpha: 0.40);
      case UrgencyLevel.warning:
        return ColorTokens.warning.withValues(alpha: 0.35);
      case UrgencyLevel.normal:
        return ColorTokens.transparent;
    }
  }

  /// D-day 숫자 색상 (테마 인식)
  Color _ddayColor(ResolvedThemeColors tc) {
    switch (urgencyLevel) {
      case UrgencyLevel.critical:
        return ColorTokens.errorLight;
      case UrgencyLevel.warning:
        return ColorTokens.warningLight;
      case UrgencyLevel.normal:
        return tc.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = context.themeColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // D-day 카드 최소 너비: 140px (mobile 기준)
        constraints: const BoxConstraints(minWidth: AppLayout.ddayCardMinWidth),
        padding: const EdgeInsets.all(AppSpacing.xl), // space-4
        decoration: BoxDecoration(
          color: _cardBackground(tc),
          borderRadius: BorderRadius.circular(AppRadius.xxl), // radius-2xl
          border: urgencyLevel != UrgencyLevel.normal
              ? Border.all(color: _borderColor, width: 1)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // D-day 숫자 (display-md: 28px, ExtraBold)
            Text(
              _ddayText,
              style: AppTypography.displayMd.copyWith(
                color: _ddayColor(tc),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // 이벤트 이름 (body-md: 13px, Medium)
            Text(
              eventName,
              style: AppTypography.bodyMd.copyWith(
                color: tc.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: AppSpacing.xs),

            // 날짜 (caption-md: 11px)
            Text(
              dateLabel,
              style: AppTypography.captionMd.copyWith(
                color: tc.textPrimaryWithAlpha(0.60),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
