// F-Memo: 저장 버튼 위젯
// 탭 시 즉시 저장 콜백을 호출하고 "저장 완료" 시각 피드백을 표시한다.
// 아이콘이 잠시 체크 표시로 변경된 후 원래 저장 아이콘으로 복원된다.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/theme_colors.dart';

/// 저장 완료 피드백 표시 시간 (ms)
const _kSavedFeedbackMs = 1200;

/// 메모 저장 버튼
/// 탭 시 즉시 저장하고, 아이콘을 체크로 잠시 변경하여 시각 피드백을 준다
class MemoSaveButton extends StatefulWidget {
  /// 즉시 저장 콜백
  final VoidCallback onSave;

  const MemoSaveButton({super.key, required this.onSave});

  @override
  State<MemoSaveButton> createState() => _MemoSaveButtonState();
}

class _MemoSaveButtonState extends State<MemoSaveButton> {
  /// 저장 완료 피드백 표시 중 여부
  bool _showSaved = false;

  /// 피드백 리셋 타이머
  Timer? _feedbackTimer;

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }

  /// 저장 실행 + 시각 피드백 표시
  void _handleSave() {
    widget.onSave();
    setState(() => _showSaved = true);
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(
      const Duration(milliseconds: _kSavedFeedbackMs),
      () {
        if (mounted) setState(() => _showSaved = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tc = context.themeColors;

    return IconButton(
      icon: AnimatedSwitcher(
        duration: AppAnimation.fast,
        child: _showSaved
            ? Icon(
                Icons.check_circle,
                key: const ValueKey('saved'),
                color: ColorTokens.success,
                size: AppLayout.iconXl,
              )
            : Icon(
                Icons.save_rounded,
                key: const ValueKey('save'),
                color: tc.textPrimary,
                size: AppLayout.iconXl,
              ),
      ),
      tooltip: _showSaved ? '저장 완료' : '저장',
      onPressed: _handleSave,
    );
  }
}
