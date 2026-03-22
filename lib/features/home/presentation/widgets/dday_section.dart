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
import '../../../../shared/widgets/section_title.dart';
import '../../providers/home_provider.dart';
import '../../providers/home_dday_provider.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// D-Day 섹션 위젯 (섹션 제목 + 수평 스크롤 카드 목록)
class DdaySection extends ConsumerWidget {
  const DdaySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 동기 Provider: 직접 값을 사용한다
    final ddays = ref.watch(upcomingDdaysProvider);

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

        // 동기 Provider이므로 직접 값을 사용한다
        ddays.isEmpty ? _buildEmpty(context) : _buildDdayList(ddays),
      ],
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
        minHeight: AppLayout.dailyScrollOffset,
      ),
    );
  }

  /// D-day 카드 수평 스크롤 목록 (AN-10)
  Widget _buildDdayList(List<DdayItem> ddays) {
    return SizedBox(
      height: AppLayout.ddayListHeight,
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
