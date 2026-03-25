// F3 유틸: TodoDialogLauncher - 투두 다이얼로그 실행 헬퍼
// 투두 생성/수정 다이얼로그를 표시하는 static 메서드를 제공한다.
// todo_create_dialog.dart에서 분리된 헬퍼 클래스이다.
import 'package:flutter/material.dart';

import '../../../../core/nlp/parsed_todo.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../shared/models/todo.dart';
import 'todo_create_dialog.dart';

/// 투두 다이얼로그 실행 헬퍼
/// AN-06: Scale(0.9->1) + Fade 250ms easeOutCubic 공통 전환 애니메이션을 적용한다
class TodoDialogLauncher {
  TodoDialogLauncher._();

  /// 생성 모드: 다이얼로그를 열고 결과를 반환한다
  /// [prefill]: 자연어 파싱 결과로 필드를 자동 채울 때 사용한다 (F20)
  /// [initialDate]: 기본 선택 날짜 (P1-16)
  static Future<TodoCreateResult?> show(
    BuildContext context, {
    ParsedTodo? prefill,
    DateTime? initialDate,
  }) {
    return _showDialog(
      context,
      TodoCreateDialog(prefill: prefill, initialDate: initialDate),
    );
  }

  /// 수정 모드: 기존 투두 데이터로 다이얼로그를 열고 결과를 반환한다
  static Future<TodoCreateResult?> showEdit(
    BuildContext context, {
    required Todo existingTodo,
  }) {
    return _showDialog(
      context,
      TodoCreateDialog(existingTodo: existingTodo),
    );
  }

  /// 공통 다이얼로그 표시 로직 (AN-06 전환 애니메이션 포함)
  static Future<TodoCreateResult?> _showDialog(
    BuildContext context,
    Widget dialog,
  ) {
    return showGeneralDialog<TodoCreateResult>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '닫기',
      barrierColor: ColorTokens.barrierBase.withValues(alpha: 0.4),
      transitionDuration: AppAnimation.standard,
      pageBuilder: (_, __, ___) => dialog,
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: AppLayout.dialogScaleStart, end: 1.0)
              .animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }
}
