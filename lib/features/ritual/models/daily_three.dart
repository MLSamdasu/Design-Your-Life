// F-Ritual: 오늘의 할일 3개 (3의 법칙) 데이터 모델
// 매일 아침 3개의 핵심 할일을 작성하면 실제 Todo로 생성된다.
// date 필드로 날짜별 고유성을 보장한다.

/// 오늘의 할일 3개 모델 (3의 법칙)
/// 매일 리셋되며, 작성된 3개 할일은 실제 Todo로 생성된다
class DailyThree {
  final String id;

  /// 날짜 키: 'yyyy-MM-dd' 형식
  final String date;

  /// 3개 할일 텍스트 (빈 문자열 허용, 길이 고정 3)
  final List<String> tasks;

  /// 생성된 Todo의 ID 목록 (Todo 연결 추적용)
  final List<String> todoIds;

  /// 작성 완료 여부 (3개 모두 입력 후 확정 시 true)
  final bool isCompleted;

  final DateTime createdAt;

  const DailyThree({
    required this.id,
    required this.date,
    required this.tasks,
    required this.todoIds,
    required this.isCompleted,
    required this.createdAt,
  });

  // ─── 직렬화 ───────────────────────────────────────────────────────────────

  /// Hive Map에서 DailyThree 인스턴스를 생성한다
  factory DailyThree.fromMap(Map<String, dynamic> map) {
    return DailyThree(
      id: (map['id'] as String?) ?? '',
      date: (map['date'] as String?) ?? '',
      tasks: _parseStringList(map['tasks'], 3),
      todoIds: _parseStringList(map['todo_ids'], 0),
      isCompleted: map['is_completed'] as bool? ?? false,
      createdAt: _parseDateTime(map['created_at']),
    );
  }

  /// Hive 저장용 Map으로 변환한다
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'tasks': tasks,
      'todo_ids': todoIds,
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 불변 업데이트: 변경할 필드만 지정하여 새 인스턴스를 반환한다
  DailyThree copyWith({
    List<String>? tasks,
    List<String>? todoIds,
    bool? isCompleted,
  }) {
    return DailyThree(
      id: id,
      date: date,
      tasks: tasks ?? this.tasks,
      todoIds: todoIds ?? this.todoIds,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }

  // ─── 내부 파싱 헬퍼 ─────────────────────────────────────────────────────

  /// 문자열 리스트를 파싱한다 (minLength > 0이면 해당 길이까지 패딩)
  static List<String> _parseStringList(dynamic raw, int minLength) {
    if (raw is List) {
      final parsed = raw.map((e) => e?.toString() ?? '').toList();
      while (parsed.length < minLength) {
        parsed.add('');
      }
      if (minLength > 0) return parsed.take(minLength).toList();
      return parsed;
    }
    if (minLength > 0) return List.filled(minLength, '');
    return [];
  }

  /// ISO 8601 문자열 또는 DateTime을 DateTime으로 파싱한다
  static DateTime _parseDateTime(dynamic raw) {
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now();
  }
}
