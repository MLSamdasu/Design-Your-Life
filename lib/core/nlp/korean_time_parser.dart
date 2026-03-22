// C0.NLP: 한국어 시간 표현 정규식 파서
// 순수 함수: 외부 상태에 의존하지 않는다.
// IN: String (한국어 텍스트)
// OUT: TimeParseResult? (파싱된 시간 + 매칭된 텍스트 범위)
import 'package:flutter/material.dart';

/// 시간 파싱 결과
/// 매칭된 텍스트 범위를 포함하여 제목 추출 시 해당 부분을 제거할 수 있다
class TimeParseResult {
  /// 파싱된 시간
  final TimeOfDay time;

  /// 매칭된 텍스트의 시작 인덱스 (inclusive)
  final int matchStart;

  /// 매칭된 텍스트의 끝 인덱스 (exclusive)
  final int matchEnd;

  const TimeParseResult({
    required this.time,
    required this.matchStart,
    required this.matchEnd,
  });
}

/// 한국어 시간 파서 (순수 함수 집합)
/// 외부 상태에 의존하지 않는다
abstract class KoreanTimeParser {
  // ─── 정규식 패턴 ──────────────────────────────────────────────────────────

  /// 명시적 시간 패턴: "오전/오후/새벽/아침/점심/저녁/밤 N시 (M분)" 또는 "N시 반"
  /// 시간대 접두어는 선택적이다 (없으면 1~6시는 오후, 7시 이상은 오전으로 가정)
  /// "밤 12시"→자정(0:00), "새벽 3시"→03:00 등 시간대 키워드로 AM/PM을 결정한다
  /// "N시 반"도 지원한다 (30분으로 처리)
  static final RegExp _explicitTimePattern = RegExp(
    r'(오전|오후|새벽|아침|점심|저녁|밤)?\s*(\d{1,2})\s*시(?:\s*(반)|\s*(\d{1,2})\s*분)?',
  );

  /// 시간대 키워드 패턴 (뒤에 "N시"가 따라오지 않는 단독 키워드만 매칭)
  /// "새벽", "아침", "점심", "저녁", "밤"을 단독 키워드로 처리한다
  /// "밤 12시"처럼 뒤에 시간이 붙은 경우는 _explicitTimePattern이 처리한다
  static final RegExp _timeKeywordPattern = RegExp(
    r'(새벽|아침|점심|저녁|밤)(?!\s*\d{1,2}\s*시)',
  );

  // ─── 퍼블릭 API ──────────────────────────────────────────────────────────

  /// 텍스트에서 한국어 시간 표현을 파싱한다
  ///
  /// 매칭 우선순위:
  ///   1. 명시적 시간: "오후 3시", "오전 10시 30분", "3시 반"
  ///   2. 시간대 키워드: "아침"(8:00), "점심"(12:00), "저녁"(18:00), "밤"(21:00), "새벽"(5:00)
  static TimeParseResult? parse(String text) {
    // 1순위: 명시적 시간 표현 파싱
    final explicitResult = _parseExplicitTime(text);
    if (explicitResult != null) return explicitResult;

    // 2순위: 시간대 키워드 파싱
    final keywordResult = _parseTimeKeyword(text);
    if (keywordResult != null) return keywordResult;

    return null;
  }

  // ─── 프라이빗 파싱 메서드 ────────────────────────────────────────────────

