// 공유 모델: Goal (년간/월간 목표)
// Hive goalsBox에 저장되는 목표 모델이다.
// 필드: id, user_id, title, description, period, year, month,
//   is_completed, tag_ids, created_at, updated_at
import '../../core/utils/date_parser.dart';
import '../../core/error/app_exception.dart';
import '../enums/goal_period.dart';

/// 목표 모델
/// Hive goalsBox에 저장된다
/// 년간/월간 기간을 period 필드로 구분한다
class Goal {
  final String id;
  final String userId;

  /// 목표 제목 (최대 200자)
  final String title;

  /// 목표 설명 (선택, 최대 1000자)
  final String? description;

  /// 기간 유형: 년간(yearly) / 월간(monthly)
  final GoalPeriod period;

  /// 대상 연도
  final int year;

  /// 대상 월 (월간 목표일 때만 유효)
  final int? month;

  /// 완료 여부
  final bool isCompleted;

  /// 부착된 태그 ID 목록
  final List<String> tagIds;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Goal({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.period,
    required this.year,
    this.month,
    this.isCompleted = false,
    this.tagIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Map 데이터에서 Goal 객체를 생성한다
  factory Goal.fromMap(Map<String, dynamic> map) {
    try {
      return Goal(
        id: map['id']?.toString() ?? '',
        userId: (map['user_id'] ?? map['userId'] ?? '').toString(),
        title: (map['title'] as String?) ?? '',
        description: map['description'] as String?,
        period: GoalPeriod.values.firstWhere(
          (e) => e.name == (map['period'] as String?),
          orElse: () => GoalPeriod.yearly,
        ),
        year: (map['year'] as num?)?.toInt() ?? DateTime.now().year,
        month: (map['month'] as num?)?.toInt(),
        isCompleted: map['is_completed'] as bool? ??
            map['isCompleted'] as bool? ??
            false,
        // tag_ids 필드 (jsonb 배열 또는 text[])
        tagIds: map['tag_ids'] != null
            ? List<String>.from(map['tag_ids'] as List)
            : map['tagIds'] != null
                ? List<String>.from(map['tagIds'] as List)
                : const [],
        createdAt: DateParser.parse(
            map['created_at'] ?? map['createdAt'] ?? DateTime.now()),
        updatedAt: DateParser.parse(
            map['updated_at'] ?? map['updatedAt'] ?? DateTime.now()),
      );
    } on TypeError catch (e) {
      throw AppException.validation(
        'Goal 파싱 실패 (id: ${map['id']}): 필드 타입이 올바르지 않습니다. 원인: $e',
      );
    }
  }

  /// INSERT용 Map (id 제외, user_id 포함)
  Map<String, dynamic> toInsertMap(String userId) {
    return {
      'user_id': userId,
      'title': title,
      'description': description,
      'period': period.name,
      'year': year,
      'month': month,
      'is_completed': isCompleted,
      'tag_ids': tagIds,
    };
  }

  /// UPDATE용 Map (id, user_id 제외 — user_id는 Hive 복원 시 필요)
  Map<String, dynamic> toUpdateMap() {
    return {
      'user_id': userId,
      'title': title,
      'description': description,
      'period': period.name,
      'year': year,
      'month': month,
      'is_completed': isCompleted,
      'tag_ids': tagIds,
    };
  }

  /// 레거시 호환: 기존 toMap 호출부를 위한 별칭
  Map<String, dynamic> toMap() => toUpdateMap();

  /// 불변 업데이트: 특정 필드만 변경된 새 인스턴스를 반환한다
  Goal copyWith({
    String? title,
    String? description,
    bool clearDescription = false,
    GoalPeriod? period,
    int? year,
    int? month,
    bool clearMonth = false,
    bool? isCompleted,
    List<String>? tagIds,
    DateTime? updatedAt,
  }) {
    return Goal(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description:
          clearDescription ? null : (description ?? this.description),
      period: period ?? this.period,
      year: year ?? this.year,
      month: clearMonth ? null : (month ?? this.month),
      isCompleted: isCompleted ?? this.isCompleted,
      tagIds: tagIds ?? this.tagIds,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
