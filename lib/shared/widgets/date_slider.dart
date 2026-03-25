// 공용 위젯: DateSlider (주간 날짜 슬라이더)
// 투두 화면 상단의 좌우 스와이프로 날짜를 변경하는 주간 슬라이더.
// 선택된 날짜를 Riverpod selectedDateProvider로 관리한다.
import 'package:flutter/material.dart';
import '../../core/theme/layout_tokens.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/utils/date_utils.dart';
import 'date_item.dart';

export 'date_item.dart';

/// 주간 날짜 슬라이더 위젯
/// 현재 주(월~일) 7개 날짜를 수평으로 표시하고 탭/스와이프로 날짜를 선택한다
class DateSlider extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const DateSlider({
    required this.selectedDate,
    required this.onDateSelected,
    super.key,
  });

  @override
  State<DateSlider> createState() => _DateSliderState();
}

class _DateSliderState extends State<DateSlider> {
  late List<DateTime> _weekDays;
  late DateTime _focusedDate;

  @override
  void initState() {
    super.initState();
    _focusedDate = widget.selectedDate;
    _weekDays = AppDateUtils.weekDays(_focusedDate);
  }

  @override
  void didUpdateWidget(DateSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!AppDateUtils.isSameDay(oldWidget.selectedDate, widget.selectedDate)) {
      _focusedDate = widget.selectedDate;
      _weekDays = AppDateUtils.weekDays(_focusedDate);
    }
  }

  /// 이전 주로 이동한다
  void _previousWeek() {
    final prev = _focusedDate.subtract(const Duration(days: 7));
    setState(() {
      _focusedDate = prev;
      _weekDays = AppDateUtils.weekDays(_focusedDate);
    });
    // 이전 주 월요일을 선택한다
    widget.onDateSelected(_weekDays.first);
  }

  /// 다음 주로 이동한다
  void _nextWeek() {
    final next = _focusedDate.add(const Duration(days: 7));
    setState(() {
      _focusedDate = next;
      _weekDays = AppDateUtils.weekDays(_focusedDate);
    });
    widget.onDateSelected(_weekDays.first);
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return Row(
      children: [
        // 이전 주 버튼 (WCAG 2.1 기준 최소 터치 타겟 44x44px 적용)
        IconButton(
          icon: Icon(
            Icons.chevron_left_rounded,
            color: context.themeColors.textPrimaryWithAlpha(0.7),
          ),
          onPressed: _previousWeek,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: AppLayout.minTouchTarget, minHeight: AppLayout.minTouchTarget),
        ),
        // 날짜 아이템 7개
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _weekDays.map((date) {
              final isSelected =
                  AppDateUtils.isSameDay(date, widget.selectedDate);
              final isToday = AppDateUtils.isSameDay(date, today);
              return DateItem(
                date: date,
                isSelected: isSelected,
                isToday: isToday,
                onTap: () => widget.onDateSelected(date),
              );
            }).toList(),
          ),
        ),
        // 다음 주 버튼 (WCAG 2.1 기준 최소 터치 타겟 44x44px 적용)
        IconButton(
          icon: Icon(
            Icons.chevron_right_rounded,
            color: context.themeColors.textPrimaryWithAlpha(0.7),
          ),
          onPressed: _nextWeek,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: AppLayout.minTouchTarget, minHeight: AppLayout.minTouchTarget),
        ),
      ],
    );
  }
}
