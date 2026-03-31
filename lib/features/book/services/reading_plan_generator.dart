// F-Book: ReadingPlanGenerator — 독서 계획 자동/수동 생성 및 미루기 재분배
import 'package:uuid/uuid.dart';
import '../../../core/utils/date_utils.dart';
import '../models/book.dart';
import '../models/reading_plan.dart';

/// 수동 분배 항목 모델
class ManualPlanEntry {
  final DateTime date;
  final int startPage;
  final int endPage;
  const ManualPlanEntry({required this.date, required this.startPage, required this.endPage});
}

/// 독서 계획 자동/수동 생성 및 재분배 서비스
class ReadingPlanGenerator {
  static const _uuid = Uuid();

  /// 도서 정보 기반 자동 계획 생성 (페이지/챕터 모드)
  static List<ReadingPlan> generatePlans(Book book) {
    if (book.trackingMode == 'chapter') return _generateChapterPlans(book);
    return _generatePagePlans(book);
  }

  /// 수동 분배 모드: 사용자 입력 기반으로 독서 계획을 생성한다
  static List<ReadingPlan> generateManualPlans(Book book, List<ManualPlanEntry> entries) {
    final now = DateTime.now();
    return entries.map((e) => ReadingPlan(
      id: _uuid.v4(), bookId: book.id,
      date: AppDateUtils.toDateString(e.date),
      startUnit: e.startPage, endUnit: e.endPage, createdAt: now,
    )).toList();
  }

  /// 페이지 기반 계획: 총 페이지를 균등 배분, 마지막 날에 나머지 합산
  static List<ReadingPlan> _generatePagePlans(Book book) {
    final targetDate = _resolveTargetDate(book);
    if (targetDate == null) return [];
    final totalDays = targetDate.difference(book.startDate).inDays;
    if (totalDays <= 0 || book.totalPages <= 0) return [];

    final dailyPages = (book.totalPages / totalDays).ceil();
    final plans = <ReadingPlan>[];
    final now = DateTime.now();
    var startPage = 1;

    for (var day = 0; day < totalDays && startPage <= book.totalPages; day++) {
      final date = book.startDate.add(Duration(days: day));
      final calcEnd = startPage + dailyPages - 1;
      final endPage = calcEnd > book.totalPages ? book.totalPages : calcEnd;
      plans.add(ReadingPlan(
        id: _uuid.v4(), bookId: book.id,
        date: AppDateUtils.toDateString(date),
        startUnit: startPage, endUnit: endPage, createdAt: now,
      ));
      startPage = endPage + 1;
    }
    return plans;
  }

  /// 챕터 기반 계획: 각 챕터에 daysPerChapter일 연속 배정
  static List<ReadingPlan> _generateChapterPlans(Book book) {
    if (book.totalChapters <= 0) return [];
    final plans = <ReadingPlan>[];
    final now = DateTime.now();
    var currentDay = 0;
    for (var ch = 1; ch <= book.totalChapters; ch++) {
      for (var d = 0; d < book.daysPerChapter; d++) {
        final date = book.startDate.add(Duration(days: currentDay));
        plans.add(ReadingPlan(
          id: _uuid.v4(), bookId: book.id,
          date: AppDateUtils.toDateString(date),
          startUnit: ch, endUnit: ch, createdAt: now,
        ));
        currentDay++;
      }
    }
    return plans;
  }

  /// 미완료 계획을 1일씩 뒤로 이동하고 재분배한다
  static List<ReadingPlan> postponeAndRedistribute(
      Book book, String fromDate, List<ReadingPlan> plans) {
    final completed = plans.where((p) => p.isCompleted).toList();
    final pending = plans
        .where((p) => !p.isCompleted && p.date.compareTo(fromDate) >= 0)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final shifted = pending.map((plan) {
      final newDate = DateTime.parse(plan.date).add(const Duration(days: 1));
      return plan.copyWith(
        date: AppDateUtils.toDateString(newDate),
        isPostponed: plan.date == fromDate ? true : plan.isPostponed,
      );
    }).toList();
    return [...completed, ...shifted];
  }

  /// 시험일 초과 경고 확인
  static String? checkExamWarning(Book book, List<ReadingPlan> plans) {
    if (book.examDate == null || plans.isEmpty) return null;
    final examStr = AppDateUtils.toDateString(book.examDate!);
    final overdue = plans.where((p) => !p.isCompleted && p.date.compareTo(examStr) > 0);
    if (overdue.isEmpty) return null;
    return '시험일(${book.examDate!.month}/${book.examDate!.day}) 이후에 '
        '${overdue.length}개의 미완료 계획이 있습니다. 일정을 조정해 주세요.';
  }

  /// 미루기 시 시험일 초과 여부를 사전 확인한다
  static bool wouldExceedExamDate(Book book, List<ReadingPlan> plans, String fromDate) {
    if (book.examDate == null) return false;
    final examStr = AppDateUtils.toDateString(book.examDate!);
    final lastPending = plans.where((p) => !p.isCompleted).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    if (lastPending.isEmpty) return false;
    final shiftedLast = DateTime.parse(lastPending.first.date).add(const Duration(days: 1));
    return AppDateUtils.toDateString(shiftedLast).compareTo(examStr) > 0;
  }

  /// 목표 날짜 결정 (targetDate > targetMonth 순서)
  static DateTime? _resolveTargetDate(Book book) {
    if (book.targetDate != null) return book.targetDate;
    if (book.targetMonth != null && book.targetMonth!.isNotEmpty) {
      final parts = book.targetMonth!.split('-');
      if (parts.length == 2) {
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        if (year != null && month != null) return DateTime(year, month + 1, 0);
      }
    }
    return null;
  }
}
