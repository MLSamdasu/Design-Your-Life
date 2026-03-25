// F5 위젯: 체크포인트 추가 다이얼로그
// TextEditingController의 수명주기를 State.dispose에서 관리하여
// 다이얼로그 닫힘 애니메이션 중 "used after disposed" 오류를 방지한다
import 'package:flutter/material.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';

/// 체크포인트 추가 다이얼로그 (StatefulWidget)
/// TextEditingController의 수명주기를 State.dispose에서 관리하여
/// 다이얼로그 닫힘 애니메이션 중 "used after disposed" 오류를 방지한다
class AddCheckpointDialog extends StatefulWidget {
  /// 부모 위젯의 BuildContext — 테마 색상 접근에 사용한다
  final BuildContext parentContext;
  const AddCheckpointDialog({super.key, required this.parentContext});

  @override
  State<AddCheckpointDialog> createState() => _AddCheckpointDialogState();
}

class _AddCheckpointDialogState extends State<AddCheckpointDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    // State.dispose에서 controller를 해제하여 다이얼로그 수명주기와 일치시킨다
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.parentContext.themeColors;
    return AlertDialog(
      backgroundColor: colors.dialogSurface,
      title: Text(
        '체크포인트 추가',
        style: AppTypography.titleMd.copyWith(
          color: colors.textPrimary,
        ),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 200,
        style: AppTypography.bodyMd.copyWith(
          color: colors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: '체크포인트 제목을 입력해주세요',
          hintStyle: AppTypography.bodyMd.copyWith(
            color: colors.textPrimaryWithAlpha(0.4),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            '취소',
            style: AppTypography.bodyMd.copyWith(
              color: colors.textPrimaryWithAlpha(0.7),
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            // pop 전에 텍스트를 캡처하여 controller 접근 타이밍 문제를 방지한다
            final text = _controller.text.trim();
            Navigator.of(context).pop(text);
          },
          child: Text(
            '추가',
            style: AppTypography.bodyMd.copyWith(
              color: colors.accent,
            ),
          ),
        ),
      ],
    );
  }
}
