// F6: 오늘의 타이머 기록 목록 위젯
// todayTimerLogsProvider에서 오늘의 타이머 로그를 실시간으로 표시한다.
// 각 로그는 시간 범위, 지속 시간, 투두 이름, 세션 유형을 보여준다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/section_title.dart';
import '../../services/timer_engine.dart';
import '../../models/timer_log.dart';
import '../../providers/timer_provider.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 오늘의 타이머 기록 목록 위젯
class TimerLogList extends ConsumerWidget {
  const TimerLogList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(todayTimerLogsProvider);

    return GlassCard(
      variant: GlassCardVariant.defaultCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 섹션 제목
          const SectionTitle(title: '오늘의 집중 기록'),
          const SizedBox(height: AppSpacing.lg),

          // 기록 목록
          logsAsync.when(
            loading: () => _buildLoading(),
            error: (_, __) => _buildError(),
            data: (logs) => _buildLogList(logs),
          ),
        ],
      ),
    );
  }

  /// 로딩 스켈레톤 UI
  Widget _buildLoading() {
    return Column(
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: LoadingSkeleton(height: 48, borderRadius: 8),
        ),
      ),
    );
  }

  /// 오류 상태 UI
  Widget _buildError() {
    return const EmptyState(
      icon: Icons.sync_problem_rounded,
      mainText: '기록을 불러오지 못했어요',
      minHeight: 80,
    );
  }

  /// 기록 목록 UI
  Widget _buildLogList(List<TimerLog> logs) {
    if (logs.isEmpty) {
      return const EmptyState(
        icon: Icons.timer_outlined,
        mainText: '오늘의 집중 기록이 없어요',
        subText: '타이머를 시작하면 기록이 쌓여요',
        minHeight: 80,
      );
    }

    return Column(
      children: logs
          .map((log) => _TimerLogItem(log: log))
          .toList(),
    );
  }
}

/// 개별 타이머 기록 아이템 위젯
class _TimerLogItem extends StatelessWidget {
  final TimerLog log;

  const _TimerLogItem({required this.log});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final startStr = timeFormat.format(log.startTime);
    final endStr = timeFormat.format(log.endTime);
    final durationStr = TimerEngine.formatTime(log.durationSeconds);
    // 세션 색상은 context를 통해 현재 테마를 인식해 결정한다
    final typeColor = _typeColor(context);
    final typeIcon = _typeIcon();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lgXl, vertical: AppSpacing.mdLg),
      decoration: BoxDecoration(
        color: context.themeColors.textPrimaryWithAlpha(0.07),
        borderRadius: BorderRadius.circular(AppRadius.lgXl),
        border: Border.all(
          color: context.themeColors.textPrimaryWithAlpha(0.10),
        ),
      ),
      child: Row(
        children: [
          // 세션 유형 아이콘
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(
              typeIcon,
              color: typeColor,
              size: AppLayout.iconMd,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),

          // 시간 정보 + 투두 이름
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 세션 유형 레이블 + 지속 시간
                Row(
                  children: [
                    // 유형 레이블은 고정 텍스트이므로 축소 불필요
                    Flexible(
                      child: Text(
                        log.type.displayLabel,
                        style: AppTypography.captionLg.copyWith(
                          color: typeColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      durationStr,
                      style: AppTypography.captionLg.copyWith(
                        color: context.themeColors.textPrimaryWithAlpha(0.70),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),

                // 시간 범위
                Text(
                  '$startStr - $endStr',
                  style: AppTypography.captionMd.copyWith(
                    color: context.themeColors.textPrimaryWithAlpha(0.50),
                  ),
                ),
              ],
            ),
          ),

          // 연결된 투두 이름 (있을 경우)
          if (log.todoTitle != null) ...[
            const SizedBox(width: AppSpacing.md),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 3),
                // 투두 이름 뱃지: 배경 테마에 맞는 악센트 색상으로 표시한다
                decoration: BoxDecoration(
                  color: context.themeColors.accentWithAlpha(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  log.todoTitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.captionMd.copyWith(
                    color: context.themeColors.accent,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 세션 유형별 색상 반환
  /// 집중 세션 색상은 배경 테마에 맞는 악센트 색상을 사용한다
  Color _typeColor(BuildContext context) {
    switch (log.type) {
      case TimerSessionType.focus:
        // 어두운 배경에서는 mainLight, 밝은 배경에서는 main을 사용한다
        return context.themeColors.accent;
      case TimerSessionType.shortBreak:
        return ColorTokens.success;
      case TimerSessionType.longBreak:
        return ColorTokens.info;
    }
  }

  /// 세션 유형별 아이콘 반환
  IconData _typeIcon() {
    switch (log.type) {
      case TimerSessionType.focus:
        return Icons.psychology_rounded;
      case TimerSessionType.shortBreak:
        return Icons.coffee_rounded;
      case TimerSessionType.longBreak:
        return Icons.self_improvement_rounded;
    }
  }
}
