// 데일리 리추얼: 오늘의 할 일 개별 입력 필드
// 아이콘 + 텍스트 입력으로 구성된 한 줄 할 일 입력 필드이다.
// 포커스 시 보더 색상이 MAIN 컬러로 전환된다.

import 'package:flutter/material.dart';

import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';

/// 오늘의 할 일 개별 입력 필드 (아이콘 + 텍스트)
/// [icon]: 필드 좌측 아이콘
/// [hint]: 플레이스홀더 텍스트
/// [controller]: 텍스트 입력 컨트롤러
/// [onChanged]: 텍스트 변경 콜백
class DailyThreeField extends StatefulWidget {
  final IconData icon;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const DailyThreeField({
    super.key,
    required this.icon,
    required this.hint,
    required this.controller,
    this.onChanged,
  });

  @override
  State<DailyThreeField> createState() => _DailyThreeFieldState();
}

class _DailyThreeFieldState extends State<DailyThreeField> {
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
      decoration: BoxDecoration(
        color: tc.overlayLight,
        borderRadius: BorderRadius.circular(AppRadius.xl),
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
          // 아이콘 영역
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            child: Icon(
              widget.icon,
              // 어두운 배경에서도 아이콘이 잘 보이도록 테마 인식 악센트 사용
              color: tc.accent.withValues(alpha: 0.85),
              size: AppLayout.iconXl,
            ),
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
                hintText: widget.hint,
                hintStyle: AppTypography.bodyLg.copyWith(
                  // 힌트 텍스트는 textSecondary로 가독성 확보
                  color: tc.textSecondary,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
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
