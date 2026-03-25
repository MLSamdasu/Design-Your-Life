// F7-M2: 드로잉 스트로크 직렬화 헬퍼
// List<StrokeData> ↔ JSON 문자열 변환을 담당한다.
// Memo.strokesJson 필드에 저장/복원할 때 사용한다.
import 'dart:convert';

import 'stroke_data.dart';

/// 스트로크 목록 직렬화/역직렬화 유틸리티
/// Hive에 JSON 문자열로 저장하고 복원하는 데 사용한다
abstract class StrokeSerializer {
  /// 스트로크 목록을 JSON 문자열로 변환한다
  static String encode(List<StrokeData> strokes) {
    final list = strokes.map((s) => s.toJson()).toList();
    return jsonEncode(list);
  }

  /// JSON 문자열에서 스트로크 목록을 복원한다
  /// 빈 문자열이나 null이면 빈 목록을 반환한다
  static List<StrokeData> decode(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List;
      return list
          .map((e) => StrokeData.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // 손상된 JSON은 빈 목록으로 복원한다
      return [];
    }
  }
}
