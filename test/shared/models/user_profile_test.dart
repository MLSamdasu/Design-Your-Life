// UserProfile 모델 단위 테스트
// fromMap/toMap 왕복 변환, schemaVersion 기본값, copyWith를 검증한다.
// Supabase user_profiles 테이블 대응 — toMap은 snake_case
// (display_name, photo_url, is_dark_mode, schema_version)
import 'package:design_your_life/shared/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('UserProfile 모델', () {
    late UserProfile profile;

    setUp(() {
      profile = UserProfile(
        uid: 'uid-123',
        displayName: '홍길동',
        email: 'hong@test.com',
        photoUrl: 'https://example.com/photo.jpg',
        isDarkMode: false,
        schemaVersion: 1,
        createdAt: testCreatedAt,
        updatedAt: testDate,
      );
    });

    test('기본값이 올바르게 설정된다', () {
      final defaultProfile = UserProfile(
        uid: 'uid-456',
        displayName: '테스트',
        email: 'test@test.com',
        createdAt: testCreatedAt,
        updatedAt: testDate,
      );
      expect(defaultProfile.isDarkMode, false);
      expect(defaultProfile.schemaVersion, 1);
      expect(defaultProfile.photoUrl, isNull);
    });

    test('toMap이 올바른 snake_case Map을 반환한다', () {
      final map = profile.toMap();
      // toMap은 toUpdateMap 별칭 — uid 미포함 (UPDATE용)
      expect(map['display_name'], '홍길동');
      expect(map['email'], 'hong@test.com');
      expect(map['photo_url'], 'https://example.com/photo.jpg');
      expect(map['is_dark_mode'], false);
      expect(map['schema_version'], 1);
      // uid는 toUpdateMap에 포함되지 않는다
      expect(map.containsKey('uid'), false);
      expect(map.containsKey('id'), false);
    });

    test('fromMap이 올바른 UserProfile 객체를 생성한다', () {
      final map = <String, dynamic>{
        'display_name': '홍길동',
        'email': 'hong@test.com',
        'photo_url': 'https://example.com/photo.jpg',
        'is_dark_mode': false,
        'schema_version': 1,
        'created_at': testCreatedAt.toIso8601String(),
        'updated_at': testDate.toIso8601String(),
      };
      final parsed = UserProfile.fromMap({...map, 'id': 'uid-123'});
      expect(parsed.uid, 'uid-123');
      expect(parsed.displayName, '홍길동');
      expect(parsed.email, 'hong@test.com');
      expect(parsed.photoUrl, 'https://example.com/photo.jpg');
    });

    test('fromMap에서 uid가 null이면 id 파라미터를 사용한다', () {
      final map = <String, dynamic>{
        'display_name': '홍길동',
        'email': 'hong@test.com',
        'created_at': testCreatedAt.toIso8601String(),
        'updated_at': testDate.toIso8601String(),
      };
      final parsed = UserProfile.fromMap({...map, 'id': 'fallback-id'});
      expect(parsed.uid, 'fallback-id');
    });

    test('fromMap/toMap 왕복 변환이 데이터를 보존한다', () {
      final map = profile.toMap();
      // toMap(=toUpdateMap)에는 id, created_at, updated_at이 없으므로 별도 추가한다
      final restored = UserProfile.fromMap({
        ...map,
        'id': profile.uid,
        'created_at': testCreatedAt.toIso8601String(),
        'updated_at': testDate.toIso8601String(),
      });
      expect(restored.uid, profile.uid);
      expect(restored.displayName, profile.displayName);
      expect(restored.email, profile.email);
      expect(restored.photoUrl, profile.photoUrl);
      expect(restored.isDarkMode, profile.isDarkMode);
      expect(restored.schemaVersion, profile.schemaVersion);
    });

    test('fromMap에서 선택 필드가 null일 때 기본값을 사용한다', () {
      final map = <String, dynamic>{
        'display_name': '테스트',
        'email': 'test@test.com',
        'created_at': testCreatedAt.toIso8601String(),
        'updated_at': testDate.toIso8601String(),
      };
      final parsed = UserProfile.fromMap({...map, 'id': 'uid-x'});
      expect(parsed.isDarkMode, false);
      expect(parsed.schemaVersion, 1);
      expect(parsed.photoUrl, isNull);
    });

    test('schemaVersion 기본값이 1이다', () {
      expect(profile.schemaVersion, 1);
    });

    test('copyWith가 지정 필드만 변경한 새 인스턴스를 반환한다', () {
      final updated = profile.copyWith(
        displayName: '김철수',
        isDarkMode: true,
        schemaVersion: 2,
      );
      expect(updated.displayName, '김철수');
      expect(updated.isDarkMode, true);
      expect(updated.schemaVersion, 2);
      expect(updated.uid, profile.uid);
      expect(updated.email, profile.email);
    });

    test('copyWith가 원본 객체를 변경하지 않는다', () {
      profile.copyWith(displayName: '변경됨');
      expect(profile.displayName, '홍길동');
    });
  });
}
