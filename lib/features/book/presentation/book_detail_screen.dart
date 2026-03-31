// F-Book: 책 상세 화면 — 커버 + 통계 + 독서 계획 목록
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/layout_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/typography_tokens.dart';
import '../models/book.dart';
import '../providers/book_provider.dart';
import '../providers/book_reading_provider.dart';
import 'widgets/book_detail_stats.dart';
import 'widgets/book_edit_dialog.dart';
import 'widgets/exam_warning_banner.dart';
import 'widgets/reading_plan_item.dart';

/// 책 상세 화면
class BookDetailScreen extends ConsumerWidget {
  final String bookId;
  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(booksProvider);
    final book = books.where((b) => b.id == bookId).firstOrNull;
    if (book == null) {
      return Scaffold(appBar: AppBar(title: const Text('책 상세')),
          body: const Center(child: Text('책을 찾을 수 없습니다')));
    }
    final progress = ref.watch(bookProgressProvider(bookId));
    final plans = ref.watch(readingPlansForBookProvider(bookId));
    final warning = ref.watch(examWarningProvider(bookId));

    return Scaffold(
      backgroundColor: ColorTokens.transparent,
      extendBodyBehindAppBar: true,
      appBar: _appBar(context, ref, book),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _Cover(coverBase64: book.coverImageBase64)),
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(book.title, style: AppTypography.headingMd
                  .copyWith(color: context.themeColors.textPrimary)),
              if (book.description?.isNotEmpty == true) ...[
                const SizedBox(height: AppSpacing.md),
                Text(book.description!, style: AppTypography.bodyMd
                    .copyWith(color: context.themeColors.textPrimaryWithAlpha(0.7))),
              ],
              const SizedBox(height: AppSpacing.xl),
              BookProgressSection(progress: progress, book: book),
              const SizedBox(height: AppSpacing.xl),
              BookStatsRow(book: book, progress: progress),
              const SizedBox(height: AppSpacing.xl),
              if (book.examDate != null) BookExamCountdown(examDate: book.examDate!, book: book),
              if (warning != null) ...[const SizedBox(height: AppSpacing.lg), ExamWarningBanner(message: warning)],
              const SizedBox(height: AppSpacing.xl),
              if (book.targetMonth != null) ...[
                BookTargetMonthRow(targetMonth: book.targetMonth!),
                const SizedBox(height: AppSpacing.xl),
              ],
              if (book.isCompleted) ...[BookCompletionBanner(bookTitle: book.title), const SizedBox(height: AppSpacing.xl)],
              Text('독서 계획', style: AppTypography.titleMd.copyWith(color: context.themeColors.textPrimary)),
              const SizedBox(height: AppSpacing.lg),
              if (plans.isEmpty)
                Text('아직 독서 계획이 없습니다', style: AppTypography.bodyMd
                    .copyWith(color: context.themeColors.textPrimaryWithAlpha(0.55)))
              else ...plans.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: ReadingPlanItem(plan: p, bookTitle: book.title))),
              const SizedBox(height: AppSpacing.enormous),
            ]),
          )),
        ],
      ),
    );
  }

  PreferredSizeWidget _appBar(BuildContext context, WidgetRef ref, Book book) {
    return AppBar(
      backgroundColor: ColorTokens.transparent, elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.themeColors.textPrimary),
        onPressed: () => Navigator.of(context).pop()),
      actions: [
        IconButton(icon: Icon(Icons.edit_outlined, color: context.themeColors.textPrimary),
            onPressed: () => showModalBottomSheet<void>(context: context, isScrollControlled: true,
                backgroundColor: ColorTokens.transparent, builder: (_) => BookEditDialog(book: book))),
        IconButton(icon: Icon(Icons.delete_outline_rounded, color: ColorTokens.error.withValues(alpha: 0.8)),
            onPressed: () => _del(context, ref, book)),
      ],
    );
  }

  void _del(BuildContext context, WidgetRef ref, Book book) {
    showDialog<void>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('책 삭제'),
      content: Text('"${book.title}"을(를) 삭제하시겠습니까?'),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('취소')),
        TextButton(
          onPressed: () async {
            await ref.read(deleteBookProvider)(book.id);
            if (ctx.mounted) Navigator.of(ctx).pop();
            if (context.mounted) Navigator.of(context).pop();
          },
          child: Text('삭제', style: TextStyle(color: ColorTokens.error))),
      ],
    ));
  }
}

/// 커버 이미지 섹션
class _Cover extends StatelessWidget {
  final String? coverBase64;
  const _Cover({this.coverBase64});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 300, width: double.infinity,
      child: coverBase64 != null && coverBase64!.isNotEmpty
          ? Image.memory(base64Decode(coverBase64!), fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _ph(context))
          : _ph(context));
  }

  Widget _ph(BuildContext context) => Container(
    decoration: const BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [ColorTokens.main, ColorTokens.sub])),
    child: Center(child: Icon(Icons.menu_book_rounded,
        size: AppLayout.iconEmpty * 2, color: ColorTokens.white.withValues(alpha: 0.5))),
  );
}
