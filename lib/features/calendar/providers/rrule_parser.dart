// RRULE(반복 규칙) 파서
// 반복 이벤트의 RRULE을 파싱하여 해당 월 범위 내 발생 날짜 목록을 반환한다
// 지원 패턴: FREQ=DAILY, FREQ=WEEKLY;BYDAY=MO,WE,FR,
//           FREQ=MONTHLY;BYMONTHDAY=15, FREQ=YEARLY
import '../../../shared/models/event.dart';

/// 반복 이벤트의 RRULE을 파싱하여 해당 월 범위 내 발생 날짜 목록을 반환한다
List<DateTime> expandRecurringEvent(
  Event event,
  DateTime monthStart,
  DateTime monthEnd,
) {
  final rule = event.recurrenceRule;
  if (rule == null || rule.isEmpty) return [];

  // RRULE 파싱: 세미콜론으로 분리한 key=value 맵을 만든다
  final parts = rule.replaceFirst('RRULE:', '').split(';');
  final ruleMap = <String, String>{};
  for (final part in parts) {
    final kv = part.split('=');
    if (kv.length == 2) {
      ruleMap[kv[0].toUpperCase()] = kv[1].toUpperCase();
    }
  }

  final freq = ruleMap['FREQ'];
  if (freq == null) return [];

  // 이벤트 시작일 이전 날짜에는 인스턴스를 생성하지 않는다
  final eventStart = DateTime(
    event.startDate.year,
    event.startDate.month,
    event.startDate.day,
  );
  // 탐색 범위의 시작일은 이벤트 시작일과 월 시작일 중 늦은 날짜를 사용한다
  final rangeStart =
      eventStart.isAfter(monthStart) ? eventStart : monthStart;

  final occurrences = <DateTime>[];

  switch (freq) {
    case 'DAILY':
      _expandDaily(rangeStart, monthEnd, occurrences);
      break;
    case 'WEEKLY':
      _expandWeekly(ruleMap, rangeStart, monthEnd, occurrences);
      break;
    case 'MONTHLY':
      _expandMonthly(
        ruleMap, event, eventStart, monthStart, monthEnd, occurrences,
      );
      break;
    case 'YEARLY':
      _expandYearly(
        ruleMap, event, eventStart, monthStart, monthEnd, occurrences,
      );
      break;
  }

  return occurrences;
}

/// 매일 반복: 범위 내 모든 날짜를 추가한다
void _expandDaily(
  DateTime rangeStart,
  DateTime monthEnd,
  List<DateTime> occurrences,
) {
  var current = rangeStart;
  while (!current.isAfter(monthEnd)) {
    occurrences.add(current);
    current = current.add(const Duration(days: 1));
  }
}

/// 주간 반복: BYDAY에 지정된 요일만 추가한다
void _expandWeekly(
  Map<String, String> ruleMap,
  DateTime rangeStart,
  DateTime monthEnd,
  List<DateTime> occurrences,
) {
  final byDay = ruleMap['BYDAY'];
  if (byDay == null) return;

  // RRULE 요일 약어를 Dart weekday (1=월 ~ 7=일)로 변환한다
  const dayMap = {
    'MO': 1, 'TU': 2, 'WE': 3, 'TH': 4,
    'FR': 5, 'SA': 6, 'SU': 7,
  };
  final targetDays = byDay
      .split(',')
      .map((d) => dayMap[d.trim()])
      .whereType<int>()
      .toSet();

  if (targetDays.isEmpty) return;

  var current = rangeStart;
  while (!current.isAfter(monthEnd)) {
    if (targetDays.contains(current.weekday)) {
      occurrences.add(current);
    }
    current = current.add(const Duration(days: 1));
  }
}

/// 월간 반복: BYMONTHDAY에 지정된 날짜를 추가한다
void _expandMonthly(
  Map<String, String> ruleMap,
  Event event,
  DateTime eventStart,
  DateTime monthStart,
  DateTime monthEnd,
  List<DateTime> occurrences,
) {
  final byMonthDay = ruleMap['BYMONTHDAY'];
  if (byMonthDay == null) {
    // BYMONTHDAY가 없으면 이벤트 시작일의 day를 사용한다
    final day = event.startDate.day;
    final lastDayOfMonth =
        DateTime(monthStart.year, monthStart.month + 1, 0).day;
    if (day <= lastDayOfMonth) {
      final candidate =
          DateTime(monthStart.year, monthStart.month, day);
      if (!candidate.isBefore(eventStart) &&
          !candidate.isAfter(monthEnd)) {
        occurrences.add(candidate);
      }
    }
  } else {
    // BYMONTHDAY 파싱 (쉼표로 여러 날짜 지정 가능)
    final days = byMonthDay
        .split(',')
        .map((d) => int.tryParse(d.trim()))
        .whereType<int>();
    final lastDayOfMonth =
        DateTime(monthStart.year, monthStart.month + 1, 0).day;
    for (final day in days) {
      if (day >= 1 && day <= lastDayOfMonth) {
        final candidate =
            DateTime(monthStart.year, monthStart.month, day);
        if (!candidate.isBefore(eventStart) &&
            !candidate.isAfter(monthEnd)) {
          occurrences.add(candidate);
        }
      }
    }
  }
}

/// 연간 반복: 매년 시작일과 동일한 월/일에 발생한다
void _expandYearly(
  Map<String, String> ruleMap,
  Event event,
  DateTime eventStart,
  DateTime monthStart,
  DateTime monthEnd,
  List<DateTime> occurrences,
) {
  final byMonth = ruleMap['BYMONTH'];
  final byMonthDayY = ruleMap['BYMONTHDAY'];
  final targetMonth = byMonth != null
      ? int.tryParse(byMonth) ?? event.startDate.month
      : event.startDate.month;
  final targetDay = byMonthDayY != null
      ? int.tryParse(byMonthDayY) ?? event.startDate.day
      : event.startDate.day;

  // 현재 표시 중인 월이 대상 월과 일치하는지 확인한다
  if (monthStart.month == targetMonth) {
    final lastDayOfMonth =
        DateTime(monthStart.year, monthStart.month + 1, 0).day;
    if (targetDay >= 1 && targetDay <= lastDayOfMonth) {
      final candidate =
          DateTime(monthStart.year, targetMonth, targetDay);
      if (!candidate.isBefore(eventStart) &&
          !candidate.isAfter(monthEnd)) {
        occurrences.add(candidate);
      }
    }
  }
}