  /// "오전/오후/새벽/아침/점심/저녁/밤 N시 (M분)" 명시적 시간 파싱
  /// 시간대 접두어로 AM/PM을 결정한다:
  ///   - 오전/새벽/아침: AM 계열 (12시→0시, 1~11시→그대로)
  ///   - 오후/점심/저녁: PM 계열 (12시→12시, 1~11시→+12)
  ///   - 밤: 특수 처리 (12시→0시=자정, 1~6시→그대로=새벽, 7~11시→+12=저녁)
  ///   - 미명시: 0시→자정, 12시→정오, 7~11→오전, 1~6→오후
  static TimeParseResult? _parseExplicitTime(String text) {
    final match = _explicitTimePattern.firstMatch(text);
    if (match == null) return null;

    final prefixStr = match.group(1); // 시간대 접두어 (nullable)
    final hourStr = match.group(2)!;
    final isHalf = match.group(3) == '반'; // "반" 여부
    final minuteStr = match.group(4); // 분 (nullable)

    final rawHour = int.tryParse(hourStr);
    if (rawHour == null || rawHour < 0 || rawHour > 23) return null;

    // 분 계산: "반"이면 30분, 명시된 분이 있으면 해당 분, 없으면 0분
    final minute = isHalf
        ? 30
        : (minuteStr != null ? (int.tryParse(minuteStr) ?? 0) : 0);

    if (minute < 0 || minute > 59) return null;

    // 시간대 접두어가 있을 때 13시 이상은 의미상 오류이므로 거부한다
    // 예: "오전 13시", "오후 15시"는 시간대 접두어와 모순되는 값이다
    if (prefixStr != null && rawHour > 12) return null;

    // 시간 보정: 시간대 접두어에 따라 24시간제로 변환한다
    final int hour;
    if (prefixStr == '오전' || prefixStr == '새벽' || prefixStr == '아침') {
      // AM 계열: 12시는 자정(0시), 1~11시는 그대로
      hour = rawHour == 12 ? 0 : rawHour;
    } else if (prefixStr == '오후' || prefixStr == '점심' || prefixStr == '저녁') {
      // PM 계열: 12시는 정오(12시), 1~11시는 +12
      hour = rawHour == 12 ? 12 : rawHour + 12;
    } else if (prefixStr == '밤') {
      // 밤 특수 처리: "밤 12시"→자정, "밤 1시"→새벽 1시, "밤 9시"→21시
      if (rawHour == 12) {
        hour = 0; // "밤 12시" = 자정 (0:00)
      } else if (rawHour <= 6) {
        hour = rawHour; // "밤 1~6시" = 자정 이후 새벽 (1:00~6:00)
      } else {
        hour = rawHour + 12; // "밤 7~11시" = 저녁~밤 (19:00~23:00)
      }
    } else {
      // 시간대 미명시: 시간대에 따라 추정한다
      if (rawHour == 0) {
        hour = 0; // "0시" = 자정
      } else if (rawHour == 12) {
        hour = 12; // "12시" = 정오
      } else if (rawHour >= 7) {
        hour = rawHour; // "7시~11시" = 오전
      } else {
        hour = rawHour + 12; // "1시~6시" = 오후
      }
    }

    // 유효한 24시간제 범위 검사
    if (hour < 0 || hour > 23) return null;

    return TimeParseResult(
      time: TimeOfDay(hour: hour, minute: minute),
      matchStart: match.start,
      matchEnd: match.end,
    );
  }

  /// "아침", "점심", "저녁", "밤", "새벽" 키워드를 기본 시간으로 변환한다
  static TimeParseResult? _parseTimeKeyword(String text) {
    final match = _timeKeywordPattern.firstMatch(text);
    if (match == null) return null;

    final keyword = match.group(1)!;
    final time = _timeFromKeyword(keyword);
    if (time == null) return null;

    return TimeParseResult(
      time: time,
      matchStart: match.start,
      matchEnd: match.end,
    );
  }

  // ─── 헬퍼 ────────────────────────────────────────────────────────────────

  /// 시간대 키워드를 기본 TimeOfDay로 변환한다
  /// 매핑되지 않는 키워드이면 null을 반환한다
  static TimeOfDay? _timeFromKeyword(String keyword) {
    const map = {
      '새벽': TimeOfDay(hour: 5, minute: 0),
      '아침': TimeOfDay(hour: 8, minute: 0),
      '점심': TimeOfDay(hour: 12, minute: 0),
      '저녁': TimeOfDay(hour: 18, minute: 0),
      '밤': TimeOfDay(hour: 21, minute: 0),
    };
    return map[keyword];
  }
}
