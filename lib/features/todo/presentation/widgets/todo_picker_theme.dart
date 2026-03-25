// F3 유틸: buildTodoPickerTheme - 테마 인식 피커 빌더
// TimePicker/DatePicker 다이얼로그에 테마 인식 배경색을 적용한다.
// 어두운 배경 테마(Glassmorphism/Neon)에서도 가독성을 보장한다.
// todo_create_dialog.dart에서 분리된 헬퍼 함수이다.
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_colors.dart';

/// TimePicker/DatePicker에 테마 인식 배경색을 적용하는 빌더
/// 어두운 배경 테마(Glassmorphism/Neon)에서도 가독성을 보장한다
Widget buildTodoPickerTheme(BuildContext context, Widget? child) {
  final dialogBg = context.themeColors.dialogSurface;
  final isOnDark = context.themeColors.isOnDarkBackground;
  return Theme(
    data: (isOnDark ? ThemeData.dark() : ThemeData.light()).copyWith(
      colorScheme: (isOnDark
              ? const ColorScheme.dark(primary: ColorTokens.main)
              : const ColorScheme.light(primary: ColorTokens.main))
          .copyWith(surface: dialogBg),
    ),
    child: MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
      child: child!,
    ),
  );
}
