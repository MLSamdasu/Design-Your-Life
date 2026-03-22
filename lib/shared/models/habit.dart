// 공유 모델: Habit (습관 정의)
// Hive habitsBox에 저장되는 습관 모델이다.
// 필드: id, user_id, name, icon, color, is_active, current_streak, longest_streak,
//        frequency, repeat_days, created_at, updated_at
import '../../core/error/app_exception.dart';
import '../../core/utils/date_parser.dart';

/// 습관 빈도 유형 (daily, weekly, custom)
enum HabitFrequency {
  /// 매일
  daily,
  /// 특정 요일 (주간)
  weekly,
  /// 커스텀 (특정 요일 선택)
  custom,
}

/// 습관 정의 모델
/// Hive habitsBox에 저장된다
class Habit {
  final String id;
  final String name;
  final String? icon;
  final String? color;
  final bool isActive;
  final int currentStreak;
  final int longestStreak;

  /// 습관 빈도 유형 (daily, weekly, custom)
  final HabitFrequency frequency;

  /// weekly/custom인 경우 실행 요일 목록 (1=월 ... 7=일, ISO 8601)
  final List<int> repeatDays;

  /// 습관 생성 시각
  final DateTime createdAt;

  /// 습관 최종 수정 시각
  final DateTime updatedAt;

