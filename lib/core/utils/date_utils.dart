// C0.9: 날짜/시간 유틸리티 (순수 함수 집합)
// 날짜 포맷, 주차 계산, D-day 계산, 주간 범위 생성 등을 담당한다.
// 모든 저장은 UTC, 표시는 로컬 타임존으로 변환한다.
// 입력: DateTime / 출력: 포맷 문자열 또는 변환된 DateTime
import 'package:intl/intl.dart';

/// 날짜/시간 유틸리티 (C0.9)
/// 순수 함수 집합: 외부 상태에 의존하지 않는다
abstract class AppDateUtils {
  // ─── 포맷터 ──────────────────────────────────────────────────────────────
  /// yyyy-MM-dd 포맷터 (날짜 전용 필드)
  static final DateFormat _dateOnly = DateFormat('yyyy-MM-dd');

  /// yyyy년 M월 d일 포맷터 (한국어 표시용)
  static final DateFormat _koreanDate = DateFormat('yyyy년 M월 d일');

  /// M월 d일 포맷터 (짧은 표시용)
  static final DateFormat _shortDate = DateFormat('M월 d일');

  /// HH:mm 포맷터 (시간 표시용)
  static final DateFormat _time = DateFormat('HH:mm');

  /// E 포맷터 (요일 약자: 월, 화, 수 ...)
  static final DateFormat _weekday = DateFormat('E', 'ko_KR');

  // ─── 날짜 비교 ───────────────────────────────────────────────────────────
  /// 두 날짜가 같은 날인지 확인 (시간 무시)
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 오늘인지 확인
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  /// 과거 날짜인지 확인 (어제 이전)
  static bool isPast(DateTime date) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final dateStart = DateTime(date.year, date.month, date.day);
    return dateStart.isBefore(todayStart);
  }

  /// 미래 날짜인지 확인 (내일 이후)
  static bool isFuture(DateTime date) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final dateStart = DateTime(date.year, date.month, date.day);
    return dateStart.isAfter(todayStart);
  }

  // ─── D-day 계산 ──────────────────────────────────────────────────────────
  /// D-day 계산: 양수=미래, 음수=과거, 0=오늘
  /// 날짜만 비교 (시간 무시)
  static int dDayCount(DateTime targetDate) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final targetStart = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );
    return targetStart.difference(todayStart).inDays;
  }

  /// D-day 표시 문자열 반환 (예: "D-3", "D+2", "D-Day")
  static String dDayString(DateTime targetDate) {
    final days = dDayCount(targetDate);
    if (days == 0) return 'D-Day';
    if (days > 0) return 'D-$days';
    return 'D+${days.abs()}';
  }

  // ─── 주간 범위 ───────────────────────────────────────────────────────────
  /// 해당 날짜가 속한 주의 월요일 (주 시작일)
  static DateTime startOfWeek(DateTime date) {
    // Dart의 weekday: 1=월요일, 7=일요일
    final daysFromMonday = date.weekday - DateTime.monday;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  /// 해당 날짜가 속한 주의 일요일 (주 끝일)
  static DateTime endOfWeek(DateTime date) {
    final monday = startOfWeek(date);
    return monday.add(const Duration(days: 6));
  }

  /// 해당 주의 7일을 List로 반환 (월~일)
  static List<DateTime> weekDays(DateTime date) {
    final monday = startOfWeek(date);
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  // ─── 날짜 이동 ───────────────────────────────────────────────────────────
  /// 해당 날짜의 당월 1일
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// 해당 날짜의 당월 마지막 날
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// 해당 날짜의 자정 (00:00:00.000)
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // ─── 포맷 변환 ───────────────────────────────────────────────────────────
  /// yyyy-MM-dd 형식 문자열 반환 (API 전송용)
  static String toDateString(DateTime date) => _dateOnly.format(date);

  /// 한국어 날짜 문자열 반환 (예: "2026년 3월 9일")
  static String toKoreanDate(DateTime date) => _koreanDate.format(date.toLocal());

  /// 짧은 날짜 문자열 (예: "3월 9일")
  static String toShortDate(DateTime date) => _shortDate.format(date.toLocal());

  /// 시간 문자열 (예: "09:30")
  static String toTimeString(DateTime date) => _time.format(date.toLocal());

  /// 요일 약자 반환 (예: "월", "화")
  static String toWeekdayShort(DateTime date) => _weekday.format(date.toLocal());

  // ─── UTC 변환 ────────────────────────────────────────────────────────────
  /// 로컬 날짜를 UTC 자정으로 변환 (날짜 전용 저장 시 사용)
  static DateTime toUtcMidnight(DateTime localDate) {
    return DateTime.utc(localDate.year, localDate.month, localDate.day);
  }

  // ─── HabitLog ID 생성 ────────────────────────────────────────────────────
  /// HabitLog ID 생성 ({habitId}_{yyyy-MM-dd})
  static String habitLogId(String habitId, DateTime date) {
    final dateStr = toDateString(date);
    return '${habitId}_$dateStr';
  }
}
