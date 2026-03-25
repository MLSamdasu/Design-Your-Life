// F2 위젯: MonthlyView - 월간 캘린더 뷰 오케스트레이터
// 캘린더 그리드 + 드래그 핸들 + 이벤트/루틴/습관 목록을 조합한다
// 하위 위젯: MonthlyCalendarGrid, MonthlyDayContentList, RoutineInfoCard, HabitCheckItem
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../sync/calendar_sync_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/global_providers.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/event_provider.dart';
import '../../../habit/presentation/widgets/routine_edit_dialog.dart';
import '../../../habit/providers/routine_provider.dart';
import '../utils/event_dialog_utils.dart';
import '../../../../core/theme/radius_tokens.dart';
import 'monthly_calendar_grid.dart';
import 'monthly_day_content_list.dart';

/// 월간 캘린더 뷰
/// 캘린더 그리드, 드래그 핸들, 선택된 날짜의 콘텐츠 목록을 조합한다
class MonthlyView extends ConsumerStatefulWidget {
  const MonthlyView({super.key});

  @override
  ConsumerState<MonthlyView> createState() => _MonthlyViewState();
}

class _MonthlyViewState extends ConsumerState<MonthlyView> {
  /// 캘린더/리스트 비율 (0.3~0.7, 기본 0.5)
  double _calendarRatio = 0.5;

  /// 초기 비율 로드 완료 여부
  bool _ratioLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 최초 1회만 Hive에서 저장된 비율을 로드한다
    if (!_ratioLoaded) {
      final cache = ref.read(hiveCacheServiceProvider);
      _calendarRatio = cache.readSetting<double>(
            AppConstants.settingsKeyCalendarRatio,
          ) ??
          0.5;
      _ratioLoaded = true;
    }
  }

  /// 이벤트 편집 다이얼로그를 열고, 저장 후 목록을 갱신한다
  void _openEditDialog(BuildContext context, CalendarEvent calendarEvent) {
    // 투두/Google 이벤트는 편집 대상이 아니다
    if (calendarEvent.isTodoEvent || calendarEvent.isGoogleEvent) return;

    // 반복 이벤트 인스턴스 ID에서 원본 ID를 추출한다
    String baseEventId = calendarEvent.id;
    if (baseEventId.length > 36 && baseEventId.contains('_')) {
      final lastUnderscoreIdx = baseEventId.lastIndexOf('_');
      final candidate = baseEventId.substring(0, lastUnderscoreIdx);
      if (candidate.length == 36) {
        baseEventId = candidate;
      }
    }

    // Hive에서 원본 Event를 조회한다
    final repository = ref.read(eventRepositoryProvider);
    final event = repository.getEventById(baseEventId);
    if (event == null) return;

    showEventEditDialog(context: context, ref: ref, event: event);
  }

  /// 루틴 카드 탭 시 원본 Routine을 조회하여 편집 다이얼로그를 연다
  void _openRoutineEditDialog(RoutineEntry entry) {
    final routineRepo = ref.read(routineRepositoryProvider);
    final routines = routineRepo.getRoutines();
    final routine = routines.where((r) => r.id == entry.id).firstOrNull;
    if (routine == null) return;

    showRoutineEditDialog(context: context, ref: ref, routine: routine);
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final focusedMonth = ref.watch(focusedCalendarMonthProvider);
    // F17: 앱 이벤트 + Google Calendar 이벤트를 병합한 날짜 맵 사용
    final eventsByDate = ref.watch(mergedEventsByDateMapProvider);
    // F17: 선택된 날짜의 이벤트도 병합된 Provider 사용
    final selectedDayEvents = ref.watch(mergedEventsForDayProvider);
    // 선택된 날짜의 루틴 목록 (활성 루틴 중 해당 요일)
    final routines = ref.watch(routinesForDayProvider);
    // 선택된 날짜의 습관 체크리스트 데이터
    final habitsForDay = ref.watch(habitsForDayProvider);

    // 캘린더/리스트 flex 비율 계산
    final calendarFlex = (_calendarRatio * 100).round();
    final listFlex = ((1 - _calendarRatio) * 100).round();

    final hasContent = selectedDayEvents.isNotEmpty ||
        routines.isNotEmpty ||
        habitsForDay.isNotEmpty;

    return Column(
      children: [
        // 월간 캘린더 그리드
        Flexible(
          flex: calendarFlex,
          child: MonthlyCalendarGrid(
            selectedDate: selectedDate,
            focusedMonth: focusedMonth,
            eventsByDate: eventsByDate,
            onDaySelected: (selected, focused) {
              ref.read(selectedCalendarDateProvider.notifier).state =
                  DateTime(selected.year, selected.month, selected.day);
              ref.read(focusedCalendarMonthProvider.notifier).state = focused;
            },
            onPageChanged: (focused) {
              ref.read(focusedCalendarMonthProvider.notifier).state = focused;
            },
          ),
        ),

        // 드래그 핸들: 캘린더와 이벤트 목록 사이의 리사이즈 핸들
        _buildDragHandle(context),

        // 선택된 날짜의 이벤트 + 루틴 + 습관 목록
        if (hasContent)
          Flexible(
            flex: listFlex,
            child: MonthlyDayContentList(
              selectedDate: selectedDate,
              selectedDayEvents: selectedDayEvents,
              routines: routines,
              habitsForDay: habitsForDay,
              onEventTap: (event) => _openEditDialog(context, event),
              onRoutineTap: _openRoutineEditDialog,
            ),
          )
        else
          Flexible(
            flex: listFlex,
            child: Center(
              child: Text(
                '일정이 없습니다',
                // WCAG 최소 대비: 빈 상태 텍스트도 0.55 이상 보장
                style: AppTypography.bodyMd.copyWith(
                  color: context.themeColors.textPrimaryWithAlpha(0.55),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 드래그 핸들 위젯을 빌드한다
  Widget _buildDragHandle(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        final screenHeight = MediaQuery.of(context).size.height;
        final delta = details.primaryDelta! / screenHeight;
        setState(() {
          _calendarRatio = (_calendarRatio + delta).clamp(0.3, 0.7);
        });
      },
      onVerticalDragEnd: (_) {
        // 변경된 비율을 Hive에 저장한다
        ref.read(hiveCacheServiceProvider).saveSetting(
              AppConstants.settingsKeyCalendarRatio,
              _calendarRatio,
            );
      },
      child: Container(
        height: 24,
        alignment: Alignment.center,
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: context.themeColors.textPrimaryWithAlpha(0.25),
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
        ),
      ),
    );
  }
}
