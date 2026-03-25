// F3: 투두 화면
// 상단 주간 날짜 슬라이더 + "하루 일정표"/"할 일 목록" 서브탭을 포함한다.
// selectedDateProvider로 날짜를 관리하고, TodoOrchestrator(F3.4) 상태를 watch한다.
// F16: TagFilterBar를 서브탭 전환 아래에 배치하여 태그 기반 필터링을 지원한다.
// F20: QuickInputBar를 TodoHeader 아래에 배치하여 자연어 빠른 투두 입력을 지원한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/nlp/parsed_todo.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../shared/models/todo.dart';
import '../../../shared/widgets/segmented_control.dart';
import '../../../shared/widgets/tag_filter_bar.dart';
import '../../../shared/providers/tag_provider.dart';
import '../providers/todo_provider.dart';
import 'widgets/add_todo_fab.dart';
import 'widgets/daily_schedule_view.dart';
import 'widgets/quick_input_bar.dart';
import 'widgets/routine_weekly_view.dart';
import 'widgets/todo_header.dart';
import 'widgets/todo_list_view.dart';
import '../../../core/theme/animation_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../shared/widgets/app_snack_bar.dart';

/// 자연어 빠른 입력 처리 함수 (F20)
/// 파싱 결과에서 날짜/시간/제목/태그를 추출하여 투두를 즉시 생성한다
/// [parsed]: 자연어 파싱 결과
/// [selectedDate]: 현재 선택된 날짜 (파싱 결과에 날짜가 없을 때 폴백으로 사용)
Future<void> _handleQuickInput(
  BuildContext context,
  WidgetRef ref,
  ParsedTodo parsed,
  DateTime selectedDate,
) async {
  // 파싱 결과가 유효하지 않으면 무시한다
  if (!parsed.isValid) return;

  final generateId = ref.read(generateTodoIdProvider);
  final createTodo = ref.read(createTodoProvider);
  final now = DateTime.now();

  // 파싱된 날짜가 있으면 해당 날짜 사용, 없으면 현재 선택된 날짜를 사용한다
  final todoDate = parsed.hasDate ? parsed.date! : selectedDate;

  // 파싱된 #태그 이름을 기존 태그 객체로 변환한다 (이름 기준 매칭)
  List<Map<String, dynamic>> matchedTags = const [];
  if (parsed.hasTags) {
    // userTagsProvider는 동기 Provider이므로 직접 사용한다
    final allTags = ref.read(userTagsProvider);
    matchedTags = parsed.tagNames
        .map((name) {
          // 태그 이름이 정확히 일치하는 태그를 찾는다 (대소문자 무시)
          final found = allTags
              .where((t) => t.name.toLowerCase() == name.toLowerCase())
              .toList();
          if (found.isEmpty) return null;
          final tag = found.first;
          return <String, dynamic>{
            'id': tag.id,
            'name': tag.name,
            'color_index': tag.colorIndex,
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  try {
    await createTodo(
      Todo(
        id: generateId(),
        title: parsed.title,
        date: todoDate,
        // 파싱된 시간이 있으면 startTime으로 설정한다
        startTime: parsed.hasTime ? parsed.time : null,
        memo: null,
        tags: matchedTags,
        createdAt: now,
      ),
    );
  } catch (e) {
    // API 호출 실패 시 사용자에게 오류를 알린다
    if (context.mounted) {
      AppSnackBar.showError(context, '할 일 추가에 실패했습니다');
    }
  }
}

/// 투두 메인 화면 (F3)
/// 하단 네비게이션 탭 3 (투두)
class TodoScreen extends ConsumerWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final subTab = ref.watch(todoSubTabProvider);

    return Scaffold(
      backgroundColor: ColorTokens.transparent,
      // 새 투두 추가 FAB
      floatingActionButton: AddTodoFab(selectedDate: selectedDate),
      // 상단 SafeArea는 MainShell에서 처리하므로 top: false로 중복 적용을 방지한다
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상단 헤더: 년/월 피커 + 날짜 슬라이더
            TodoHeader(selectedDate: selectedDate),
            const SizedBox(height: AppSpacing.md),
            // 자연어 빠른 입력 바 (F20)
            // 사용자가 자연어 문장을 입력하면 파싱하여 투두를 즉시 생성한다
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: QuickInputBar(
                onSubmit: (parsed) => _handleQuickInput(
                  context,
                  ref,
                  parsed,
                  selectedDate,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // 서브탭 전환 (일정표 / 주간 루틴 / 할 일)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: SegmentedControl<TodoSubTab>(
                values: TodoSubTab.values,
                selected: subTab,
                labelBuilder: (tab) => switch (tab) {
                  TodoSubTab.dailySchedule => '일정표',
                  TodoSubTab.weeklyRoutine => '주간 루틴',
                  TodoSubTab.todoList => '할 일',
                },
                onChanged: (tab) => ref.read(todoSubTabProvider.notifier).state = tab,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // 태그 필터 바 (F16: 태그 기반 필터링)
            // 사용자 태그가 있을 때만 표시된다 (TagFilterBar 내부에서 처리)
            const TagFilterBar(),
            const SizedBox(height: AppSpacing.xs),
            // 서브탭 콘텐츠 (AN-09: CrossFade 전환)
            // DailyScheduleView 내부 타임라인은 자체 ConstrainedBox+SingleChildScrollView를 가진다.
            // TodoListView는 자체 SingleChildScrollView를 사용한다.
            Expanded(
              child: AnimatedSwitcher(
                duration: AppAnimation.medium,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: switch (subTab) {
                  TodoSubTab.dailySchedule => const DailyScheduleView(key: ValueKey('daily')),
                  TodoSubTab.weeklyRoutine => const RoutineWeeklyView(key: ValueKey('weekly-routine')),
                  TodoSubTab.todoList => const TodoListView(key: ValueKey('list')),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
