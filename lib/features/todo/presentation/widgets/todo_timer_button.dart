// F3 위젯: TodoTimerButton - 포모도로 타이머 연결 버튼
// 해당 투두를 연결한 상태로 타이머 화면으로 이동한다
// 원형 테두리 + 아이콘으로 직관적인 타이머 시작 버튼을 제공한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../timer/providers/timer_provider.dart';

/// 포모도로 타이머 연결 버튼 위젯
/// 탭 시 해당 투두를 타이머에 연결하고 타이머 탭으로 전환한다
class TodoTimerButton extends StatelessWidget {
  final String todoId;
  final String todoTitle;

  const TodoTimerButton({
    required this.todoId,
    required this.todoTitle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // 타이머에 투두를 연결한 뒤 타이머 탭으로 전환한다
        final container = ProviderScope.containerOf(context);
        container.read(timerStateProvider.notifier).linkTodo(
              todoId: todoId,
              todoTitle: todoTitle,
            );
        context.go(RoutePaths.timer);
      },
      child: SizedBox(
        width: AppLayout.minTouchTarget,
        height: AppLayout.minTouchTarget,
        child: Center(
          child: Container(
            width: AppLayout.containerMd,
            height: AppLayout.containerMd,
            decoration: BoxDecoration(
              // 포모도로 아이콘 배경: 악센트 색상 힌트로 직관성 향상
              color: context.themeColors.accentWithAlpha(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: context.themeColors.accentWithAlpha(0.35),
              ),
            ),
            child: Icon(
              Icons.timer_rounded,
              // WCAG 대비: accent 배경 위에서 테마 색상으로 고대비 확보
              color: context.themeColors.textPrimaryWithAlpha(0.8),
              size: AppLayout.iconSm,
            ),
          ),
        ),
      ),
    );
  }
}
