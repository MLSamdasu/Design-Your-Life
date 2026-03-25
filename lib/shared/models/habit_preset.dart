// 인기 습관 프리셋 정의
// 서버 공개 컬렉션 없이 앱 번들에 포함되는 정적 프리셋이다.

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
