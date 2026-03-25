// C0.5-B: 이벤트·캘린더·습관 전용 컬러 토큰
// 캘린더 카드, 이벤트 색상 팔레트(Light/Dark), 습관 시맨틱 컬러, 테마 프리뷰 색상을 정의한다.
import 'package:flutter/material.dart';

import 'color_base_tokens.dart';

/// 이벤트·캘린더·습관 전용 컬러 토큰
/// 이벤트 카테고리별 색상, 습관 체크 색상, 테마 프리뷰 색상 등을 포함한다
abstract class ColorEventTokens {
  // ─── 캘린더 카드 시맨틱 컬러 ────────────────────────────────────────────
  /// 투두 카드 색상: 캘린더 뷰에서 투두 아이템 카드 배경/보더에 사용한다
  static const Color todoCard = Color(0xFF0EA5E9);

  /// 타이머 세션 카드 색상: 캘린더 뷰에서 포모도로 완료 세션 카드에 사용한다
  static const Color timerSession = Color(0xFF10B981);

  // ─── 이벤트 색상 팔레트 (8색, Light Mode) ────────────────────────────────
  /// 업무/회의 (index: 0) → Apple Blue
  static const Color eventWork = Color(0xFF007AFF);

  /// 개인 일정 (index: 1)
  static const Color eventPersonal = Color(0xFFEC4899);

  /// 학습/공부 (index: 2)
  static const Color eventStudy = Color(0xFF3B82F6);

  /// 운동/건강 (index: 3)
  static const Color eventHealth = Color(0xFF22C55E);

  /// 약속/모임 (index: 4)
  static const Color eventSocial = Color(0xFFF59E0B);

  /// 재무/금융 (index: 5)
  static const Color eventFinance = Color(0xFF06B6D4);

  /// 창작/취미 (index: 6)
  static const Color eventCreative = Color(0xFFF97316);

  /// 중요/긴급 (index: 7)
  static const Color eventImportant = Color(0xFFEF4444);

  /// Google Calendar 연동 (index: 8) - Google 브랜드 블루
  /// Google 이벤트에만 사용하며, 기존 앱 이벤트(0~7)와 시각적으로 구분된다
  static const Color eventGoogle = ColorBaseTokens.googleBrand;

  // ─── 이벤트 색상 팔레트 (8색, Dark Mode) ────────────────────────────────
  static const Color eventWorkDark = Color(0xFF5AC8FA);
  static const Color eventPersonalDark = Color(0xFFF472B6);
  static const Color eventStudyDark = Color(0xFF60A5FA);
  static const Color eventHealthDark = Color(0xFF4ADE80);
  static const Color eventSocialDark = Color(0xFFFBBF24);
  static const Color eventFinanceDark = Color(0xFF22D3EE);
  static const Color eventCreativeDark = Color(0xFFFB923C);
  static const Color eventImportantDark = Color(0xFFF87171);

  // ─── 습관 전용 시맨틱 컬러 ───────────────────────────────────────────────
  /// 습관 체크 완료 색상: 원형 체크박스 활성 상태 (#4CD964)
  /// 초록 계열, 습관 완료 시각적 피드백용
  static const Color habitCheck = Color(0xFF4CD964);

  /// 습관 진행률 색상: 도넛차트·스탯카드 초록 하이라이트 (#A0F0C0)
  /// habitCheck보다 밝은 민트 그린, 백그라운드 강조용
  static const Color habitProgress = Color(0xFFA0F0C0);

  /// 안내 메시지 색상 (연두색): 오류/안내 텍스트에 사용
  static const Color infoHint = Color(0xFF7FD858);

  /// 안내 메시지 SnackBar 배경색
  static const Color infoHintBg = Color(0xFF4CAF50);

  // ─── 다크 모드 서피스 컬러 ─────────────────────────────────────────────
  /// 다크 모드 DatePicker/TimePicker 서피스 색상
  /// Apple 다크 서피스 (#2C2C2E)
  static const Color darkPickerSurface = Color(0xFF2C2C2E);

  // ─── 테마 프리뷰 전용 색상 ──────────────────────────────────────────────
  /// 다크 글라스 테마 프리뷰 카드 배경 (Apple 다크)
  static const Color previewDarkGlassBg = Color(0xFF1C1C1E);

  /// 클린 테마 프리뷰 카드 보더 (Apple 시스템 그레이)
  static const Color previewCleanBorder = Color(0xFFE5E5EA);

  /// 클린 테마 프리뷰 텍스트 줄 색상 (Apple 다크)
  static const Color previewCleanLine = Color(0xFF2C2C2E);

  // ─── 헬퍼 메서드 ─────────────────────────────────────────────────────────
  /// colorIndex(0~8)로 Light Mode 이벤트 색상 반환
  /// index 8: Google Calendar 이벤트 전용 (Google 브랜드 블루 #4285F4)
  static Color eventColor(int index, {bool isDark = false}) {
    final lightColors = [
      eventWork,       // 0: 업무/회의
      eventPersonal,   // 1: 개인 일정
      eventStudy,      // 2: 학습/공부
      eventHealth,     // 3: 운동/건강
      eventSocial,     // 4: 약속/모임
      eventFinance,    // 5: 재무/금융
      eventCreative,   // 6: 창작/취미
      eventImportant,  // 7: 중요/긴급
      eventGoogle,     // 8: Google Calendar 연동 이벤트 (F17)
    ];
    final darkColors = [
      eventWorkDark,
      eventPersonalDark,
      eventStudyDark,
      eventHealthDark,
      eventSocialDark,
      eventFinanceDark,
      eventCreativeDark,
      eventImportantDark,
      eventGoogle, // 8: Google Blue는 다크 모드에서도 동일 색상 사용
    ];
    // 범위 벗어난 인덱스는 기본 색상(work)으로 처리 (0~8)
    final safeIndex = index.clamp(0, 8);
    return isDark ? darkColors[safeIndex] : lightColors[safeIndex];
  }

  /// colorIndex(0~8)로 이벤트 배경 색상 반환 (15% opacity)
  /// index 8(Google)도 동일하게 처리된다
  static Color eventBackgroundColor(int index, {bool isDark = false}) {
    return eventColor(index, isDark: isDark).withValues(alpha: isDark ? 0.20 : 0.15);
  }
}
