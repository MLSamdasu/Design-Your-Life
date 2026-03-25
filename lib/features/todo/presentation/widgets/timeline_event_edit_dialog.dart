// 타임라인 이벤트 편집 다이얼로그
// 캘린더 이벤트와 투두를 유형에 따라 적절한 편집 다이얼로그로 연다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/todo.dart';
import '../../../../shared/providers/tag_provider.dart';
import '../../../calendar/presentation/utils/event_dialog_utils.dart';
import '../../../calendar/providers/event_provider.dart';
import '../../providers/todo_provider.dart';
import 'todo_create_dialog.dart';

/// 유형에 따른 편집 다이얼로그를 연다
void openTimelineEditDialog(
  BuildContext context,
  WidgetRef ref,
  Todo todo,
) {
  if (todo.id.startsWith('cal_')) {
    // 캘린더 이벤트: cal_ 접두사를 제거하고 원본 이벤트를 조회한다
    final rawId = todo.id.replaceFirst('cal_', '');
    // 반복 인스턴스 ID 처리: {uuid}_{yyyymmdd} → 원본 uuid 추출
    String baseEventId = rawId;
    if (baseEventId.length > 36 && baseEventId.contains('_')) {
      final lastUnderscoreIdx = baseEventId.lastIndexOf('_');
      final candidate = baseEventId.substring(0, lastUnderscoreIdx);
      if (candidate.length == 36) {
        baseEventId = candidate;
      }
    }
    final repository = ref.read(eventRepositoryProvider);
    final event = repository.getEventById(baseEventId);
    if (event == null) return;
    showEventEditDialog(context: context, ref: ref, event: event);
  } else {
    _openTodoEditDialog(context, ref, todo);
  }
}

/// 투두 수정 다이얼로그를 열고 결과를 반영한다
Future<void> _openTodoEditDialog(
  BuildContext context,
  WidgetRef ref,
  Todo todo,
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

  final updateTodo = ref.read(updateTodoProvider);
  await updateTodo(
    todo.id,
    todo.copyWith(
      title: result.title,
      // 다이얼로그에서 변경된 날짜를 반영한다
      date: result.date,
      startTime: result.startTime,
      clearStartTime: result.startTime == null,
      endTime: result.endTime,
      clearEndTime: result.endTime == null,
      color: result.colorIndex.toString(),
      memo: result.memo,
      clearMemo: result.memo == null,
      tags: tagMaps,
    ),
  );
}
