// Tag 모델 단위 테스트
// fromMap/toMap 왕복 변환, copyWith, 기본값, null 처리를 검증한다.
// maxTagsPerUser, maxTagsPerItem 상수도 검증한다.
// Supabase tags 테이블 대응 — toMap은 name, color_index만 반환 (UPDATE용)
import 'package:design_your_life/shared/models/tag.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('Tag 모델', () {
    late Tag tag;

    setUp(() {
      tag = Tag(
        id: 'tag-1',
        userId: 'user-1',
        name: '업무',
        colorIndex: 0,
        createdAt: testCreatedAt,
      );
    });

    // ─── 상수 검증 ──────────────────────────────────────────────────────────

    test('maxTagsPerUser가 20이다', () {
      expect(Tag.maxTagsPerUser, 20);
    });

    test('maxTagsPerItem이 5이다', () {
      expect(Tag.maxTagsPerItem, 5);
    });

    // ─── 생성 검증 ──────────────────────────────────────────────────────────

    test('모든 필드가 올바르게 설정된다', () {
      expect(tag.id, 'tag-1');
      expect(tag.userId, 'user-1');
      expect(tag.name, '업무');
      expect(tag.colorIndex, 0);
      expect(tag.createdAt, testCreatedAt);
    });

    // ─── toMap 검증 ─────────────────────────────────────────────────────────

    test('toMap이 올바른 snake_case Map을 반환한다', () {
      final map = tag.toMap();
      // toMap은 toUpdateMap 별칭 — name과 color_index만 반환한다
      expect(map['name'], '업무');
      expect(map['color_index'], 0);
    });

    test('toMap에 id, userId, createdAt 필드가 포함되지 않는다', () {
      // toUpdateMap은 수정 가능한 필드만 반환한다
      final map = tag.toMap();
      expect(map.containsKey('id'), isFalse);
      expect(map.containsKey('user_id'), isFalse);
      expect(map.containsKey('userId'), isFalse);
      expect(map.containsKey('created_at'), isFalse);
      expect(map.containsKey('createdAt'), isFalse);
    });

    // ─── fromMap 검증 ────────────────────────────────────────────────────────

    test('fromMap이 올바른 Tag 객체를 생성한다', () {
      final map = <String, dynamic>{
        'user_id': 'user-1',
        'name': '업무',
        'color_index': 2,
        'created_at': testCreatedAt.toIso8601String(),
      };
      final parsed = Tag.fromMap({...map, 'id': 'tag-1'});
      expect(parsed.id, 'tag-1');
      expect(parsed.userId, 'user-1');
      expect(parsed.name, '업무');
      expect(parsed.colorIndex, 2);
      expect(parsed.createdAt, testCreatedAt);
    });

    test('fromMap에서 colorIndex 미포함 시 0으로 폴백한다', () {
      final map = <String, dynamic>{
        'user_id': 'user-1',
        'name': '테스트',
        'created_at': testCreatedAt.toIso8601String(),
      };
      final parsed = Tag.fromMap({...map, 'id': 'tag-2'});
      expect(parsed.colorIndex, 0);
    });

    // ─── 왕복 변환 검증 ──────────────────────────────────────────────────────

    test('fromMap/toMap 왕복 변환이 데이터를 보존한다', () {
      final map = tag.toMap();
      // toMap(=toUpdateMap)에는 user_id, created_at이 없으므로 별도 추가한다
      final restored = Tag.fromMap({
        ...map,
        'id': tag.id,
        'user_id': tag.userId,
        'created_at': testCreatedAt.toIso8601String(),
      });
      expect(restored.id, tag.id);
      expect(restored.userId, tag.userId);
      expect(restored.name, tag.name);
      expect(restored.colorIndex, tag.colorIndex);
    });

    // ─── copyWith 검증 ──────────────────────────────────────────────────────

    test('copyWith가 지정 필드만 변경한 새 인스턴스를 반환한다', () {
      final updated = tag.copyWith(name: '개인', colorIndex: 3);
      expect(updated.name, '개인');
      expect(updated.colorIndex, 3);
      // 변경하지 않은 필드는 원본 값 유지
      expect(updated.id, tag.id);
      expect(updated.userId, tag.userId);
      expect(updated.createdAt, tag.createdAt);
    });

    test('copyWith가 원본 객체를 변경하지 않는다', () {
      tag.copyWith(name: '변경된 이름');
      expect(tag.name, '업무');
    });

    test('copyWith에서 이름만 변경된다', () {
      final updated = tag.copyWith(name: '학습');
      expect(updated.name, '학습');
      expect(updated.colorIndex, tag.colorIndex);
    });

    test('copyWith에서 색상만 변경된다', () {
      final updated = tag.copyWith(colorIndex: 7);
      expect(updated.colorIndex, 7);
      expect(updated.name, tag.name);
    });
  });

  group('Tag 모델 - 경계값 테스트', () {
    test('colorIndex 0이 정상 처리된다', () {
      final tag = Tag(
        id: 'tag-edge-1',
        userId: 'user-1',
        name: '테스트',
        colorIndex: 0,
        createdAt: testCreatedAt,
      );
      expect(tag.colorIndex, 0);
      expect(tag.toMap()['color_index'], 0);
    });

    test('colorIndex 7이 정상 처리된다', () {
      final tag = Tag(
        id: 'tag-edge-2',
        userId: 'user-1',
        name: '테스트',
        colorIndex: 7,
        createdAt: testCreatedAt,
      );
      expect(tag.colorIndex, 7);
    });

    test('이름 20자가 정상 처리된다', () {
      final longName = 'A' * 20;
      final tag = Tag(
        id: 'tag-edge-3',
        userId: 'user-1',
        name: longName,
        colorIndex: 0,
        createdAt: testCreatedAt,
      );
      expect(tag.name.length, 20);
    });

    test('한글 이름이 정상 처리된다', () {
      final tag = Tag(
        id: 'tag-edge-4',
        userId: 'user-1',
        name: '한글태그',
        colorIndex: 0,
        createdAt: testCreatedAt,
      );
      expect(tag.name, '한글태그');
    });
  });
}
