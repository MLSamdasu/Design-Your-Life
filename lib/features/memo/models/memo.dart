// 공유 모델: Memo (메모 아이템)
// Hive memosBox에 저장되는 메모 모델이다.
// 필드: id, title, content, type, strokes_json, color_index,
//   is_pinned, created_at, updated_at

import '../../../core/error/app_exception.dart';
import '../../../core/utils/date_parser.dart';

/// 메모 타입 열거형 (텍스트 / 드로잉)
/// Hive에는 String('text', 'drawing')으로 저장된다
enum MemoType {
  /// 텍스트 메모
  text('text'),

  /// 드로잉 (손글씨/스케치) 메모
  drawing('drawing');

  /// Hive 저장용 문자열 값
  final String value;
  const MemoType(this.value);

  /// 문자열에서 MemoType으로 변환한다 (기본값: text)
  static MemoType fromString(String? s) =>
      s == 'drawing' ? MemoType.drawing : MemoType.text;
}

/// 메모 아이템 모델
/// Hive memosBox에 저장된다
class Memo {
  final String id;
  final String title;

  /// 텍스트 본문
  final String content;

  /// 메모 타입 ('text' 또는 'drawing')
  final String type;

  /// 드로잉 스트로크 JSON (type='drawing'일 때 사용)
  final String strokesJson;

  /// 메모 색상 인덱스 (0~7)
  final int colorIndex;

  /// 고정 메모 여부
  final bool isPinned;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Memo({
    required this.id,
    required this.title,
    this.content = '',
    this.type = 'text',
    this.strokesJson = '',
    this.colorIndex = 0,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // ─── 직렬화 ───────────────────────────────────────────────────────────────

  /// Map 데이터에서 Memo 객체를 생성한다
  /// 백업 호환을 위해 camelCase와 snake_case 키를 모두 지원한다
  factory Memo.fromMap(Map<String, dynamic> map) {
    try {
      return Memo(
        id: map['id']?.toString() ?? '',
        title: (map['title'] as String?) ?? '',
        content: (map['content'] as String?) ?? '',
        type: (map['type'] as String?) ?? 'text',
        strokesJson: (map['strokes_json'] as String?) ??
            (map['strokesJson'] as String?) ??
            '',
        colorIndex: (map['color_index'] as num?)?.toInt() ??
            (map['colorIndex'] as num?)?.toInt() ??
            0,
        isPinned: map['is_pinned'] as bool? ??
            map['isPinned'] as bool? ??
            false,
        createdAt: DateParser.parse(
            map['created_at'] ?? map['createdAt'] ?? DateTime.now()),
        updatedAt: DateParser.parse(
            map['updated_at'] ?? map['updatedAt'] ?? DateTime.now()),
      );
    } on TypeError catch (e) {
      throw AppException.validation(
        'Memo 파싱 실패 (id: ${map['id']}): '
        '필드 타입이 올바르지 않습니다. 원인: $e',
      );
    }
  }

  /// INSERT용 Map (id 제외, user_id 포함)
  Map<String, dynamic> toInsertMap(String userId) {
    return {
      'user_id': userId,
      'title': title,
      'content': content,
      'type': type,
      'strokes_json': strokesJson,
      'color_index': colorIndex,
      'is_pinned': isPinned,
    };
  }

  /// UPDATE용 Map (id, user_id 제외)
  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'content': content,
      'type': type,
      'strokes_json': strokesJson,
      'color_index': colorIndex,
      'is_pinned': isPinned,
    };
  }

  /// 불변 업데이트: 특정 필드만 변경된 새 인스턴스를 반환한다
  Memo copyWith({
    String? title,
    String? content,
    String? type,
    String? strokesJson,
    int? colorIndex,
    bool? isPinned,
    DateTime? updatedAt,
  }) {
    return Memo(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      strokesJson: strokesJson ?? this.strokesJson,
      colorIndex: colorIndex ?? this.colorIndex,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
