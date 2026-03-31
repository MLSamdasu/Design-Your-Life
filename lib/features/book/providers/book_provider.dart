// F-Book: 도서 Provider
// Repository 초기화, 목록 조회, 선택 상태, CRUD 액션을 담당한다.
// CRUD 후 bookDataVersionProvider를 증가시켜 전체 파생 체인이 자동 갱신된다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/data_store_providers.dart';
import '../../../core/providers/global_providers.dart';
import '../models/book.dart';
import '../services/book_repository.dart';
import '../services/reading_plan_generator.dart';

// 정렬/필터 Provider를 re-export한다
export 'book_filter_provider.dart';

// ─── Repository Provider ────────────────────────────────────────────────────

/// BookRepository Provider (로컬 퍼스트)
final bookRepositoryProvider = Provider((ref) {
  final cache = ref.watch(hiveCacheServiceProvider);
  return BookRepository(cache: cache);
});

// ─── 도서 목록 Provider (SSOT에서 파생) ──────────────────────────────────────

/// 전체 도서 목록 Provider (최신 수정순 정렬)
final booksProvider = Provider<List<Book>>((ref) {
  final rawList = ref.watch(allBooksRawProvider);
  final books = rawList.map((m) => Book.fromMap(m)).toList();
  books.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return books;
});

/// 진행 중인 도서 목록 Provider
final activeBooksProvider = Provider<List<Book>>((ref) {
  final books = ref.watch(booksProvider);
  return books.where((b) => !b.isCompleted).toList();
});

/// 완독된 도서 목록 Provider
final completedBooksProvider = Provider<List<Book>>((ref) {
  final books = ref.watch(booksProvider);
  return books.where((b) => b.isCompleted).toList();
});

// ─── 선택 상태 Provider ─────────────────────────────────────────────────────

/// 현재 선택된 도서 ID
final selectedBookIdProvider = StateProvider<String?>((ref) => null);

// ─── 도서 CRUD 액션 Provider ────────────────────────────────────────────────

/// 도서 생성 + 독서 계획 자동 생성
final createBookProvider = Provider<Future<String> Function(Book)>((ref) {
  final repository = ref.watch(bookRepositoryProvider);
  return (Book book) async {
    final id = await repository.createBook(book);
    final savedBook = repository.getBook(id);
    if (savedBook != null) {
      final plans = ReadingPlanGenerator.generatePlans(savedBook);
      await repository.savePlans(plans);
      ref.read(readingPlanDataVersionProvider.notifier).state++;
    }
    ref.read(bookDataVersionProvider.notifier).state++;
    return id;
  };
});

/// 수동 분배 계획으로 도서를 생성한다
final createBookWithManualPlansProvider =
    Provider<Future<String> Function(Book, List<ManualPlanEntry>)>((ref) {
  final repository = ref.watch(bookRepositoryProvider);
  return (Book book, List<ManualPlanEntry> entries) async {
    final id = await repository.createBook(book);
    final savedBook = repository.getBook(id);
    if (savedBook != null) {
      final plans =
          ReadingPlanGenerator.generateManualPlans(savedBook, entries);
      await repository.savePlans(plans);
      ref.read(readingPlanDataVersionProvider.notifier).state++;
    }
    ref.read(bookDataVersionProvider.notifier).state++;
    return id;
  };
});

/// 도서 수정 액션
final updateBookProvider =
    Provider<Future<void> Function(String, Book)>((ref) {
  final repository = ref.watch(bookRepositoryProvider);
  return (String bookId, Book book) async {
    await repository.updateBook(bookId, book);
    ref.read(bookDataVersionProvider.notifier).state++;
  };
});

/// 도서 수정 + 독서 계획 재생성
final updateBookAndRegeneratePlansProvider =
    Provider<Future<void> Function(String, Book)>((ref) {
  final repository = ref.watch(bookRepositoryProvider);
  return (String bookId, Book book) async {
    await repository.updateBook(bookId, book);
    await repository.deletePlansForBook(bookId);
    final updated = repository.getBook(bookId);
    if (updated != null) {
      final plans = ReadingPlanGenerator.generatePlans(updated);
      await repository.savePlans(plans);
    }
    ref.read(bookDataVersionProvider.notifier).state++;
    ref.read(readingPlanDataVersionProvider.notifier).state++;
  };
});

/// 도서 삭제 액션
final deleteBookProvider = Provider<Future<void> Function(String)>((ref) {
  final repository = ref.watch(bookRepositoryProvider);
  return (String bookId) async {
    await repository.deleteBook(bookId);
    if (ref.read(selectedBookIdProvider) == bookId) {
      ref.read(selectedBookIdProvider.notifier).state = null;
    }
    ref.read(bookDataVersionProvider.notifier).state++;
    ref.read(readingPlanDataVersionProvider.notifier).state++;
  };
});
