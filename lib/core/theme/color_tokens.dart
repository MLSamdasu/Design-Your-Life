// C0.5: 컬러 디자인 토큰 (배럴 재수출)
// ColorBaseTokens + ColorEventTokens를 통합하여 기존 ColorTokens API를 유지한다.
// 신규 코드에서는 세분화된 클래스를 직접 임포트해도 무방하다.
import 'package:flutter/material.dart';

export 'color_base_tokens.dart';
export 'color_event_tokens.dart';

import 'color_base_tokens.dart';
import 'color_event_tokens.dart';

/// 앱 전체 컬러 토큰 (하위 호환 배럴 클래스)
/// ColorBaseTokens + ColorEventTokens를 하나의 네임스페이스로 통합한다
/// Dart에서 정적 멤버는 상속되지 않으므로 양쪽 모두 명시적으로 위임한다
abstract class ColorTokens {
  // ─── ColorBaseTokens 위임 (MAIN/SUB, Tinted Grey, 그라디언트, 시맨틱) ─────
  static const Color main = ColorBaseTokens.main;
  static const Color mainHover = ColorBaseTokens.mainHover;
  static const Color mainPressed = ColorBaseTokens.mainPressed;
  static const Color mainLight = ColorBaseTokens.mainLight;
  static const Color sub = ColorBaseTokens.sub;
  static const Color subLight = ColorBaseTokens.subLight;
  static const Color subHover = ColorBaseTokens.subHover;

  // Tinted Grey 팔레트
  static const Color gray50 = ColorBaseTokens.gray50;
  static const Color gray100 = ColorBaseTokens.gray100;
  static const Color gray200 = ColorBaseTokens.gray200;
  static const Color gray300 = ColorBaseTokens.gray300;
  static const Color gray400 = ColorBaseTokens.gray400;
  static const Color gray500 = ColorBaseTokens.gray500;
  static const Color gray600 = ColorBaseTokens.gray600;
  static const Color gray700 = ColorBaseTokens.gray700;
  static const Color gray800 = ColorBaseTokens.gray800;
  static const Color gray900 = ColorBaseTokens.gray900;

  // 그림자·배리어·유틸리티
  static const Color shadowBase = ColorBaseTokens.shadowBase;
  static const Color barrierBase = ColorBaseTokens.barrierBase;
  static const Color transparent = ColorBaseTokens.transparent;
  static const Color white = ColorBaseTokens.white;
  static const Color black = ColorBaseTokens.black;

  // 외부 브랜드
  static const Color googleBrand = ColorBaseTokens.googleBrand;

  // Glassmorphism 그라디언트
  static const Color gradientStart = ColorBaseTokens.gradientStart;
  static const Color gradientMid = ColorBaseTokens.gradientMid;
  static const Color gradientEnd = ColorBaseTokens.gradientEnd;

  // Refined Glass 라이트 그라디언트
  static const Color refinedGradientStart = ColorBaseTokens.refinedGradientStart;
  static const Color refinedGradientMid = ColorBaseTokens.refinedGradientMid;
  static const Color refinedGradientEnd = ColorBaseTokens.refinedGradientEnd;

  // 다크 모드 그라디언트
  static const Color darkGradientStart = ColorBaseTokens.darkGradientStart;
  static const Color darkGradientMid = ColorBaseTokens.darkGradientMid;
  static const Color darkGradientEnd = ColorBaseTokens.darkGradientEnd;

  // Semantic 컬러
  static const Color success = ColorBaseTokens.success;
  static const Color successLight = ColorBaseTokens.successLight;
  static const Color successDark = ColorBaseTokens.successDark;
  static const Color warning = ColorBaseTokens.warning;
  static const Color warningLight = ColorBaseTokens.warningLight;
  static const Color warningDark = ColorBaseTokens.warningDark;
  static const Color error = ColorBaseTokens.error;
  static const Color errorLight = ColorBaseTokens.errorLight;
  static const Color errorDark = ColorBaseTokens.errorDark;
  static const Color info = ColorBaseTokens.info;
  static const Color infoLight = ColorBaseTokens.infoLight;
  static const Color infoDark = ColorBaseTokens.infoDark;

  // ─── ColorEventTokens 위임 (캘린더·이벤트·습관) ─────────────────────────
  static const Color todoCard = ColorEventTokens.todoCard;
  static const Color timerSession = ColorEventTokens.timerSession;

  // 이벤트 Light 팔레트
  static const Color eventWork = ColorEventTokens.eventWork;
  static const Color eventPersonal = ColorEventTokens.eventPersonal;
  static const Color eventStudy = ColorEventTokens.eventStudy;
  static const Color eventHealth = ColorEventTokens.eventHealth;
  static const Color eventSocial = ColorEventTokens.eventSocial;
  static const Color eventFinance = ColorEventTokens.eventFinance;
  static const Color eventCreative = ColorEventTokens.eventCreative;
  static const Color eventImportant = ColorEventTokens.eventImportant;
  static const Color eventGoogle = ColorEventTokens.eventGoogle;

  // 이벤트 Dark 팔레트
  static const Color eventWorkDark = ColorEventTokens.eventWorkDark;
  static const Color eventPersonalDark = ColorEventTokens.eventPersonalDark;
  static const Color eventStudyDark = ColorEventTokens.eventStudyDark;
  static const Color eventHealthDark = ColorEventTokens.eventHealthDark;
  static const Color eventSocialDark = ColorEventTokens.eventSocialDark;
  static const Color eventFinanceDark = ColorEventTokens.eventFinanceDark;
  static const Color eventCreativeDark = ColorEventTokens.eventCreativeDark;
  static const Color eventImportantDark = ColorEventTokens.eventImportantDark;

  // 습관 전용 시맨틱 컬러
  static const Color habitCheck = ColorEventTokens.habitCheck;
  static const Color habitProgress = ColorEventTokens.habitProgress;
  static const Color infoHint = ColorEventTokens.infoHint;
  static const Color infoHintBg = ColorEventTokens.infoHintBg;

  // 다크 모드 서피스
  static const Color darkPickerSurface = ColorEventTokens.darkPickerSurface;

  // 테마 프리뷰 전용
  static const Color previewDarkGlassBg = ColorEventTokens.previewDarkGlassBg;
  static const Color previewCleanBorder = ColorEventTokens.previewCleanBorder;
  static const Color previewCleanLine = ColorEventTokens.previewCleanLine;

  // ─── 헬퍼 메서드 위임 ───────────────────────────────────────────────────
  /// colorIndex(0~8)로 이벤트 색상 반환 (Light/Dark 자동 선택)
  static Color eventColor(int index, {bool isDark = false}) =>
      ColorEventTokens.eventColor(index, isDark: isDark);

  /// colorIndex(0~8)로 이벤트 배경 색상 반환 (15% opacity)
  static Color eventBackgroundColor(int index, {bool isDark = false}) =>
      ColorEventTokens.eventBackgroundColor(index, isDark: isDark);
}
