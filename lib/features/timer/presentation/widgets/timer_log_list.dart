// F6: 오늘의 타이머 기록 목록 위젯
// selectedDateTimerLogsProvider에서 선택된 날짜의 타이머 로그를 실시간으로 표시한다.
// 각 로그는 시간 범위, 지속 시간, 투두 이름, 세션 유형을 보여준다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/section_title.dart';
import '../../models/timer_log.dart';
import '../../providers/timer_provider.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import 'timer_log_item.dart';

export 'timer_log_item.dart';

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
      itemBuilder: (context, index) => TimerLogItem(log: logs[index]),
    );
  }
}
