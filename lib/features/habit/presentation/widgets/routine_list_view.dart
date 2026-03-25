// F4 위젯: RoutineListView - 내 루틴 뷰
// 루틴 카드 리스트 + 주간 시간표 그리드를 표시한다.
// 빈 상태: "아직 등록된 루틴이 없어요" + "첫 루틴 만들기" CTA
//
// SRP 분리: RoutineListSection, RoutineWeeklySection을 별도 파일로 추출
export 'routine_list_section.dart';
export 'routine_weekly_section.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../shared/widgets/bottom_scroll_spacer.dart';
import '../../providers/routine_provider.dart';
import 'routine_list_section.dart';
import 'routine_weekly_section.dart';

/// 내 루틴 서브탭 뷰
class RoutineListView extends ConsumerWidget {
  const RoutineListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // routinesProvider는 동기 Provider이므로 직접 사용한다
    final routines = ref.watch(routinesProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RoutineListSection(routines: routines),
          const SizedBox(height: AppSpacing.xxl),
          () {
            final active = routines.where((x) => x.isActive).toList();
            return active.isEmpty
                ? const SizedBox.shrink()
                : RoutineWeeklySection(routines: active);
          }(),
          // 하단 여백: 마지막 콘텐츠를 화면 중앙까지 스크롤 가능하도록 화면 절반 높이
          const BottomScrollSpacer(),
        ],
      ),
    );
  }
}
