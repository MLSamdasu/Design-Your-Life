// C0.5: 타이포그래피 디자인 토큰
// Google Fonts 기반 폰트 패밀리, 크기, 행간, 자간을 중앙 집중 관리한다.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 앱 타이포그래피 토큰
/// design-system.md의 타이포그래피 스케일을 Flutter TextStyle로 구현한다
/// Pretendard 폰트 우선, Noto Sans KR Fallback 사용
abstract class AppTypography {
  // ─── 폰트 패밀리 ────────────────────────────────────────────────────────
  /// Pretendard 폰트 (한글 가독성 최적화, CanvasKit WASM 렌더러 대응)
  /// Flutter Web + CanvasKit에서 가장 안정적인 한글 폰트로 Noto Sans KR 사용
  static TextStyle get _base => GoogleFonts.notoSansKr();

  /// 폰트 패밀리 이름
  static String get fontFamily => GoogleFonts.notoSansKr().fontFamily ?? 'Noto Sans KR';

  // ─── 타이포그래피 스케일 ─────────────────────────────────────────────────

  /// 디스플레이 Large (34px, ExtraBold)
  /// 용도: 스플래시 타이틀, 만다라트 핵심 목표
  static TextStyle get displayLg => _base.copyWith(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.8,
      );

  /// 디스플레이 Medium (28px, ExtraBold)
  /// 용도: D-day 숫자, 통계 수치
  static TextStyle get displayMd => _base.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.5,
      );

  /// 헤딩 Large (26px, Bold)
  /// 용도: 인사 메시지 (이름)
  static TextStyle get headingLg => _base.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.5,
      );

  /// 헤딩 Medium (22px, ExtraBold)
  /// 용도: 도넛차트 퍼센트
  static TextStyle get headingMd => _base.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        height: 1.3,
        letterSpacing: -0.3,
      );

  /// 헤딩 Small (18px, Bold)
  /// 용도: 섹션 제목
  static TextStyle get headingSm => _base.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.2,
      );

  /// 타이틀 Large (16px, Bold)
  /// 용도: 카드 타이틀
  static TextStyle get titleLg => _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.4,
        letterSpacing: 0,
      );

  /// 타이틀 Medium (15px, SemiBold)
  /// 용도: 모달 타이틀, 서브 헤딩
  static TextStyle get titleMd => _base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0,
      );

  /// 본문 Large (14px, Regular)
  /// 용도: 기본 본문, 체크리스트 항목
  static TextStyle get bodyLg => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0,
      );

  /// 본문 Medium (13px, Medium)
  /// 용도: D-day 타이틀, 습관 이름
  static TextStyle get bodyMd => _base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.5,
        letterSpacing: 0,
      );

  /// 본문 Small (13px, Regular)
  /// 용도: 보조 본문
  static TextStyle get bodySm => _base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0,
      );

  /// 캡션 Large (12px, SemiBold)
  /// 용도: 뱃지 텍스트, 네비게이션 라벨
  static TextStyle get captionLg => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0,
      );

  /// 캡션 Medium (11px, Regular)
  /// 용도: 습관 상태, D-day 날짜, 타임스탬프
  static TextStyle get captionMd => _base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 1.4,
        letterSpacing: 0,
      );

  /// 캡션 Small (10px, Regular)
  /// 용도: 도넛차트 레이블, 미니 주석
  static TextStyle get captionSm => _base.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        height: 1.4,
        letterSpacing: 0,
      );

  /// 오버라인 (13px, SemiBold, 대문자)
  /// 용도: 섹션 분류 레이블
  static TextStyle get overline => _base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 1.0,
      );

  // ─── 이모지 전용 사이즈 토큰 ─────────────────────────────────────────────

  /// 이모지 Large (22px)
  /// 용도: 습관 카드 이모지 아이콘, 프리셋 시트 이모지
  static TextStyle get emojiLg => _base.copyWith(
        fontSize: 22,
        height: 1.0,
      );

  /// 이모지 Medium (20px)
  /// 용도: HabitPill 이모지 아이콘
  static TextStyle get emojiMd => _base.copyWith(
        fontSize: 20,
        height: 1.0,
      );

  /// 이모지 Small (14px)
  /// 용도: 캘린더 섹션 내 작은 이모지 레이블
  static TextStyle get emojiSm => _base.copyWith(
        fontSize: 14,
        height: 1.0,
      );

  /// 캡션 이모지 (10px, Regular)
  /// 용도: habit_pill 스트릭 배지 내 이모지 아이콘
  static TextStyle get captionEmoji => _base.copyWith(
        fontSize: 10,
        height: 1.0,
      );

  // ─── 폰트 웨이트 시맨틱 토큰 ───────────────────────────────────────────
  /// 레귤러 웨이트 (비선택 상태, 일반 텍스트)
  static const FontWeight weightRegular = FontWeight.w400;

  /// 미디엄 웨이트 (본문 강조)
  static const FontWeight weightMedium = FontWeight.w500;

  /// 세미볼드 웨이트 (서브 타이틀)
  static const FontWeight weightSemiBold = FontWeight.w600;

  /// 볼드 웨이트 (선택된 상태, 제목)
  static const FontWeight weightBold = FontWeight.w700;

  /// 엑스트라볼드 웨이트 (강조 수치, 디스플레이)
  static const FontWeight weightExtraBold = FontWeight.w800;
}
