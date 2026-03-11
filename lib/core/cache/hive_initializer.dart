// C0.6: Hive 초기화 + Box 등록
// Hive.initFlutter() 호출 후 각 Box를 오픈한다.
// AES 암호화 키를 flutter_secure_storage에서 읽어 Hive Box 암호화에 사용한다.
// 암호화 키가 없으면 새로 생성 후 저장한다 (초회 설치 시).
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// Hive 초기화 모듈 (C0.6)
/// 앱 시작 시 main.dart에서 단 한 번 호출한다
/// AES 256-bit 암호화를 적용하여 로컬 저장 데이터를 보호한다
abstract class HiveInitializer {
  /// flutter_secure_storage 인스턴스
  /// Hive 암호화 키를 안전하게 저장한다 (iOS Keychain, Android Keystore)
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Hive AES 키 저장 키 이름
  static const _hiveEncryptionKeyName = 'hive_encryption_key';

  // ─── 초기화 ───────────────────────────────────────────────────────────────
  /// Hive를 초기화하고 모든 Box를 오픈한다
  /// 암호화 Box는 AES 256-bit 키로 보호한다
  static Future<void> init() async {
    // Flutter + Web 환경 초기화
    await Hive.initFlutter();

    // 암호화 키 획득 또는 생성 (Web이면 null 반환)
    final encryptionKey = await _getOrCreateEncryptionKey();

    // 암호화 적용 Box (사용자 데이터 보관) — Web에서는 암호화 없이 오픈
    await _openEncryptedBoxes(encryptionKey);

    // 비암호화 Box (설정, 메타데이터)
    await _openPlainBoxes();
  }

  // ─── 안전한 Box 오픈 헬퍼 ──────────────────────────────────────────────────
  /// 이미 열려 있는 Box를 중복으로 열지 않도록 보호한다
  /// clearAll() 후 init() 재호출 시 발생할 수 있는 중복 오픈 오류를 방지한다
  static Future<void> _safeOpenBox(String name,
      {HiveAesCipher? cipher}) async {
    if (!Hive.isBoxOpen(name)) {
      await Hive.openBox<dynamic>(name, encryptionCipher: cipher);
    }
  }

  // ─── 암호화 키 관리 ──────────────────────────────────────────────────────
  /// AES 암호화 키를 반환한다 (없으면 생성 후 SecureStorage에 저장)
  /// Web 환경에서는 null을 반환하여 암호화 없이 Box를 열도록 한다.
  /// 이유: Web은 페이지 로드마다 새 키를 생성하면 이전에 저장한 Box를 읽지 못하므로
  /// 암호화를 적용하지 않는 것이 올바른 동작이다.
  static Future<HiveAesCipher?> _getOrCreateEncryptionKey() async {
    // Web 환경에서는 암호화 없이 사용 (페이지 로드 시 키가 초기화되어 재사용 불가)
    if (kIsWeb) {
      return null;
    }

    String? existingKey = await _secureStorage.read(key: _hiveEncryptionKeyName);

    if (existingKey != null) {
      // 기존 키를 List<int>로 변환 (쉼표 구분 문자열로 저장)
      final keyList = existingKey.split(',').map(int.parse).toList();
      return HiveAesCipher(keyList);
    }

    // 최초 설치: 새 256-bit 키 생성
    final newKey = Hive.generateSecureKey();
    final keyString = newKey.join(',');
    await _secureStorage.write(key: _hiveEncryptionKeyName, value: keyString);

    return HiveAesCipher(newKey);
  }

  // ─── Box 오픈 ────────────────────────────────────────────────────────────
  /// 사용자 데이터 Box를 오픈한다
  /// cipher가 null이면 (Web 환경) 암호화 없이 오픈한다.
  /// cipher가 존재하면 (네이티브 환경) AES 256-bit 암호화를 적용한다.
  static Future<void> _openEncryptedBoxes(HiveAesCipher? cipher) async {
    await Future.wait([
      _safeOpenBox(AppConstants.userProfileBox, cipher: cipher),
      _safeOpenBox(AppConstants.eventsBox, cipher: cipher),
      _safeOpenBox(AppConstants.todosBox, cipher: cipher),
      _safeOpenBox(AppConstants.habitsBox, cipher: cipher),
      _safeOpenBox(AppConstants.habitLogsBox, cipher: cipher),
      _safeOpenBox(AppConstants.routinesBox, cipher: cipher),
      _safeOpenBox(AppConstants.goalsBox, cipher: cipher),
      _safeOpenBox(AppConstants.subGoalsBox, cipher: cipher),
      _safeOpenBox(AppConstants.goalTasksBox, cipher: cipher),
      // 로컬 퍼스트 아키텍처: 타이머 로그, 업적, 태그 Box 추가
      _safeOpenBox(AppConstants.timerLogsBox, cipher: cipher),
      _safeOpenBox(AppConstants.achievementsBox, cipher: cipher),
      _safeOpenBox(AppConstants.tagsBox, cipher: cipher),
    ]);
  }

  /// 설정 및 메타데이터 Box를 일반 모드로 오픈한다
  /// 민감하지 않은 데이터(테마 설정, 동기화 메타)는 암호화하지 않는다
  static Future<void> _openPlainBoxes() async {
    await Future.wait([
      _safeOpenBox(AppConstants.settingsBox),
      _safeOpenBox(AppConstants.syncMetaBox),
    ]);
  }

  // ─── 초기화 해제 ────────────────────────────────────────────────────────
  /// 로그아웃 시 모든 Hive Box를 완전히 삭제한다
  /// 사용자 데이터 보호를 위해 로컬 캐시를 완전히 제거한다
  /// 열려 있는 Box를 먼저 닫은 후 디스크에서 삭제해야
  /// Hive 내부 레지스트리 불일치 오류를 방지한다
  static Future<void> clearAll() async {
    // 삭제 대상 Box 이름 목록 (로컬 퍼스트 아키텍처 추가 Box 포함)
    final boxNames = [
      AppConstants.userProfileBox,
      AppConstants.eventsBox,
      AppConstants.todosBox,
      AppConstants.habitsBox,
      AppConstants.habitLogsBox,
      AppConstants.routinesBox,
      AppConstants.goalsBox,
      AppConstants.subGoalsBox,
      AppConstants.goalTasksBox,
      AppConstants.timerLogsBox,
      AppConstants.achievementsBox,
      AppConstants.tagsBox,
      AppConstants.settingsBox,
      AppConstants.syncMetaBox,
    ];

    // 열려 있는 Box를 먼저 닫아야 디스크 삭제 시 레지스트리 불일치가 발생하지 않는다
    for (final name in boxNames) {
      if (Hive.isBoxOpen(name)) {
        await Hive.box<dynamic>(name).close();
      }
    }

    // 모든 Box가 닫힌 후 디스크에서 삭제한다
    await Future.wait(
      boxNames.map(Hive.deleteBoxFromDisk),
    );
  }
}
