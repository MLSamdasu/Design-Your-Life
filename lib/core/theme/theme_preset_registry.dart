// C0.5: 테마 프리셋 레지스트리
// enum과 ThemePresetData를 1:1로 매핑하는 정적 팩토리를 제공한다.
// 각 프리셋의 구체적인 데이터는 별도 파일에 분리되어 있다.
import 'theme_preset.dart';
import 'theme_preset_clean_minimal.dart';
import 'theme_preset_dark_glass.dart';
import 'theme_preset_data.dart';
import 'theme_preset_refined_glass.dart';

/// 테마 프리셋 레지스트리
/// enum과 ThemePresetData를 1:1로 매핑하는 정적 팩토리를 제공한다
abstract class ThemePresetRegistry {
  /// 프리셋 enum에 대응하는 ThemePresetData를 반환한다
  static ThemePresetData dataFor(ThemePreset preset) {
    return switch (preset) {
      ThemePreset.refinedGlass => buildRefinedGlass(),
      ThemePreset.cleanMinimal => buildCleanMinimal(),
      ThemePreset.darkGlass => buildDarkGlass(),
    };
  }
}
