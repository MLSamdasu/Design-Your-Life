// 공용 위젯: DateSlider (주간 날짜 슬라이더)
// 투두 화면 상단의 좌우 스와이프로 날짜를 변경하는 주간 슬라이더.
// 선택된 날짜를 Riverpod selectedDateProvider로 관리한다.
import 'package:flutter/material.dart';
import '../../core/theme/animation_tokens.dart';
import '../../core/theme/layout_tokens.dart';
import '../../core/theme/radius_tokens.dart';
import '../../core/theme/spacing_tokens.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/typography_tokens.dart';
import '../../core/utils/date_utils.dart';

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
              return _DateItem(
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

/// 날짜 슬라이더 개별 날짜 아이템
class _DateItem extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  const _DateItem({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  static const List<String> _weekdayLabels = [
    '월', '화', '수', '목', '금', '토', '일'
  ];

  @override
  Widget build(BuildContext context) {
    // Dart weekday: 1=월 ~ 7=일
    final weekdayLabel = _weekdayLabels[date.weekday - 1];
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimation.normal,
        curve: Curves.easeInOutCubic,
        width: 36,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        // 선택된 날짜 캡슐: 배경 테마에 맞는 악센트 색상을 사용한다.
        // Glassmorphism/Neon에서는 밝은 보라(mainLight)로 표시해 가독성을 확보한다.
        decoration: isSelected
            ? BoxDecoration(
                color: context.themeColors.accent,
                borderRadius: BorderRadius.circular(AppRadius.xxl + 2),
                boxShadow: [
                  BoxShadow(
                    color: context.themeColors.accentWithAlpha(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 요일 텍스트
            Text(
              weekdayLabel,
              style: AppTypography.captionMd.copyWith(
                // 선택된 상태는 MAIN 컬러 배경 위이므로 흰색 유지
                color: isSelected
                    ? Colors.white
                    : context.themeColors.textPrimaryWithAlpha(0.6),
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            // 날짜 숫자
            Text(
              '${date.day}',
              style: AppTypography.bodyMd.copyWith(
                // 선택된 상태는 MAIN 컬러 배경 위이므로 흰색 유지
                color: isSelected
                    ? Colors.white
                    : isToday
                        ? context.themeColors.textPrimary
                        : context.themeColors.textPrimaryWithAlpha(0.7),
                fontWeight: isSelected || isToday
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
            ),
            // 오늘 표시 점: 배경 테마에 맞는 악센트 색상을 사용한다.
            // 보라 그라디언트 배경 위에서 진한 보라 점은 거의 안 보이므로 밝은 버전을 사용한다.
            if (isToday && !isSelected)
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.xxs),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: context.themeColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
