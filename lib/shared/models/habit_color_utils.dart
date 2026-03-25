// 습관 색상 유틸리티
// colorIndex 계산과 hex 파싱 로직을 분리한다.

/// 습관/루틴 공용 색상 팔레트 및 매칭 유틸리티
class HabitColorUtils {
  HabitColorUtils._();

  /// 이벤트 색상 팔레트 (Routine과 동일)
  static const List<String> colorPalette = [
    '#7C3AED', '#EC4899', '#3B82F6', '#22C55E',
    '#F59E0B', '#06B6D4', '#F97316', '#EF4444',
  ];

  /// hex 문자열을 RGB 튜플로 파싱한다
  static (int, int, int)? parseHex(String hex) {
    final clean = hex.replaceAll('#', '');
    if (clean.length != 6) return null;
    final r = int.tryParse(clean.substring(0, 2), radix: 16);
    final g = int.tryParse(clean.substring(2, 4), radix: 16);
    final b = int.tryParse(clean.substring(4, 6), radix: 16);
    if (r == null || g == null || b == null) return null;
    return (r, g, b);
  }

  /// color 필드(hex 문자열 또는 정수 인덱스)를 팔레트 인덱스(0~7)로 변환한다
  /// 일치하는 색상이 없으면 RGB 거리 기반으로 가장 가까운 색상을 반환한다
  static int resolveColorIndex(String? color) {
    if (color == null || color.isEmpty) return 0;

    // 정수 문자열인 경우 직접 파싱 (Todo와 호환)
    final asInt = int.tryParse(color);
    if (asInt != null) return (asInt >= 0 && asInt <= 7) ? asInt : 0;

    // hex 문자열인 경우 팔레트에서 정확히 매칭
    final upper = color.toUpperCase();
    for (var i = 0; i < colorPalette.length; i++) {
      if (colorPalette[i].toUpperCase() == upper) return i;
    }

    // 정확한 매칭 없으면 RGB 거리로 가장 가까운 색상 선택
    final target = parseHex(color);
    if (target == null) return 0;
    var minDist = double.infinity;
    var closest = 0;
    for (var i = 0; i < colorPalette.length; i++) {
      final rgb = parseHex(colorPalette[i]);
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
}
