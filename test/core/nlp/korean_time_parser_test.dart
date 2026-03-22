// KoreanTimeParser 순수 함수 테스트
// 한국어 시간 패턴 파싱, 오전/오후 보정, 시간대 키워드, 엣지 케이스 검증
import 'package:design_your_life/core/nlp/korean_time_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KoreanTimeParser - 오전 N시 패턴', () {
    test('오전 10시를 파싱한다', () {
      final result = KoreanTimeParser.parse('오전 10시 회의');
      expect(result, isNotNull);
      expect(result!.time, const TimeOfDay(hour: 10, minute: 0));
    });

    test('오전 10시 30분을 파싱한다', () {
      final result = KoreanTimeParser.parse('오전 10시 30분 미팅');
      expect(result, isNotNull);
      expect(result!.time, const TimeOfDay(hour: 10, minute: 30));
    });

    test('오전 12시를 파싱하면 0시가 된다 (자정)', () {
      // 오전 12시 = 자정 (00:00)
      final result = KoreanTimeParser.parse('오전 12시');
      expect(result, isNotNull);
      expect(result!.time, const TimeOfDay(hour: 0, minute: 0));
    });

    test('오전 1시를 파싱한다', () {
      final result = KoreanTimeParser.parse('오전 1시 새벽 운동');
      expect(result, isNotNull);
      expect(result!.time, const TimeOfDay(hour: 1, minute: 0));
    });
  });

  group('KoreanTimeParser - 오후 N시 패턴', () {
    test('오후 3시를 파싱하면 15시가 된다', () {
      final result = KoreanTimeParser.parse('오후 3시 미팅');
      expect(result, isNotNull);
      expect(result!.time, const TimeOfDay(hour: 15, minute: 0));
    });

    test('오후 3시 30분을 파싱하면 15시 30분이 된다', () {
      final result = KoreanTimeParser.parse('오후 3시 30분 미팅');
      expect(result, isNotNull);
      expect(result!.time, const TimeOfDay(hour: 15, minute: 30));
    });

    test('오후 12시를 파싱하면 12시가 된다 (정오)', () {
      // 오후 12시 = 정오 (12:00)
      final result = KoreanTimeParser.parse('오후 12시 점심');
      expect(result, isNotNull);
      expect(result!.time, const TimeOfDay(hour: 12, minute: 0));
    });

    test('오후 6시를 파싱하면 18시가 된다', () {
      final result = KoreanTimeParser.parse('오후 6시 저녁 약속');
      expect(result, isNotNull);
      expect(result!.time, const TimeOfDay(hour: 18, minute: 0));
    });

    test('공백 없이 오후3시도 파싱된다', () {
      final result = KoreanTimeParser.parse('오후3시 회의');
      expect(result, isNotNull);
      expect(result!.time, const TimeOfDay(hour: 15, minute: 0));
    });
  });

  group('KoreanTimeParser - N시 (오전/오후 미명시)', () {
    test('3시는 오후로 가정하여 15시가 된다 (N <= 6이면 오후)', () {
      final result = KoreanTimeParser.parse('3시 미팅');
      expect(result, isNotNull);
      expect(result!.time, const TimeOfDay(hour: 15, minute: 0));
    });

    test('9시는 오전으로 가정하여 9시가 된다 (N >= 7이면 오전)', () {
      final result = KoreanTimeParser.parse('9시 운동');
      expect(result, isNotNull);
      expect(result!.time, const TimeOfDay(hour: 9, minute: 0));
    });

    test('7시는 오전으로 가정하여 7시가 된다 (경계값)', () {
      final result = KoreanTimeParser.parse('7시 기상');
      expect(result, isNotNull);
      expect(result!.time, const TimeOfDay(hour: 7, minute: 0));
    });

    test('6시는 오후로 가정하여 18시가 된다 (경계값)', () {
      final result = KoreanTimeParser.parse('6시 저녁');
      expect(result, isNotNull);
      expect(result!.time, const TimeOfDay(hour: 18, minute: 0));
    });

    test('1시는 오후로 가정하여 13시가 된다', () {
      final result = KoreanTimeParser.parse('1시 점심');
      expect(result, isNotNull);
      expect(result!.time, const TimeOfDay(hour: 13, minute: 0));
    });
  });

  group('KoreanTimeParser - N시 반 패턴', () {
    test('오후 3시 반을 파싱하면 15시 30분이 된다', () {
      final result = KoreanTimeParser.parse('오후 3시 반 미팅');
      expect(result, isNotNull);
      expect(result!.time, const TimeOfDay(hour: 15, minute: 30));
    });

    test('오전 10시 반을 파싱하면 10시 30분이 된다', () {
      final result = KoreanTimeParser.parse('오전 10시 반 회의');
      expect(result, isNotNull);
      expect(result!.time, const TimeOfDay(hour: 10, minute: 30));
    });

    test('9시 반은 오전으로 가정하여 9시 30분이 된다', () {
      final result = KoreanTimeParser.parse('9시 반 운동');
      expect(result, isNotNull);
      expect(result!.time, const TimeOfDay(hour: 9, minute: 30));
    });
  });

  group('KoreanTimeParser - 시간대 키워드', () {
    test('아침은 08:00으로 파싱된다', () {
      final result = KoreanTimeParser.parse('아침 운동');
      expect(result, isNotNull);
      expect(result!.time, const TimeOfDay(hour: 8, minute: 0));
    });

    test('점심은 12:00으로 파싱된다', () {
      final result = KoreanTimeParser.parse('점심 약속');
      expect(result, isNotNull);
      expect(result!.time, const TimeOfDay(hour: 12, minute: 0));
    });

    test('저녁은 18:00으로 파싱된다', () {
      final result = KoreanTimeParser.parse('저녁 모임');
      expect(result, isNotNull);
      expect(result!.time, const TimeOfDay(hour: 18, minute: 0));
    });

    test('밤은 21:00으로 파싱된다', () {
      final result = KoreanTimeParser.parse('밤 독서');
      expect(result, isNotNull);
      expect(result!.time, const TimeOfDay(hour: 21, minute: 0));
    });

    test('새벽은 05:00으로 파싱된다', () {
      final result = KoreanTimeParser.parse('새벽 러닝');
      expect(result, isNotNull);
      expect(result!.time, const TimeOfDay(hour: 5, minute: 0));
    });
  });

  group('KoreanTimeParser - 우선순위 (명시적 시간 > 키워드)', () {
    test('명시적 시간이 있으면 키워드보다 우선한다', () {
      // "저녁"이 있어도 "오후 7시"가 명시적이므로 명시적 시간을 사용한다
      final result = KoreanTimeParser.parse('저녁 오후 7시 약속');
      expect(result, isNotNull);
      // 명시적 시간 패턴이 먼저 매칭되어야 한다
      expect(result!.time, const TimeOfDay(hour: 19, minute: 0));
    });
  });

  group('KoreanTimeParser - 매칭 인덱스', () {
    test('오전 10시의 매칭 인덱스가 올바르다', () {
      final text = '오전 10시 회의';
      final result = KoreanTimeParser.parse(text);
      expect(result, isNotNull);
      final matched = text.substring(result!.matchStart, result.matchEnd);
      // "오전 10시"가 매칭되어야 한다
      expect(matched, '오전 10시');
    });
  });

  group('KoreanTimeParser - 시간대 키워드 + 명시적 시간 조합', () {
    test('밤 12시를 파싱하면 자정(0시)이 된다', () {
      // "밤 12시"는 자정을 의미한다 — 정오(12시)가 아니다
      final result = KoreanTimeParser.parse('밤 12시 공부');
      expect(result, isNotNull);
      expect(result!.time, const TimeOfDay(hour: 0, minute: 0));
    });

    test('밤 11시를 파싱하면 23시가 된다', () {
      final result = KoreanTimeParser.parse('밤 11시 독서');
      expect(result, isNotNull);
      expect(result!.time, const TimeOfDay(hour: 23, minute: 0));
    });

    test('밤 9시를 파싱하면 21시가 된다', () {
      final result = KoreanTimeParser.parse('밤 9시 산책');
      expect(result, isNotNull);
      expect(result!.time, const TimeOfDay(hour: 21, minute: 0));
    });

    test('밤 1시를 파싱하면 새벽 1시(01:00)가 된다', () {
      // "밤 1시" = 자정 이후 새벽 시간대
      final result = KoreanTimeParser.parse('밤 1시 취침');
      expect(result, isNotNull);
      expect(result!.time, const TimeOfDay(hour: 1, minute: 0));
    });

    test('새벽 3시를 파싱하면 03:00이 된다', () {
      final result = KoreanTimeParser.parse('새벽 3시 기상');
      expect(result, isNotNull);
      expect(result!.time, const TimeOfDay(hour: 3, minute: 0));
    });

    test('새벽 5시 30분을 파싱하면 05:30이 된다', () {
      final result = KoreanTimeParser.parse('새벽 5시 30분 러닝');
      expect(result, isNotNull);
      expect(result!.time, const TimeOfDay(hour: 5, minute: 30));
    });

    test('아침 8시를 파싱하면 08:00이 된다', () {
      final result = KoreanTimeParser.parse('아침 8시 출근');
      expect(result, isNotNull);
      expect(result!.time, const TimeOfDay(hour: 8, minute: 0));
    });

    test('점심 12시를 파싱하면 정오(12:00)가 된다', () {
      final result = KoreanTimeParser.parse('점심 12시 식사');
      expect(result, isNotNull);
      expect(result!.time, const TimeOfDay(hour: 12, minute: 0));
    });

    test('점심 1시를 파싱하면 13:00이 된다', () {
      // "점심 1시" → PM 계열 → 1 + 12 = 13
      final result = KoreanTimeParser.parse('점심 1시 미팅');
      expect(result, isNotNull);
      expect(result!.time, const TimeOfDay(hour: 13, minute: 0));
    });

    test('저녁 7시를 파싱하면 19:00이 된다', () {
      final result = KoreanTimeParser.parse('저녁 7시 약속');
      expect(result, isNotNull);
      expect(result!.time, const TimeOfDay(hour: 19, minute: 0));
    });

    test('저녁 6시 반을 파싱하면 18:30이 된다', () {
      final result = KoreanTimeParser.parse('저녁 6시 반 퇴근');
      expect(result, isNotNull);
      expect(result!.time, const TimeOfDay(hour: 18, minute: 30));
    });

    test('밤 12시 30분을 파싱하면 00:30이 된다', () {
      // "밤 12시 30분" = 자정 30분
      final result = KoreanTimeParser.parse('밤 12시 30분 취침');
      expect(result, isNotNull);
      expect(result!.time, const TimeOfDay(hour: 0, minute: 30));
    });
  });

  group('KoreanTimeParser - 파싱 실패 케이스', () {
    test('시간 표현이 없으면 null을 반환한다', () {
      final result = KoreanTimeParser.parse('그냥 할 일');
      expect(result, isNull);
    });

    test('빈 문자열은 null을 반환한다', () {
      final result = KoreanTimeParser.parse('');
      expect(result, isNull);
    });

    test('숫자만 있는 텍스트는 null을 반환한다', () {
      final result = KoreanTimeParser.parse('123');
      expect(result, isNull);
    });
  });
}
