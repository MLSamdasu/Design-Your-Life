// C0.CalSync: Google Calendar 동기화 Riverpod Provider
// GoogleCalendarService 인스턴스와 동기화 상태를 관리한다.
// 설정 화면의 연동 토글과 캘린더 화면의 이벤트 병합에 사용한다.
// Google 이벤트는 메모리에서만 관리하며 서버에 저장하지 않는다.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../features/calendar/providers/calendar_provider.dart';
import '../../features/calendar/providers/event_provider.dart';
import '../../features/timer/models/timer_log.dart';
import '../../shared/models/event.dart' show EventType;
import '../../shared/models/habit_log.dart';
import '../../shared/models/routine.dart';
import '../error/error_handler.dart';
import '../providers/data_store_providers.dart';
import '../utils/date_utils.dart';
import '../auth/auth_provider.dart';
import '../providers/global_providers.dart';
import 'google_calendar_service.dart';
import 'google_event_mapper.dart';

// ─── GoogleSignIn Provider ─────────────────────────────────────────────────

/// GoogleSignIn 인스턴스 Provider (AuthService 인스턴스를 공유)
/// 별도 인스턴스를 생성하면 토큰/스코프 불일치가 발생할 수 있으므로
/// AuthService가 관리하는 단일 GoogleSignIn 인스턴스를 재사용한다
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.googleSignIn;
});

// ─── GoogleCalendarService Provider ────────────────────────────────────────

/// Google Calendar 서비스 Provider
/// googleSignInProvider의 GoogleSignIn 인스턴스를 주입받아 생성한다
final googleCalendarServiceProvider = Provider<GoogleCalendarService>((ref) {
  final googleSignIn = ref.watch(googleSignInProvider);
  return GoogleCalendarService(googleSignIn);
});

// ─── 동기화 설정 Provider ──────────────────────────────────────────────────

/// Google Calendar 연동 활성화 여부 Provider
/// Hive settingsBox의 'googleCalendarSync' 키에 저장/읽기한다.
/// 앱 재시작 후에도 설정이 유지된다.
final googleCalendarSyncEnabledProvider = StateProvider<bool>((ref) {
  final cacheService = ref.watch(hiveCacheServiceProvider);
  // Hive에서 이전 설정값을 읽어 초기값으로 사용한다
  return cacheService.readSetting<bool>('googleCalendarSync') ?? false;
});

// ─── 동기화 상태 Provider ──────────────────────────────────────────────────

/// Google Calendar 동기화 현재 상태 Provider
/// 연동 비활성화 시 notConnected, 활성화 시 connected를 초기 상태로 설정한다.
/// GoogleCalendarEventsProvider 실행 중에는 syncing으로, 실패 시 error로 변경된다.
final calendarSyncStatusProvider =
    StateProvider<CalendarSyncStatus>((ref) {
  final enabled = ref.watch(googleCalendarSyncEnabledProvider);
  // 연동이 꺼져 있으면 notConnected 상태로 초기화한다
  if (!enabled) return CalendarSyncStatus.notConnected;
  return CalendarSyncStatus.connected;
});

// ─── Google Calendar 이벤트 Provider ────────────────────────────────────────

/// Google Calendar 이벤트 Provider (월별 FutureProvider)
/// googleCalendarSyncEnabledProvider가 true이고 로그인된 상태일 때만 API를 호출한다.
/// focusedCalendarMonthProvider 변경 시 자동으로 재로드된다.
final googleCalendarEventsProvider =
    FutureProvider<List<CalendarEvent>>((ref) async {
  final enabled = ref.watch(googleCalendarSyncEnabledProvider);
  // 연동이 비활성화되어 있으면 빈 목록 반환 (API 호출 없음)
  if (!enabled) return const [];

  final authState = ref.watch(currentAuthStateProvider);
  // 로그인되지 않은 상태이면 빈 목록 반환
  if (!authState.isAuthenticated) return const [];

  final service = ref.watch(googleCalendarServiceProvider);
  final focusedMonth = ref.watch(focusedCalendarMonthProvider);

  try {
    // 동기화 진행 중 상태로 변경한다
    ref.read(calendarSyncStatusProvider.notifier).state =
        CalendarSyncStatus.syncing;

    // Google Calendar API 호출 → GoogleCalendarEvent 목록
    final googleEvents = await service.fetchEventsForMonth(focusedMonth);

    // GoogleCalendarEvent → CalendarEvent 변환 (순수 함수 매퍼 사용)
    final calendarEvents = GoogleEventMapper.toCalendarEvents(googleEvents);

    // 동기화 성공 상태로 변경한다
    ref.read(calendarSyncStatusProvider.notifier).state =
        CalendarSyncStatus.connected;

    return calendarEvents;
  } catch (e, stack) {
    // 동기화 실패 시 오류 상태로 변경하고 빈 목록 반환
    // 예외를 삼키지 않고 상태로 변환하여 UI에서 오류를 인지할 수 있게 한다
    // 에러 로그를 기록하여 프로덕션 환경에서도 원인 추적이 가능하도록 한다
    ErrorHandler.logServiceError('GoogleCalendarSync', e, stack);
    ref.read(calendarSyncStatusProvider.notifier).state =
        CalendarSyncStatus.error;
    return const [];
  }
});

