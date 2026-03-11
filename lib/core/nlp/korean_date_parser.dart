// C0.NLP: 한국어 날짜 표현 정규식 파서
// 순수 함수: 외부 상태에 의존하지 않는다. DateTime.now() 대신 baseDate를 주입받는다.
// IN: String (한국어 텍스트), DateTime (기준 날짜)
// OUT: DateParseResult? (파싱된 날짜 + 매칭된 텍스트 범위)

/// 날짜 파싱 결과
/// 매칭된 텍스트 범위를 포함하여 제목 추출 시 해당 부분을 제거할 수 있다
class DateParseResult {
  /// 파싱된 날짜
  final DateTime date;

  /// 매칭된 텍스트의 시작 인덱스 (inclusive)
  final int matchStart;

  /// 매칭된 텍스트의 끝 인덱스 (exclusive)
  final int matchEnd;

  const DateParseResult({
    required this.date,
    required this.matchStart,
    required this.matchEnd,
  });
}

/// 한국어 날짜 파서 (순수 함수 집합)
/// 외부 상태에 의존하지 않으며, 테스트 가능성을 위해 baseDate를 주입받는다
abstract class KoreanDateParser {
  // ─── 정규식 패턴 ──────────────────────────────────────────────────────────

  /// 절대 날짜 패턴: "N월 D일", "N월D일" (공백 선택)
  /// 예: "3월 15일", "12월25일"
  static final RegExp _absoluteDatePattern = RegExp(
    r'(\d{1,2})\s*월\s*(\d{1,2})\s*일',
  );

  /// 마감 패턴: "N월 D일까지", "내일까지" 등 (~까지 접미사)
  static final RegExp _deadlinePattern = RegExp(
    r'((?:\d{1,2}\s*월\s*\d{1,2}\s*일|오늘|내일|모레|글피|(?:이번|다음|다다음)\s*주\s*(?:월|화|수|목|금|토|일)요일))까지',
  );

  /// 상대 날짜 패턴: "오늘", "내일", "모레", "글피", "내일모레"
  static final RegExp _relativePattern = RegExp(
    r'(내일모레|모레|글피|오늘|내일)',
  );

  /// 주 기반 패턴: "이번주/다음주/다다음주" + "월/화/수/목/금/토/일" + "요일"
  /// 공백이 있을 수도 없을 수도 있다 (예: "이번 주 금요일", "다음주금요일")
  static final RegExp _weekdayPattern = RegExp(
    r'(이번\s*주|다음\s*주|다다음\s*주)\s*(월|화|수|목|금|토|일)요일',
  );

  /// N일 단독 패턴: "15일", "1일" 등 (이번 달 특정 일)
  /// 가변 길이 lookbehind는 Dart에서 지원하지 않으므로 제거한다.
  /// 대신 매칭 후 앞에 "월"이 있는지 직접 검사하여 절대 날짜(N월 D일)와 중복 처리를 방지한다.
  static final RegExp _dayOnlyPattern = RegExp(
    r'(\d{1,2})\s*일(?!까지)',
  );

  // ─── 퍼블릭 API ──────────────────────────────────────────────────────────

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
    final deadlineResult = _parseDeadline(text, baseDate);
    if (deadlineResult != null) return deadlineResult;

    // 2순위: 절대 날짜 파싱 (N월 D일)
    final absoluteResult = _parseAbsoluteDate(text, baseDate);
    if (absoluteResult != null) return absoluteResult;

    // 3순위: 상대 날짜 파싱 (오늘, 내일, 모레, 글피)
    final relativeResult = _parseRelativeDay(text, baseDate);
    if (relativeResult != null) return relativeResult;

    // 4순위: 주 기반 파싱 (이번주/다음주/다다음주 X요일)
    final weekdayResult = _parseWeekday(text, baseDate);
    if (weekdayResult != null) return weekdayResult;

    // 5순위: N일 단독 파싱 (이번 달 특정 일)
    final dayOnlyResult = _parseDayOnly(text, baseDate);
    if (dayOnlyResult != null) return dayOnlyResult;

    return null;
  }

  // ─── 프라이빗 파싱 메서드 ────────────────────────────────────────────────

  /// "오늘", "내일", "모레", "글피", "내일모레" 파싱
  /// baseDate 기준으로 날짜를 계산한다
  static DateParseResult? _parseRelativeDay(String text, DateTime baseDate) {
    final match = _relativePattern.firstMatch(text);
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
  static DateParseResult? _parseWeekday(String text, DateTime baseDate) {
    final match = _weekdayPattern.firstMatch(text);
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
    final targetWeekday = _weekdayFromKorean(dayStr);
    // 월요일로부터의 오프셋 (0=월, 6=일)
    final dayOffset = targetWeekday - DateTime.monday;

    final date = thisMonday.add(Duration(days: weekOffset + dayOffset));

    return DateParseResult(
      date: date,
      matchStart: match.start,
      matchEnd: match.end,
    );
  }

  /// "N월 D일", "N월D일" 절대 날짜 파싱
  /// 연도는 baseDate와 동일한 해를 사용한다
  static DateParseResult? _parseAbsoluteDate(String text, DateTime baseDate) {
    final match = _absoluteDatePattern.firstMatch(text);
    if (match == null) return null;

    final month = int.tryParse(match.group(1)!);
    final day = int.tryParse(match.group(2)!);

    // 유효하지 않은 월/일 값이면 무시한다
    if (month == null || day == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;

    final date = DateTime(baseDate.year, month, day);

    return DateParseResult(
      date: date,
      matchStart: match.start,
      matchEnd: match.end,
    );
  }

  /// "~까지" 접미사 처리 (마감일 표현)
  /// 예: "3월 15일까지 보고서 제출"
  static DateParseResult? _parseDeadline(String text, DateTime baseDate) {
    final match = _deadlinePattern.firstMatch(text);
    if (match == null) return null;

    // 내부 날짜 표현 추출
    final innerText = match.group(1)!;
    // 내부 날짜를 재귀적으로 파싱한다 (단, 마감 패턴 제외)
    final innerDate = _parseAbsoluteDate(innerText, baseDate) ??
        _parseRelativeDay(innerText, baseDate) ??
        _parseWeekday(innerText, baseDate);

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
  static DateParseResult? _parseDayOnly(String text, DateTime baseDate) {
    // 절대 날짜(N월 D일)가 이미 매칭되지 않은 경우에만 처리한다
    // (절대 날짜가 있으면 이미 상위에서 처리됨)
    if (_absoluteDatePattern.hasMatch(text)) return null;

    final match = _dayOnlyPattern.firstMatch(text);
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

    return DateParseResult(
      date: date,
      matchStart: match.start,
      matchEnd: match.end,
    );
  }

  // ─── 헬퍼 ────────────────────────────────────────────────────────────────

  /// 한국어 요일 문자열을 DateTime.weekday 값(1=월~7=일)으로 변환한다
  static int _weekdayFromKorean(String dayStr) {
    const map = {
      '월': DateTime.monday,    // 1
      '화': DateTime.tuesday,   // 2
      '수': DateTime.wednesday, // 3
      '목': DateTime.thursday,  // 4
      '금': DateTime.friday,    // 5
      '토': DateTime.saturday,  // 6
      '일': DateTime.sunday,    // 7
    };
    return map[dayStr] ?? DateTime.monday;
  }
}
