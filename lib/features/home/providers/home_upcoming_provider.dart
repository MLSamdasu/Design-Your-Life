// F1: 홈 대시보드 — 다가오는 일정 Provider
// 앱 이벤트 + 투두 + Google Calendar 이벤트를 통합하여
// 오늘의 아직 끝나지 않은 항목을 시간순으로 최대 5개 반환한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/data_store_providers.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/error/error_handler.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/models/event.dart';
import '../../../shared/models/calendar_event.dart';
import '../../calendar/sync/calendar_sync_provider.dart';
import 'home_models.dart';

/// 다가오는 일정 Provider (앱 이벤트 + 투두 + Google Calendar 이벤트)
final upcomingEventsProvider = Provider<List<UpcomingEventItem>>((ref) {
  final allEventsRaw = ref.watch(allEventsRawProvider);
  final allTodosRaw = ref.watch(allTodosRawProvider);
  final today = ref.watch(todayDateProvider);
  final now = DateTime.now();
  final dateStr = AppDateUtils.toDateString(today);

  try {
    final items = <_RawItem>[];

    // ─── 1. 앱 이벤트 ──────────────────────────────────────────────────
    _collectAppEvents(items, allEventsRaw, today, now);

    // ─── 2. 미완료 투두 ────────────────────────────────────────────────
    _collectTodos(items, allTodosRaw, dateStr, now);

    // ─── 3. Google Calendar 이벤트 ─────────────────────────────────────
    final gEvents = ref.watch(googleCalendarEventsProvider).valueOrNull;
    if (gEvents != null && gEvents.isNotEmpty) {
      _collectGoogleEvents(items, gEvents, today, now);
    }

    // ─── 4. 시간순 정렬 후 최대 5개 반환 ────────────────────────────────
    items.sort((a, b) => a.sortMin.compareTo(b.sortMin));
    return items.take(5).map((r) => UpcomingEventItem(
      id: r.id, title: r.title, timeLabel: r.time,
      colorIndex: r.color, isTodoEvent: r.isTodo,
      isGoogleEvent: r.isGoogle,
    )).toList();
  } catch (e, stack) {
    ErrorHandler.logServiceError('HomeProvider:upcomingEvents', e, stack);
    return const [];
  }
});

// ─── 앱 이벤트 수집 ──────────────────────────────────────────────────────

void _collectAppEvents(
  List<_RawItem> items, List<Map<String, dynamic>> raw,
  DateTime today, DateTime now,
) {
  for (final map in raw) {
    final ev = Event.fromMap(map);
    final d0 = AppDateUtils.startOfDay(ev.startDate);
    final d1 = ev.endDate != null ? AppDateUtils.startOfDay(ev.endDate!) : d0;
    if (d0 != today && !(d0.isBefore(today) && !d1.isBefore(today))) continue;

    if (ev.allDay) {
      items.add(_RawItem(ev.id, ev.title, '종일', ev.colorIndex, -1));
      continue;
    }
    final end = ev.endDate ?? ev.startDate;
    if (end.isBefore(now) && d0 == today) continue;

    items.add(_RawItem(ev.id, ev.title, _fmt(ev.startDate, end),
        ev.colorIndex, ev.startDate.hour * 60 + ev.startDate.minute));
  }
}

// ─── 투두 수집 ───────────────────────────────────────────────────────────

void _collectTodos(
  List<_RawItem> items, List<Map<String, dynamic>> raw,
  String dateStr, DateTime now,
) {
  final nowMin = now.hour * 60 + now.minute;
  for (final m in raw) {
    final sched = m['scheduled_date'] as String?;
    if (sched == null) continue;
    final dp = sched.length >= 10 ? sched.substring(0, 10) : sched;
    if (dp != dateStr || m['is_completed'] == true) continue;

    final title = m['title'] as String? ?? '';
    final id = m['id']?.toString() ?? '';
    final ci = int.tryParse(m['color'] as String? ?? '') ?? 0;
    final sRaw = m['start_time'] as String?;
    final eRaw = m['end_time'] as String?;

    if (sRaw == null) {
      items.add(_RawItem(id, title, '종일', ci, -1, isTodo: true));
      continue;
    }
    final sp = sRaw.split(':');
    final sH = int.tryParse(sp[0]) ?? 0;
    final sM = sp.length > 1 ? (int.tryParse(sp[1]) ?? 0) : 0;
    var eH = sH, eM = sM;
    if (eRaw != null) {
      final ep = eRaw.split(':');
      eH = int.tryParse(ep[0]) ?? sH;
      eM = ep.length > 1 ? (int.tryParse(ep[1]) ?? 0) : 0;
    }
    if (eRaw != null && (eH * 60 + eM) < nowMin) continue;

    final time = eRaw != null
        ? '${_p(sH)}:${_p(sM)} ~ ${_p(eH)}:${_p(eM)}'
        : '${_p(sH)}:${_p(sM)}';
    items.add(_RawItem(id, title, time, ci, sH * 60 + sM, isTodo: true));
  }
}

// ─── Google Calendar 이벤트 수집 ──────────────────────────────────────────

void _collectGoogleEvents(
  List<_RawItem> items, List<CalendarEvent> gEvents,
  DateTime today, DateTime now,
) {
  final nowMin = now.hour * 60 + now.minute;
  for (final e in gEvents) {
    final d0 = DateTime(e.startDate.year, e.startDate.month, e.startDate.day);
    final d1 = e.endDate != null
        ? DateTime(e.endDate!.year, e.endDate!.month, e.endDate!.day)
        : d0;
    if (d0 != today && !(d0.isBefore(today) && !d1.isBefore(today))) continue;

    if (e.isAllDay || (e.startHour == null && e.startMinute == null)) {
      items.add(_RawItem(e.id, e.title, '종일', e.colorIndex, -1, isGoogle: true));
      continue;
    }
    final eH = e.endHour ?? e.startHour ?? 0;
    final eM = e.endMinute ?? e.startMinute ?? 0;
    if ((eH * 60 + eM) < nowMin) continue;

    final sH = e.startHour ?? 0;
    final sM = e.startMinute ?? 0;
    items.add(_RawItem(e.id, e.title,
        '${_p(sH)}:${_p(sM)} ~ ${_p(eH)}:${_p(eM)}',
        e.colorIndex, sH * 60 + sM, isGoogle: true));
  }
}

// ─── 헬퍼 ────────────────────────────────────────────────────────────────

String _p(int v) => v.toString().padLeft(2, '0');

String _fmt(DateTime s, DateTime e) =>
    '${_p(s.hour)}:${_p(s.minute)} ~ ${_p(e.hour)}:${_p(e.minute)}';

/// 정렬용 내부 모델 (시간순 정렬 후 UpcomingEventItem으로 변환)
class _RawItem {
  final String id;
  final String title;
  final String time;
  final int color;
  final int sortMin;
  final bool isTodo;
  final bool isGoogle;

  const _RawItem(this.id, this.title, this.time, this.color, this.sortMin,
      {this.isTodo = false, this.isGoogle = false});
}
