// F-Book: 책 카드 위젯 — 책장 그리드 내 개별 책 표시
// 커버 이미지 + 제목 + 진행 바 + 시험 뱃지 + 롱프레스 메뉴
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import '../../models/book.dart';
import '../../providers/book_reading_provider.dart';
import '../book_detail_screen.dart';
import 'book_context_menu.dart';

/// 책 카드 위젯 — 그리드 아이템으로 사용
class BookCard extends ConsumerWidget {
  final Book book;
  const BookCard({super.key, required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(bookProgressProvider(book.id));
    return GestureDetector(
      onLongPress: () => showBookContextMenu(context, ref, book),
      child: GlassmorphicCard(
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => BookDetailScreen(bookId: book.id))),
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 3, child: _Cover(coverBase64: book.coverImageBase64)),
            Expanded(flex: 2, child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Flexible(child: Text(book.title,
                    style: AppTypography.titleMd.copyWith(color: context.themeColors.textPrimary),
                    maxLines: 2, overflow: TextOverflow.ellipsis)),
                const SizedBox(height: AppSpacing.sm),
                _ProgressRow(progress: progress),
                const SizedBox(height: AppSpacing.xs),
                Text(book.trackingMode == 'chapter'
                    ? '${book.totalChapters}챕터' : '${book.totalPages}페이지',
                    style: AppTypography.captionSm.copyWith(
                        color: context.themeColors.textPrimaryWithAlpha(0.55))),
              ]),
            )),
            if (book.examDate != null) _ExamBadge(examDate: book.examDate!),
          ],
        ),
      ),
    );
  }
}

/// 커버 이미지 또는 그라디언트 플레이스홀더
class _Cover extends StatelessWidget {
  final String? coverBase64;
  const _Cover({this.coverBase64});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      child: coverBase64 != null && coverBase64!.isNotEmpty
          ? Image.memory(base64Decode(coverBase64!), fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _ph(context))
          : _ph(context),
    );
  }

  Widget _ph(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [ColorTokens.main, ColorTokens.sub])),
        child: Center(child: Icon(Icons.menu_book_rounded,
            size: AppLayout.iconEmpty, color: ColorTokens.white.withValues(alpha: 0.7))),
      );
}

/// 진행 바 + 퍼센트
class _ProgressRow extends StatelessWidget {
  final double progress;
  const _ProgressRow({required this.progress});

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return Row(children: [
      Expanded(child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0), minHeight: AppSpacing.xs,
          backgroundColor: context.themeColors.textPrimaryWithAlpha(0.12),
          valueColor: const AlwaysStoppedAnimation<Color>(ColorTokens.main)),
      )),
      const SizedBox(width: AppSpacing.sm),
      Text('$pct%', style: AppTypography.captionSm.copyWith(
          color: context.themeColors.textPrimaryWithAlpha(0.7),
          fontWeight: AppTypography.weightSemiBold)),
    ]);
  }
}

/// 시험 D-day 뱃지
class _ExamBadge extends StatelessWidget {
  final DateTime examDate;
  const _ExamBadge({required this.examDate});

  @override
  Widget build(BuildContext context) {
    final d = examDate.difference(DateTime.now()).inDays;
    final label = d >= 0 ? '시험 D-$d' : '시험 D+${-d}';
    final urgent = d >= 0 && d <= 7;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: urgent
            ? ColorTokens.error.withValues(alpha: 0.15)
            : ColorTokens.warning.withValues(alpha: 0.15),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.card)),
      ),
      child: Text(label, textAlign: TextAlign.center,
          style: AppTypography.captionSm.copyWith(
              color: urgent ? ColorTokens.error : ColorTokens.warning,
              fontWeight: AppTypography.weightSemiBold)),
    );
  }
}
