// F-Book: 내 책장 뷰 — 등록된 책 목록을 2열 그리드로 표시
// 정렬/필터 + FAB 추가 지원
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/bottom_scroll_spacer.dart';
import '../../models/book.dart';
import '../../providers/book_provider.dart';
import 'book_card.dart';
import 'book_create_dialog.dart';
import 'bookshelf_filter_bar.dart';

/// 내 책장 뷰 — 정렬/필터 + 2열 그리드
class BookshelfView extends ConsumerWidget {
  const BookshelfView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(filteredBooksProvider);
    final filter = ref.watch(bookFilterModeProvider);

    return Stack(
      children: [
        books.isEmpty
            ? _emptyState(context, filter)
            : _grid(context, books),
        Positioned(
          right: AppSpacing.pageHorizontal,
          bottom: AppSpacing.xxxl,
          child: _AddFab(onTap: () => _showCreate(context)),
        ),
      ],
    );
  }

  Widget _emptyState(BuildContext context, BookFilterMode filter) {
    final msg = switch (filter) {
      BookFilterMode.active => '진행 중인 책이 없어요',
      BookFilterMode.completed => '완독한 책이 없어요',
      BookFilterMode.all => '등록된 책이 없어요',
    };
    return Center(
      child: EmptyState(
        icon: Icons.menu_book_rounded,
        mainText: msg,
        subText: '책을 추가해보세요!',
        ctaLabel: '책 추가하기',
        onCtaTap: () => _showCreate(context),
      ),
    );
  }

  Widget _grid(BuildContext context, List<Book> books) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageHorizontal),
            child: const BookshelfFilterBar(),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageHorizontal),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.xl,
              crossAxisSpacing: AppSpacing.xl,
              childAspectRatio: 0.65,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) => BookCard(book: books[i]),
              childCount: books.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: BottomScrollSpacer()),
      ],
    );
  }

  void _showCreate(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColorTokens.transparent,
      builder: (_) => const BookCreateDialog(),
    );
  }
}

/// 책 추가 FAB
class _AddFab extends StatelessWidget {
  final VoidCallback onTap;
  const _AddFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppLayout.minTouchTarget + AppSpacing.lg,
        height: AppLayout.minTouchTarget + AppSpacing.lg,
        decoration: BoxDecoration(
          color: ColorTokens.main,
          borderRadius: BorderRadius.circular(AppRadius.fab),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.main.withValues(alpha: 0.35),
              blurRadius: EffectLayout.ctaShadowBlur,
              offset: const Offset(0, EffectLayout.ctaShadowOffsetY),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded,
            color: ColorTokens.white, size: AppLayout.iconXl),
      ),
    );
  }
}
