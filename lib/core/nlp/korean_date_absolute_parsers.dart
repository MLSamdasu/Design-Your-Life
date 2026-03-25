// C0.NLP: 절대 날짜 파싱 함수 (N월 D일, N일 단독, 마감 표현)
// 순수 함수: baseDate를 주입받아 절대적 날짜를 계산한다
// 입력: String (텍스트), DateTime (기준 날짜)
// 출력: DateParseResult? (파싱 결과)

import 'date_parse_result.dart';
import 'korean_date_patterns.dart';
import 'korean_date_relative_parsers.dart';

/// "N월 D일", "N월D일" 절대 날짜 파싱
/// 연도는 baseDate와 동일한 해를 사용한다
DateParseResult? parseAbsoluteDate(String text, DateTime baseDate) {
  final match = absoluteDatePattern.firstMatch(text);
  if (match == null) return null;

  final month = int.tryParse(match.group(1)!);
  final day = int.tryParse(match.group(2)!);

  // 유효하지 않은 월/일 값이면 무시한다
  if (month == null || day == null) return null;
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;

  var date = DateTime(baseDate.year, month, day);

  // Dart DateTime 자동 보정 방지: 입력한 월/일과 결과가 다르면 무효 처리
  // 예: 2월 31일 → DateTime이 3월 3일로 보정하는 것을 차단한다
  if (date.month != month || date.day != day) return null;

  // 과거 날짜이면 다음 해로 전환 (사용자는 미래 날짜를 의도할 가능성이 높다)
  final baseDay = DateTime(baseDate.year, baseDate.month, baseDate.day);
  if (date.isBefore(baseDay)) {
    date = DateTime(baseDate.year + 1, month, day);
    // 다음 해에서도 유효하지 않은 날짜면 무효 처리 (예: 윤년이 아닌 해의 2월 29일)
    if (date.month != month || date.day != day) return null;
  }

  return DateParseResult(
    date: date,
    matchStart: match.start,
    matchEnd: match.end,
  );
}

/// "~까지" 접미사 처리 (마감일 표현)
/// 예: "3월 15일까지 보고서 제출"
DateParseResult? parseDeadline(String text, DateTime baseDate) {
  final match = deadlinePattern.firstMatch(text);
  if (match == null) return null;

  // 내부 날짜 표현 추출
  final innerText = match.group(1)!;
  // 내부 날짜를 재귀적으로 파싱한다 (단, 마감 패턴 제외)
  // "15일까지" 같은 일 단독 마감도 지원하기 위해 parseDayOnlyInner를 포함한다
  final innerDate = parseAbsoluteDate(innerText, baseDate) ??
      parseRelativeDay(innerText, baseDate) ??
      parseWeekday(innerText, baseDate) ??
      parseDayOnlyInner(innerText, baseDate);

  if (innerDate == null) return null;

  // 매칭 범위는 "~까지"를 포함하여 반환한다
  return DateParseResult(
    date: innerDate.date,
    matchStart: match.start,
    matchEnd: match.end,
  );
}

/// "N일" 단독 파싱 (이번 달 특정 일)
/// 예: "15일" → 이번 달 15일
/// 가변 길이 lookbehind 대신 매칭 후 앞 문자열에 "월"이 포함되어 있으면 스킵한다.
DateParseResult? parseDayOnly(String text, DateTime baseDate) {
  // 절대 날짜(N월 D일)가 이미 매칭되지 않은 경우에만 처리한다
  // (절대 날짜가 있으면 이미 상위에서 처리됨)
  if (absoluteDatePattern.hasMatch(text)) return null;

  final match = dayOnlyPattern.firstMatch(text);
  if (match == null) return null;

  // 가변 길이 lookbehind를 대신하여 매칭 위치 앞 텍스트에 "월"이 있으면 건너뛴다.
  // "3월 15일" 형태에서 "15일"이 단독 매칭되는 것을 방지한다.
  if (match.start > 0) {
    final prefix = text.substring(0, match.start);
    // 앞에 "N월" 패턴이 있으면 절대 날짜의 일 부분이므로 무시한다
    if (RegExp(r'\d\s*월\s*$').hasMatch(prefix)) return null;
  }

  final day = int.tryParse(match.group(1)!);
  if (day == null || day < 1 || day > 31) return null;

  final date = DateTime(baseDate.year, baseDate.month, day);

  // Dart DateTime 자동 보정 방지: 해당 월에 존재하지 않는 날짜면 null을 반환한다
  // 예: 2월 31일 → DateTime이 3월 3일로 보정하는 것을 차단한다
  if (date.month != baseDate.month || date.day != day) return null;

  return DateParseResult(
    date: date,
    matchStart: match.start,
    matchEnd: match.end,
  );
}

/// 마감 패턴 내부에서 "N일" 단독 파싱을 수행한다
/// parseDayOnly와 달리 (?!까지) 제약 없이 "15일" 형태를 직접 파싱한다
DateParseResult? parseDayOnlyInner(String text, DateTime baseDate) {
  final match = RegExp(r'(\d{1,2})\s*일').firstMatch(text);
  if (match == null) return null;

  final day = int.tryParse(match.group(1)!);
  if (day == null || day < 1 || day > 31) return null;

  final date = DateTime(baseDate.year, baseDate.month, day);

  // Dart DateTime 자동 보정 방지: 해당 월에 존재하지 않는 날짜면 null을 반환한다
  if (date.month != baseDate.month || date.day != day) return null;

  return DateParseResult(
    date: date,
    matchStart: match.start,
    matchEnd: match.end,
  );
}