// ─── 병합된 이벤트 Provider (일별) ──────────────────────────────────────────

/// 앱 이벤트 + Google Calendar 이벤트를 병합한 일별 Provider
/// DailyView에서 이 Provider를 watch하여 선택된 날짜의 모든 이벤트를 표시한다.
/// 시간순으로 정렬되며, 시간 없는 이벤트는 맨 뒤에 위치한다.
final mergedEventsForDayProvider = Provider<List<CalendarEvent>>((ref) {
  final appEvents = ref.watch(eventsForDayProvider);
  final googleEventsAsync = ref.watch(googleCalendarEventsProvider);
  final selectedDate = ref.watch(selectedCalendarDateProvider);
  // 타이머 세션을 타임라인에 표시하기 위해 추가한다
  final timerEvents = ref.watch(timerLogsForCalendarDayProvider);

  // Google 이벤트 로딩 실패 또는 비활성화 시 빈 목록 사용
  final googleEvents = googleEventsAsync.valueOrNull ?? const [];

  // 선택된 날짜에 해당하는 Google 이벤트만 필터링한다
  final filteredGoogleEvents = googleEvents.where((e) {
    final sameDay = e.startDate.year == selectedDate.year &&
        e.startDate.month == selectedDate.month &&
        e.startDate.day == selectedDate.day;
    // 범위 이벤트: 선택된 날짜가 시작~종료 범위 내에 있으면 포함한다
    if (e.endDate != null) {
      return !selectedDate.isBefore(e.startDate) &&
          !selectedDate.isAfter(e.endDate!);
    }
    return sameDay;
  }).toList();

  // 앱 이벤트 + Google 이벤트 + 타이머 세션을 병합하여 시간순으로 정렬한다
  final merged = [...appEvents, ...filteredGoogleEvents, ...timerEvents];
  merged.sort((a, b) {
    // 시간 없는 이벤트(종일)는 맨 뒤로 정렬 (hour=24 가정)
    final aTime = (a.startHour ?? 24) * 60 + (a.startMinute ?? 0);
    final bTime = (b.startHour ?? 24) * 60 + (b.startMinute ?? 0);
    return aTime.compareTo(bTime);
  });

  return merged;
});

// ─── 병합된 이벤트 Provider (월별) ──────────────────────────────────────────

/// 앱 이벤트 + Google Calendar 이벤트 + 타이머 세션을 병합한 월별 Provider
/// WeeklyView에서 주 단위로 이벤트를 필터링할 때 사용한다.
/// eventsForMonthProvider(앱+투두) + googleCalendarEventsProvider(Google)
/// + 타이머 세션(allTimerLogsRawProvider)을 합친다.
final mergedEventsForMonthProvider = Provider<List<CalendarEvent>>((ref) {
  // eventsForMonthProvider는 동기 Provider이므로 직접 사용한다
  final appEvents = ref.watch(eventsForMonthProvider);
  final googleEventsAsync = ref.watch(googleCalendarEventsProvider);
  final focusedMonth = ref.watch(focusedCalendarMonthProvider);
  final allTimerLogsRaw = ref.watch(allTimerLogsRawProvider);
  // Google 이벤트 (비활성화 또는 로딩 실패 시 빈 목록)
  final googleEvents = googleEventsAsync.valueOrNull ?? const [];

  // 타이머 세션을 CalendarEvent로 변환한다 (해당 월 + 집중 세션만)
  final monthStr =
      '${focusedMonth.year}-${focusedMonth.month.toString().padLeft(2, '0')}';
  final timerEvents = <CalendarEvent>[];
  for (final logMap in allTimerLogsRaw) {
    final log = TimerLog.fromMap(logMap);
    // 집중 세션만 표시한다 (휴식은 제외)
    if (log.type != TimerSessionType.focus) continue;
    // 해당 월의 로그만 필터링한다
    final logDateStr = log.startTime.toIso8601String();
    if (!logDateStr.startsWith(monthStr)) continue;

    final durationMinutes = log.durationSeconds ~/ 60;
    final endTotalMinutes =
        log.startTime.hour * 60 + log.startTime.minute + durationMinutes;
    final endHour = (endTotalMinutes ~/ 60).clamp(0, 23);
    final endMinute = endTotalMinutes % 60;

    timerEvents.add(CalendarEvent(
      id: 'timer_${log.id}',
      title: log.todoTitle ?? '집중 세션',
      startDate: DateTime(
        log.startTime.year,
        log.startTime.month,
        log.startTime.day,
      ),
      startHour: log.startTime.hour,
      startMinute: log.startTime.minute,
      endHour: endHour,
      endMinute: endMinute,
      colorIndex: 3, // 운동/건강 초록 계열 — 타이머 세션에 적합
      type: EventType.normal.name,
      source: 'timer',
    ));
  }

  // 병합하여 시간순으로 정렬한다
  final merged = [...appEvents, ...googleEvents, ...timerEvents];
  merged.sort((a, b) {
    // 시간 없는 이벤트(종일)는 맨 뒤로 정렬 (hour=24 가정)
    final aTime = (a.startHour ?? 24) * 60 + (a.startMinute ?? 0);
    final bTime = (b.startHour ?? 24) * 60 + (b.startMinute ?? 0);
    return aTime.compareTo(bTime);
  });

  return merged;
});

