// F-Ritual: 데일리 리추얼 데이터 모델
// 워렌 버핏 25/5 법칙 기반 — 기간별 25개 목표 + TOP 5 선택을 저장한다.
// periodType은 'monthly' 또는 'yearly'이고,
// periodKey는 '2026-03' 또는 '2026' 형식이다.

/// 데일리 리추얼 모델 (워렌 버핏 25/5 법칙)
/// 기간(월간/연간)별로 25개 목표를 작성하고 TOP 5를 선택한다
class DailyRitual {
  final String id;

  /// 기간 유형: 'monthly' 또는 'yearly'
  final String periodType;

  /// 기간 키: 'yyyy-MM' (월간) 또는 'yyyy' (연간)
  final String periodKey;

  /// 25개 목표 텍스트 (빈 문자열 허용, 길이 고정 25)
  final List<String> goals;

  /// 선택된 TOP 5 인덱스 (0~24 범위, 최대 5개)
  final List<int> top5Indices;

  final DateTime createdAt;
  final DateTime updatedAt;

  const DailyRitual({
    required this.id,
    required this.periodType,
    required this.periodKey,
    required this.goals,
    required this.top5Indices,
    required this.createdAt,
    required this.updatedAt,
  });

  // ─── 직렬화 ───────────────────────────────────────────────────────────────

  /// Hive Map에서 DailyRitual 인스턴스를 생성한다
  factory DailyRitual.fromMap(Map<String, dynamic> map) {
    return DailyRitual(
      id: (map['id'] as String?) ?? '',
      periodType: (map['period_type'] as String?) ?? 'monthly',
      periodKey: (map['period_key'] as String?) ?? '',
      goals: _parseStringList(map['goals'], 25),
      top5Indices: _parseIntList(map['top5_indices']),
      createdAt: _parseDateTime(map['created_at']),
      updatedAt: _parseDateTime(map['updated_at']),
    );
  }

  /// Hive 저장용 Map으로 변환한다
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'period_type': periodType,
      'period_key': periodKey,
      'goals': goals,
      'top5_indices': top5Indices,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 불변 업데이트: 변경할 필드만 지정하여 새 인스턴스를 반환한다
  DailyRitual copyWith({
    List<String>? goals,
    List<int>? top5Indices,
    DateTime? updatedAt,
  }) {
    return DailyRitual(
      id: id,
      periodType: periodType,
      periodKey: periodKey,
      goals: goals ?? this.goals,
      top5Indices: top5Indices ?? this.top5Indices,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // ─── 내부 파싱 헬퍼 ─────────────────────────────────────────────────────

  /// 목표 리스트를 파싱한다 (expectedLength까지 빈 문자열로 패딩)
  static List<String> _parseStringList(dynamic raw, int expectedLength) {
    if (raw is List) {
      final parsed = raw.map((e) => e?.toString() ?? '').toList();
      // 부족한 슬롯은 빈 문자열로 채운다
      while (parsed.length < expectedLength) {
        parsed.add('');
      }
      return parsed.take(expectedLength).toList();
    }
    return List.filled(expectedLength, '');
  }

  /// 정수 리스트를 파싱한다 (TOP 5 인덱스 등)
  static List<int> _parseIntList(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => e is int ? e : int.tryParse(e.toString()) ?? -1)
          .where((i) => i >= 0)
          .toList();
    }
    return [];
  }

  /// ISO 8601 문자열 또는 DateTime을 DateTime으로 파싱한다
  static DateTime _parseDateTime(dynamic raw) {
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now();
  }
}
