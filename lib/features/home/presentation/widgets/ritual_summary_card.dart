// F1: 홈 대시보드 데일리 리추얼 요약 카드
// 좌측: Top 5 목표 + Goal 진행률, 우측: 오늘의 3가지 + Todo 완료 상태
// 탭 시 확인 다이얼로그 → DailyRitualScreen 재오픈을 지원한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../ritual/models/daily_ritual.dart';
import '../../../ritual/presentation/daily_ritual_screen.dart';
import '../../../ritual/providers/ritual_home_provider.dart';
import '../../../ritual/providers/ritual_provider.dart';
import 'ritual_card_header.dart';
import 'ritual_daily_three_column.dart';
import 'ritual_top5_column.dart';

/// 홈 대시보드 데일리 리추얼 요약 카드
/// 리추얼 완료 여부 + Top 5 진행률 + Daily Three 완료 상태를 표시한다
class RitualSummaryCard extends ConsumerWidget {
  const RitualSummaryCard({super.key});

  /// 현재 월간 기간 키 (yyyy-MM)
  String get _periodKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tc = context.themeColors;
    final completed = ref.watch(hasCompletedTodayProvider);
    final dailyThree = ref.watch(todayDailyThreeProvider);
    final ritual = ref.watch(
      currentRitualProvider(
        (periodType: 'monthly', periodKey: _periodKey),
      ),
    );

    // Top 5 목표 텍스트 추출
    final top5Texts = _extractTop5Texts(ritual);
    // Top 5 진행률 조회
    final progressMap = ref.watch(
      top5GoalProgressProvider((top5Texts: top5Texts)),
    );
    // DailyThree Todo 완료 상태 조회 (직접 watch — family 동등성 문제 회피)
    final todoStatusMap = ref.watch(dailyThreeTodoStatusProvider);

    return GestureDetector(
      onTap: completed
          ? () => _showReopenDialog(context, ref)
          : null,
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더: 아이콘 + 제목 + 날짜 + 배지
            RitualCardHeader(completed: completed),
            const SizedBox(height: AppSpacing.xl),
            // 미완료 빈 상태: 리추얼 시작 안내
            if (!completed && ritual == null)
              _buildInvitation(tc)
            else
              // 2열 레이아웃: 좌 = Top 5, 우 = Daily Three
              _buildTwoColumns(
                top5Texts: top5Texts,
                progressMap: progressMap,
                dailyThree: dailyThree,
                todoStatusMap: todoStatusMap,
              ),
          ],
        ),
      ),
    );
  }

  /// TOP 5 인덱스에 해당하는 목표 텍스트를 추출한다
  List<String> _extractTop5Texts(DailyRitual? ritual) {
    if (ritual == null) return [];
    return ritual.top5Indices
        .where((i) => i >= 0 && i < ritual.goals.length)
        .map((i) => ritual.goals[i])
        .where((t) => t.trim().isNotEmpty)
        .toList();
  }

  /// 리추얼 미설정 시 초대 안내 메시지
  Widget _buildInvitation(ResolvedThemeColors tc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Text(
          '데일리 리추얼을 시작해보세요!',
          style: AppTypography.bodyMd.copyWith(
            color: tc.textPrimaryWithAlpha(0.50),
          ),
        ),
      ),
    );
  }

  /// 2열 레이아웃: 좌측 Top 5, 우측 Daily Three
  Widget _buildTwoColumns({
    required List<String> top5Texts,
    required Map<String, double?> progressMap,
    required dynamic dailyThree,
    required Map<String, bool> todoStatusMap,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 좌측: Top 5 목표 + 진행률
          Expanded(
            child: RitualTop5Column(
              top5Texts: top5Texts,
              progressMap: progressMap,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          // 우측: 오늘의 3가지
          Expanded(
            child: RitualDailyThreeColumn(
              dailyThree: dailyThree,
              todoStatusMap: todoStatusMap,
            ),
          ),
        ],
      ),
    );
  }

  /// 리추얼 재설정 확인 다이얼로그 표시
  Future<void> _showReopenDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('데일리 리추얼'),
        content: const Text('데일리 리추얼을 다시 설정하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('설정하기'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // 오늘의 완료 플래그를 리셋한다
    await _resetTodayCompletion(ref);

    // DailyRitualScreen을 다시 연다
    if (!context.mounted) return;
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (_, __, ___) => const DailyRitualScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: AppAnimation.medium,
      ),
    );
  }

  /// 오늘의 DailyThree 완료 상태를 리셋한다
  Future<void> _resetTodayCompletion(WidgetRef ref) async {
    final dailyThree = ref.read(todayDailyThreeProvider);
    if (dailyThree == null) return;

    // isCompleted를 false로 변경하여 리추얼 재진행을 허용한다
    final reset = dailyThree.copyWith(isCompleted: false);
    final save = ref.read(saveDailyThreeProvider);
    await save(reset);
  }
}
