// F-Book: 독서 계획 아이템 위젯 — 개별 독서 계획 행 표시
// 체크박스 + 책 제목 + 페이지 범위 + 미루기 버튼으로 구성
// 완료 시 취소선 애니메이션, 미루기 시 확인 다이얼로그를 적용한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../shared/widgets/animated_checkbox.dart';
import '../../../../shared/widgets/animated_strikethrough.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../models/reading_plan.dart';
import '../../providers/book_provider.dart';
import '../../providers/book_reading_provider.dart';
import '../../services/reading_plan_generator.dart';

/// 독서 계획 아이템 위젯
class ReadingPlanItem extends ConsumerWidget {
  final ReadingPlan plan;

  /// 외부에서 책 제목을 전달받는다 (선택, 미전달 시 bookId에서 조회)
  final String? bookTitle;

  const ReadingPlanItem({
    super.key,
    required this.plan,
    this.bookTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = plan.isCompleted;

    // 책 제목 조회 (외부 미전달 시 provider에서 가져온다)
    final title = bookTitle ?? _resolveBookTitle(ref, plan.bookId);

    final textStyle = AppTypography.bodyMd.copyWith(
      color: isCompleted
          ? context.themeColors
              .textPrimaryWithAlpha(AppAnimation.completedTextAlpha)
          : context.themeColors
              .textPrimaryWithAlpha(AppAnimation.activeTextAlpha),
    );

    return Row(
      children: [
        // 체크박스
        AnimatedCheckbox(
          isCompleted: isCompleted,
          onTap: () => _handleToggle(context, ref, isCompleted),
        ),
        const SizedBox(width: AppSpacing.lg),
        // 책 제목 + 페이지 범위 (취소선 애니메이션)
        Expanded(
          child: AnimatedStrikethrough(
            text: '$title  p.${plan.startUnit}~${plan.endUnit}',
            style: textStyle,
            isActive: isCompleted,
          ),
        ),
        // 미루기 버튼 (완료되지 않은 경우만)
        if (!isCompleted)
          _PostponeButton(
            onTap: () => _handlePostpone(context, ref),
          ),
      ],
    );
  }

  /// 완료 토글 + 완독 시 축하 메시지
  void _handleToggle(
    BuildContext context,
    WidgetRef ref,
    bool currentCompleted,
  ) {
    ref.read(toggleReadingPlanProvider)(plan.id, !currentCompleted);

    // 완독 자동 감지는 toggleReadingPlanProvider 내부에서 처리된다
  }

  /// 미루기 확인 다이얼로그
  void _handlePostpone(BuildContext context, WidgetRef ref) {
    // 시험일 초과 사전 경고 확인
    final books = ref.read(booksProvider);
    final book = books.where((b) => b.id == plan.bookId).firstOrNull;
    final plans = ref.read(readingPlansForBookProvider(plan.bookId));

    final wouldExceed = book != null &&
        ReadingPlanGenerator.wouldExceedExamDate(
          book,
          plans,
          plan.date,
        );

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('미루기'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('오늘 분량을 내일로 미룹니다.\n이후 일정이 재조정됩니다.'),
            if (wouldExceed) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                '경고: 미루기 시 시험일을 초과하게 됩니다!',
                style: TextStyle(
                  color: ColorTokens.error,
                  fontWeight: AppTypography.weightSemiBold,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(postponePlanProvider)(plan.bookId, plan.date);
              AppSnackBar.showSuccess(context, '일정이 재조정되었습니다');
            },
            child: Text(
              '미루기',
              style: TextStyle(
                color: wouldExceed ? ColorTokens.error : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// bookId로 책 제목을 조회한다
  String _resolveBookTitle(WidgetRef ref, String bookId) {
    final books = ref.watch(booksProvider);
    final book = books.where((b) => b.id == bookId).firstOrNull;
    return book?.title ?? '알 수 없는 책';
  }
}

/// 미루기 버튼 (작은 텍스트 버튼)
class _PostponeButton extends StatelessWidget {
  final VoidCallback onTap;

  const _PostponeButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          '미루기',
          style: AppTypography.captionMd.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.55),
          ),
        ),
      ),
    );
  }
}
