// F5 헬퍼: 만다라트 위저드 저장 핸들러
// 입력된 핵심 목표·세부 목표·실천 과제를 Hive에 원자적으로 저장하고
// 위저드 상태를 초기화하는 단일 비동기 함수이다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../shared/models/goal.dart';
import '../../../../shared/enums/goal_period.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../providers/goal_provider.dart';
import '../../providers/mandalart_provider.dart';

/// 입력 데이터를 로컬 Hive에 원자적으로 저장하고 위저드를 완료한다
/// state 변경과 버전 갱신을 한 번만 수행하여 크래시를 방지한다.
/// 저장 성공 시 true, 실패 시 false를 반환한다.
Future<bool> saveMandalartAndComplete({
  required WidgetRef ref,
  required BuildContext context,
  required TextEditingController coreGoalController,
  required List<TextEditingController> subGoalControllers,
  required List<List<TextEditingController>> taskControllers,
}) async {
  // 로컬 퍼스트: 로그인 없이도 저장 가능하도록 폴백 사용자 ID를 적용한다
  final userId =
      ref.read(currentUserIdProvider) ?? AppConstants.localUserId;

  final coreGoalTitle = coreGoalController.text.trim();
  if (coreGoalTitle.isEmpty) return false;

  try {
    final now = DateTime.now();
    final goal = Goal(
      id: '',
      userId: userId,
      title: coreGoalTitle,
      period: GoalPeriod.yearly,
      year: now.year,
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
    );

    // 세부 목표 제목 8개 수집
    final subGoalTitles =
        subGoalControllers.map((c) => c.text.trim()).toList();

    // 실천 과제 제목 8×8 수집
    final taskTitles = <List<String>>[];
    for (int i = 0; i < taskControllers.length; i++) {
      taskTitles.add(
        taskControllers[i].map((c) => c.text.trim()).toList(),
      );
    }

    // 원자적 생성: Goal + 8 SubGoal + 64 GoalTask 한 번에 저장
    final goalId = await ref
        .read(goalNotifierProvider.notifier)
        .createMandalart(goal, subGoalTitles, taskTitles);

    if (goalId == null) {
      if (context.mounted) {
        AppSnackBar.showError(context, '만다라트 저장에 실패했습니다');
      }
      return false;
    }

    // 위저드 상태 초기화
    resetWizard(ref);
    return true;
  } catch (e) {
    if (context.mounted) {
      AppSnackBar.showError(context, '만다라트 저장에 실패했습니다');
    }
    return false;
  }
}
