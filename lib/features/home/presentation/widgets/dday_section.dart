// F1: 홈 대시보드 D-Day 섹션 위젯
// 수평 스크롤 D-day 카드 목록 + 섹션 제목
// AN-10: BouncingScrollPhysics 물리 기반 수평 스크롤
// 긴급 일정(D-3 이하) 빨간색 강조 표시 (AC-HM-05)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../shared/widgets/dday_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/section_title.dart';
import '../../providers/home_provider.dart';
import '../../providers/home_dday_provider.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// D-Day 섹션 위젯 (섹션 제목 + 수평 스크롤 카드 목록)
class DdaySection extends ConsumerWidget {
  const DdaySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ddaysAsync = ref.watch(upcomingDdaysProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 섹션 제목 (padding: 0 20px)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: SectionTitle(
            title: '다가오는 일정',
            actionLabel: '일정 추가',
            onActionTap: () => context.go(RoutePaths.calendar),
          ),
        ),

        // D-day 카드 수평 스크롤 영역
        ddaysAsync.when(
          loading: () => _buildSkeleton(),
          error: (_, __) => _buildError(),
          data: (ddays) => ddays.isEmpty
              ? _buildEmpty(context)
              : _buildDdayList(ddays),
        ),
      ],
    );
  }

  /// 로딩 스켈레톤
  Widget _buildSkeleton() {
    // 고정 높이 대신 IntrinsicHeight 기반으로 적응형 높이를 사용한다
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        itemCount: 3,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          child: LoadingSkeleton(
            width: 140,
            height: 110,
            borderRadius: 16,
          ),
        ),
      ),
    );
  }

  /// 에러 상태
  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: EmptyState(
        icon: Icons.sync_problem_rounded,
        mainText: '일정을 불러오지 못했어요',
        minHeight: 100,
      ),
    );
  }

  /// 빈 상태 (일정 없음)
  Widget _buildEmpty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: EmptyState(
        icon: Icons.event_rounded,
        mainText: '다가오는 일정이 없어요',
        ctaLabel: '일정 추가하러 가기',
        onCtaTap: () => context.go(RoutePaths.calendar),
        minHeight: 100,
      ),
    );
  }

  /// D-day 카드 수평 스크롤 목록 (AN-10)
  Widget _buildDdayList(List<DdayItem> ddays) {
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        // AN-10: BouncingScrollPhysics
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        itemCount: ddays.length,
        itemBuilder: (context, index) {
          final item = ddays[index];
          return Padding(
            // D-day 카드 간격: 12px (space-3)
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: DdayCard(
              eventName: item.eventName,
              daysRemaining: item.daysRemaining,
              dateLabel: item.dateLabel,
              urgencyLevel: item.urgencyLevel,
            ),
          );
        },
      ),
    );
  }
}
