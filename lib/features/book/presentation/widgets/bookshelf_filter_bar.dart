// F-Book: 책장 정렬/필터 바 — 필터 칩 + 정렬 드롭다운
// BookshelfView 상단에 표시되는 정렬/필터 UI 위젯
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../providers/book_provider.dart';

/// 정렬/필터 바
class BookshelfFilterBar extends ConsumerWidget {
  const BookshelfFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(bookSortModeProvider);
    final filter = ref.watch(bookFilterModeProvider);

    return Row(
      children: [
        _Chip(
          label: '진행중',
          isActive: filter == BookFilterMode.active,
          onTap: () => ref.read(bookFilterModeProvider.notifier).state =
              BookFilterMode.active,
        ),
        const SizedBox(width: AppSpacing.sm),
        _Chip(
          label: '완독',
          isActive: filter == BookFilterMode.completed,
          onTap: () => ref.read(bookFilterModeProvider.notifier).state =
              BookFilterMode.completed,
        ),
        const SizedBox(width: AppSpacing.sm),
        _Chip(
          label: '전체',
          isActive: filter == BookFilterMode.all,
          onTap: () => ref.read(bookFilterModeProvider.notifier).state =
              BookFilterMode.all,
        ),
        const Spacer(),
        _SortDropdown(sort: sort, ref: ref),
      ],
    );
  }
}

/// 필터 칩
class _Chip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isActive
              ? ColorTokens.main.withValues(alpha: 0.2)
              : context.themeColors.textPrimaryWithAlpha(0.08),
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Text(label,
            style: AppTypography.captionLg.copyWith(
              color: isActive
                  ? ColorTokens.main
                  : context.themeColors.textPrimaryWithAlpha(0.7),
              fontWeight: isActive
                  ? AppTypography.weightSemiBold
                  : AppTypography.weightRegular,
            )),
      ),
    );
  }
}

/// 정렬 드롭다운 버튼
class _SortDropdown extends StatelessWidget {
  final BookSortMode sort;
  final WidgetRef ref;
  const _SortDropdown({required this.sort, required this.ref});

  @override
  Widget build(BuildContext context) {
    final label = switch (sort) {
      BookSortMode.recent => '최근',
      BookSortMode.title => '제목',
      BookSortMode.progress => '진행률',
      BookSortMode.deadline => '마감일',
    };
    return PopupMenuButton<BookSortMode>(
      onSelected: (m) =>
          ref.read(bookSortModeProvider.notifier).state = m,
      itemBuilder: (_) => const [
        PopupMenuItem(
            value: BookSortMode.recent, child: Text('최근 수정순')),
        PopupMenuItem(
            value: BookSortMode.title, child: Text('제목순')),
        PopupMenuItem(
            value: BookSortMode.progress, child: Text('진행률순')),
        PopupMenuItem(
            value: BookSortMode.deadline, child: Text('마감일순')),
      ],
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.sort_rounded,
            size: 16,
            color: context.themeColors.textPrimaryWithAlpha(0.55)),
        const SizedBox(width: AppSpacing.xs),
        Text(label,
            style: AppTypography.captionMd.copyWith(
                color: context.themeColors
                    .textPrimaryWithAlpha(0.55))),
      ]),
    );
  }
}
