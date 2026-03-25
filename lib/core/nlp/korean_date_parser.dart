// C0.NLP: 한국어 날짜 표현 파서 — 배럴 파일 + 퍼블릭 API
// SRP 분리: 값 객체, 정규식 패턴, 상대/절대 파싱 함수를 별도 파일로 분리
// 외부에서는 이 파일만 import하면 DateParseResult + KoreanDateParser를 사용할 수 있다

export 'date_parse_result.dart';

import 'date_parse_result.dart';
import 'korean_date_absolute_parsers.dart' as absolute;
import 'korean_date_relative_parsers.dart' as relative;

/// 한국어 날짜 파서 (순수 함수 집합)
/// 외부 상태에 의존하지 않으며, 테스트 가능성을 위해 baseDate를 주입받는다
abstract class KoreanDateParser {
  /// 텍스트에서 한국어 날짜 표현을 파싱한다
  /// 여러 패턴 중 가장 먼저 매칭되는 것을 반환한다
  ///
  /// 매칭 우선순위:
  ///   1. 마감 표현: "N월 D일까지", "내일까지" 등
  ///   2. 절대 날짜: "3월 15일", "12월 25일"
  ///   3. 상대 날짜: "오늘", "내일", "모레", "글피"
  ///   4. 주 기반: "이번주 금요일", "다음주 월요일"
  ///   5. N일 단독: "15일" (이번 달)
  static DateParseResult? parse(String text, {required DateTime baseDate}) {
    // 1순위: 마감 표현 파싱 (~까지 접미사)
    final deadlineResult = absolute.parseDeadline(text, baseDate);
    if (deadlineResult != null) return deadlineResult;

    // 2순위: 절대 날짜 파싱 (N월 D일)
    final absoluteResult = absolute.parseAbsoluteDate(text, baseDate);
    if (absoluteResult != null) return absoluteResult;

    // 3순위: 상대 날짜 파싱 (오늘, 내일, 모레, 글피)
    final relativeResult = relative.parseRelativeDay(text, baseDate);
    if (relativeResult != null) return relativeResult;

    // 4순위: 주 기반 파싱 (이번주/다음주/다다음주 X요일)
    final weekdayResult = relative.parseWeekday(text, baseDate);
    if (weekdayResult != null) return weekdayResult;

    // 5순위: N일 단독 파싱 (이번 달 특정 일)
    final dayOnlyResult = absolute.parseDayOnly(text, baseDate);
    if (dayOnlyResult != null) return dayOnlyResult;

    return null;
  }
}
