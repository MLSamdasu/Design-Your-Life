// F-Book: 책 컨텍스트 메뉴 — 롱프레스 시 표시되는 하단 시트 메뉴
// 수정, 완독 처리, 삭제 액션을 제공한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../models/book.dart';
import '../../providers/book_provider.dart';
import 'book_edit_dialog.dart';

/// 책 롱프레스 컨텍스트 메뉴를 표시한다
void showBookContextMenu(
  BuildContext context,
  WidgetRef ref,
  Book book,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: ColorTokens.gray900,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('수정'),
            onTap: () {
              Navigator.of(ctx).pop();
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: ColorTokens.transparent,
                builder: (_) => BookEditDialog(book: book),
              );
            },
          ),
          if (!book.isCompleted)
            ListTile(
              leading: Icon(Icons.check_circle_outline_rounded,
                  color: ColorTokens.success),
              title: const Text('완독 처리'),
              onTap: () async {
                Navigator.of(ctx).pop();
                await ref.read(updateBookProvider)(
                    book.id, book.copyWith(isCompleted: true));
              },
            ),
          ListTile(
            leading: Icon(Icons.delete_outline_rounded,
                color: ColorTokens.error),
            title: Text('삭제',
                style: TextStyle(color: ColorTokens.error)),
            onTap: () {
              Navigator.of(ctx).pop();
              _confirmDelete(context, ref, book);
            },
          ),
        ],
      ),
    ),
  );
}

void _confirmDelete(BuildContext context, WidgetRef ref, Book book) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('책 삭제'),
      content: Text('"${book.title}"을(를) 삭제하시겠습니까?'),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소')),
        TextButton(
          onPressed: () async {
            await ref.read(deleteBookProvider)(book.id);
            if (ctx.mounted) Navigator.of(ctx).pop();
          },
          child: Text('삭제',
              style: TextStyle(color: ColorTokens.error)),
        ),
      ],
    ),
  );
}
