// F-Book: ReadingPlan 모델
// Hive readingPlansBox에 저장되는 독서 계획 모델이다.
// 날짜별 읽어야 할 페이지/챕터 범위를 나타낸다.

import '../../../core/error/app_exception.dart';
import '../../../core/utils/date_parser.dart';

/// 독서 계획 아이템 모델
/// Hive readingPlansBox에 저장된다
class ReadingPlan {
  final String id;
  final String bookId;

  /// 계획 날짜 ('yyyy-MM-dd' 형식)
  final String date;

  /// 시작 페이지/챕터 번호
  final int startUnit;

  /// 끝 페이지/챕터 번호
  final int endUnit;

  /// 완료 여부
  final bool isCompleted;

  /// 미루기 처리 여부
  final bool isPostponed;

  final DateTime createdAt;

  const ReadingPlan({
    required this.id,
    required this.bookId,
    required this.date,
    required this.startUnit,
    required this.endUnit,
    this.isCompleted = false,
    this.isPostponed = false,
    required this.createdAt,
  });

  // ─── 직렬화 ───────────────────────────────────────────────────────────────

  /// Map 데이터에서 ReadingPlan 객체를 생성한다
  factory ReadingPlan.fromMap(Map<String, dynamic> map) {
    try {
      return ReadingPlan(
        id: map['id']?.toString() ?? '',
        bookId: (map['book_id'] as String?) ?? '',
        date: (map['date'] as String?) ?? '',
        startUnit: (map['start_unit'] as num?)?.toInt() ?? 0,
        endUnit: (map['end_unit'] as num?)?.toInt() ?? 0,
        isCompleted: map['is_completed'] as bool? ?? false,
        isPostponed: map['is_postponed'] as bool? ?? false,
        createdAt: DateParser.parse(map['created_at'] ?? DateTime.now()),
      );
    } on TypeError catch (e) {
      throw AppException.validation(
        'ReadingPlan 파싱 실패 (id: ${map['id']}): '
        '필드 타입이 올바르지 않습니다. 원인: $e',
      );
    }
  }

  /// Hive 저장용 Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'book_id': bookId,
        'date': date,
        'start_unit': startUnit,
        'end_unit': endUnit,
        'is_completed': isCompleted,
        'is_postponed': isPostponed,
        'created_at': createdAt.toIso8601String(),
      };

  /// 불변 업데이트: 특정 필드만 변경된 새 인스턴스를 반환한다
  ReadingPlan copyWith({
    String? date,
    int? startUnit,
    int? endUnit,
    bool? isCompleted,
    bool? isPostponed,
  }) =>
      ReadingPlan(
        id: id,
        bookId: bookId,
        date: date ?? this.date,
        startUnit: startUnit ?? this.startUnit,
        endUnit: endUnit ?? this.endUnit,
        isCompleted: isCompleted ?? this.isCompleted,
        isPostponed: isPostponed ?? this.isPostponed,
        createdAt: createdAt,
      );
}
