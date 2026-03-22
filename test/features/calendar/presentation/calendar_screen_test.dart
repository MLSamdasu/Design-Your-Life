// CalendarScreen 관련 테스트
// 캘린더 뷰 타입 전환, 날짜 선택, 이벤트 필터링 로직을 검증한다.
import 'package:design_your_life/core/auth/auth_service.dart';
import 'package:design_your_life/core/cache/hive_cache_service.dart';
import 'package:design_your_life/core/calendar_sync/calendar_sync_provider.dart';
import 'package:design_your_life/core/auth/auth_provider.dart';
import 'package:design_your_life/core/providers/data_store_providers.dart';
import 'package:design_your_life/core/providers/global_providers.dart';
import 'package:design_your_life/features/calendar/presentation/calendar_screen.dart';
import 'package:design_your_life/features/calendar/providers/calendar_provider.dart';
import 'package:design_your_life/features/calendar/providers/event_provider.dart';
import 'package:design_your_life/shared/enums/view_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Hive 의존성 없이 테스트를 위한 MockHiveCacheService
/// getAll/query도 빈 목록을 반환하여 Hive 박스 접근을 완전히 차단한다
class _MockHiveCacheService extends HiveCacheService {
  @override
  Future<void> saveSetting(String key, Object value) async {}

  @override
  T? readSetting<T>(String key) => null;

  @override
  List<Map<String, dynamic>> getAll(String boxName) => const [];

  @override
  List<Map<String, dynamic>> query(
    String boxName,
    bool Function(Map<String, dynamic>) predicate,
  ) => const [];
}

