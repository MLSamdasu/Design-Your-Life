// 투두 탭 서브탭 2: 주간 루틴 뷰 (풀 CRUD)
// 습관 탭의 "내 루틴"과 동일한 기능을 제공한다.
// RoutineCard + RoutineWeeklySection을 재사용하여 코드 중복을 방지한다.
// 루틴 생성/수정/삭제/토글을 모두 지원한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing_tokens.dart';
import '../../../../shared/widgets/bottom_scroll_spacer.dart';
import '../../../habit/providers/routine_provider.dart';
import '../../../habit/presentation/widgets/routine_list_section.dart';
import '../../../habit/presentation/widgets/routine_weekly_section.dart';

export 'routine_weekly_item.dart';

/// 주간 루틴 뷰 — 습관 탭의 "내 루틴"과 동일한 풀 CRUD 뷰
/// RoutineListSection (카드 리스트 + 생성/수정/삭제)과
/// RoutineWeeklySection (주간 시간표 그리드)을 함께 표시한다.
class RoutineWeeklyView extends ConsumerWidget {
  const RoutineWeeklyView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // routinesProvider는 동기 Provider이므로 직접 사용한다
    final routines = ref.watch(routinesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 루틴 카드 리스트 (CRUD 지원)
          RoutineListSection(routines: routines),
          const SizedBox(height: AppSpacing.xxl),
          // 활성 루틴이 있을 때만 주간 시간표를 표시한다
          () {
            final active = routines.where((x) => x.isActive).toList();
            return active.isEmpty
                ? const SizedBox.shrink()
                : RoutineWeeklySection(routines: active);
          }(),
          // 하단 여백: FAB 가림 방지
          const BottomScrollSpacer(),
        ],
      ),
    );
  }
}