// ─── 병합된 날짜별 이벤트 유무 맵 Provider ─────────────────────────────────

/// 날짜별 이벤트 유무 맵 (앱 + Google 이벤트 병합)
/// MonthlyView에서 날짜 셀에 dot을 표시할 때 사용한다.
/// 앱 이벤트와 Google 이벤트 모두 dot을 표시한다.
final mergedEventsByDateMapProvider = Provider<Map<String, bool>>((ref) {
  // 앱 이벤트 날짜 맵 (기존 provider 재사용)
  final appMap = ref.watch(eventsByDateMapProvider);
  // Google 이벤트 목록
  final googleEventsAsync = ref.watch(googleCalendarEventsProvider);
  final googleEvents = googleEventsAsync.valueOrNull ?? const [];
  // 활성 루틴 목록 (월간 dot 표시용)
  final allRoutinesRaw = ref.watch(allRoutinesRawProvider);
  final focusedMonth = ref.watch(focusedCalendarMonthProvider);
  // 습관 로그 (완료된 날짜 dot 표시용)
  final allHabitLogsRaw = ref.watch(allHabitLogsRawProvider);

  // 앱 이벤트 맵을 기반으로 Google 이벤트 날짜를 추가한다
  // P1-9: 다중일 Google 이벤트의 중간 날짜에도 dot을 표시한다
  final merged = Map<String, bool>.from(appMap);
  for (final event in googleEvents) {
    final startDay = DateTime(
      event.startDate.year, event.startDate.month, event.startDate.day,
    );
    merged[AppDateUtils.toDateString(startDay)] = true;
    if (event.endDate != null) {
      final endDay = DateTime(
        event.endDate!.year, event.endDate!.month, event.endDate!.day,
      );
      var cursor = startDay.add(const Duration(days: 1));
      while (!cursor.isAfter(endDay)) {
        merged[AppDateUtils.toDateString(cursor)] = true;
        cursor = cursor.add(const Duration(days: 1));
      }
    }
  }

  // 활성 루틴의 해당 월 날짜를 추가한다
  final activeRoutines = allRoutinesRaw
      .map((map) => Routine.fromMap(map))
      .where((r) => r.isActive)
      .toList();

  if (activeRoutines.isNotEmpty) {
    // 포커스된 월의 모든 날짜를 순회하며 루틴 요일과 매칭한다
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final lastDay = DateTime(focusedMonth.year, focusedMonth.month + 1, 0);

    for (var day = firstDay;
        !day.isAfter(lastDay);
        day = day.add(const Duration(days: 1))) {
      final weekday = day.weekday;
      final hasRoutine =
          activeRoutines.any((r) => r.repeatDays.contains(weekday));
      if (hasRoutine) {
        final key = AppDateUtils.toDateString(day);
        merged[key] = true;
      }
    }
  }

  // 습관 로그(완료된 날짜)를 추가한다
  for (final logMap in allHabitLogsRaw) {
    final log = HabitLog.fromMap(logMap);
    if (log.isCompleted &&
        log.date.year == focusedMonth.year &&
        log.date.month == focusedMonth.month) {
      final logDateStr = AppDateUtils.toDateString(log.date);
      merged[logDateStr] = true;
    }
  }

  return merged;
});

// ─── 수동 동기화 액션 Provider ──────────────────────────────────────────────

/// 수동 동기화 버튼 클릭 시 호출하는 액션 Provider
/// googleCalendarEventsProvider를 강제 무효화하여 재로드를 트리거한다
final syncGoogleCalendarProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    // Provider 캐시를 무효화하면 다음 watch 시 API를 재호출한다
    ref.invalidate(googleCalendarEventsProvider);
  };
});
