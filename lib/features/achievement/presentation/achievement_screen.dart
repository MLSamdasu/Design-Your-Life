// F8: 업적/배지 메인 화면
// 상단에 업적 달성 현황, 하단에 업적 그리드를 표시한다.
// Glassmorphism 디자인을 따른다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../models/achievement.dart';
import '../models/achievement_definition.dart';
import '../providers/achievement_provider.dart';
import 'widgets/achievement_grid.dart';
import '../../../core/theme/radius_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/layout_tokens.dart';

/// 업적/배지 메인 화면
/// 업적 달성 현황과 전체 업적 목록을 표시한다
class AchievementScreen extends ConsumerWidget {
  const AchievementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Achievement>> achievementsAsync = ref.watch(userAchievementsProvider);
    final unlockedIds = ref.watch(unlockedAchievementIdsProvider);

    return Scaffold(
      backgroundColor: ColorTokens.transparent,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 상단 헤더 영역
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 헤더 행: 뒤로가기 버튼 + 화면 제목
                    Row(
                      children: [
                        // 뒤로가기 버튼 (TagManagementScreen과 동일한 패턴)
                        GestureDetector(
                          onTap: () => context.pop(),
                          behavior: HitTestBehavior.opaque,
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Center(
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: context.themeColors.textPrimaryWithAlpha(0.8),
                                size: AppLayout.iconXl,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        // 화면 제목
                        Text(
                          '업적 & 배지',
                          style: AppTypography.headingSm.copyWith(
                            color: context.themeColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // 업적 섹션 제목
                    Row(
                      children: [
                        Text(
                          '배지',
                          style: AppTypography.titleLg.copyWith(
                    color: context.themeColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        // 달성 업적 수 / 전체 업적 수 표시 (전체 수는 AchievementDef.all.length로 동적 계산)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 3,
                          ),
                          // 업적 수 배지: 배경 테마에 맞는 악센트 색상으로 표시한다
                          decoration: BoxDecoration(
                            color: context.themeColors.accentWithAlpha(0.25),
                            borderRadius: BorderRadius.circular(AppRadius.circle),
                          ),
                          child: Text(
                            '${unlockedIds.length}/${AchievementDef.all.length}',
                            style: AppTypography.captionLg.copyWith(
                              color: context.themeColors.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),

            // 업적 그리드 (달성 상태에 따라 정렬)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: achievementsAsync.when(
                  loading: () => _buildGridSkeleton(),
                  error: (_, __) => _buildError(context),
                  data: (_) => AchievementGrid(unlockedIds: unlockedIds),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 그리드 로딩 스켈레톤
  Widget _buildGridSkeleton() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.90,
      ),
      itemBuilder: (_, __) => const LoadingSkeleton(
        height: double.infinity,
        borderRadius: 16,
      ),
    );
  }

  /// 에러 상태 UI
  Widget _buildError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sync_problem_rounded,
            size: 48,
            color: context.themeColors.textPrimaryWithAlpha(0.40),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '업적을 불러오지 못했어요',
            style: AppTypography.bodyMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.60),
            ),
          ),
        ],
      ),
    );
  }
}
