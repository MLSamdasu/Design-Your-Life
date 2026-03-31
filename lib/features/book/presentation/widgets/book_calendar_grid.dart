// F-Book: 북 캘린더 그리드 위젯 — 월 헤더 + 요일 헤더 + 날짜 셀
// 독서 계획이 있는 날에 컬러 점을 표시한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/providers/data_store_providers.dart';
import '../../../../core/utils/date_utils.dart';

/// 월 네비게이션 헤더
class BookMonthHeader extends StatelessWidget {
  final DateTime focusedMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  const BookMonthHeader({super.key, required this.focusedMonth, required this.onPrevious, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      IconButton(onPressed: onPrevious,
          icon: Icon(Icons.chevron_left_rounded, color: context.themeColors.textPrimary)),
      Text('${focusedMonth.year}년 ${focusedMonth.month}월',
          style: AppTypography.titleLg.copyWith(color: context.themeColors.textPrimary)),
      IconButton(onPressed: onNext,
          icon: Icon(Icons.chevron_right_rounded, color: context.themeColors.textPrimary)),
    ]);
  }
}

/// 요일 헤더 (일~토)
class BookWeekdayHeader extends StatelessWidget {
  const BookWeekdayHeader({super.key});
  static const _days = ['일', '월', '화', '수', '목', '금', '토'];
  @override
  Widget build(BuildContext context) {
    return Row(children: _days.map((d) => Expanded(child: Center(
      child: Text(d, style: AppTypography.captionMd
          .copyWith(color: context.themeColors.textPrimaryWithAlpha(0.55))),
    ))).toList());
  }
}

/// 캘린더 날짜 그리드 (독서 계획 점 표시 포함)
class BookCalendarGrid extends ConsumerWidget {
  final DateTime focusedMonth;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  const BookCalendarGrid({super.key, required this.focusedMonth, required this.selectedDay, required this.onDaySelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawPlans = ref.watch(allReadingPlansRawProvider);
    final planDates = <String, _Info>{};
    for (final m in rawPlans) {
      final date = m['date'] as String?;
      if (date == null) continue;
      final info = planDates.putIfAbsent(date, () => _Info());
      info.total++;
      if (m['is_completed'] == true) info.done++;
    }

    final days = _genDays();
    return Column(children: List.generate(days.length ~/ 7, (wi) {
      return Row(children: List.generate(7, (di) {
        final day = days[wi * 7 + di];
        final cur = day.month == focusedMonth.month;
        final sel = _same(day, selectedDay);
        final today = _same(day, DateTime.now());
        final info = planDates[AppDateUtils.toDateString(day)];

        return Expanded(child: GestureDetector(
          onTap: () => onDaySelected(day),
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: AppLayout.minTouchTarget,
            decoration: sel ? BoxDecoration(
                color: ColorTokens.main.withValues(alpha: 0.2),
                shape: BoxShape.circle) : null,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('${day.day}', style: AppTypography.bodyMd.copyWith(
                color: !cur ? context.themeColors.textPrimaryWithAlpha(0.25)
                    : today ? ColorTokens.main : context.themeColors.textPrimary,
                fontWeight: today ? AppTypography.weightBold : AppTypography.weightRegular,
              )),
              if (info != null && cur) Container(
                width: AppSpacing.sm, height: AppSpacing.sm,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: info.allDone ? ColorTokens.success : ColorTokens.main,
                  shape: BoxShape.circle),
              ),
            ]),
          ),
        ));
      }));
    }));
  }

  List<DateTime> _genDays() {
    final first = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final offset = first.weekday % 7;
    final start = first.subtract(Duration(days: offset));
    return List.generate(42, (i) => start.add(Duration(days: i)));
  }

  bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _Info {
  int total = 0;
  int done = 0;
  bool get allDone => total > 0 && done == total;
}
