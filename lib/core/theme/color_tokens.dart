// C0.5: 컬러 디자인 토큰
// Tinted Grey 팔레트 (Gray 50~900)와 MAIN/SUB 2색 시스템을 정의한다.
// 순수 무채색(S=0%) 사용을 금지하고 MAIN Hue가 미세하게 섞인 Tinted Grey를 사용한다.
import 'package:flutter/material.dart';

/// 앱 전체 컬러 토큰
/// color-system.md의 정의를 Flutter Color 객체로 구현한다
/// 하드코딩 금지: 반드시 이 클래스를 통해 참조한다
abstract class ColorTokens {
  // ─── MAIN + SUB 2색 시스템 ───────────────────────────────────────────────
  /// 메인 컬러: Violet (#7C3AED)
  /// 용도: CTA 버튼, 주요 하이라이트, 활성 상태, 링크, 포커스 링
  static const Color main = Color(0xFF7C3AED);

  /// 메인 호버 상태: 밝기 10% 감소
  static const Color mainHover = Color(0xFF6A2DD3);

  /// 메인 Pressed 상태: 밝기 20% 감소
  static const Color mainPressed = Color(0xFF5B24BA);

  /// 메인 다크 모드 밝은 변형 (링크, 뱃지 텍스트용)
  static const Color mainLight = Color(0xFFA78BFA);

  /// 서브 컬러: Light Violet (#EDE9FE)
  /// 용도: 페이지 배경, 카드 배경, 보조 보더, 뱃지 배경
  static const Color sub = Color(0xFFEDE9FE);

  /// 서브 라이트 틴트 (배경 틴트용)
  static const Color subLight = Color(0xFFFDFCFE);

  /// 서브 호버 상태
  static const Color subHover = Color(0xFFDDD8F1);

  // ─── Tinted Grey 팔레트 (MAIN Hue: 263, 순수 무채색 금지) ─────────────────
  /// Gray 50: B=98.5%, S=1.5% - 가장 밝은 배경, 페이지 배경
  static const Color gray50 = Color(0xFFF8F7FB);

  /// Gray 100: B=96%, S=2% - 카드 배경, 섹션 구분
  static const Color gray100 = Color(0xFFF1EFF4);

  /// Gray 200: B=91.5%, S=2.5% - 보더, 디바이더
  static const Color gray200 = Color(0xFFE5E3E9);

  /// Gray 300: B=86.5%, S=2.5% - 비활성 보더, 입력 필드 배경
  static const Color gray300 = Color(0xFFD9D7DC);

  /// Gray 400: B=65%, S=4% - 플레이스홀더 텍스트, 비활성 아이콘
  static const Color gray400 = Color(0xFFA19FA5);

  /// Gray 500: B=50%, S=5% - 보조 텍스트, 캡션
  static const Color gray500 = Color(0xFF7B797F);

  /// Gray 600: B=38%, S=5.5% - 본문 보조 텍스트
  static const Color gray600 = Color(0xFF5D5B60);

  /// Gray 700: B=30%, S=7% - 본문 텍스트
  static const Color gray700 = Color(0xFF49474C);

  /// Gray 800: B=18%, S=8% - 제목 텍스트
  static const Color gray800 = Color(0xFF2B2A2D);

  /// Gray 900: B=12%, S=10% - 가장 어두운 텍스트, 다크모드 배경
  static const Color gray900 = Color(0xFF1C1B1E);

  // ─── 그림자·배리어 시맨틱 토큰 ──────────────────────────────────────────
  /// 그림자 베이스 색상: gray900 기반 (순수 #000000 대신 Tinted Grey 사용)
  static const Color shadowBase = gray900;

  /// 다이얼로그 배리어 색상: gray900 기반
  static const Color barrierBase = gray900;

  /// 투명 색상 토큰
  static const Color transparent = Color(0x00000000);

  /// 순수 흰색 토큰 (Glass 오버레이, CTA 전경색 등)
  static const Color white = Color(0xFFFFFFFF);

  /// 순수 검정색 토큰 (오버레이 그라디언트 등)
  static const Color black = Color(0xFF000000);

  // ─── 외부 브랜드 컬러 ───────────────────────────────────────────────────
  /// Google 브랜드 블루
  /// Google 로그인 버튼, Google Calendar 뱃지 등 Google 관련 UI에 사용한다
  static const Color googleBrand = Color(0xFF4285F4);

  // ─── Glassmorphism 그라디언트 ────────────────────────────────────────────
  /// 앱 배경 그라디언트 시작점
  static const Color gradientStart = Color(0xFF667EEA);

  /// 앱 배경 그라디언트 중간점
  static const Color gradientMid = Color(0xFF764BA2);

  /// 앱 배경 그라디언트 끝점
  static const Color gradientEnd = Color(0xFFF093FB);

  // ─── Refined Glass 라이트 배경 그라디언트 ───────────────────────────────
  /// 밝은 라벤더 시작점
  static const Color refinedGradientStart = Color(0xFFF5F3FF);
  /// sub 색상과 동일한 중간점
  static const Color refinedGradientMid = Color(0xFFEDE9FE);
  /// 밝은 핑크 라벤더 끝점
  static const Color refinedGradientEnd = Color(0xFFFDF4FF);

  // ─── 다크 모드 그라디언트 ─────────────────────────────────────────────────
  /// 다크 모드 배경 그라디언트 시작점
  static const Color darkGradientStart = Color(0xFF2D3561);

  /// 다크 모드 배경 그라디언트 중간점
  static const Color darkGradientMid = Color(0xFF3B1F5C);

  /// 다크 모드 배경 그라디언트 끝점
  static const Color darkGradientEnd = Color(0xFF5C2E6B);

  // ─── Semantic 컬러 ────────────────────────────────────────────────────────
  /// Success (성공)
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFF4ADE80);
  static const Color successDark = Color(0xFF16A34A);

  /// Warning (경고)
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color warningDark = Color(0xFFD97706);

  /// Error (오류)
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  static const Color errorDark = Color(0xFFDC2626);

  /// Info (정보)
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF60A5FA);
  static const Color infoDark = Color(0xFF2563EB);

  // ─── 이벤트 색상 팔레트 (8색, Light Mode) ────────────────────────────────
  /// 업무/회의 (index: 0)
  static const Color eventWork = Color(0xFF7C3AED);

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
  static const Color eventGoogle = googleBrand;

  // ─── 이벤트 색상 팔레트 (8색, Dark Mode) ────────────────────────────────
  static const Color eventWorkDark = Color(0xFFA78BFA);
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
  /// gradientMid와 유사한 딥 퍼플 (#2D1F4E)
  static const Color darkPickerSurface = Color(0xFF2D1F4E);

  // ─── 테마 프리뷰 전용 색상 ──────────────────────────────────────────────
  /// 다크 글라스 테마 프리뷰 카드 배경 (딥 다크 퍼플)
  static const Color previewDarkGlassBg = Color(0xFF1A1130);

  /// 클린 테마 프리뷰 카드 보더 (라이트 블루 그레이)
  static const Color previewCleanBorder = Color(0xFFE8ECF0);

  /// 클린 테마 프리뷰 텍스트 줄 색상 (딥 네이비)
  static const Color previewCleanLine = Color(0xFF1A1A2E);

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
