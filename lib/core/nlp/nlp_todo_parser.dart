// C0.NLP: 자연어 투두 파서 (통합 오케스트레이터)
// KoreanDateParser + KoreanTimeParser를 조합하여 ParsedTodo를 생성한다.
// Manager 계층: 직접 파싱 로직을 수행하지 않고 Atomic Module 호출만 한다.
// IN: String (원본 텍스트), DateTime (기준 날짜)
// OUT: ParsedTodo
import 'korean_date_parser.dart';
import 'korean_time_parser.dart';
import 'parsed_todo.dart';

/// 자연어 투두 파서 (Manager 계층)
/// 날짜/시간 파서를 조합하고 제목을 추출한다
abstract class NlpTodoParser {
  /// 자연어 텍스트를 파싱하여 ParsedTodo를 반환한다
  ///
  /// [text]: 사용자 입력 원본 텍스트
  /// [baseDate]: 기준 날짜 ("오늘", "내일" 등의 기준점), null이면 DateTime.now() 사용
  ///
  /// 처리 순서:
  /// 1. KoreanDateParser.parse()로 날짜 추출
  /// 2. KoreanTimeParser.parse()로 시간 추출
  /// 3. 매칭된 부분을 원본 텍스트에서 제거하여 제목 추출
  /// 4. 제목 앞뒤 공백/조사 정리
  static ParsedTodo parse(String text, {DateTime? baseDate}) {
    // 빈 텍스트이면 빈 결과를 반환한다
    if (text.trim().isEmpty) {
      return ParsedTodo(title: '', originalText: text);
    }

    // 기준 날짜 결정: 외부 주입이 없으면 오늘 날짜를 사용한다
    // 테스트 가능성을 위해 DateTime.now()는 여기서만 호출한다
    final base = baseDate ?? DateTime.now();

    // 1. 날짜 파싱
    final dateResult = KoreanDateParser.parse(text, baseDate: base);

    // 2. 시간 파싱
    final timeResult = KoreanTimeParser.parse(text);

    // 3. 매칭된 부분을 뒤에서부터 제거하여 제목 추출한다
    //    뒤에서부터 제거하는 이유: 앞쪽 매칭을 먼저 제거하면 뒤쪽 인덱스가 틀어진다
    String title = text;
    final ranges = <({int start, int end})>[];

    if (dateResult != null) {
      ranges.add((start: dateResult.matchStart, end: dateResult.matchEnd));
    }
    if (timeResult != null) {
      ranges.add((start: timeResult.matchStart, end: timeResult.matchEnd));
    }

    // 범위가 겹치는 경우 더 큰 범위를 사용한다 (중복 제거)
    final mergedRanges = _mergeRanges(ranges);

    // 뒤에서부터 제거 (인덱스 변경 방지)
    mergedRanges.sort((a, b) => b.start.compareTo(a.start));
    for (final range in mergedRanges) {
      // 인덱스가 텍스트 범위를 벗어나지 않도록 안전하게 처리한다
      final safeStart = range.start.clamp(0, title.length);
      final safeEnd = range.end.clamp(0, title.length);
      title = title.substring(0, safeStart) + title.substring(safeEnd);
    }

    // 4. 정리: 연속 공백 제거, 앞뒤 공백 제거
    title = _cleanTitle(title);

    return ParsedTodo(
      title: title,
      date: dateResult?.date,
      time: timeResult?.time,
      originalText: text,
    );
  }

  /// 제목 텍스트를 정리한다
  /// 날짜/시간 제거 후 남은 연속 공백을 단일 공백으로 합치고 앞뒤를 트림한다
  static String _cleanTitle(String raw) {
    return raw
        .replaceAll(RegExp(r'\s+'), ' ') // 연속 공백을 단일 공백으로
        .trim();
  }

  /// 겹치는 범위를 병합한다
  /// 두 범위가 겹치거나 인접하면 하나의 큰 범위로 합친다
  static List<({int start, int end})> _mergeRanges(
    List<({int start, int end})> ranges,
  ) {
    if (ranges.isEmpty) return [];
    if (ranges.length == 1) return ranges;

    // 시작 인덱스 기준으로 정렬한다
    final sorted = [...ranges]..sort((a, b) => a.start.compareTo(b.start));
    final merged = <({int start, int end})>[];

    var current = sorted.first;
    for (int i = 1; i < sorted.length; i++) {
      final next = sorted[i];
      // 현재 범위와 다음 범위가 겹치거나 인접하면 병합한다
      if (next.start <= current.end) {
        current = (
          start: current.start,
          end: next.end > current.end ? next.end : current.end,
        );
      } else {
        merged.add(current);
        current = next;
      }
    }
    merged.add(current);
    return merged;
  }
}
