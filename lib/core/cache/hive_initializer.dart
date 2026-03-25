// C0.6: Hive 초기화 배럴 파일
// 암호화 키 관리(hive_encryption_key_manager)와
// Box 등록(hive_box_registry)을 조합하여 Hive 전체 초기화를 수행한다.
//
// 기존 import를 유지하기 위해 HiveInitializer 클래스의 퍼블릭 API를
// 그대로 보존한다 (init, clearAll).
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'hive_box_registry.dart';
import 'hive_encryption_key_manager.dart';

// 배럴 re-export: 하위 모듈을 직접 사용할 수도 있도록 내보낸다
export 'hive_box_registry.dart';
export 'hive_encryption_key_manager.dart';

/// Hive 초기화 모듈 (C0.6)
/// 앱 시작 시 main.dart에서 단 한 번 호출한다
/// AES 256-bit 암호화를 적용하여 로컬 저장 데이터를 보호한다
abstract class HiveInitializer {
  /// Hive를 초기화하고 모든 Box를 오픈한다
  /// 암호화 Box는 AES 256-bit 키로 보호한다
  static Future<void> init() async {
    // Flutter 네이티브 환경 초기화
    debugPrint('[Hive] initFlutter 시작...');
    await Hive.initFlutter();
    debugPrint('[Hive] initFlutter 완료');

    // 암호화 키 획득 또는 생성
    debugPrint('[Hive] 암호화 키 획득 시작...');
    final encryptionKey = await HiveEncryptionKeyManager.getOrCreateKey();
    debugPrint('[Hive] 암호화 키 획득 완료');

    // 암호화 적용 Box (사용자 데이터 보관)
    debugPrint('[Hive] 암호화 Box 오픈 시작...');
    await HiveBoxRegistry.openEncryptedBoxes(encryptionKey);
    debugPrint('[Hive] 암호화 Box 오픈 완료');

    // 비암호화 Box (설정, 메타데이터)
    debugPrint('[Hive] 일반 Box 오픈 시작...');
    await HiveBoxRegistry.openPlainBoxes();
    debugPrint('[Hive] 일반 Box 오픈 완료');
  }

  /// 로그아웃 시 모든 Hive Box를 완전히 삭제한다
  /// HiveBoxRegistry.clearAll()에 위임한다
  static Future<void> clearAll() => HiveBoxRegistry.clearAll();
}
