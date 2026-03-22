// KoreanDateParser 순수 함수 테스트
// 한국어 날짜 패턴 파싱, 엣지 케이스(월말, 연말), 우선순위 검증
// 고정된 baseDate를 사용하여 결정적인(deterministic) 결과를 보장한다
// baseDate: 2026-03-10 (화요일)
import 'package:design_your_life/core/nlp/korean_date_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 고정 기준 날짜: 2026년 3월 10일 (화요일)
  // 이 날짜를 기준으로 "오늘", "내일" 등의 상대 날짜를 계산한다
  final baseDate = DateTime(2026, 3, 10);

  group('KoreanDateParser - 상대 날짜 (오늘/내일/모레/글피)', () {
    test('오늘을 파싱하면 baseDate를 반환한다', () {
      final result = KoreanDateParser.parse('오늘 미팅', baseDate: baseDate);
      expect(result, isNotNull);
      expect(result!.date, DateTime(2026, 3, 10));
    });

    test('내일을 파싱하면 baseDate + 1일을 반환한다', () {
      final result = KoreanDateParser.parse('내일 보고서 제출', baseDate: baseDate);
      expect(result, isNotNull);
      expect(result!.date, DateTime(2026, 3, 11));
    });

    test('모레를 파싱하면 baseDate + 2일을 반환한다', () {
      final result = KoreanDateParser.parse('모레 점심약속', baseDate: baseDate);
      expect(result, isNotNull);
      expect(result!.date, DateTime(2026, 3, 12));
    });

    test('내일모레를 파싱하면 baseDate + 2일을 반환한다', () {
      final result = KoreanDateParser.parse('내일모레 약속', baseDate: baseDate);
      expect(result, isNotNull);
      expect(result!.date, DateTime(2026, 3, 12));
    });

    test('글피를 파싱하면 baseDate + 3일을 반환한다', () {
      final result = KoreanDateParser.parse('글피 출장', baseDate: baseDate);
      expect(result, isNotNull);
      expect(result!.date, DateTime(2026, 3, 13));
    });

    test('상대 날짜 매칭 인덱스가 올바르게 반환된다', () {
      // "오늘"은 0번째 문자부터 시작한다
      final result = KoreanDateParser.parse('오늘 미팅', baseDate: baseDate);
      expect(result!.matchStart, 0);
      expect(result.matchEnd, 2); // "오늘" = 2글자
    });

    test('중간에 있는 상대 날짜도 올바른 인덱스를 반환한다', () {
      final result = KoreanDateParser.parse('일정: 내일 회의', baseDate: baseDate);
      expect(result, isNotNull);
      // "일정: " 이후에 "내일"이 시작된다
      expect(result!.date, DateTime(2026, 3, 11));
    });
  });

  group('KoreanDateParser - 절대 날짜 (N월 D일)', () {
    test('3월 15일을 파싱한다', () {
      final result = KoreanDateParser.parse('3월 15일 발표', baseDate: baseDate);
      expect(result, isNotNull);
      expect(result!.date, DateTime(2026, 3, 15));
    });

    test('공백 없는 3월15일도 파싱한다', () {
      final result = KoreanDateParser.parse('3월15일 발표', baseDate: baseDate);
      expect(result, isNotNull);
      expect(result!.date, DateTime(2026, 3, 15));
    });

    test('12월 25일(크리스마스)를 파싱한다', () {
      final result = KoreanDateParser.parse('12월 25일 크리스마스 파티', baseDate: baseDate);
      expect(result, isNotNull);
      expect(result!.date, DateTime(2026, 12, 25));
    });

    test('1월 1일(신정)를 파싱한다 — 과거이면 다음 해로 전환', () {
      // baseDate(3월 10일) 기준으로 1월 1일은 과거이므로 2027-01-01을 반환한다
      final result = KoreanDateParser.parse('1월 1일 신년회', baseDate: baseDate);
      expect(result, isNotNull);
      expect(result!.date, DateTime(2027, 1, 1));
    });

    test('절대 날짜의 연도는 baseDate 연도를 사용한다', () {
      final result = KoreanDateParser.parse('6월 1일 행사', baseDate: baseDate);
      expect(result!.date.year, 2026);
    });
  });

  group('KoreanDateParser - 주 기반 날짜 (이번주/다음주/다다음주)', () {
    // baseDate: 2026-03-10 (화요일)
    // 이번주 월요일: 2026-03-09
    // 이번주 금요일: 2026-03-13
    // 다음주 월요일: 2026-03-16
    // 다다음주 화요일: 2026-03-24

    test('이번주 금요일을 파싱한다 (2026-03-13)', () {
      final result = KoreanDateParser.parse('이번주 금요일 회의', baseDate: baseDate);
      expect(result, isNotNull);
      expect(result!.date, DateTime(2026, 3, 13));
    });

    test('이번주 월요일을 파싱한다 (2026-03-09)', () {
      final result = KoreanDateParser.parse('이번주 월요일 회의', baseDate: baseDate);
      expect(result, isNotNull);
      expect(result!.date, DateTime(2026, 3, 9));
    });

    test('이번주 일요일을 파싱한다 (2026-03-15)', () {
      final result = KoreanDateParser.parse('이번주 일요일 휴식', baseDate: baseDate);
      expect(result, isNotNull);
      expect(result!.date, DateTime(2026, 3, 15));
    });

    test('다음주 월요일을 파싱한다 (2026-03-16)', () {
      final result = KoreanDateParser.parse('다음주 월요일 면접', baseDate: baseDate);
      expect(result, isNotNull);
      expect(result!.date, DateTime(2026, 3, 16));
    });

    test('다음주 수요일을 파싱한다 (2026-03-18)', () {
      final result = KoreanDateParser.parse('다음주 수요일 약속', baseDate: baseDate);
      expect(result, isNotNull);
      expect(result!.date, DateTime(2026, 3, 18));
    });

    test('다다음주 화요일을 파싱한다 (2026-03-24)', () {
      final result = KoreanDateParser.parse('다다음주 화요일 워크숍', baseDate: baseDate);
      expect(result, isNotNull);
      expect(result!.date, DateTime(2026, 3, 24));
    });

    test('주 이름에 공백이 있어도 파싱된다 (다음 주 금요일)', () {
      final result = KoreanDateParser.parse('다음 주 금요일 미팅', baseDate: baseDate);
      expect(result, isNotNull);
      expect(result!.date, DateTime(2026, 3, 20));
    });
  });

  group('KoreanDateParser - 마감 날짜 (~까지)', () {
    test('3월 15일까지를 파싱한다', () {
      final result = KoreanDateParser.parse('3월 15일까지 보고서 제출', baseDate: baseDate);
      expect(result, isNotNull);
      expect(result!.date, DateTime(2026, 3, 15));
    });

    test('내일까지를 파싱한다', () {
      final result = KoreanDateParser.parse('내일까지 과제 제출', baseDate: baseDate);
      expect(result, isNotNull);
      expect(result!.date, DateTime(2026, 3, 11));
    });

    test('마감 날짜 매칭 범위가 ~까지를 포함한다', () {
      final text = '3월 15일까지 제출';
      final result = KoreanDateParser.parse(text, baseDate: baseDate);
      expect(result, isNotNull);
      // 매칭 텍스트는 "3월 15일까지" 전체여야 한다
      final matchedText = text.substring(result!.matchStart, result.matchEnd);
      expect(matchedText, '3월 15일까지');
    });
  });

  group('KoreanDateParser - N일 단독 (이번 달 특정 일)', () {
    test('15일은 이번 달 15일로 파싱된다', () {
      final result = KoreanDateParser.parse('15일 회의', baseDate: baseDate);
      expect(result, isNotNull);
      expect(result!.date, DateTime(2026, 3, 15));
    });

    test('1일은 이번 달 1일로 파싱된다', () {
      final result = KoreanDateParser.parse('1일 납부', baseDate: baseDate);
      expect(result, isNotNull);
      expect(result!.date, DateTime(2026, 3, 1));
    });

    test('절대 날짜가 있으면 N일 단독 패턴을 사용하지 않는다', () {
      // "3월 15일"이 있으므로 절대 날짜가 우선순위를 가진다
      final result = KoreanDateParser.parse('3월 15일 회의', baseDate: baseDate);
      expect(result, isNotNull);
      expect(result!.date, DateTime(2026, 3, 15));
    });
  });

  group('KoreanDateParser - 파싱 실패 케이스', () {
    test('날짜 표현이 없으면 null을 반환한다', () {
      final result = KoreanDateParser.parse('그냥 할 일', baseDate: baseDate);
      expect(result, isNull);
    });

    test('빈 문자열은 null을 반환한다', () {
      final result = KoreanDateParser.parse('', baseDate: baseDate);
      expect(result, isNull);
    });

    test('숫자만 있는 텍스트는 null을 반환한다', () {
      final result = KoreanDateParser.parse('123 456', baseDate: baseDate);
      expect(result, isNull);
    });
  });

  group('KoreanDateParser - 우선순위 검증', () {
    test('마감 표현이 절대 날짜보다 우선순위가 높다', () {
      // "3월 15일까지"가 있으므로 마감 패턴이 먼저 매칭된다
      final result = KoreanDateParser.parse('3월 15일까지 3월 20일 검토', baseDate: baseDate);
      expect(result, isNotNull);
      // 마감 패턴이 먼저 매칭되어야 한다
      expect(result!.date, DateTime(2026, 3, 15));
    });
  });

  group('KoreanDateParser - 월말/연말 엣지 케이스', () {
    test('31일은 해당 달의 마지막 날로 파싱된다 (3월 31일)', () {
      final result = KoreanDateParser.parse('31일 마지막', baseDate: baseDate);
      expect(result, isNotNull);
      expect(result!.date, DateTime(2026, 3, 31));
    });

    test('월말(baseDate=3월 31일)에서 다음주 계산이 올바르다', () {
      // 3월 31일 (화요일)
      final endOfMarch = DateTime(2026, 3, 31);
      // 다음주 금요일: 2026-04-10 (3월 31 + 7 = 4월 7일이 화요일, +3=금요일)
      final result = KoreanDateParser.parse('다음주 금요일', baseDate: endOfMarch);
      expect(result, isNotNull);
      expect(result!.date.month, 4); // 4월이어야 한다
    });
  });
}
