// C0.NLP: 한국어 날짜 표현 정규식 패턴 및 요일 변환 헬퍼
// 순수 상수 + 순수 함수: 외부 상태에 의존하지 않는다
// 입력: (패턴) 없음 / (헬퍼) String 요일 문자
// 출력: (패턴) RegExp / (헬퍼) int weekday 값

/// 절대 날짜 패턴: "N월 D일", "N월D일" (공백 선택)
/// 예: "3월 15일", "12월25일"
final RegExp absoluteDatePattern = RegExp(
  r'(\d{1,2})\s*월\s*(\d{1,2})\s*일',
);

/// 마감 패턴: "N월 D일까지", "15일까지", "내일까지" 등 (~까지 접미사)
/// "15일까지"(일 단독 마감)도 지원하기 위해 \d{1,2}\s*일 패턴을 포함한다
final RegExp deadlinePattern = RegExp(
  r'((?:\d{1,2}\s*월\s*\d{1,2}\s*일|\d{1,2}\s*일|오늘|내일|모레|글피|(?:이번|다음|다다음)\s*주\s*(?:월|화|수|목|금|토|일)요일))까지',
);

/// 상대 날짜 패턴: "오늘", "내일", "모레", "글피", "내일모레"
final RegExp relativePattern = RegExp(
  r'(내일모레|모레|글피|오늘|내일)',
);

/// 주 기반 패턴: "이번주/다음주/다다음주" + "월/화/수/목/금/토/일" + "요일"
/// 공백이 있을 수도 없을 수도 있다 (예: "이번 주 금요일", "다음주금요일")
final RegExp weekdayPattern = RegExp(
  r'(이번\s*주|다음\s*주|다다음\s*주)\s*(월|화|수|목|금|토|일)요일',
);

/// N일 단독 패턴: "15일", "1일" 등 (이번 달 특정 일)
/// 가변 길이 lookbehind는 Dart에서 지원하지 않으므로 제거한다.
/// 대신 매칭 후 앞에 "월"이 있는지 직접 검사하여 절대 날짜(N월 D일)와 중복 처리를 방지한다.
final RegExp dayOnlyPattern = RegExp(
  r'(\d{1,2})\s*일(?!까지)',
);

/// 한국어 요일 문자열을 DateTime.weekday 값(1=월~7=일)으로 변환한다
int weekdayFromKorean(String dayStr) {
  const map = {
    '월': DateTime.monday, // 1
    '화': DateTime.tuesday, // 2
    '수': DateTime.wednesday, // 3
    '목': DateTime.thursday, // 4
    '금': DateTime.friday, // 5
    '토': DateTime.saturday, // 6
    '일': DateTime.sunday, // 7
  };
  return map[dayStr] ?? DateTime.monday;
}
