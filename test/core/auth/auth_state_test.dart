// AuthState 단위 테스트
// AuthState 값 객체의 인증 상태 판별, 팩토리 생성자를 검증한다.
// 외부 의존성 없이 순수 로직만 테스트한다.
import 'package:design_your_life/core/auth/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthState', () {
    test('userId가 있으면 인증된 상태이다', () {
      const state = AuthState(
        userId: 'user-123',
        displayName: '테스트 유저',
        email: 'test@example.com',
      );
      expect(state.isAuthenticated, true);
    });

    test('userId가 null이면 미인증 상태이다', () {
      const state = AuthState();
      expect(state.isAuthenticated, false);
    });

    test('unauthenticated 팩토리가 모든 필드를 null로 설정한다', () {
      const state = AuthState.unauthenticated();
      expect(state.userId, isNull);
      expect(state.displayName, isNull);
      expect(state.email, isNull);
      expect(state.photoUrl, isNull);
      expect(state.isAuthenticated, false);
    });

    test('photoUrl은 선택 필드이다', () {
      const withPhoto = AuthState(
        userId: 'user-1',
        photoUrl: 'https://example.com/photo.jpg',
      );
      expect(withPhoto.photoUrl, isNotNull);

      const withoutPhoto = AuthState(userId: 'user-1');
      expect(withoutPhoto.photoUrl, isNull);
      expect(withoutPhoto.isAuthenticated, true);
    });

    test('toString이 userId와 인증 상태를 포함한다', () {
      const state = AuthState(userId: 'user-123');
      final str = state.toString();
      expect(str, contains('user-123'));
      expect(str, contains('true'));
    });

    test('미인증 상태의 toString이 null과 false를 포함한다', () {
      const state = AuthState.unauthenticated();
      final str = state.toString();
      expect(str, contains('null'));
      expect(str, contains('false'));
    });
  });
}
