// C0.5: 테마 프리셋 열거형
// 3가지 시각적 테마 스타일을 정의한다.
// Hive settingsBox에 name 문자열로 저장/복원한다.

/// 앱 테마 프리셋 유형
/// 시각적 처리 방식(배경, 카드, 블러)만 다르며 ColorTokens의 MAIN/SUB는 변경하지 않는다
enum ThemePreset {
  /// 기본 테마: Refined Glass (밝은 배경 + 미묘한 글라스 효과)
  refinedGlass,

  /// 깔끔함 테마: Clean Minimal (밝은 단색 배경 + 블러 없음)
  cleanMinimal,

  /// 다크 테마: Dark Glass (어두운 배경 + 글라스 효과 유지)
  darkGlass,
}
