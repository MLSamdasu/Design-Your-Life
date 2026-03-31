// F-Book: 북 캘린더 뷰 — 월별 캘린더 + 선택일 독서 체크리스트
// 캘린더 그리드에 독서 계획 점을 표시하고,
// 하단에 선택된 날짜의 독서 계획 체크리스트를 표시한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import '../../../../shared/widgets/bottom_scroll_spacer.dart';
import '../../models/reading_plan.dart';
import '../../providers/book_reading_provider.dart';
import 'book_calendar_grid.dart';
import 'reading_plan_item.dart';

/// 북 캘린더 뷰
class BookCalendarView extends ConsumerStatefulWidget {
  const BookCalendarView({super.key});

  @override
  ConsumerState<BookCalendarView> createState() =>
      _BookCalendarViewState();
}

class _BookCalendarViewState extends ConsumerState<BookCalendarView> {
  /// 현재 표시 중인 월
  late DateTime _focusedMonth;

  /// 선택된 날짜
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    // 선택된 날짜의 독서 계획을 조회한다
    final selectedPlans = ref.watch(
      selectedDayReadingPlansProvider(_selectedDay),
    );

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        // 월별 캘린더
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageHorizontal,
            ),
            child: GlassmorphicCard(
              child: Column(
                children: [
                  BookMonthHeader(
                    focusedMonth: _focusedMonth,
                    onPrevious: _goToPreviousMonth,
                    onNext: _goToNextMonth,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const BookWeekdayHeader(),
                  const SizedBox(height: AppSpacing.md),
                  BookCalendarGrid(
                    focusedMonth: _focusedMonth,
                    selectedDay: _selectedDay,
                    onDaySelected: (day) =>
                        setState(() => _selectedDay = day),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: AppSpacing.xl),
        ),
        // 선택 날짜의 독서 체크리스트
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageHorizontal,
            ),
            child: _SelectedDayReadingSection(
              selectedDay: _selectedDay,
              plans: selectedPlans,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: BottomScrollSpacer()),
      ],
    );
  }

  void _goToPreviousMonth() {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month - 1,
      );
    });
  }

  void _goToNextMonth() {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + 1,
      );
    });
  }
}

/// 선택 날짜의 독서 섹션
class _SelectedDayReadingSection extends StatelessWidget {
  final DateTime selectedDay;
  final List<ReadingPlan> plans;

  const _SelectedDayReadingSection({
    required this.selectedDay,
    required this.plans,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = AppDateUtils.toShortDate(selectedDay);
    final isToday = AppDateUtils.isToday(selectedDay);
    final headerText = isToday ? '오늘의 독서' : '$dateLabel 독서';

    return GlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headerText,
            style: AppTypography.titleMd.copyWith(
              color: context.themeColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (plans.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  isToday ? '오늘 읽을 책이 없어요' : '이 날 독서 계획이 없어요',
                  style: AppTypography.bodyMd.copyWith(
                    color: context.themeColors
                        .textPrimaryWithAlpha(0.55),
                  ),
                ),
              ),
            )
          else
            ...plans.map(
              (plan) => Padding(
                padding: const EdgeInsets.only(
                  bottom: AppSpacing.md,
                ),
                child: ReadingPlanItem(plan: plan),
              ),
            ),
        ],
      ),
    );
  }
}
