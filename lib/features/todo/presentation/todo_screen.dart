// F3: 투두 화면
// 상단 주간 날짜 슬라이더 + "하루 일정표"/"할 일 목록" 서브탭을 포함한다.
// selectedDateProvider로 날짜를 관리하고, TodoOrchestrator(F3.4) 상태를 watch한다.
// F16: TagFilterBar를 서브탭 전환 아래에 배치하여 태그 기반 필터링을 지원한다.
// F20: QuickInputBar를 _TodoHeader 아래에 배치하여 자연어 빠른 투두 입력을 지원한다.
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/nlp/parsed_todo.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../shared/models/todo.dart';
import '../../../shared/widgets/date_slider.dart';
import '../../../shared/widgets/tag_filter_bar.dart';
import '../../../core/auth/auth_provider.dart';
import '../providers/todo_provider.dart';
import 'widgets/daily_schedule_view.dart';
import 'widgets/quick_input_bar.dart';
import 'widgets/todo_create_dialog.dart';
import 'widgets/todo_list_view.dart';
import '../../../core/theme/animation_tokens.dart';
import '../../../core/theme/radius_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/layout_tokens.dart';

/// 자연어 빠른 입력 처리 함수 (F20)
/// 파싱 결과에서 날짜/시간/제목을 추출하여 투두를 즉시 생성한다
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

  final userId = ref.read(currentUserIdProvider);
  if (userId == null) return;

  final generateId = ref.read(generateTodoIdProvider);
  final createTodo = ref.read(createTodoProvider);
  final now = DateTime.now();

  // 파싱된 날짜가 있으면 해당 날짜 사용, 없으면 현재 선택된 날짜를 사용한다
  final todoDate = parsed.hasDate ? parsed.date! : selectedDate;

  try {
    await createTodo(
      Todo(
        id: generateId(),
        title: parsed.title,
        date: todoDate,
        // 파싱된 시간이 있으면 startTime으로 설정한다
        startTime: parsed.hasTime ? parsed.time : null,
        memo: null,
        createdAt: now,
      ),
    );
  } catch (e) {
    // API 호출 실패 시 사용자에게 오류를 알린다
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('할 일 추가에 실패했습니다'),
          backgroundColor: ColorTokens.infoHintBg,
        ),
      );
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
      floatingActionButton: _AddTodoFab(selectedDate: selectedDate),
      // 상단 SafeArea는 MainShell에서 처리하므로 top: false로 중복 적용을 방지한다
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상단 헤더: 년/월 피커 + 날짜 슬라이더
            _TodoHeader(selectedDate: selectedDate),
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
            // 서브탭 전환 (하루 일정표 / 할 일 목록)
            _SubTabSwitcher(currentTab: subTab),
            const SizedBox(height: AppSpacing.lg),
            // 태그 필터 바 (F16: 태그 기반 필터링)
            // 사용자 태그가 있을 때만 표시된다 (TagFilterBar 내부에서 처리)
            const TagFilterBar(),
            const SizedBox(height: AppSpacing.xs),
            // 서브탭 콘텐츠 (AN-09: CrossFade 전환)
            // Expanded 내부이므로 SingleChildScrollView를 제거한다.
            // DailyScheduleView 내부 타임라인은 자체 ConstrainedBox+SingleChildScrollView를 가진다.
            // TodoListView는 자체 SingleChildScrollView를 사용한다.
            Expanded(
              child: AnimatedSwitcher(
                duration: AppAnimation.medium,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: subTab == TodoSubTab.dailySchedule
                    ? const DailyScheduleView(key: ValueKey('daily'))
                    : const TodoListView(key: ValueKey('list')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 투두 화면 상단 헤더
/// 년/월 피커 + 주간 날짜 슬라이더
class _TodoHeader extends ConsumerWidget {
  final DateTime selectedDate;

  const _TodoHeader({required this.selectedDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 년/월 표시 + 피커 버튼
          GestureDetector(
            onTap: () => _showMonthPicker(context, ref),
            child: Row(
              children: [
                Text(
                  '${selectedDate.year}년 ${selectedDate.month}월',
                  style: AppTypography.headingSm.copyWith(
                    color: context.themeColors.textPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: context.themeColors.textPrimaryWithAlpha(0.7),
                  size: AppLayout.iconXl,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // 주간 날짜 슬라이더
          DateSlider(
            selectedDate: selectedDate,
            onDateSelected: (date) {
              ref.read(selectedDateProvider.notifier).state = date;
            },
          ),
        ],
      ),
    );
  }

  /// 년/월 선택 다이얼로그 표시
  Future<void> _showMonthPicker(BuildContext context, WidgetRef ref) async {
    final current = ref.read(selectedDateProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      // 테마 인식 DatePicker: modalDecoration 배경색으로 모든 테마에서 가독성 보장
      builder: (context, child) {
        final dialogBg = context.themeColors.dialogSurface;
        final isOnDark = context.themeColors.textPrimary == Colors.white;
        return Theme(
          data: (isOnDark ? ThemeData.dark() : ThemeData.light()).copyWith(
            colorScheme: (isOnDark
                    ? const ColorScheme.dark(primary: ColorTokens.main)
                    : const ColorScheme.light(primary: ColorTokens.main))
                .copyWith(surface: dialogBg),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      ref.read(selectedDateProvider.notifier).state = picked;
    }
  }
}

/// 서브탭 전환 위젯 (Glass Pill 스타일)
class _SubTabSwitcher extends ConsumerWidget {
  final TodoSubTab currentTab;

  const _SubTabSwitcher({required this.currentTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: context.themeColors.textPrimaryWithAlpha(0.12),
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              border: Border.all(
                color: context.themeColors.textPrimaryWithAlpha(0.15),
              ),
            ),
            child: Row(
              children: TodoSubTab.values.map((tab) {
                final isActive = tab == currentTab;
                final label = tab == TodoSubTab.dailySchedule
                    ? '하루 일정표'
                    : '할 일 목록';
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      ref.read(todoSubTabProvider.notifier).state = tab;
                    },
                    child: AnimatedContainer(
                      duration: AppAnimation.standard,
                      curve: Curves.easeInOutCubic,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.mdLg),
                      decoration: isActive
                          ? BoxDecoration(
                              color: context.themeColors.textPrimaryWithAlpha(0.25),
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                            )
                          : null,
                      child: Center(
                        child: Text(
                          label,
                          style: AppTypography.bodyMd.copyWith(
                            color: isActive
                                ? context.themeColors.textPrimary
                                : context.themeColors.textPrimaryWithAlpha(0.55),
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

/// 새 투두 추가 FAB (Floating Action Button)
/// AN-06: 탭 시 TodoCreateDialog 모달 열기
class _AddTodoFab extends ConsumerWidget {
  final DateTime selectedDate;

  const _AddTodoFab({required this.selectedDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () => _openCreateDialog(context, ref),
      backgroundColor: ColorTokens.main,
      foregroundColor: Colors.white,
      elevation: 0,
      child: const Icon(Icons.add_rounded, size: AppLayout.iconHuge),
    );
  }

  /// 투두 생성 다이얼로그를 열고 결과를 서버에 저장한다
  /// 저장 실패 시 SnackBar로 사용자에게 피드백한다
  Future<void> _openCreateDialog(BuildContext context, WidgetRef ref) async {
    final result = await TodoCreateDialog.show(context);
    if (result == null) return;

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final generateId = ref.read(generateTodoIdProvider);
    final createTodo = ref.read(createTodoProvider);
    final now = DateTime.now();

    try {
      await createTodo(
        Todo(
          id: generateId(),
          title: result.title,
          date: selectedDate,
          // 시작/종료 시간을 모두 설정한다
          startTime: result.startTime,
          endTime: result.endTime,
          memo: result.memo,
          createdAt: now,
        ),
      );
    } catch (e) {
      // API 호출 실패 시 사용자에게 오류를 알린다
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('할 일 추가에 실패했습니다'),
            backgroundColor: ColorTokens.infoHintBg,
          ),
        );
      }
    }
  }
}
