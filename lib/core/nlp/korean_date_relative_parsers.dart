// C0.NLP: 상대 날짜 파싱 함수 (오늘/내일/모레/글피 + 주 기반 요일)
// 순수 함수: baseDate를 주입받아 상대적 날짜를 계산한다
// 입력: String (텍스트), DateTime (기준 날짜)
// 출력: DateParseResult? (파싱 결과)

import 'date_parse_result.dart';
import 'korean_date_patterns.dart';

/// "오늘", "내일", "모레", "글피", "내일모레" 파싱
/// baseDate 기준으로 날짜를 계산한다
DateParseResult? parseRelativeDay(String text, DateTime baseDate) {
  final match = relativePattern.firstMatch(text);
  if (match == null) return null;

  final word = match.group(1)!;
  final DateTime date;

  switch (word) {
    case '오늘':
      date = DateTime(baseDate.year, baseDate.month, baseDate.day);
    case '내일모레':
      // "내일모레"는 "모레"와 같은 의미이므로 2일 후
      date = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
      ).add(const Duration(days: 2));
    case '내일':
      date = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
      ).add(const Duration(days: 1));
    case '모레':
      date = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
      ).add(const Duration(days: 2));
    case '글피':
      date = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
      ).add(const Duration(days: 3));
    default:
      return null;
  }

  return DateParseResult(
    date: date,
    matchStart: match.start,
    matchEnd: match.end,
  );
}

/// "이번주 X요일", "다음주 X요일", "다다음주 X요일" 파싱
/// baseDate 기준으로 해당 주의 특정 요일을 계산한다
DateParseResult? parseWeekday(String text, DateTime baseDate) {
  final match = weekdayPattern.firstMatch(text);
  if (match == null) return null;

  // 주 지정자 정규화 (공백 제거)
  final weekSpec = match.group(1)!.replaceAll(RegExp(r'\s+'), '');
  final dayStr = match.group(2)!;

  // 해당 주의 월요일 계산
  final todayWeekday = baseDate.weekday; // 1=월, 7=일
  final daysFromMonday = todayWeekday - DateTime.monday;
  final thisMonday = DateTime(
    baseDate.year,
    baseDate.month,
    baseDate.day - daysFromMonday,
  );

  // 주 오프셋 계산
  final int weekOffset;
  switch (weekSpec) {
    case '이번주':
      weekOffset = 0;
    case '다음주':
      weekOffset = 7;
    case '다다음주':
      weekOffset = 14;
    default:
      weekOffset = 0;
  }

  // 목표 요일 계산 (1=월요일, 7=일요일)
  final targetWeekday = weekdayFromKorean(dayStr);
  // 월요일로부터의 오프셋 (0=월, 6=일)
  final dayOffset = targetWeekday - DateTime.monday;

  final date = thisMonday.add(Duration(days: weekOffset + dayOffset));

  return DateParseResult(
    date: date,
    matchStart: match.start,
    matchEnd: match.end,
  );
}
