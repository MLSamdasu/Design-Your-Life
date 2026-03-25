// F6: 개별 타이머 기록 아이템 위젯
// 시간 범위, 지속 시간, 투두 이름, 세션 유형을 표시한다 (SRP 분리)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../services/timer_engine.dart';
import '../../models/timer_log.dart';

/// 개별 타이머 기록 아이템 위젯
class TimerLogItem extends StatelessWidget {
  final TimerLog log;

  const TimerLogItem({required this.log, super.key});

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
  Color _typeColor(BuildContext context) {
    switch (log.type) {
      case TimerSessionType.focus:
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
