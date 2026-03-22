// F8: 업적/배지 메인 화면
// 상단에 업적 달성 현황, 하단에 업적 그리드를 표시한다.
// Glassmorphism 디자인을 따른다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/theme/theme_colors.dart';
import '../models/achievement_definition.dart';
import '../providers/achievement_provider.dart';
import 'widgets/achievement_grid.dart';
import '../../../core/theme/radius_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/layout_tokens.dart';
import '../../../shared/widgets/bottom_scroll_spacer.dart';

/// 업적/배지 메인 화면
/// 업적 달성 현황과 전체 업적 목록을 표시한다
class AchievementScreen extends ConsumerWidget {
  const AchievementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                padding: const EdgeInsets.fromLTRB(AppSpacing.pageHorizontal, AppSpacing.pageVertical, AppSpacing.pageHorizontal, 0),
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
                            width: AppLayout.minTouchTarget,
                            height: AppLayout.minTouchTarget,
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
                            vertical: AppSpacing.xxs,
                          ),
                          // 업적 수 배지: 배경 테마에 맞는 악센트 색상으로 표시한다
                          decoration: BoxDecoration(
                            color: context.themeColors.accentWithAlpha(0.25),
                            borderRadius: BorderRadius.circular(AppRadius.circle),
                          ),
                          child: Text(
                            '${unlockedIds.length}/${AchievementDef.all.length}',
                            style: AppTypography.captionLg.copyWith(
                              // WCAG 대비: accent 배경 위에서 테마 텍스트 색상으로 고대비 확보
                              color: context.themeColors.textPrimaryWithAlpha(0.85),
                              fontWeight: AppTypography.weightBold,
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
                // 하단 여백은 아래 BottomScrollSpacer에서 처리
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
                // 동기 Provider이므로 직접 렌더링한다
                child: AchievementGrid(unlockedIds: unlockedIds),
              ),
            ),

            // 하단 여백: 마지막 콘텐츠를 화면 중앙까지 스크롤 가능하도록 화면 절반 높이
            const SliverToBoxAdapter(
              child: BottomScrollSpacer(),
            ),
          ],
        ),
      ),
    );
  }

}
