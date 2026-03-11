// ThemePreset enum 단위 테스트
// enum 값 존재 여부, name 문자열 직렬화/역직렬화, 기본값 동작을 검증한다.
import 'package:design_your_life/core/theme/theme_preset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemePreset enum', () {
    test('6가지 프리셋 값이 모두 존재한다', () {
      // 각 프리셋이 올바르게 정의되어 있는지 확인한다
      expect(ThemePreset.values.length, 6);
      expect(ThemePreset.values, contains(ThemePreset.glassmorphism));
      expect(ThemePreset.values, contains(ThemePreset.minimal));
      expect(ThemePreset.values, contains(ThemePreset.retro));
      expect(ThemePreset.values, contains(ThemePreset.neon));
      expect(ThemePreset.values, contains(ThemePreset.clean));
      expect(ThemePreset.values, contains(ThemePreset.soft));
    });

    test('glassmorphism이 첫 번째 기본값이다', () {
      // 기본값(인덱스 0)이 glassmorphism인지 확인한다
      expect(ThemePreset.values.first, ThemePreset.glassmorphism);
    });

    test('name 문자열 직렬화가 올바르다', () {
      // Hive 저장 시 사용되는 name 문자열을 검증한다
      expect(ThemePreset.glassmorphism.name, 'glassmorphism');
      expect(ThemePreset.minimal.name, 'minimal');
      expect(ThemePreset.retro.name, 'retro');
      expect(ThemePreset.neon.name, 'neon');
    });

    test('name 문자열로 역직렬화(복원)가 올바르다', () {
      // Hive에서 읽은 문자열로 enum 값을 복원하는 로직을 검증한다
      final restored = ThemePreset.values.firstWhere(
        (e) => e.name == 'minimal',
        orElse: () => ThemePreset.glassmorphism,
      );
      expect(restored, ThemePreset.minimal);
    });

    test('알 수 없는 name 문자열이면 glassmorphism으로 폴백한다', () {
      // 유효하지 않은 Hive 저장값에 대한 폴백 동작을 검증한다
      final fallback = ThemePreset.values.firstWhere(
        (e) => e.name == 'unknown_preset',
        orElse: () => ThemePreset.glassmorphism,
      );
      expect(fallback, ThemePreset.glassmorphism);
    });

    test('각 프리셋 name이 고유하다', () {
      // 중복 name이 없어야 한다 (Hive 직렬화 충돌 방지)
      final names = ThemePreset.values.map((e) => e.name).toList();
      final uniqueNames = names.toSet();
      expect(names.length, uniqueNames.length);
    });
  });
}
