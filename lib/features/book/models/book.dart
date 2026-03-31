// F-Book: Book 모델 — Hive booksBox에 저장되는 도서 모델
// 페이지 기반 또는 챕터 기반 독서 추적을 지원한다.
import '../../../core/error/app_exception.dart';
import '../../../core/utils/date_parser.dart';

/// 도서 모델 — Hive booksBox에 저장된다
class Book {
  final String id;
  final String title;
  final String? description;
  final String? coverImageBase64; // 표지 이미지 base64
  final int totalPages;
  final int totalChapters; // 0이면 페이지 기반
  final String trackingMode; // 'page' or 'chapter'
  final DateTime startDate;
  final DateTime? targetDate; // 완독 목표일
  final String? targetMonth; // 완독 목표 월 'yyyy-MM'
  final DateTime? examDate; // 시험 날짜
  final int daysPerChapter; // 챕터당 소요 일수 (기본 1)
  final bool isCompleted;
  final int currentProgress; // 현재 진도
  final DateTime createdAt;
  final DateTime updatedAt;

  const Book({
    required this.id,
    required this.title,
    this.description,
    this.coverImageBase64,
    this.totalPages = 0,
    this.totalChapters = 0,
    this.trackingMode = 'page',
    required this.startDate,
    this.targetDate,
    this.targetMonth,
    this.examDate,
    this.daysPerChapter = 1,
    this.isCompleted = false,
    this.currentProgress = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  // ─── 직렬화 ───────────────────────────────────────────────────────────────

  /// Map 데이터에서 Book 객체를 생성한다
  factory Book.fromMap(Map<String, dynamic> map) {
    try {
      return Book(
        id: map['id']?.toString() ?? '',
        title: (map['title'] as String?) ?? '',
        description: map['description'] as String?,
        coverImageBase64: map['cover_image_base64'] as String?,
        totalPages: (map['total_pages'] as num?)?.toInt() ?? 0,
        totalChapters: (map['total_chapters'] as num?)?.toInt() ?? 0,
        trackingMode: (map['tracking_mode'] as String?) ?? 'page',
        startDate: DateParser.parse(map['start_date'] ?? DateTime.now()),
        targetDate: map['target_date'] != null
            ? DateParser.parse(map['target_date'])
            : null,
        targetMonth: map['target_month'] as String?,
        examDate: map['exam_date'] != null
            ? DateParser.parse(map['exam_date'])
            : null,
        daysPerChapter: (map['days_per_chapter'] as num?)?.toInt() ?? 1,
        isCompleted: map['is_completed'] as bool? ?? false,
        currentProgress: (map['current_progress'] as num?)?.toInt() ?? 0,
        createdAt: DateParser.parse(map['created_at'] ?? DateTime.now()),
        updatedAt: DateParser.parse(map['updated_at'] ?? DateTime.now()),
      );
    } on TypeError catch (e) {
      throw AppException.validation(
        'Book 파싱 실패 (id: ${map['id']}): '
        '필드 타입이 올바르지 않습니다. 원인: $e',
      );
    }
  }

  /// INSERT용 Map (id 제외, user_id 포함)
  Map<String, dynamic> toInsertMap(String userId) => {
        'user_id': userId,
        'title': title,
        'description': description,
        'cover_image_base64': coverImageBase64,
        'total_pages': totalPages,
        'total_chapters': totalChapters,
        'tracking_mode': trackingMode,
        'start_date': startDate.toIso8601String(),
        'target_date': targetDate?.toIso8601String(),
        'target_month': targetMonth,
        'exam_date': examDate?.toIso8601String(),
        'days_per_chapter': daysPerChapter,
        'is_completed': isCompleted,
        'current_progress': currentProgress,
      };

  /// UPDATE용 Map (id, user_id 제외)
  Map<String, dynamic> toUpdateMap() => {
        'title': title,
        'description': description,
        'cover_image_base64': coverImageBase64,
        'total_pages': totalPages,
        'total_chapters': totalChapters,
        'tracking_mode': trackingMode,
        'start_date': startDate.toIso8601String(),
        'target_date': targetDate?.toIso8601String(),
        'target_month': targetMonth,
        'exam_date': examDate?.toIso8601String(),
        'days_per_chapter': daysPerChapter,
        'is_completed': isCompleted,
        'current_progress': currentProgress,
      };

  /// 불변 업데이트: 특정 필드만 변경된 새 인스턴스를 반환한다
  Book copyWith({
    String? title,
    String? description,
    String? coverImageBase64,
    int? totalPages,
    int? totalChapters,
    String? trackingMode,
    DateTime? startDate,
    DateTime? targetDate,
    String? targetMonth,
    DateTime? examDate,
    int? daysPerChapter,
    bool? isCompleted,
    int? currentProgress,
    DateTime? updatedAt,
  }) =>
      Book(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        coverImageBase64: coverImageBase64 ?? this.coverImageBase64,
        totalPages: totalPages ?? this.totalPages,
        totalChapters: totalChapters ?? this.totalChapters,
        trackingMode: trackingMode ?? this.trackingMode,
        startDate: startDate ?? this.startDate,
        targetDate: targetDate ?? this.targetDate,
        targetMonth: targetMonth ?? this.targetMonth,
        examDate: examDate ?? this.examDate,
        daysPerChapter: daysPerChapter ?? this.daysPerChapter,
        isCompleted: isCompleted ?? this.isCompleted,
        currentProgress: currentProgress ?? this.currentProgress,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
