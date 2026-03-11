// 공유 모델: Habit (습관 정의)
// Hive habitsBox에 저장되는 습관 모델이다.
// 필드: id, user_id, name, icon, color, is_active, current_streak, longest_streak
import '../../core/error/app_exception.dart';

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

  const Habit({
    required this.id,
    required this.name,
    this.icon,
    this.color,
    this.isActive = true,
    this.currentStreak = 0,
    this.longestStreak = 0,
  });

  // ─── UI 호환 컴퓨티드 속성 ────────────────────────────────────────────────

  /// UI에서 사용하는 colorIndex (0~7)
  int get colorIndex => 0;

  /// UI에서 사용하는 userId (빈 문자열)
  String get userId => '';

  // ─── 직렬화 ───────────────────────────────────────────────────────────────

  /// Map 데이터에서 Habit 객체를 생성한다
  factory Habit.fromMap(Map<String, dynamic> map) {
    try {
      return Habit(
        id: map['id']?.toString() ?? '',
        name: map['name'] as String,
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
      );
    } on TypeError catch (e) {
      throw AppException.validation(
        'Habit 파싱 실패 (id: ${map['id']}): 필드 타입이 올바르지 않습니다. 원인: $e',
      );
    }
  }

  /// INSERT용 Map (id 제외, user_id 포함)
  Map<String, dynamic> toInsertMap(String userId) {
    return {
      'user_id': userId,
      'name': name,
      'icon': icon,
      'color': color,
      'is_active': isActive,
    };
  }

  /// UPDATE용 Map (id, user_id 제외)
  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'icon': icon,
      'color': color,
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
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
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
