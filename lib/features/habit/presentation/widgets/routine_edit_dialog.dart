// F4 위젯: RoutineEditDialog - 루틴 편집 다이얼로그
// RoutineCreateDialog를 편집 모드로 호출하는 헬퍼이다.
// 캘린더 탭의 루틴 카드 탭 시 사용한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/routine.dart';
import '../../../habit/providers/routine_provider.dart';
import 'routine_create_dialog.dart';

/// 루틴 편집 헬퍼: 기존 Routine 데이터를 RoutineCreateDialog에 전달하고
/// 저장 결과를 updateRoutineProvider를 통해 업데이트한다
Future<void> showRoutineEditDialog({
  required BuildContext context,
  required WidgetRef ref,
  required Routine routine,
}) async {
  // 기존 루틴 데이터를 RoutineCreateResult로 변환한다
  final initialData = RoutineCreateResult(
    name: routine.name,
    repeatDays: routine.repeatDays,
    startTime: routine.startTime,
    endTime: routine.endTime,
    colorIndex: routine.colorIndex,
  );

  final result = await RoutineCreateDialog.show(context, initialData: initialData);
  if (result == null) return; // 취소됨

  // 수정된 루틴을 updateRoutineProvider를 통해 Hive에 저장한다
  final updated = routine.copyWith(
    name: result.name,
    repeatDays: result.repeatDays,
    startTime: result.startTime,
    endTime: result.endTime,
    colorIndex: result.colorIndex,
    updatedAt: DateTime.now(),
  );

  await ref.read(updateRoutineProvider)(routine.id, updated);
}
