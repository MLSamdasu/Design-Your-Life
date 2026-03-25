// 새 투두/루틴 추가 FAB (Floating Action Button)
// 현재 서브탭에 따라 투두 또는 루틴 생성 다이얼로그를 연다.
// weeklyRoutine 탭: RoutineCreateDialog → 루틴 생성
// 그 외 탭: TodoCreateDialog → 투두 생성
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../shared/models/routine.dart';
import '../../../../shared/models/todo.dart';
import '../../../../shared/providers/tag_provider.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../providers/todo_provider.dart';
import '../../../habit/presentation/widgets/routine_create_dialog.dart';
import '../../../habit/providers/routine_provider.dart';
import 'todo_create_dialog.dart';

/// 서브탭에 따라 투두 또는 루틴 추가 FAB
/// weeklyRoutine 서브탭일 때는 RoutineCreateDialog를 열고,
/// 나머지 서브탭에서는 TodoCreateDialog를 연다.
class AddTodoFab extends ConsumerWidget {
  final DateTime selectedDate;

  const AddTodoFab({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // FAB 하단 여백 (사이드 네비게이션 레이아웃 기준)
    return Padding(
      padding: const EdgeInsets.only(bottom: AppLayout.bottomNavArea),
      child: FloatingActionButton(
        onPressed: () => _onPressed(context, ref),
        backgroundColor: ColorTokens.main,
        foregroundColor: ColorTokens.white,
        elevation: EffectLayout.elevationNone,
        child: const Icon(Icons.add_rounded, size: AppLayout.iconHuge),
      ),
    );
  }

  /// 현재 서브탭에 따라 적절한 생성 다이얼로그를 연다
  void _onPressed(BuildContext context, WidgetRef ref) {
    final subTab = ref.read(todoSubTabProvider);
    if (subTab == TodoSubTab.weeklyRoutine) {
      _openRoutineCreateDialog(context, ref);
    } else {
      _openTodoCreateDialog(context, ref);
    }
  }

  /// 루틴 생성 다이얼로그를 열고 결과를 저장한다
  Future<void> _openRoutineCreateDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await RoutineCreateDialog.show(context);
    if (result == null) return;

    // 로컬 퍼스트: 인증 없이도 루틴을 생성할 수 있다
    final userId =
        ref.read(currentUserIdProvider) ?? AppConstants.localUserId;
    final now = DateTime.now();

    try {
      await ref.read(createRoutineProvider).call(Routine(
            id: '', // Repository에서 UUID v4로 ID를 생성하므로 빈 문자열 전달
            userId: userId,
            name: result.name,
            repeatDays: result.repeatDays,
            startTime: result.startTime,
            endTime: result.endTime,
            colorIndex: result.colorIndex,
            createdAt: now,
            updatedAt: now,
          ));
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(context, '루틴 추가에 실패했습니다');
      }
    }
  }

  /// 투두 생성 다이얼로그를 열고 결과를 저장한다
  Future<void> _openTodoCreateDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // P1-16: 현재 선택된 날짜를 초기값으로 전달한다
    final result =
        await TodoCreateDialog.show(context, initialDate: selectedDate);
    if (result == null) return;

    final generateId = ref.read(generateTodoIdProvider);
    final createTodo = ref.read(createTodoProvider);
    final now = DateTime.now();

    // 선택된 태그 ID를 Tag 객체 정보가 포함된 Map 목록으로 변환한다
    final List<Map<String, dynamic>> tagMaps =
        result.tagIds.map((tagId) {
      final tag = ref.read(tagByIdProvider(tagId));
      if (tag == null) return null;
      return <String, dynamic>{
        'id': tag.id,
        'name': tag.name,
        'color_index': tag.colorIndex,
      };
    }).whereType<Map<String, dynamic>>().toList();

    try {
      await createTodo(
        Todo(
          id: generateId(),
          title: result.title,
          // P1-16: 다이얼로그에서 선택한 날짜를 사용한다 (폴백: selectedDate)
          date: result.date ?? selectedDate,
          startTime: result.startTime,
          endTime: result.endTime,
          color: result.colorIndex.toString(),
          memo: result.memo,
          tags: tagMaps,
          createdAt: now,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(context, '할 일 추가에 실패했습니다');
      }
    }
  }
}
