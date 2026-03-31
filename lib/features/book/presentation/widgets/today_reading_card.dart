// F-Book: 오늘의 독서 카드 — 홈 대시보드에 표시되는 요약 카드
// 활성 도서 중 오늘 읽어야 할 독서 계획을 체크리스트로 보여준다.
// 연속 독서 기록(스트릭)을 함께 표시한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import '../../models/reading_plan.dart';
import '../../providers/book_provider.dart';
import '../../providers/book_reading_provider.dart';
import 'reading_plan_item.dart';

/// 오늘의 독서 카드 — 홈 대시보드용 요약 위젯
class TodayReadingCard extends ConsumerWidget {
  const TodayReadingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayPlans = ref.watch(todayReadingPlansProvider);
    final activeBooks = ref.watch(activeBooksProvider);
    final streak = ref.watch(readingStreakProvider);

    // 활성 도서가 없거나 오늘 계획이 없으면 빈 위젯 반환
    if (activeBooks.isEmpty || todayPlans.isEmpty) {
      return const SizedBox.shrink();
    }

    return GlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Icon(
                Icons.menu_book_rounded,
                color: ColorTokens.main,
                size: AppLayout.iconLg,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                '오늘의 독서',
                style: AppTypography.titleMd.copyWith(
                  color: context.themeColors.textPrimary,
                ),
              ),
              const Spacer(),
              // 완료 카운트 뱃지
              _CompletionBadge(plans: todayPlans),
            ],
          ),
          // 연속 독서 스트릭 표시
          if (streak > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '연속 $streak일 독서 중!',
              style: AppTypography.captionLg.copyWith(
                color: ColorTokens.success,
                fontWeight: AppTypography.weightSemiBold,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          // 독서 계획 목록
          ...todayPlans.map(
            (plan) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: ReadingPlanItem(plan: plan),
            ),
          ),
        ],
      ),
    );
  }
}

/// 완료 카운트 뱃지 (2/5 형식)
class _CompletionBadge extends StatelessWidget {
  final List<ReadingPlan> plans;

  const _CompletionBadge({required this.plans});

  @override
  Widget build(BuildContext context) {
    final completed = plans.where((p) => p.isCompleted).length;
    final total = plans.length;

    return Text(
      '$completed/$total',
      style: AppTypography.captionLg.copyWith(
        color: completed == total
            ? ColorTokens.success
            : context.themeColors.textPrimaryWithAlpha(0.55),
        fontWeight: AppTypography.weightSemiBold,
      ),
    );
  }
}
