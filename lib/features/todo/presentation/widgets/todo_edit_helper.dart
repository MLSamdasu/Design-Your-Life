// 투두 수정 다이얼로그 헬퍼
// 수정 다이얼로그를 열고 결과를 updateTodo로 저장하는 유틸리티 함수
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/todo.dart';
import '../../../../shared/providers/tag_provider.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import 'todo_create_dialog.dart';

/// 수정 다이얼로그를 열고 결과를 updateTodo로 저장한다
Future<void> openEditDialog(
  BuildContext context,
  WidgetRef ref,
  Todo todo,
  DateTime selectedDate,
  Future<void> Function(String, Todo) updateTodo,
) async {
  final result = await TodoCreateDialog.showEdit(
    context,
    existingTodo: todo,
  );
  if (result == null) return;

  // 선택된 태그 ID를 Tag 객체 정보가 포함된 Map 목록으로 변환한다
  final List<Map<String, dynamic>> tagMaps = result.tagIds.map((tagId) {
    final tag = ref.read(tagByIdProvider(tagId));
    if (tag == null) return null;
    return <String, dynamic>{
      'id': tag.id,
      'name': tag.name,
      'color_index': tag.colorIndex,
    };
  }).whereType<Map<String, dynamic>>().toList();

  try {
    // 기존 투두를 수정된 필드로 업데이트한다
    await updateTodo(
      todo.id,
      todo.copyWith(
        title: result.title,
        // P1-16: 다이얼로그에서 변경된 날짜를 반영한다
        date: result.date,
        startTime: result.startTime,
        clearStartTime: result.startTime == null,
        endTime: result.endTime,
        clearEndTime: result.endTime == null,
        // 색상 인덱스를 문자열로 저장한다
        color: result.colorIndex.toString(),
        memo: result.memo,
        clearMemo: result.memo == null,
        // 태그 정보를 Map 목록으로 전달한다
        tags: tagMaps,
      ),
    );
  } catch (e) {
    // 수정 실패 시 사용자에게 오류를 알린다
    if (context.mounted) {
      AppSnackBar.showError(context, '할 일 수정에 실패했습니다');
    }
  }
}
