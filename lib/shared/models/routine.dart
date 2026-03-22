// 공유 모델: Routine (주간 반복 루틴)
// Hive routinesBox에 저장되는 루틴 모델이다.
// 필드: id, user_id, name, days_of_week, start_time, end_time,
//   color, is_active, created_at, updated_at
// days_of_week: text[] 배열 ("MON","TUE",...) — Java DayOfWeek enum 약어
// start_time/end_time: time 타입 "HH:mm:ss"
// color: text "#RRGGBB" hex 문자열
import 'package:flutter/material.dart';

import '../../core/utils/date_parser.dart';
import '../../core/error/app_exception.dart';

/// 주간 반복 루틴 모델
/// Hive routinesBox에 저장된다
class Routine {
  final String id;
  final String userId;
  final String name;
  final List<int> repeatDays;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int colorIndex;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Routine({
    required this.id,
    required this.userId,
    required this.name,
    required this.repeatDays,
    required this.startTime,
    required this.endTime,
    required this.colorIndex,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // ─── 요일 변환: int(ISO 8601) ↔ String(DayOfWeek 약어) ──────────────

  /// ISO 8601 요일 번호(1=월~7=일) → DayOfWeek 약어 매핑
  static const Map<int, String> _dayIntToString = {
    1: 'MON',
    2: 'TUE',
    3: 'WED',
    4: 'THU',
    5: 'FRI',
    6: 'SAT',
    7: 'SUN',
  };

  /// DayOfWeek 약어 → ISO 8601 요일 번호 역매핑
  static const Map<String, int> _dayStringToInt = {
    'MON': 1,
    'TUE': 2,
    'WED': 3,
    'THU': 4,
    'FRI': 5,
    'SAT': 6,
    'SUN': 7,
  };

  /// int 요일 리스트를 DayOfWeek 약어 리스트로 변환한다
  static List<String> _daysToStringList(List<int> days) {
    return days
        .map((d) => _dayIntToString[d] ?? 'MON')
        .toList();
  }

  /// DayOfWeek 약어 리스트를 int 요일 리스트로 변환한다
  /// 인식 불가능한 요일 문자열은 기본값 대신 건너뛴다
  static List<int> _daysFromStringList(List<dynamic> days) {
    return days
        .map((d) => _dayStringToInt[d.toString()])
        .whereType<int>()
        .toList();
  }

  // ─── 시간 변환: TimeOfDay ↔ "HH:mm" 문자열 ─────────────────

  /// TimeOfDay를 "HH:mm" 형식 문자열로 변환한다
  static String _timeToIsoString(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// "HH:mm" 또는 "HH:mm:ss" 형식 문자열에서 TimeOfDay로 변환한다
  /// 파싱 실패 시 기본값 TimeOfDay(hour: 0, minute: 0)을 반환한다
  static TimeOfDay _timeFromIsoString(String value) {
    try {
      final parts = value.split(':');
      if (parts.length < 2) return const TimeOfDay(hour: 0, minute: 0);
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (_) {
      // 잘못된 시간 문자열은 자정으로 기본 처리한다
      return const TimeOfDay(hour: 0, minute: 0);
    }
  }

  // ─── 색상 변환: colorIndex(0~7) ↔ hex 문자열 ─────────────────────────────

  /// colorIndex(0~7)에 대응하는 hex 색상 문자열 팔레트
  static const List<String> _colorPalette = [
    '#7C3AED', // 0: 업무/회의
    '#EC4899', // 1: 개인 일정
    '#3B82F6', // 2: 학습/공부
    '#22C55E', // 3: 운동/건강
    '#F59E0B', // 4: 약속/모임
    '#06B6D4', // 5: 재무/금융
    '#F97316', // 6: 창작/취미
    '#EF4444', // 7: 중요/긴급
  ];

  /// colorIndex를 hex 문자열로 변환한다
  static String _colorIndexToHex(int index) {
    final safeIndex = index.clamp(0, _colorPalette.length - 1);
    return _colorPalette[safeIndex];
  }

  /// hex 문자열에서 가장 가까운 colorIndex를 찾는다
  static int _hexToColorIndex(String? hex) {
    if (hex == null || hex.isEmpty) return 0;
    final upper = hex.toUpperCase();
    for (var i = 0; i < _colorPalette.length; i++) {
      if (_colorPalette[i].toUpperCase() == upper) return i;
    }
    final targetRgb = _parseHex(hex);
    if (targetRgb == null) return 0;
    var minDist = double.infinity;
    var closest = 0;
    for (var i = 0; i < _colorPalette.length; i++) {
      final rgb = _parseHex(_colorPalette[i]);
      if (rgb == null) continue;
      final dist = _colorDistance(targetRgb, rgb);
      if (dist < minDist) {
        minDist = dist;
        closest = i;
      }
    }
    return closest;
  }

  /// hex 문자열을 (r, g, b) 튜플로 파싱한다
  static (int, int, int)? _parseHex(String hex) {
    var clean = hex.replaceAll('#', '');
    if (clean.length == 6) {
      final r = int.tryParse(clean.substring(0, 2), radix: 16);
      final g = int.tryParse(clean.substring(2, 4), radix: 16);
      final b = int.tryParse(clean.substring(4, 6), radix: 16);
      if (r != null && g != null && b != null) return (r, g, b);
    }
    return null;
  }

  /// 두 RGB 색상 사이의 유클리드 거리를 계산한다
  static double _colorDistance((int, int, int) a, (int, int, int) b) {
    final dr = a.$1 - b.$1;
    final dg = a.$2 - b.$2;
    final db = a.$3 - b.$3;
    return (dr * dr + dg * dg + db * db).toDouble();
  }

  // ─── 직렬화/역직렬화 ─────────────────────────────────────────────────────

  /// Map 데이터에서 Routine 객체를 생성한다
  factory Routine.fromMap(Map<String, dynamic> map) {
    try {
      return Routine(
        id: map['id']?.toString() ?? '',
        // user_id 필드 (uuid)
        userId: (map['user_id'] ?? map['userId'] ?? '').toString(),
        name: (map['name'] as String?) ?? '',
        // days_of_week 필드 (text[] 배열)
        repeatDays: _daysFromStringList(
            map['days_of_week'] as List? ?? map['daysOfWeek'] as List? ?? []),
        // start_time/end_time 필드 (time 타입)
        // null 안전: 양쪽 키가 모두 null이면 빈 문자열로 처리한다
        startTime: _timeFromIsoString(
            (map['start_time'] ?? map['startTime'] ?? '').toString()),
        endTime: _timeFromIsoString(
            (map['end_time'] ?? map['endTime'] ?? '').toString()),
        // color 필드 (text hex)
        colorIndex: _hexToColorIndex(map['color'] as String?),
        // is_active 필드 (boolean)
        isActive: map['is_active'] as bool? ??
            map['active'] as bool? ??
            map['isActive'] as bool? ??
            true,
        createdAt: DateParser.parse(
            map['created_at'] ?? map['createdAt'] ?? DateTime.now()),
        updatedAt: DateParser.parse(
            map['updated_at'] ?? map['updatedAt'] ?? DateTime.now()),
      );
    } on TypeError catch (e) {
      throw AppException.validation(
        'Routine 파싱 실패 (id: ${map['id']}): 필드 타입이 올바르지 않습니다. 원인: $e',
      );
    }
  }

  /// INSERT용 Map (id 제외, user_id 포함)
  Map<String, dynamic> toInsertMap(String userId) {
    return {
      'user_id': userId,
      'name': name,
      'days_of_week': _daysToStringList(repeatDays),
      'start_time': _timeToIsoString(startTime),
      'end_time': _timeToIsoString(endTime),
      'color': _colorIndexToHex(colorIndex),
      'is_active': isActive,
    };
  }

  /// UPDATE용 Map (id 제외, user_id 포함)
  Map<String, dynamic> toUpdateMap() {
    return {
      'user_id': userId,
      'name': name,
      'days_of_week': _daysToStringList(repeatDays),
      'start_time': _timeToIsoString(startTime),
      'end_time': _timeToIsoString(endTime),
      'color': _colorIndexToHex(colorIndex),
      'is_active': isActive,
    };
  }

  /// 레거시 호환: 기존 toMap 호출부를 위한 별칭
  Map<String, dynamic> toMap() => toUpdateMap();

  /// 불변 업데이트: 특정 필드만 변경된 새 인스턴스를 반환한다
  Routine copyWith({
    String? name,
    List<int>? repeatDays,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    int? colorIndex,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return Routine(
      id: id,
      userId: userId,
      name: name ?? this.name,
      repeatDays: repeatDays ?? this.repeatDays,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      colorIndex: colorIndex ?? this.colorIndex,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