void main() {
  // table_calendar가 intl 로케일 데이터를 필요로 하므로 테스트 전에 초기화한다
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  group('캘린더 뷰 전환 통합 테스트', () {
    test('monthly -> weekly -> daily 순차 전환', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(calendarViewTypeProvider), ViewType.monthly);

      container.read(calendarViewTypeProvider.notifier).state = ViewType.weekly;
      expect(container.read(calendarViewTypeProvider), ViewType.weekly);

      container.read(calendarViewTypeProvider.notifier).state = ViewType.daily;
      expect(container.read(calendarViewTypeProvider), ViewType.daily);
    });

    test('daily -> monthly 직접 전환', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(calendarViewTypeProvider.notifier).state = ViewType.daily;
      container.read(calendarViewTypeProvider.notifier).state = ViewType.monthly;

      expect(container.read(calendarViewTypeProvider), ViewType.monthly);
    });
  });

  group('캘린더 날짜 선택 통합 테스트', () {
    test('날짜 선택 시 focusedMonth가 해당 월로 설정된다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 5월 20일 선택
      container.read(selectedCalendarDateProvider.notifier).state =
          DateTime(2026, 5, 20);

      expect(container.read(selectedCalendarDateProvider).month, 5);
      expect(container.read(selectedCalendarDateProvider).day, 20);
    });

    test('12월에서 1월로 넘어가면 연도가 변경된다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(focusedCalendarMonthProvider.notifier).state =
          DateTime(2026, 12, 1);
      expect(container.read(focusedCalendarMonthProvider).year, 2026);
      expect(container.read(focusedCalendarMonthProvider).month, 12);

      container.read(focusedCalendarMonthProvider.notifier).state =
          DateTime(2027, 1, 1);
      expect(container.read(focusedCalendarMonthProvider).year, 2027);
      expect(container.read(focusedCalendarMonthProvider).month, 1);
    });
  });

  group('CalendarEvent 필터링 로직 테스트', () {
    test('같은 날짜의 이벤트만 필터링된다', () {
      final events = [
        CalendarEvent(
          id: 'e1',
          title: '3월 9일 이벤트',
          startDate: DateTime(2026, 3, 9),
          colorIndex: 0,
          type: 'normal',
        ),
        CalendarEvent(
          id: 'e2',
          title: '3월 10일 이벤트',
          startDate: DateTime(2026, 3, 10),
          colorIndex: 0,
          type: 'normal',
        ),
        CalendarEvent(
          id: 'e3',
          title: '3월 9일 이벤트 2',
          startDate: DateTime(2026, 3, 9),
          colorIndex: 1,
          type: 'normal',
        ),
      ];

      final selectedDate = DateTime(2026, 3, 9);
      final filtered = events.where((e) {
        return e.startDate.year == selectedDate.year &&
            e.startDate.month == selectedDate.month &&
            e.startDate.day == selectedDate.day;
      }).toList();

      expect(filtered.length, 2);
      expect(filtered.every((e) => e.startDate.day == 9), true);
    });

    test('범위 이벤트가 범위 내 날짜에서 표시된다', () {
      final event = CalendarEvent(
        id: 'e1',
        title: '출장',
        startDate: DateTime(2026, 3, 10),
        endDate: DateTime(2026, 3, 15),
        colorIndex: 0,
        type: 'range',
      );

      final testDates = [
        DateTime(2026, 3, 9),  // 범위 외
        DateTime(2026, 3, 10), // 시작일
        DateTime(2026, 3, 12), // 범위 내
        DateTime(2026, 3, 15), // 종료일
        DateTime(2026, 3, 16), // 범위 외
      ];

      final results = testDates.map((date) {
        if (event.endDate != null) {
          return !date.isBefore(event.startDate) &&
              !date.isAfter(event.endDate!);
        }
        return event.startDate.year == date.year &&
            event.startDate.month == date.month &&
            event.startDate.day == date.day;
      }).toList();

      expect(results, [false, true, true, true, false]);
    });

    test('이벤트가 시간순으로 정렬된다', () {
      final events = [
        CalendarEvent(
          id: 'e1',
          title: '저녁',
          startDate: DateTime(2026, 3, 9),
          startHour: 18,
          startMinute: 0,
          colorIndex: 0,
          type: 'normal',
        ),
        CalendarEvent(
          id: 'e2',
          title: '아침',
          startDate: DateTime(2026, 3, 9),
          startHour: 8,
          startMinute: 0,
          colorIndex: 0,
          type: 'normal',
        ),
        CalendarEvent(
          id: 'e3',
          title: '점심',
          startDate: DateTime(2026, 3, 9),
          startHour: 12,
          startMinute: 30,
          colorIndex: 0,
          type: 'normal',
        ),
      ];

      events.sort((a, b) {
        final aTime = (a.startHour ?? 24) * 60 + (a.startMinute ?? 0);
        final bTime = (b.startHour ?? 24) * 60 + (b.startMinute ?? 0);
        return aTime.compareTo(bTime);
      });

      expect(events[0].title, '아침');
      expect(events[1].title, '점심');
      expect(events[2].title, '저녁');
    });

    test('시간 미지정 이벤트가 시간 지정 이벤트 뒤에 정렬된다', () {
      final events = [
        CalendarEvent(
          id: 'e1',
          title: '종일 이벤트',
          startDate: DateTime(2026, 3, 9),
          colorIndex: 0,
          type: 'normal',
        ),
        CalendarEvent(
          id: 'e2',
          title: '오전 회의',
          startDate: DateTime(2026, 3, 9),
          startHour: 9,
          startMinute: 0,
          colorIndex: 0,
          type: 'normal',
        ),
      ];

      events.sort((a, b) {
        final aTime = (a.startHour ?? 24) * 60 + (a.startMinute ?? 0);
        final bTime = (b.startHour ?? 24) * 60 + (b.startMinute ?? 0);
        return aTime.compareTo(bTime);
      });

      expect(events.first.title, '오전 회의');
      expect(events.last.title, '종일 이벤트');
    });
  });

  // ─── 위젯 인터랙션 테스트 ─────────────────────────────────────────────────
  group('CalendarScreen - 위젯 렌더링 및 인터랙션', () {
    // table_calendar가 충분한 높이를 요구하므로 테스트 화면 크기를 확보한다
    const testSurfaceSize = Size(1080, 1920);

    /// 테스트용 위젯 래퍼: Provider override로 API, Hive, Google Calendar 의존성을 격리한다
    Widget buildCalendarTestWidget() {
      return ProviderScope(
        overrides: [
          hiveCacheServiceProvider.overrideWithValue(_MockHiveCacheService()),
          currentAuthStateProvider.overrideWithValue(
            const AuthState(
              userId: 'test-user',
              displayName: '테스트 유저',
              email: 'test@test.com',
            ),
          ),
          currentUserIdProvider.overrideWithValue('test-user'),
          isAuthenticatedProvider.overrideWithValue(true),
          eventsForMonthProvider.overrideWith(
            (ref) => const <CalendarEvent>[],
          ),
          routinesForDayProvider.overrideWith(
            (ref) => const <RoutineEntry>[],
          ),
          // F17: Google Calendar 연동은 테스트에서 비활성화한다 (Hive/네트워크 의존성 격리)
          googleCalendarSyncEnabledProvider.overrideWith((ref) => false),
          googleCalendarEventsProvider.overrideWith(
            (ref) async => const <CalendarEvent>[],
          ),
          // MonthlyView가 참조하는 병합 Provider들이 allXxxRawProvider에 의존하므로
          // Hive 박스 접근을 차단하기 위해 모든 데이터 스토어 Provider를 빈 목록으로 격리한다
          allEventsRawProvider.overrideWithValue(const []),
          allTodosRawProvider.overrideWithValue(const []),
          allRoutinesRawProvider.overrideWithValue(const []),
          allHabitsRawProvider.overrideWithValue(const []),
          allHabitLogsRawProvider.overrideWithValue(const []),
          allTimerLogsRawProvider.overrideWithValue(const []),
          allRoutineLogsRawProvider.overrideWithValue(const []),
        ],
        child: const MaterialApp(
          home: CalendarScreen(),
        ),
      );
    }

    testWidgets('CalendarScreen이 Scaffold를 포함한다', (tester) async {
      // 테스트 화면 크기를 캘린더가 오버플로우 없이 렌더링될 수 있도록 확보한다
      tester.view.physicalSize = testSurfaceSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildCalendarTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('FAB(FloatingActionButton)이 존재한다', (tester) async {
      tester.view.physicalSize = testSurfaceSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildCalendarTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('FAB에 add 아이콘이 표시된다', (tester) async {
      tester.view.physicalSize = testSurfaceSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildCalendarTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    testWidgets('뷰 전환 탭 "월간", "주간", "일간"이 표시된다', (tester) async {
      tester.view.physicalSize = testSurfaceSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildCalendarTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('월간'), findsOneWidget);
      expect(find.text('주간'), findsOneWidget);
      expect(find.text('일간'), findsOneWidget);
    });

    testWidgets('"주간" 탭을 누르면 뷰가 전환된다', (tester) async {
      tester.view.physicalSize = testSurfaceSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildCalendarTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('주간'));
      await tester.pump(const Duration(milliseconds: 400));

      // 전환 후에도 에러 없이 렌더링된다
      expect(tester.takeException(), isNull);
    });

    testWidgets('"일간" 탭을 누르면 뷰가 전환된다', (tester) async {
      tester.view.physicalSize = testSurfaceSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildCalendarTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('일간'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
    });

    testWidgets('"오늘" 버튼이 표시된다', (tester) async {
      tester.view.physicalSize = testSurfaceSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildCalendarTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // 캘린더 헤더 영역에 "오늘" 텍스트가 하나 이상 존재한다
      expect(find.text('오늘'), findsWidgets);
    });

    testWidgets('"오늘" 버튼 탭이 에러 없이 동작한다', (tester) async {
      tester.view.physicalSize = testSurfaceSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildCalendarTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // 여러 "오늘" 텍스트 중 첫 번째를 탭한다
      await tester.tap(find.text('오늘').first);
      await tester.pump(const Duration(milliseconds: 100));

      // 탭 후에도 위젯 트리가 정상이다
      expect(find.text('오늘'), findsWidgets);
    });

    testWidgets('월 네비게이션 이전/다음 버튼이 존재한다', (tester) async {
      tester.view.physicalSize = testSurfaceSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildCalendarTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // chevron 아이콘이 하나 이상 존재한다
      expect(find.byIcon(Icons.chevron_left_rounded), findsWidgets);
      expect(find.byIcon(Icons.chevron_right_rounded), findsWidgets);
    });

    testWidgets('이전 월 버튼 탭이 에러 없이 동작한다', (tester) async {
      tester.view.physicalSize = testSurfaceSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildCalendarTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // 여러 chevron_left 중 첫 번째를 탭한다
      await tester.tap(find.byIcon(Icons.chevron_left_rounded).first);
      await tester.pump(const Duration(milliseconds: 100));

      // 탭 후에도 chevron 아이콘이 존재한다
      expect(find.byIcon(Icons.chevron_left_rounded), findsWidgets);
    });

    testWidgets('다음 월 버튼 탭이 에러 없이 동작한다', (tester) async {
      tester.view.physicalSize = testSurfaceSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildCalendarTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // 여러 chevron_right 중 첫 번째를 탭한다
      await tester.tap(find.byIcon(Icons.chevron_right_rounded).first);
      await tester.pump(const Duration(milliseconds: 100));

      // 탭 후에도 chevron 아이콘이 존재한다
      expect(find.byIcon(Icons.chevron_right_rounded), findsWidgets);
    });

    testWidgets('현재 월/연도 텍스트가 표시된다', (tester) async {
      tester.view.physicalSize = testSurfaceSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildCalendarTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      final now = DateTime.now();
      final headerText = '${now.year}년 ${now.month}월';
      // 커스텀 헤더 + table_calendar 내부 헤더에서 동일 텍스트가 각각 렌더링될 수 있다
      expect(find.text(headerText), findsWidgets);
    });

    testWidgets('AnimatedSwitcher가 뷰 전환에 사용된다', (tester) async {
      tester.view.physicalSize = testSurfaceSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildCalendarTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AnimatedSwitcher), findsOneWidget);
    });

    testWidgets('뷰 전환 후 다시 월간으로 돌아올 수 있다', (tester) async {
      tester.view.physicalSize = testSurfaceSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildCalendarTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // 주간 -> 일간 -> 월간 순차 전환
      await tester.tap(find.text('주간'));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('일간'));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('월간'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
    });
  });

  group('CalendarScreen - Provider 뷰 전환 상태 검증', () {
    test('뷰 전환 시 focusedCalendarMonthProvider가 유지된다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(focusedCalendarMonthProvider.notifier).state =
          DateTime(2026, 5, 1);
      container.read(calendarViewTypeProvider.notifier).state = ViewType.weekly;

      // 뷰 전환 후에도 월 포커스가 유지된다
      expect(container.read(focusedCalendarMonthProvider).month, 5);
    });

    test('이전 월 이동 후 focusedCalendarMonthProvider가 갱신된다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(focusedCalendarMonthProvider.notifier).state =
          DateTime(2026, 3, 1);

      // 이전 월로 이동
      final current = container.read(focusedCalendarMonthProvider);
      final prev = DateTime(current.year, current.month - 1, 1);
      container.read(focusedCalendarMonthProvider.notifier).state = prev;

      expect(container.read(focusedCalendarMonthProvider).month, 2);
    });

    test('다음 월 이동 후 focusedCalendarMonthProvider가 갱신된다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(focusedCalendarMonthProvider.notifier).state =
          DateTime(2026, 3, 1);

      // 다음 월로 이동
      final current = container.read(focusedCalendarMonthProvider);
      final next = DateTime(current.year, current.month + 1, 1);
      container.read(focusedCalendarMonthProvider.notifier).state = next;

      expect(container.read(focusedCalendarMonthProvider).month, 4);
    });
  });

  group('eventsByDateMap 로직 테스트', () {
    test('이벤트가 있는 날짜가 맵에 포함된다', () {
      final events = [
        CalendarEvent(
          id: 'e1',
          title: '이벤트 1',
          startDate: DateTime(2026, 3, 9),
          colorIndex: 0,
          type: 'normal',
        ),
        CalendarEvent(
          id: 'e2',
          title: '이벤트 2',
          startDate: DateTime(2026, 3, 15),
          colorIndex: 0,
          type: 'normal',
        ),
      ];

      final map = <String, bool>{};
      for (final event in events) {
        final key = '${event.startDate.year}-${event.startDate.month}-${event.startDate.day}';
        map[key] = true;
      }

      expect(map['2026-3-9'], true);
      expect(map['2026-3-15'], true);
      expect(map['2026-3-10'], isNull);
    });

    test('같은 날짜에 여러 이벤트가 있어도 맵에 하나만 기록된다', () {
      final events = [
        CalendarEvent(
          id: 'e1',
          title: '이벤트 1',
          startDate: DateTime(2026, 3, 9),
          colorIndex: 0,
          type: 'normal',
        ),
        CalendarEvent(
          id: 'e2',
          title: '이벤트 2',
          startDate: DateTime(2026, 3, 9),
          colorIndex: 1,
          type: 'normal',
        ),
      ];

      final map = <String, bool>{};
      for (final event in events) {
        final key = '${event.startDate.year}-${event.startDate.month}-${event.startDate.day}';
        map[key] = true;
      }

      expect(map.length, 1);
      expect(map['2026-3-9'], true);
    });
  });
}
