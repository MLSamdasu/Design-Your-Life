// ThemePresetRegistry 팩토리 단위 테스트
// 모든 프리셋이 유효한 ThemePresetData를 반환하는지 검증한다.
// 배경 그라디언트 색상 수, 블러 설정, 데코레이션 함수 호출 가능 여부를 확인한다.
import 'package:design_your_life/core/theme/theme_preset.dart';
import 'package:design_your_life/core/theme/theme_preset_data.dart';
import 'package:design_your_life/core/theme/theme_preset_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemePresetRegistry', () {
    // 모든 프리셋에 대해 유효한 데이터를 반환해야 한다
    for (final preset in ThemePreset.values) {
      group('${preset.name} 프리셋', () {
        late ThemePresetData data;

        setUp(() {
          // 각 테스트 전에 팩토리 메서드를 호출한다
          data = ThemePresetRegistry.dataFor(preset);
        });

        test('ThemePresetData 인스턴스를 반환한다', () {
          expect(data, isA<ThemePresetData>());
        });

        test('배경 그라디언트(라이트)에 색상이 있다', () {
          // 최소 2개의 색상이 있어야 그라디언트를 표시할 수 있다
          expect(data.backgroundGradient.colors.length, greaterThanOrEqualTo(2));
        });

        test('배경 그라디언트(다크)에 색상이 있다', () {
          expect(data.darkBackgroundGradient.colors.length, greaterThanOrEqualTo(2));
        });

        test('라이트 카드 데코레이션 함수가 호출 가능하다', () {
          // null 없이 정상적으로 BoxDecoration을 반환해야 한다
          expect(() => data.cardDecoration(), returnsNormally);
        });

        test('다크 카드 데코레이션 함수가 호출 가능하다', () {
          expect(() => data.darkCardDecoration(), returnsNormally);
        });

        test('강조 카드 데코레이션 함수가 호출 가능하다', () {
          expect(() => data.elevatedCardDecoration(), returnsNormally);
        });

        test('다크 강조 카드 데코레이션 함수가 호출 가능하다', () {
          expect(() => data.darkElevatedCardDecoration(), returnsNormally);
        });

        test('보조 카드 데코레이션 함수가 호출 가능하다 (기본 radius)', () {
          expect(() => data.subtleCardDecoration(), returnsNormally);
        });

        test('보조 카드 데코레이션 함수가 커스텀 radius로 호출 가능하다', () {
          expect(() => data.subtleCardDecoration(radius: 20), returnsNormally);
        });

        test('모달 데코레이션 함수가 호출 가능하다', () {
          expect(() => data.modalDecoration(), returnsNormally);
        });

        test('Bottom Nav 데코레이션 함수가 호출 가능하다', () {
          expect(() => data.bottomNavDecoration(), returnsNormally);
        });

        test('다크 Bottom Nav 데코레이션 함수가 호출 가능하다', () {
          expect(() => data.darkBottomNavDecoration(), returnsNormally);
        });

        test('blurSigma가 0 이상이다', () {
          // 음수 blurSigma는 허용하지 않는다
          expect(data.blurSigma, greaterThanOrEqualTo(0.0));
        });

        test('useBlur=false이면 blurSigma가 0이다', () {
          // 블러 비활성 프리셋은 blurSigma도 0이어야 한다
          if (!data.useBlur) {
            expect(data.blurSigma, 0.0);
          }
        });

        test('useBlur=true이면 blurSigma가 0보다 크다', () {
          // 블러 활성 프리셋은 양수 blurSigma를 가져야 한다
          if (data.useBlur) {
            expect(data.blurSigma, greaterThan(0.0));
          }
        });

        test('resolveCardDecoration(라이트 모드)가 호출 가능하다', () {
          expect(
            () => data.resolveCardDecoration(isDark: false),
            returnsNormally,
          );
        });

        test('resolveCardDecoration(다크 모드)가 호출 가능하다', () {
          expect(
            () => data.resolveCardDecoration(isDark: true),
            returnsNormally,
          );
        });

        test('텍스트 색상이 null이 아니다', () {
          // 모든 텍스트 색상 속성이 null 없이 정의되어야 한다
          expect(data.textPrimary, isNotNull);
          expect(data.textSecondary, isNotNull);
          expect(data.darkTextPrimary, isNotNull);
          expect(data.darkTextSecondary, isNotNull);
        });
      });
    }

    group('refinedGlass 프리셋 특성', () {
      late ThemePresetData data;

      setUp(() {
        data = ThemePresetRegistry.dataFor(ThemePreset.refinedGlass);
      });

      test('블러가 활성화되어 있다', () {
        // refinedGlass는 미묘한 블러 효과를 사용한다
        expect(data.useBlur, isTrue);
      });

      test('blurSigma가 20.0이다', () {
        // 리치 그라디언트 글라스모피즘을 위한 강한 블러 시그마
        expect(data.blurSigma, 20.0);
      });

      test('배경이 4가지 리치 컬러 그라디언트이다', () {
        // 딥 인디고 → 바이올렛 → 마젠타 → 틸 4색 그라디언트
        expect(data.backgroundGradient.colors.length, 4);
      });
    });

    group('cleanMinimal 프리셋 특성', () {
      late ThemePresetData data;

      setUp(() {
        data = ThemePresetRegistry.dataFor(ThemePreset.cleanMinimal);
      });

      test('블러가 비활성화되어 있다', () {
        // cleanMinimal은 플랫 디자인 원칙에 따라 블러를 사용하지 않는다
        expect(data.useBlur, isFalse);
      });

      test('blurSigma가 0.0이다', () {
        expect(data.blurSigma, 0.0);
      });
    });

    group('darkGlass 프리셋 특성', () {
      late ThemePresetData data;

      setUp(() {
        data = ThemePresetRegistry.dataFor(ThemePreset.darkGlass);
      });

      test('블러가 활성화되어 있다', () {
        // darkGlass는 글라스 효과를 유지한다
        expect(data.useBlur, isTrue);
      });

      test('blurSigma가 16.0이다', () {
        // 다크 글라스 블러 시그마
        expect(data.blurSigma, 16.0);
      });

      test('라이트/다크 배경이 동일하다 (항상 다크)', () {
        // darkGlass는 항상 다크 테마이므로 라이트/다크 배경이 같다
        expect(
          data.backgroundGradient.colors,
          data.darkBackgroundGradient.colors,
        );
      });
    });
  });
}
