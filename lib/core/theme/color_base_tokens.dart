// C0.5-A: 기본 컬러 디자인 토큰
// MAIN/SUB 2색 시스템, Tinted Grey 팔레트, 그라디언트, 시맨틱 컬러를 정의한다.
// 순수 무채색(S=0%) 사용을 금지하고 MAIN Hue가 미세하게 섞인 Tinted Grey를 사용한다.
import 'package:flutter/material.dart';

/// 앱 기본 컬러 토큰 (메인/서브, Tinted Grey, 그라디언트, 시맨틱)
/// color-system.md의 정의를 Flutter Color 객체로 구현한다
/// 하드코딩 금지: 반드시 이 클래스를 통해 참조한다
abstract class ColorBaseTokens {
  // ─── MAIN + SUB 2색 시스템 ───────────────────────────────────────────────
  /// 메인 컬러: Apple Blue (#007AFF)
  /// 용도: CTA 버튼, 주요 하이라이트, 활성 상태, 링크, 포커스 링
  static const Color main = Color(0xFF007AFF);

  /// 메인 호버 상태: 밝기 10% 감소
  static const Color mainHover = Color(0xFF006ADD);

  /// 메인 Pressed 상태: 밝기 20% 감소
  static const Color mainPressed = Color(0xFF005ABB);

  /// 메인 다크 모드 밝은 변형 (링크, 뱃지 텍스트용)
  static const Color mainLight = Color(0xFF5AC8FA);

  /// 서브 컬러: Apple Light Gray (#F2F2F7)
  /// 용도: 페이지 배경, 카드 배경, 보조 보더, 뱃지 배경
  static const Color sub = Color(0xFFF2F2F7);

  /// 서브 라이트 틴트 (배경 틴트용)
  static const Color subLight = Color(0xFFF9F9FB);

  /// 서브 호버 상태
  static const Color subHover = Color(0xFFE5E5EA);

  // ─── Tinted Grey 팔레트 (MAIN Hue: 225, Apple 시스템 그레이 기반) ───────────
  /// Gray 50: 가장 밝은 배경 — Apple systemBackground에 가까운 쿨 화이트
  static const Color gray50 = Color(0xFFF8F8FA);

  /// Gray 100: 카드 배경, 섹션 구분 — Apple systemGray6 기반
  static const Color gray100 = Color(0xFFF2F2F6);

  /// Gray 200: 보더, 디바이더 — Apple systemGray5 기반
  static const Color gray200 = Color(0xFFE5E5EA);

  /// Gray 300: 비활성 보더, 입력 필드 배경 — Apple systemGray4 기반
  static const Color gray300 = Color(0xFFD1D1D6);

  /// Gray 400: 플레이스홀더 텍스트, 비활성 아이콘 — Apple systemGray2 기반
  static const Color gray400 = Color(0xFFAEAEB2);

  /// Gray 500: 보조 텍스트, 캡션 — Apple systemGray 기반
  static const Color gray500 = Color(0xFF8E8E93);

  /// Gray 600: 본문 보조 텍스트
  static const Color gray600 = Color(0xFF636366);

  /// Gray 700: 본문 텍스트
  static const Color gray700 = Color(0xFF48484A);

  /// Gray 800: 제목 텍스트 — Apple tertiarySystemBackground 다크 기반
  static const Color gray800 = Color(0xFF2C2C2E);

  /// Gray 900: 가장 어두운 텍스트, 다크모드 배경 — Apple secondarySystemBackground 다크 기반
  static const Color gray900 = Color(0xFF1C1C1E);

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
  /// 앱 배경 그라디언트 시작점 (Apple Blue)
  static const Color gradientStart = Color(0xFF007AFF);

  /// 앱 배경 그라디언트 중간점 (딥 블루)
  static const Color gradientMid = Color(0xFF005EC4);

  /// 앱 배경 그라디언트 끝점 (라이트 블루)
  static const Color gradientEnd = Color(0xFF5AC8FA);

  // ─── Refined Glass 라이트 배경 그라디언트 ───────────────────────────────
  /// 쿨 화이트 시작점 (Apple 스타일 절제된 톤)
  static const Color refinedGradientStart = Color(0xFFF5F5FA);
  /// 쿨 라이트 그레이 중간점
  static const Color refinedGradientMid = Color(0xFFF0F0F6);
  /// 쿨 화이트 끝점
  static const Color refinedGradientEnd = Color(0xFFF8F8FC);

  // ─── 다크 모드 그라디언트 ─────────────────────────────────────────────────
  /// 다크 모드 배경 그라디언트 시작점 (Apple 다크 #1C1C1E)
  static const Color darkGradientStart = Color(0xFF1C1C1E);

  /// 다크 모드 배경 그라디언트 중간점
  static const Color darkGradientMid = Color(0xFF141416);

  /// 다크 모드 배경 그라디언트 끝점 (Apple 니어 블랙)
  static const Color darkGradientEnd = Color(0xFF0D0D0F);

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
}
