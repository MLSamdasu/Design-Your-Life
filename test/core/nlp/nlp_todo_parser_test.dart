// NlpTodoParser 통합 테스트
// 날짜+시간+제목 통합 파싱, 매칭 범위 제거, 제목 추출, 엣지 케이스 검증
// baseDate: 2026-03-10 (화요일)
import 'package:design_your_life/core/nlp/nlp_todo_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 고정 기준 날짜: 2026년 3월 10일 (화요일)
  final baseDate = DateTime(2026, 3, 10);

  group('NlpTodoParser - 날짜 + 시간 + 제목 통합 파싱', () {
    test('"내일 오후 3시 미팅"을 파싱한다', () {
      final result = NlpTodoParser.parse('내일 오후 3시 미팅', baseDate: baseDate);
      expect(result.date, DateTime(2026, 3, 11));
      expect(result.time, const TimeOfDay(hour: 15, minute: 0));
      expect(result.title, '미팅');
    });

    test('"다음주 월요일 아침 운동"을 파싱한다', () {
      final result = NlpTodoParser.parse('다음주 월요일 아침 운동', baseDate: baseDate);
      expect(result.date, DateTime(2026, 3, 16));
      expect(result.time, const TimeOfDay(hour: 8, minute: 0));
      expect(result.title, '운동');
    });

    test('"이번주 금요일 오후 2시 팀 미팅"을 파싱한다', () {
      final result = NlpTodoParser.parse('이번주 금요일 오후 2시 팀 미팅', baseDate: baseDate);
      expect(result.date, DateTime(2026, 3, 13));
      expect(result.time, const TimeOfDay(hour: 14, minute: 0));
      expect(result.title, '팀 미팅');
    });

    test('"오늘 저녁 독서"를 파싱한다', () {
      final result = NlpTodoParser.parse('오늘 저녁 독서', baseDate: baseDate);
      expect(result.date, DateTime(2026, 3, 10));
      expect(result.time, const TimeOfDay(hour: 18, minute: 0));
      expect(result.title, '독서');
    });
  });

  group('NlpTodoParser - 날짜만 있는 케이스', () {
    test('"3월 15일까지 보고서 제출"을 파싱한다', () {
      final result = NlpTodoParser.parse('3월 15일까지 보고서 제출', baseDate: baseDate);
      expect(result.date, DateTime(2026, 3, 15));
      expect(result.time, isNull);
      expect(result.title, '보고서 제출');
    });

    test('"내일 보고서 작성"에서 날짜만 파싱된다', () {
      final result = NlpTodoParser.parse('내일 보고서 작성', baseDate: baseDate);
      expect(result.date, DateTime(2026, 3, 11));
      expect(result.time, isNull);
      expect(result.title, '보고서 작성');
    });

    test('"오늘" 하나만 입력하면 날짜는 있고 제목이 비어있다', () {
      final result = NlpTodoParser.parse('오늘', baseDate: baseDate);
      expect(result.date, DateTime(2026, 3, 10));
      expect(result.time, isNull);
      // 날짜 제거 후 남은 텍스트가 없으므로 제목이 비어있다
      expect(result.title, '');
      expect(result.isValid, false);
    });
  });

  group('NlpTodoParser - 시간만 있는 케이스', () {
    test('"오후 3시 운동"에서 시간만 파싱된다', () {
      final result = NlpTodoParser.parse('오후 3시 운동', baseDate: baseDate);
      expect(result.date, isNull);
      expect(result.time, const TimeOfDay(hour: 15, minute: 0));
      expect(result.title, '운동');
    });

    test('"아침 운동"에서 시간 키워드만 파싱된다', () {
      final result = NlpTodoParser.parse('아침 운동', baseDate: baseDate);
      expect(result.date, isNull);
      expect(result.time, const TimeOfDay(hour: 8, minute: 0));
      expect(result.title, '운동');
    });
  });

  group('NlpTodoParser - 날짜/시간 없는 일반 텍스트', () {
    test('날짜/시간 없는 텍스트는 제목만 반환한다', () {
      final result = NlpTodoParser.parse('은행 업무', baseDate: baseDate);
      expect(result.date, isNull);
      expect(result.time, isNull);
      expect(result.title, '은행 업무');
    });

    test('한글 문장을 그대로 제목으로 반환한다', () {
      final result = NlpTodoParser.parse('매일 영어 공부하기', baseDate: baseDate);
      expect(result.title, '매일 영어 공부하기');
    });
  });

  group('NlpTodoParser - 엣지 케이스', () {
    test('빈 문자열은 빈 ParsedTodo를 반환한다', () {
      final result = NlpTodoParser.parse('', baseDate: baseDate);
      expect(result.title, '');
      expect(result.date, isNull);
      expect(result.time, isNull);
      expect(result.isEmpty, true);
      expect(result.isValid, false);
    });

    test('공백만 있는 문자열도 빈 ParsedTodo를 반환한다', () {
      final result = NlpTodoParser.parse('   ', baseDate: baseDate);
      expect(result.title, '');
      expect(result.date, isNull);
      expect(result.time, isNull);
    });

    test('원본 텍스트는 변경되지 않고 originalText에 저장된다', () {
      const input = '내일 오후 3시 미팅';
      final result = NlpTodoParser.parse(input, baseDate: baseDate);
      expect(result.originalText, input);
    });

    test('baseDate가 null이면 오늘 날짜를 사용한다 (DateTime.now() 대체)', () {
      // baseDate 없이 호출 시 오류 없이 결과를 반환해야 한다
      expect(() => NlpTodoParser.parse('내일 미팅'), returnsNormally);
    });

    test('제목의 연속 공백이 정리된다', () {
      // "내일"이 제거되고 남은 텍스트에 연속 공백이 생길 수 있다
      final result = NlpTodoParser.parse('내일  미팅  준비', baseDate: baseDate);
      expect(result.title, '미팅 준비');
    });
  });

  group('NlpTodoParser - hasDate, hasTime, isValid 검증', () {
    test('날짜와 시간이 모두 파싱되면 hasDate, hasTime이 true다', () {
      final result = NlpTodoParser.parse('내일 오전 9시 회의', baseDate: baseDate);
      expect(result.hasDate, true);
      expect(result.hasTime, true);
    });

    test('제목이 있으면 isValid가 true다', () {
      final result = NlpTodoParser.parse('회의', baseDate: baseDate);
      expect(result.isValid, true);
    });

    test('날짜/시간만 파싱되고 제목이 없으면 isValid가 false다', () {
      // "오늘"만 입력 시 날짜는 파싱되지만 제목이 없다
      final result = NlpTodoParser.parse('오늘', baseDate: baseDate);
      expect(result.isValid, false);
    });
  });
}
