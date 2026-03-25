// 데일리 리추얼: 목표 입력 필드 위젯
// 번호 + 텍스트 입력으로 구성된 한 줄 목표 입력 필드이다.
// 포커스 시 보더 색상이 변경되고, 입력 시 자동 저장된다.

import 'package:flutter/material.dart';

import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';

/// 리추얼 목표 입력 필드
/// [index]: 목표 번호 (1~25)
/// [controller]: 텍스트 입력 컨트롤러
/// [onChanged]: 텍스트 변경 콜백
class RitualGoalField extends StatefulWidget {
  final int index;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const RitualGoalField({
    super.key,
    required this.index,
    required this.controller,
    this.onChanged,
  });

  @override
  State<RitualGoalField> createState() => _RitualGoalFieldState();
}

class _RitualGoalFieldState extends State<RitualGoalField> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tc = context.themeColors;

    return AnimatedContainer(
      duration: AppAnimation.normal,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: tc.overlayLight,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(
          color: _isFocused
              ? tc.accent.withValues(alpha: 0.50)
              : tc.borderLight,
          width: _isFocused
              ? AppLayout.borderMedium
              : AppLayout.borderThin,
        ),
      ),
      child: Row(
        children: [
          // 번호 인디케이터
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text(
              '${widget.index}',
              style: AppTypography.titleMd.copyWith(
                // 어두운 배경에서도 번호가 잘 보이도록 테마 인식 악센트 사용
                color: tc.accent.withValues(alpha: 0.85),
              ),
            ),
          ),
          // 구분선
          Container(
            width: AppLayout.borderThin,
            height: 28,
            color: tc.dividerColor,
          ),
          // 텍스트 입력 영역
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              cursorColor: tc.textPrimary,
              style: AppTypography.bodyLg.copyWith(
                color: tc.textPrimary,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '목표 ${widget.index}번을 입력하세요',
                hintStyle: AppTypography.bodyLg.copyWith(
                  // 힌트 텍스트는 textSecondary로 가독성 확보
                  color: tc.textSecondary,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.lgXl,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
