// F2 위젯: EventCard - 캘린더 이벤트 표시 카드
// 색상 코딩 + 제목 + 시간을 표시하는 작은 카드 위젯
// Glass Subtle 스타일 (radius-lg: 12px)
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../providers/event_provider.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 이벤트 카드 위젯
class EventCard extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback? onTap;

  const EventCard({super.key, required this.event, this.onTap});

  /// 시간 포맷 (예: "14:30")
  String? _formatTime(int? hour, int? minute) {
    if (hour == null) return null;
    final h = hour.toString().padLeft(2, '0');
    final m = (minute ?? 0).toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final eventColor = ColorTokens.eventColor(event.colorIndex);
    final startTime = _formatTime(event.startHour, event.startMinute);
    final endTime = _formatTime(event.endHour, event.endMinute);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.mdLg),
        decoration: BoxDecoration(
          color: eventColor.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(AppRadius.xl), // radius-lg
          border: Border.all(
            color: eventColor.withValues(alpha: 0.40),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // 색상 인디케이터 바 (4px 너비)
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: eventColor,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
            ),
            const SizedBox(width: AppSpacing.mdLg),

            // 이벤트 제목 + 시간
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    event.title,
                    style: AppTypography.bodyMd.copyWith(color: context.themeColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (startTime != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      endTime != null ? '$startTime - $endTime' : startTime,
                      style: AppTypography.captionMd.copyWith(
                        color: context.themeColors.textPrimaryWithAlpha(0.60),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 이벤트 유형 뱃지 (범위 일정: 태그 표시)
            if (event.rangeTag != null) ...[
              const SizedBox(width: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: eventColor.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(AppRadius.huge),
                ),
                child: Text(
                  event.rangeTag!,
                  style: AppTypography.captionMd.copyWith(color: context.themeColors.textPrimary),
                ),
              ),
            ],

            // Google Calendar 출처 뱃지 (F17: source == 'google'인 이벤트에만 표시)
            if (event.isGoogleEvent) ...[
              const SizedBox(width: AppSpacing.md),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  // Google 브랜드 블루 30% 투명도 배경
                  color: ColorTokens.googleBrand.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Center(
                  child: Text(
                    'G',
                    style: TextStyle(
                      // Google 브랜드 블루
                      color: ColorTokens.googleBrand,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
