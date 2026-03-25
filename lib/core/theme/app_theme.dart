// C0.5: ThemeData 정의 (라이트/다크 모드) — 배럴 리-익스포트
// 실제 ThemeData 생성은 app_theme_light.dart / app_theme_dark.dart에 위임한다.
// 출력: ThemeData (라이트/다크 테마)
export 'app_theme_dark.dart';
export 'app_theme_light.dart';

import 'package:flutter/material.dart';

import 'app_theme_dark.dart';
import 'app_theme_light.dart';

/// 앱 테마 팩토리 (C0.5)
/// 라이트/다크 ThemeData를 각 서브모듈에 위임하여 반환한다
abstract class AppTheme {
  /// 라이트 모드 ThemeData
  static ThemeData get light => buildLightTheme();

  /// 다크 모드 ThemeData
  static ThemeData get dark => buildDarkTheme();
}
