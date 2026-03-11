// F6: 포모도로 타이머 메인 화면
// GoRouter extra로 todoId/todoTitle을 받아 투두와 연결된 상태로 시작할 수 있다.
// Glassmorphism 디자인: GlassCard, ColorTokens 사용
// 타이머 화면은 StatefulShellRoute 바깥의 독립 라우트이다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/theme/theme_colors.dart';
import '../models/timer_log.dart';
import '../models/timer_state.dart';
import '../providers/timer_provider.dart';
import 'widgets/timer_controls.dart';
import 'widgets/timer_display.dart';
import 'widgets/timer_log_list.dart';
import 'widgets/timer_session_info.dart';
import 'widgets/timer_todo_selector.dart';
import '../../../core/theme/radius_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';

/// 포모도로 타이머 메인 화면
/// GoRouter extra: {'todoId': String?, 'todoTitle': String?}
class TimerScreen extends ConsumerStatefulWidget {
  /// 연결할 투두 ID (GoRouter extra로 전달)
  final String? todoId;

  /// 연결할 투두 제목 (GoRouter extra로 전달)
  final String? todoTitle;

  const TimerScreen({
    this.todoId,
    this.todoTitle,
    super.key,
  });

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  @override
  void initState() {
    super.initState();
    // 투두가 전달된 경우 타이머 시작 전 미리 연결한다
    if (widget.todoId != null && widget.todoTitle != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(timerStateProvider.notifier).linkTodo(
                todoId: widget.todoId!,
                todoTitle: widget.todoTitle!,
              );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerStateProvider);

    return Scaffold(
      // 배경을 투명으로 설정하여 앱 그라디언트 배경이 보이게 한다
      backgroundColor: ColorTokens.transparent,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, timerState),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),

              // 세션 정보 (집중/휴식 유형 + 회차)
              Center(
                child: TimerSessionInfo(timerState: timerState),
              ),

              const SizedBox(height: AppSpacing.huge),

              // 원형 타이머 디스플레이
              Center(
                child: TimerDisplay(timerState: timerState),
              ),

              const SizedBox(height: AppSpacing.huge),

              // 세션 완료 축하 메시지 (completed 상태에서만 표시)
              if (timerState.phase == TimerPhase.completed) ...[
                _buildCompletedBanner(timerState),
                const SizedBox(height: AppSpacing.xxl),
              ],

              // 타이머 컨트롤 버튼
              TimerControls(
                onSelectTodo: () => TimerTodoSelector.show(context),
              ),

              const SizedBox(height: 28),

              // 오늘의 타이머 기록 목록
              const TimerLogList(),

              // 하단 여백
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  /// 앱바 구성 (뒤로가기 + 제목)
  PreferredSizeWidget _buildAppBar(BuildContext context, TimerState timerState) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      // 커스텀 뒤로가기: 타이머 실행 중이면 경고 다이얼로그 표시
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: context.themeColors.textPrimary),
        onPressed: () => _handleBack(context, timerState),
      ),
      title: Text(
        '포모도로 타이머',
        style: AppTypography.titleLg.copyWith(color: context.themeColors.textPrimary),
      ),
      centerTitle: true,
      // 오늘 총 집중 시간 표시
      actions: [
        _buildFocusMinutesBadge(),
        const SizedBox(width: AppSpacing.md),
      ],
    );
  }

  /// 오늘 총 집중 시간 뱃지 (AppBar 우측)
  Widget _buildFocusMinutesBadge() {
    final minutes = ref.watch(todayFocusMinutesProvider);
    if (minutes == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mdLg, vertical: AppSpacing.xs),
      // 집중 시간 배지: 배경 테마에 맞는 악센트 색상으로 표시한다
      decoration: BoxDecoration(
        color: context.themeColors.accentWithAlpha(0.25),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: context.themeColors.accentWithAlpha(0.40),
        ),
      ),
      child: Text(
        '$minutes분',
        style: AppTypography.captionLg.copyWith(
          color: context.themeColors.accent,
        ),
      ),
    );
  }

  /// 세션 완료 축하 배너
  Widget _buildCompletedBanner(TimerState state) {
    final isFocus = state.sessionType == TimerSessionType.focus;
    final message = isFocus ? '집중 완료! 수고했어요 🎉' : '휴식 완료! 다시 시작할까요?';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.lg),
      // 세션 완료 배너: 집중 완료 시 배경 테마 악센트 색상, 휴식 완료 시 성공 색상을 사용한다
      decoration: BoxDecoration(
        color: isFocus
            ? context.themeColors.accentWithAlpha(0.20)
            : ColorTokens.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: isFocus
              ? context.themeColors.accentWithAlpha(0.30)
              : ColorTokens.success.withValues(alpha: 0.30),
        ),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTypography.bodyMd.copyWith(
                    color: context.themeColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// 뒤로가기 처리
  /// 타이머 실행 중이면 확인 다이얼로그를 표시한다
  Future<void> _handleBack(BuildContext context, TimerState timerState) async {
    if (timerState.phase == TimerPhase.running) {
      // 실행 중 뒤로가기 시 일시정지 후 확인 요청
      ref.read(timerStateProvider.notifier).pause();
      final confirmed = await _showLeaveConfirmDialog(context);
      // async 갭 이후 위젯이 언마운트되면 조기 반환한다
      if (!mounted) return;
      if (confirmed == true) {
        ref.read(timerStateProvider.notifier).reset();
        _navigateBack();
      } else {
        // 취소 시 타이머 재개
        ref.read(timerStateProvider.notifier).resume();
      }
    } else {
      _navigateBack();
    }
  }

  /// mounted 상태가 보장된 컨텍스트에서 뒤로가기를 수행한다
  void _navigateBack() {
    if (mounted) {
      // context.pop()을 동기 메서드로 분리하여 async 갭 문제를 해결한다
      context.pop();
    }
  }

  /// 타이머 실행 중 나가기 확인 다이얼로그
  Future<bool?> _showLeaveConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      // 테마 인식 다이얼로그 배경: 모든 테마에서 텍스트 가독성 보장
      builder: (ctx) => AlertDialog(
        backgroundColor: context.themeColors.dialogSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.huge)),
        title: Text(
          '타이머를 종료할까요?',
          style: AppTypography.titleLg.copyWith(color: context.themeColors.textPrimary),
        ),
        content: Text(
          '현재 세션이 취소되며 기록이 저장되지 않아요.',
          style: AppTypography.bodyLg.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              '계속 집중',
              style: AppTypography.bodyMd.copyWith(
                color: context.themeColors.accent,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              '나가기',
              style: AppTypography.bodyMd.copyWith(
                color: ColorTokens.errorLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