  Habit({
    required this.id,
    required this.name,
    this.icon,
    this.color,
    this.isActive = true,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.frequency = HabitFrequency.daily,
    this.repeatDays = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // ─── UI 호환 컴퓨티드 속성 ────────────────────────────────────────────────

  /// UI에서 사용하는 colorIndex (0~7)
  /// color 필드(hex 문자열)를 이벤트 색상 팔레트 인덱스로 변환한다
  /// 일치하는 색상이 없으면 RGB 거리 기반으로 가장 가까운 색상을 반환한다
  int get colorIndex {
    if (color == null || color!.isEmpty) return 0;
    // 정수 문자열인 경우 직접 파싱 (Todo와 호환)
    final asInt = int.tryParse(color!);
    if (asInt != null) return (asInt >= 0 && asInt <= 7) ? asInt : 0;
    // hex 문자열인 경우 팔레트에서 매칭
    final upper = color!.toUpperCase();
    for (var i = 0; i < _colorPalette.length; i++) {
      if (_colorPalette[i].toUpperCase() == upper) return i;
    }
    // 정확한 매칭 없으면 RGB 거리로 가장 가까운 색상 선택
    final target = _parseHex(color!);
    if (target == null) return 0;
    var minDist = double.infinity;
    var closest = 0;
    for (var i = 0; i < _colorPalette.length; i++) {
      final rgb = _parseHex(_colorPalette[i]);
      if (rgb == null) continue;
      final dr = target.$1 - rgb.$1;
      final dg = target.$2 - rgb.$2;
      final db = target.$3 - rgb.$3;
      final dist = (dr * dr + dg * dg + db * db).toDouble();
      if (dist < minDist) {
        minDist = dist;
        closest = i;
      }
    }
    return closest;
  }

  /// 이벤트 색상 팔레트 (Routine과 동일)
  static const List<String> _colorPalette = [
    '#7C3AED', '#EC4899', '#3B82F6', '#22C55E',
    '#F59E0B', '#06B6D4', '#F97316', '#EF4444',
  ];

  /// hex 문자열을 RGB 튜플로 파싱한다
  static (int, int, int)? _parseHex(String hex) {
    final clean = hex.replaceAll('#', '');
    if (clean.length != 6) return null;
    final r = int.tryParse(clean.substring(0, 2), radix: 16);
    final g = int.tryParse(clean.substring(2, 4), radix: 16);
    final b = int.tryParse(clean.substring(4, 6), radix: 16);
    if (r == null || g == null || b == null) return null;
    return (r, g, b);
  }

  /// UI에서 사용하는 userId (빈 문자열)
  String get userId => '';

  // ─── 빈도 관련 유틸리티 ─────────────────────────────────────────────────

  /// 특정 날짜에 이 습관이 예정되어 있는지 판단한다
  /// daily: 항상 true
  /// weekly/custom: 해당 날짜의 요일이 repeatDays에 포함되어야 true
  bool isScheduledFor(DateTime date) {
    if (frequency == HabitFrequency.daily) return true;
    // Dart weekday: 1=월 ... 7=일 (ISO 8601과 동일)
    return repeatDays.contains(date.weekday);
  }

  // ─── 직렬화 ───────────────────────────────────────────────────────────────

  /// Map 데이터에서 Habit 객체를 생성한다
  factory Habit.fromMap(Map<String, dynamic> map) {
    try {
      // frequency 문자열을 enum으로 변환한다 (하위 호환: 없으면 daily)
      final freqStr = map['frequency'] as String? ??
          map['habitFrequency'] as String? ??
          'daily';
      final frequency = HabitFrequency.values.firstWhere(
        (e) => e.name == freqStr,
        orElse: () => HabitFrequency.daily,
      );

      // repeat_days를 List<int>로 파싱한다 (하위 호환: 없으면 빈 리스트)
      final rawDays = map['repeat_days'] ?? map['repeatDays'];
      final repeatDays = rawDays is List
          // 백업 복원 시 JSON 직렬화로 int가 String으로 변환될 수 있으므로 안전하게 파싱한다
          ? rawDays
              .map((e) =>
                  e is num ? e.toInt() : int.tryParse(e.toString()) ?? 0)
              .toList()
          : <int>[];

      // created_at / updated_at 타임스탬프 파싱 (하위 호환: 없으면 현재 시각)
      final rawCreated = map['created_at'] ?? map['createdAt'];
      final rawUpdated = map['updated_at'] ?? map['updatedAt'];

      return Habit(
        id: map['id']?.toString() ?? '',
        name: (map['name'] as String?) ?? '',
        icon: map['icon'] as String?,
        color: map['color'] as String?,
        // is_active 필드 (boolean)
        isActive: map['is_active'] as bool? ??
            map['active'] as bool? ??
            map['isActive'] as bool? ??
            true,
        currentStreak: (map['current_streak'] as num?)?.toInt() ??
            (map['currentStreak'] as num?)?.toInt() ??
            0,
        longestStreak: (map['longest_streak'] as num?)?.toInt() ??
            (map['longestStreak'] as num?)?.toInt() ??
            0,
        frequency: frequency,
        repeatDays: repeatDays,
        createdAt: rawCreated != null ? DateParser.parse(rawCreated) : null,
        updatedAt: rawUpdated != null ? DateParser.parse(rawUpdated) : null,
      );
    } on TypeError catch (e) {
      throw AppException.validation(
        'Habit 파싱 실패 (id: ${map['id']}): 필드 타입이 올바르지 않습니다. 원인: $e',
      );
    }
  }

  /// INSERT용 Map (id 제외, user_id 포함)
  /// 백업/복원 시 streak 데이터가 누락되지 않도록 포함한다
  Map<String, dynamic> toInsertMap(String userId) {
    return {
      'user_id': userId,
      'name': name,
      'icon': icon,
      'color': color,
      'is_active': isActive,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'frequency': frequency.name,
      'repeat_days': repeatDays,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// UPDATE용 Map (id, user_id 제외)
  /// updated_at을 현재 시각으로 갱신한다
  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'icon': icon,
      'color': color,
      'is_active': isActive,
      'frequency': frequency.name,
      'repeat_days': repeatDays,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// 레거시 호환: 기존 toCreateMap 호출부를 위한 별칭
  Map<String, dynamic> toCreateMap() => toUpdateMap();

  /// 불변 업데이트: 특정 필드만 변경된 새 인스턴스를 반환한다
  Habit copyWith({
    String? name,
    String? icon,
    String? color,
    bool? isActive,
    int? currentStreak,
    int? longestStreak,
    HabitFrequency? frequency,
    List<int>? repeatDays,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      frequency: frequency ?? this.frequency,
      repeatDays: repeatDays ?? this.repeatDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 인기 습관 프리셋 (앱 번들 하드코딩)
/// 서버 공개 컬렉션 없이 즉시 등록 가능하도록 정적으로 포함한다
class HabitPreset {
  final String name;
  final String icon;
  final String? color;

  const HabitPreset({
    required this.name,
    required this.icon,
    this.color,
  });

  /// 5가지 인기 습관 프리셋 목록
  static const List<HabitPreset> presets = [
    HabitPreset(name: '운동 30분', icon: '\u{1F4AA}', color: '#4CAF50'),
    HabitPreset(name: '독서', icon: '\u{1F4DA}', color: '#2196F3'),
    HabitPreset(name: '물 마시기', icon: '\u{1F4A7}', color: '#03A9F4'),
    HabitPreset(name: '영어 공부', icon: '\u{1F4AC}', color: '#9C27B0'),
    HabitPreset(name: '일기 쓰기', icon: '\u{270F}\u{FE0F}', color: '#FF9800'),
  ];
}
