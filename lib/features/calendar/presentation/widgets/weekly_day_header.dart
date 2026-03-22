// F2 위젯: WeeklyDayHeader - 주간 날짜 헤더 행 (SRP 분리)
// weekly_view.dart에서 추출한다.
// 요일 라벨 + 날짜 숫자(오늘/선택 강조)를 7일치 렌더링한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../providers/calendar_provider.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 주간 날짜 헤더 행
/// 요일 라벨(월~일) + 날짜 숫자를 표시하며 탭으로 날짜를 선택할 수 있다
class WeeklyDayHeader extends ConsumerWidget {
  final List<DateTime> weekDays;
  final DateTime selectedDate;
  final DateTime now;
  final double timeColumnWidth;
  /// 각 날짜별 습관 완료율 (선택적, 없으면 표시하지 않는다)
  final Map<DateTime, ({int completed, int total})>? habitCompletion;

  const WeeklyDayHeader({
    super.key,
    required this.weekDays,
    required this.selectedDate,
    required this.now,
    required this.timeColumnWidth,
    this.habitCompletion,
  });

  /// 요일 라벨 (짧은 형식)
  String _dayLabel(DateTime date) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    return labels[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: AppLayout.weeklyHeaderHeight,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.themeColors.textPrimaryWithAlpha(0.12),
            width: AppLayout.borderThin,
          ),
        ),
      ),
      child: Row(
        children: [
          // 시간 열 공백
          SizedBox(width: timeColumnWidth),

          // 7일 헤더
          ...weekDays.map((day) {
            final isToday = now.year == day.year &&
                now.month == day.month &&
                now.day == day.day;
            final isSelected = selectedDate.year == day.year &&
                selectedDate.month == day.month &&
                selectedDate.day == day.day;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  ref.read(selectedCalendarDateProvider.notifier).state =
                      DateTime(day.year, day.month, day.day);
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 요일 라벨
                    Text(
                      _dayLabel(day),
                      style: AppTypography.captionMd.copyWith(
                        // 오늘 날짜 요일 라벨은 배경 테마에 맞는 악센트 색상을 사용한다
                        color: isToday
                            ? context.themeColors.accent
                            : context.themeColors.textPrimaryWithAlpha(0.55),
                        fontWeight:
                            isToday ? AppTypography.weightSemiBold : AppTypography.weightRegular,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    // 날짜 숫자 (오늘/선택 표시)
                    Container(
                      width: AppLayout.iconHuge,
                      height: AppLayout.iconHuge,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // 선택된 날짜는 배경 테마에 맞는 악센트 색상 원으로 표시한다
                        color: isSelected
                            ? context.themeColors.accent
                            : isToday
                                ? context.themeColors.textPrimaryWithAlpha(0.25)
                                : ColorTokens.transparent,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${day.day}',
                        style: AppTypography.captionLg.copyWith(
                    color: context.themeColors.textPrimary,
                          fontWeight: isSelected || isToday
                              ? AppTypography.weightBold
                              : AppTypography.weightRegular,
                        ),
                      ),
                    ),
                    // 습관 완료율 표시 (있을 때만)
                    if (habitCompletion != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Builder(builder: (context) {
                        final dayKey = DateTime(day.year, day.month, day.day);
                        final data = habitCompletion![dayKey];
                        if (data == null || data.total == 0) {
                          return const SizedBox.shrink();
                        }
                        final allDone = data.completed == data.total;
                        return Text(
                          '${data.completed}/${data.total}',
                          style: AppTypography.captionSm.copyWith(
                            color: allDone
                                ? ColorTokens.success
                                : context.themeColors.textPrimaryWithAlpha(0.4),
                            fontWeight: allDone
                                ? AppTypography.weightSemiBold
                                : AppTypography.weightRegular,
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
