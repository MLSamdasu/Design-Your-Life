// F-Book: 도서 정렬/필터 Provider
// 책장 뷰에서 사용하는 정렬 기준, 필터 기준, 필터링된 목록을 관리한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book.dart';
import 'book_provider.dart';

/// 책장 정렬 기준
enum BookSortMode { recent, title, progress, deadline }

/// 책장 필터 기준
enum BookFilterMode { active, completed, all }

/// 현재 정렬 모드
final bookSortModeProvider =
    StateProvider<BookSortMode>((ref) => BookSortMode.recent);

/// 현재 필터 모드
final bookFilterModeProvider =
    StateProvider<BookFilterMode>((ref) => BookFilterMode.active);

/// 정렬+필터 적용된 도서 목록 Provider
final filteredBooksProvider = Provider<List<Book>>((ref) {
  final books = ref.watch(booksProvider);
  final filter = ref.watch(bookFilterModeProvider);
  final sort = ref.watch(bookSortModeProvider);

  // 필터링
  var filtered = switch (filter) {
    BookFilterMode.active => books.where((b) => !b.isCompleted).toList(),
    BookFilterMode.completed => books.where((b) => b.isCompleted).toList(),
    BookFilterMode.all => List<Book>.from(books),
  };

  // 정렬
  switch (sort) {
    case BookSortMode.recent:
      filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    case BookSortMode.title:
      filtered.sort((a, b) => a.title.compareTo(b.title));
    case BookSortMode.progress:
      filtered.sort((a, b) {
        final aTotal = a.trackingMode == 'chapter'
            ? a.totalChapters
            : a.totalPages;
        final bTotal = b.trackingMode == 'chapter'
            ? b.totalChapters
            : b.totalPages;
        final aP = aTotal > 0 ? a.currentProgress / aTotal : 0.0;
        final bP = bTotal > 0 ? b.currentProgress / bTotal : 0.0;
        return bP.compareTo(aP);
      });
    case BookSortMode.deadline:
      filtered.sort((a, b) {
        final aDate = a.targetDate ?? a.examDate;
        final bDate = b.targetDate ?? b.examDate;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return aDate.compareTo(bDate);
      });
  }

  return filtered;
});
