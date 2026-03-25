// F6: 포모도로 타이머 메인 화면 (배럴 재-export + 메인 위젯)
// StatefulShellRoute 6번째 탭으로 메인 네비게이션에 포함된다.
// SegmentedControl로 '타이머'/'통계' 서브탭을 전환한다.
// 투두 연결은 timerStateProvider.linkTodo()로 사전 설정 후 탭 전환한다.
export 'timer_screen_content.dart';
export 'timer_screen_header.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../shared/widgets/segmented_control.dart';
import '../providers/timer_provider.dart';
import '../providers/timer_stats_provider.dart';
import 'timer_screen_content.dart';
import 'timer_screen_header.dart';
import 'widgets/timer_stats_view.dart';

/// 서브탭 레이블 목록 (타이머 / 통계)
const _subTabLabels = ['타이머', '통계'];

/// 포모도로 타이머 메인 화면
/// SegmentedControl로 타이머/통계 서브탭을 전환한다
class TimerScreen extends ConsumerWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerStateProvider);
    final subTab = ref.watch(timerSubTabProvider);
    final sessionsBeforeLong = ref.watch(timerSessionsBeforeLongBreakProvider);

    return Scaffold(
      // 배경을 투명으로 설정하여 앱 그라디언트 배경이 보이게 한다
      backgroundColor: ColorTokens.transparent,
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상단 헤더: 제목 + 집중 시간 뱃지 + 업적/설정 아이콘
            TimerHeader(timerState: timerState),
            const SizedBox(height: AppSpacing.lg),
            // 서브탭 스위처 (타이머 / 통계)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.md,
              ),
              child: SegmentedControl<int>(
                values: const [0, 1],
                selected: subTab,
                labelBuilder: (i) => _subTabLabels[i],
                onChanged: (i) =>
                    ref.read(timerSubTabProvider.notifier).state = i,
              ),
            ),
            // 서브탭 콘텐츠
            Expanded(
              child: subTab == 0
                  ? TimerContent(
                      timerState: timerState,
                      sessionsBeforeLongBreak: sessionsBeforeLong,
                    )
                  : const TimerStatsView(),
            ),
          ],
        ),
      ),
    );
  }
}
