// REST API 날짜 파싱 유틸리티
// ISO 8601 문자열 기반의 날짜 파싱을 제공한다.
// 모든 모델의 fromMap/toMap에서 이 헬퍼를 사용한다.

/// REST API 날짜 파싱 헬퍼
/// ISO 8601 문자열, 밀리초 타임스탬프, DateTime 객체를 일관되게 처리한다
abstract class DateParser {
  /// 다양한 형식의 날짜 값을 DateTime으로 파싱한다
  /// 지원 형식: ISO 8601 문자열, 밀리초 타임스탬프(int), DateTime 객체
  static DateTime parse(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.parse(value);
    }
    if (value is int) {
      // 밀리초 타임스탬프로 간주
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    // 알 수 없는 타입이면 현재 시각 반환
    return DateTime.now();
  }

  /// nullable 날짜 값을 파싱한다 (값이 없으면 null 반환)
  static DateTime? parseNullable(dynamic value) {
    if (value == null) return null;
    return parse(value);
  }

  /// DateTime을 ISO 8601 문자열로 변환한다 (REST API 전송용)
  static String toIso8601(DateTime dateTime) {
    return dateTime.toIso8601String();
  }

  /// nullable DateTime을 ISO 8601 문자열로 변환한다
  static String? toIso8601Nullable(DateTime? dateTime) {
    if (dateTime == null) return null;
    return dateTime.toIso8601String();
  }
}
