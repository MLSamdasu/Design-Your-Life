// F-Book: 독서 진행 Provider
// 독서 계획 조회, 완료 토글, 미루기, 진행률, 시험일 경고를 담당한다.
// CRUD 후 readingPlanDataVersionProvider를 증가시켜 파생 체인이 자동 갱신된다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/data_store_providers.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/utils/date_utils.dart';
import '../models/book.dart';
import '../models/reading_plan.dart';
import '../services/reading_plan_generator.dart';
import 'book_provider.dart';

// ─── 독서 계획 조회 Provider ────────────────────────────────────────────────

/// 특정 도서의 독서 계획 목록 Provider (날짜순 정렬)
final readingPlansForBookProvider =
    Provider.family<List<ReadingPlan>, String>((ref, bookId) {
  final rawList = ref.watch(allReadingPlansRawProvider);
  final plans = rawList
      .where((m) => m['book_id'] == bookId)
      .map((m) => ReadingPlan.fromMap(m))
      .toList();
  plans.sort((a, b) => a.date.compareTo(b.date));
  return plans;
});

/// 오늘의 독서 계획 목록 Provider (모든 도서 대상, 오늘 날짜로 필터링)
final todayReadingPlansProvider = Provider<List<ReadingPlan>>((ref) {
  final today = ref.watch(todayDateProvider);
  final todayStr = AppDateUtils.toDateString(today);
  final rawList = ref.watch(allReadingPlansRawProvider);

  return rawList
      .where((m) => m['date'] == todayStr)
      .map((m) => ReadingPlan.fromMap(m))
      .toList();
});

/// 특정 날짜의 독서 계획 목록 Provider (캘린더에서 선택한 날짜용)
final selectedDayReadingPlansProvider =
    Provider.family<List<ReadingPlan>, DateTime>((ref, selectedDay) {
  final dateStr = AppDateUtils.toDateString(selectedDay);
  final rawList = ref.watch(allReadingPlansRawProvider);

  final plans = rawList
      .where((m) => m['date'] == dateStr)
      .map((m) => ReadingPlan.fromMap(m))
      .toList();
  plans.sort((a, b) => a.date.compareTo(b.date));
  return plans;
});

// ─── 독서 계획 액션 Provider ────────────────────────────────────────────────

/// 독서 계획 완료 토글 + 도서 진행도 업데이트 + 완독 자동 감지
final toggleReadingPlanProvider =
    Provider<Future<void> Function(String planId, bool completed)>((ref) {
  final repository = ref.watch(bookRepositoryProvider);

  return (String planId, bool completed) async {
    // 계획을 조회하여 완료 상태를 변경한다
    final rawList = ref.read(allReadingPlansRawProvider);
    final planMap = rawList.where((m) => m['id'] == planId).firstOrNull;
    if (planMap == null) return;

    final plan = ReadingPlan.fromMap(planMap);
    final updated = plan.copyWith(isCompleted: completed);
    await repository.savePlan(updated);

    // 도서의 현재 진행도를 재계산한다
    final bookPlans = ref.read(readingPlansForBookProvider(plan.bookId));
    final completedCount = bookPlans.where((p) {
      if (p.id == planId) return completed;
      return p.isCompleted;
    }).length;

    final book = repository.getBook(plan.bookId);
    if (book != null) {
      // 완료된 계획의 최대 endUnit을 현재 진행도로 설정한다
      final completedPlans = bookPlans.where((p) {
        if (p.id == planId) return completed;
        return p.isCompleted;
      });
      final maxProgress = completedPlans.isEmpty
          ? 0
          : completedPlans
              .map((p) => p.endUnit)
              .reduce((a, b) => a > b ? a : b);

      final totalUnit = book.trackingMode == 'chapter'
          ? book.totalChapters
          : book.totalPages;
      // 모든 계획이 완료되면 도서를 완독 처리한다
      final isBookCompleted =
          totalUnit > 0 && completedCount == bookPlans.length;

      await repository.updateBook(
        plan.bookId,
        book.copyWith(
          currentProgress: maxProgress,
          isCompleted: isBookCompleted,
        ),
      );
      ref.read(bookDataVersionProvider.notifier).state++;
    }

    ref.read(readingPlanDataVersionProvider.notifier).state++;
  };
});

/// 미루기 액션: 미완료 계획을 1일 뒤로 이동하고 재분배한다
final postponePlanProvider =
    Provider<Future<void> Function(String bookId, String fromDate)>((ref) {
  final repository = ref.watch(bookRepositoryProvider);

  return (String bookId, String fromDate) async {
    final book = repository.getBook(bookId);
    if (book == null) return;

    final plans = repository.getPlansForBook(bookId);
    final redistributed = ReadingPlanGenerator.postponeAndRedistribute(
      book,
      fromDate,
      plans,
    );

    // 기존 계획을 모두 삭제 후 재생성한다
    await repository.deletePlansForBook(bookId);
    await repository.savePlans(redistributed);

    ref.read(readingPlanDataVersionProvider.notifier).state++;
  };
});

// ─── 파생 상태 Provider ─────────────────────────────────────────────────────

/// 도서별 진행률 Provider (0.0 ~ 1.0)
final bookProgressProvider = Provider.family<double, String>((ref, bookId) {
  final rawBooks = ref.watch(allBooksRawProvider);
  final bookMap = rawBooks.where((m) => m['id'] == bookId).firstOrNull;
  if (bookMap == null) return 0.0;

  final book = Book.fromMap(bookMap);
  final total =
      book.trackingMode == 'chapter' ? book.totalChapters : book.totalPages;
  if (total <= 0) return 0.0;

  return (book.currentProgress / total).clamp(0.0, 1.0);
});

/// 시험일 경고 Provider (경고 문자열 또는 null)
final examWarningProvider = Provider.family<String?, String>((ref, bookId) {
  final rawBooks = ref.watch(allBooksRawProvider);
  final bookMap = rawBooks.where((m) => m['id'] == bookId).firstOrNull;
  if (bookMap == null) return null;

  final book = Book.fromMap(bookMap);
  final plans = ref.watch(readingPlansForBookProvider(bookId));

  return ReadingPlanGenerator.checkExamWarning(book, plans);
});

/// 독서 연속 기록 Provider (연속 며칠 독서했는지 계산)
final readingStreakProvider = Provider<int>((ref) {
  final rawList = ref.watch(allReadingPlansRawProvider);
  final completedDates = <String>{};

  for (final map in rawList) {
    if (map['is_completed'] == true) {
      final date = map['date'] as String?;
      if (date != null) completedDates.add(date);
    }
  }

  // 오늘부터 과거로 거슬러 올라가며 연속 일수를 센다
  var streak = 0;
  var checkDate = DateTime.now();

  while (true) {
    final dateStr = AppDateUtils.toDateString(checkDate);
    if (completedDates.contains(dateStr)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else {
      break;
    }
  }

  return streak;
});
