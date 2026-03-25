// C0.CalSync: Google Calendar 동기화 상태 관리 Provider
// 동기화 활성화 여부, 동기화 상태, Google 이벤트 로딩, 수동 동기화 액션을 담당한다.
// Hive settingsBox에 연동 설정을 영속적으로 저장한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/calendar_event.dart';
import '../providers/calendar_provider.dart';
import '../../../core/error/error_handler.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/providers/global_providers.dart';
import 'google_calendar_service.dart';
import 'google_event_mapper.dart';
import 'google_sign_in_provider.dart';

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

// ─── 수동 동기화 액션 Provider ──────────────────────────────────────────────

/// 수동 동기화 버튼 클릭 시 호출하는 액션 Provider
/// googleCalendarEventsProvider를 강제 무효화하여 재로드를 트리거한다
final syncGoogleCalendarProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    // Provider 캐시를 무효화하면 다음 watch 시 API를 재호출한다
    ref.invalidate(googleCalendarEventsProvider);
  };
});
