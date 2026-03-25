// F5 헬퍼: 만다라트 위저드 필드 검증·자동 채우기 유틸리티
// 텍스트 컨트롤러 리스트를 받아 빈 칸 채우기, 입력 완료 수 계산,
// 다음 단계 진행 가능 여부를 판정하는 순수 함수 모음이다.
import 'package:flutter/material.dart';

import '../../../../core/theme/layout_tokens.dart';

/// 빈 칸에 자동 채우기 (만다라트 원칙: 억지로라도 81칸 전부 채운다)
/// [step] 2이면 세부 목표, 3이면 실천 과제를 대상으로 한다.
void autoFillWizardStep({
  required int step,
  required List<TextEditingController> subGoalControllers,
  required List<List<TextEditingController>> taskControllers,
}) {
  if (step == 2) {
    // 세부 목표 빈 칸 자동 채우기
    for (int i = 0; i < subGoalControllers.length; i++) {
      if (subGoalControllers[i].text.trim().isEmpty) {
        subGoalControllers[i].text = '세부 목표 ${i + 1}';
      }
    }
  } else if (step == 3) {
    // 실천 과제 빈 칸 자동 채우기
    for (int i = 0; i < subGoalControllers.length; i++) {
      final sgTitle = subGoalControllers[i].text.trim();
      for (int j = 0; j < taskControllers[i].length; j++) {
        if (taskControllers[i][j].text.trim().isEmpty) {
          taskControllers[i][j].text = '$sgTitle - 과제 ${j + 1}';
        }
      }
    }
  }
}

/// 현재 단계의 입력 완료 수를 반환한다
int wizardFilledCount({
  required int step,
  required List<TextEditingController> subGoalControllers,
  required List<List<TextEditingController>> taskControllers,
}) {
  switch (step) {
    case 2:
      return subGoalControllers
          .where((c) => c.text.trim().isNotEmpty)
          .length;
    case 3:
      int count = 0;
      for (int i = 0; i < subGoalControllers.length; i++) {
        for (int j = 0; j < taskControllers[i].length; j++) {
          if (taskControllers[i][j].text.trim().isNotEmpty) count++;
        }
      }
      return count;
    default:
      return 0;
  }
}

/// 현재 단계의 총 필드 수를 반환한다
int wizardTotalCount(int step) {
  switch (step) {
    case 2:
      return GoalLayout.mandalartSubGoalCount; // 8
    case 3:
      return GoalLayout.mandalartSubGoalCount *
          GoalLayout.mandalartSubGoalCount; // 64
    default:
      return 0;
  }
}

/// 현재 단계에서 다음 단계로 진행 가능한지 검증한다
/// 만다라트는 81칸 전부 필수이므로 부분 입력으로 진행할 수 없다
bool canProceedWizardStep({
  required int step,
  required TextEditingController coreGoalController,
  required List<TextEditingController> subGoalControllers,
  required List<List<TextEditingController>> taskControllers,
}) {
  switch (step) {
    case 1:
      // 핵심 목표 필수
      return coreGoalController.text.trim().isNotEmpty;
    case 2:
      // 세부 목표 8개 전부 필수
      return subGoalControllers.every((c) => c.text.trim().isNotEmpty);
    case 3:
      // 실천 과제 64개 전부 필수
      for (int i = 0; i < taskControllers.length; i++) {
        for (int j = 0; j < taskControllers[i].length; j++) {
          if (taskControllers[i][j].text.trim().isEmpty) return false;
        }
      }
      return true;
    default:
      return false;
  }
}
