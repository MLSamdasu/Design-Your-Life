// F6: 오늘의 타이머 기록 목록 위젯
// selectedDateTimerLogsProvider에서 선택된 날짜의 타이머 로그를 실시간으로 표시한다.
// 각 로그는 시간 범위, 지속 시간, 투두 이름, 세션 유형을 보여준다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/glass_card.dart';
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
    // selectedDateTimerLogsProvider는 동기 Provider이므로 직접 사용한다
    final logs = ref.watch(selectedDateTimerLogsProvider);

    return GlassCard(
      variant: GlassCardVariant.defaultCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 섹션 제목
          const SectionTitle(title: '오늘의 집중 기록'),
          const SizedBox(height: AppSpacing.lg),

          // 동기 Provider이므로 직접 렌더링한다
          _buildLogList(logs),
        ],
      ),
    );
  }

  /// 기록 목록 UI
  /// ListView.builder로 지연 빌드하여 로그 수가 많을 때 성능을 개선한다
  Widget _buildLogList(List<TimerLog> logs) {
    if (logs.isEmpty) {
      return const EmptyState(
        icon: Icons.timer_outlined,
        mainText: '오늘의 집중 기록이 없어요',
        subText: '타이머를 시작하면 기록이 쌓여요',
        minHeight: AppLayout.containerXl,
      );
    }

    // 부모가 Column이므로 shrinkWrap + NeverScrollableScrollPhysics 사용
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: logs.length,
      itemBuilder: (context, index) => _TimerLogItem(log: logs[index]),
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
            width: AppLayout.containerMd,
            height: AppLayout.containerMd,
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
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xxs),
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
                    // WCAG 대비: accent 배경 위에서 테마 텍스트 색상으로 고대비 확보
                    color: context.themeColors.textPrimaryWithAlpha(0.85),
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
