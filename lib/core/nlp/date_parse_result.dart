// C0.NLP: 날짜 파싱 결과 값 객체
// 입력: DateTime, int matchStart, int matchEnd
// 출력: DateParseResult (불변 데이터 클래스)

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
