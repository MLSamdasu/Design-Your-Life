// F-Book: BookRepository (로컬 퍼스트 아키텍처)
// Book과 ReadingPlan의 CRUD를 Hive 로컬 저장소에서 수행한다.
// 인터넷 없이도 완전히 동작한다.

import 'package:uuid/uuid.dart';

import '../../../core/cache/hive_cache_service.dart';
import '../../../core/constants/app_constants.dart';
import '../models/book.dart';
import '../models/reading_plan.dart';

/// 도서 + 독서 계획 저장소 (로컬 퍼스트 아키텍처)
/// Hive 로컬 저장소를 기본 저장소로 사용하여 오프라인에서도 완전히 동작한다
class BookRepository {
  final HiveCacheService _cache;

  static const _booksBox = AppConstants.booksBox;
  static const _plansBox = AppConstants.readingPlansBox;
  static const _uuid = Uuid();

  BookRepository({required HiveCacheService cache}) : _cache = cache;

  // ─── Book CRUD ─────────────────────────────────────────────────────────────

  /// 전체 도서 목록을 조회한다
  List<Book> getAllBooks() {
    final items = _cache.getAll(_booksBox);
    return items.map((m) => Book.fromMap(m)).toList();
  }

  /// 특정 도서를 ID로 조회한다
  Book? getBook(String bookId) {
    final map = _cache.get(_booksBox, bookId);
    if (map == null) return null;
    return Book.fromMap(map);
  }

  /// 새 도서를 생성한다
  Future<String> createBook(Book book) async {
    final id = book.id.isNotEmpty ? book.id : _uuid.v4();
    final now = DateTime.now();

    final map = book.toInsertMap(AppConstants.localUserId)
      ..['id'] = id
      ..['created_at'] = now.toIso8601String()
      ..['updated_at'] = now.toIso8601String();

    await _cache.put(_booksBox, id, map);
    return id;
  }

  /// 도서를 수정한다
  Future<Book?> updateBook(String bookId, Book book) async {
    final existing = _cache.get(_booksBox, bookId);
    if (existing == null) return null;

    final updatedMap = book.toUpdateMap()
      ..['id'] = bookId
      ..['user_id'] = existing['user_id'] ?? AppConstants.localUserId
      ..['created_at'] = existing['created_at']
      ..['updated_at'] = DateTime.now().toIso8601String();

    await _cache.put(_booksBox, bookId, updatedMap);
    return Book.fromMap(updatedMap);
  }

  /// 도서를 삭제한다 (연관 독서 계획도 함께 삭제)
  Future<void> deleteBook(String bookId) async {
    // 연관 독서 계획을 먼저 삭제한다
    final plans = getPlansForBook(bookId);
    for (final plan in plans) {
      await _cache.deleteById(_plansBox, plan.id);
    }
    await _cache.deleteById(_booksBox, bookId);
  }

  // ─── ReadingPlan CRUD ──────────────────────────────────────────────────────

  /// 특정 도서의 독서 계획 목록을 조회한다
  List<ReadingPlan> getPlansForBook(String bookId) {
    final items = _cache.query(
      _plansBox,
      (map) => map['book_id'] == bookId,
    );
    final plans = items.map((m) => ReadingPlan.fromMap(m)).toList();
    plans.sort((a, b) => a.date.compareTo(b.date));
    return plans;
  }

  /// 특정 날짜의 독서 계획 목록을 조회한다 (모든 도서 대상)
  List<ReadingPlan> getPlansForDate(String date) {
    final items = _cache.query(
      _plansBox,
      (map) => map['date'] == date,
    );
    return items.map((m) => ReadingPlan.fromMap(m)).toList();
  }

  /// 독서 계획을 저장한다 (생성 또는 덮어쓰기)
  Future<void> savePlan(ReadingPlan plan) async {
    await _cache.put(_plansBox, plan.id, plan.toMap());
  }

  /// 여러 독서 계획을 일괄 저장한다
  Future<void> savePlans(List<ReadingPlan> plans) async {
    for (final plan in plans) {
      await _cache.put(_plansBox, plan.id, plan.toMap());
    }
  }

  /// 특정 도서의 독서 계획을 모두 삭제한다
  Future<void> deletePlansForBook(String bookId) async {
    final plans = getPlansForBook(bookId);
    for (final plan in plans) {
      await _cache.deleteById(_plansBox, plan.id);
    }
  }
}
