// C0.6: Hive 초기화 + Box 등록
// Hive.initFlutter() 호출 후 각 Box를 오픈한다.
// AES 암호화 키를 flutter_secure_storage에서 읽어 Hive Box 암호화에 사용한다.
// 데스크톱(macOS/Windows)에서 Keychain 접근이 실패하면 파일 기반 키 저장소를 사용한다.
// 암호화 키가 없으면 새로 생성 후 저장한다 (초회 설치 시).
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

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

  /// flutter_secure_storage 타임아웃 (초)
  /// macOS에서 Keychain 접근이 무한 대기할 수 있으므로 타임아웃을 설정한다
  static const _secureStorageTimeoutSeconds = 5;

  // ─── 초기화 ───────────────────────────────────────────────────────────────
  /// Hive를 초기화하고 모든 Box를 오픈한다
  /// 암호화 Box는 AES 256-bit 키로 보호한다
  static Future<void> init() async {
    // Flutter 네이티브 환경 초기화
    debugPrint('[Hive] initFlutter 시작...');
    await Hive.initFlutter();
    debugPrint('[Hive] initFlutter 완료');

    // 암호화 키 획득 또는 생성
    debugPrint('[Hive] 암호화 키 획득 시작...');
    final encryptionKey = await _getOrCreateEncryptionKey();
    debugPrint('[Hive] 암호화 키 획득 완료');

    // 암호화 적용 Box (사용자 데이터 보관)
    debugPrint('[Hive] 암호화 Box 오픈 시작...');
    await _openEncryptedBoxes(encryptionKey);
    debugPrint('[Hive] 암호화 Box 오픈 완료');

    // 비암호화 Box (설정, 메타데이터)
    debugPrint('[Hive] 일반 Box 오픈 시작...');
    await _openPlainBoxes();
    debugPrint('[Hive] 일반 Box 오픈 완료');
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
  /// AES 암호화 키를 반환한다 (없으면 생성 후 저장)
  /// 모바일(Android/iOS): flutter_secure_storage (Keychain/Keystore)
  /// 데스크톱(macOS/Windows): flutter_secure_storage 시도 후 실패 시 파일 기반 폴백
  static Future<HiveAesCipher> _getOrCreateEncryptionKey() async {
    // 데스크톱 플랫폼에서는 Keychain 접근이 무한 대기할 수 있으므로
    // 타임아웃 후 파일 기반 키 저장소로 폴백한다
    if (_isDesktop) {
      return _getOrCreateEncryptionKeyDesktop();
    }

    // 모바일(Android/iOS): flutter_secure_storage를 직접 사용한다
    return _getOrCreateEncryptionKeyMobile();
  }

  /// 데스크톱 여부 (macOS/Windows/Linux)
  static bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  /// 모바일용 암호화 키 관리 (flutter_secure_storage 사용)
  static Future<HiveAesCipher> _getOrCreateEncryptionKeyMobile() async {
    String? existingKey =
        await _secureStorage.read(key: _hiveEncryptionKeyName);

    if (existingKey != null) {
      try {
        final keyList = existingKey.split(',').map(int.parse).toList();
        return HiveAesCipher(keyList);
      } catch (e) {
        developer.log(
          '[HiveInitializer] 암호화 키 파싱 실패, 새 키 생성: $e',
          name: 'hive',
        );
      }
    }

    // 최초 설치: 새 256-bit 키 생성
    final newKey = Hive.generateSecureKey();
    final keyString = newKey.join(',');
    await _secureStorage.write(key: _hiveEncryptionKeyName, value: keyString);

    return HiveAesCipher(newKey);
  }

  /// 데스크톱용 암호화 키 관리
  /// flutter_secure_storage를 타임아웃으로 시도한 후,
  /// 실패 시 파일 기반 키 저장소로 폴백한다
  static Future<HiveAesCipher> _getOrCreateEncryptionKeyDesktop() async {
    // 1차: flutter_secure_storage 시도 (타임아웃 적용)
    try {
      debugPrint('[Hive] 데스크톱: SecureStorage 시도 ($_secureStorageTimeoutSeconds초 타임아웃)...');
      final existingKey = await _secureStorage
          .read(key: _hiveEncryptionKeyName)
          .timeout(
            Duration(seconds: _secureStorageTimeoutSeconds),
          );

      if (existingKey != null) {
        final keyList = existingKey.split(',').map(int.parse).toList();
        debugPrint('[Hive] 데스크톱: SecureStorage에서 기존 키 로드 성공');
        return HiveAesCipher(keyList);
      }

      // SecureStorage에 키가 없으면 새로 생성하여 SecureStorage에 저장 시도
      final newKey = Hive.generateSecureKey();
      final keyString = newKey.join(',');
      await _secureStorage
          .write(key: _hiveEncryptionKeyName, value: keyString)
          .timeout(Duration(seconds: _secureStorageTimeoutSeconds));
      debugPrint('[Hive] 데스크톱: SecureStorage에 새 키 저장 성공');
      return HiveAesCipher(newKey);
    } catch (e) {
      // SecureStorage 실패(타임아웃 포함) → 파일 기반 폴백
      debugPrint('[Hive] 데스크톱: SecureStorage 실패 ($e), 파일 기반 폴백 사용');
    }

    // 2차: 파일 기반 키 저장소 (앱 서포트 디렉토리에 저장)
    return _getOrCreateEncryptionKeyFromFile();
  }

  /// 파일 기반 암호화 키 저장소 (데스크톱 폴백용)
  /// Application Support 디렉토리에 암호화 키를 JSON 파일로 저장한다
  /// Keychain보다 보안 수준이 낮지만 앱이 정상 동작하도록 보장한다
  static Future<HiveAesCipher> _getOrCreateEncryptionKeyFromFile() async {
    final dir = await getApplicationSupportDirectory();
    final keyFile = File('${dir.path}/.hive_key');

    // 기존 키 파일이 있으면 읽기
    if (keyFile.existsSync()) {
      try {
        final content = await keyFile.readAsString();
        final keyList =
            (jsonDecode(content) as List<dynamic>).cast<int>().toList();
        debugPrint('[Hive] 데스크톱: 파일에서 기존 키 로드 성공');
        return HiveAesCipher(keyList);
      } catch (e) {
        developer.log(
          '[HiveInitializer] 파일 기반 키 파싱 실패, 새 키 생성: $e',
          name: 'hive',
        );
      }
    }

    // 새 키 생성 후 파일에 저장
    final newKey = Hive.generateSecureKey();
    await keyFile.writeAsString(jsonEncode(newKey));

    // macOS/Linux에서 키 파일 권한을 소유자만 읽기/쓰기로 제한한다 (0600)
    // Windows는 POSIX 권한 모델이 없으므로 제외한다
    if (!Platform.isWindows) {
      await Process.run('chmod', ['600', keyFile.path]);
    }
    debugPrint('[Hive] 데스크톱: 파일에 새 키 저장 완료 (권한 설정 적용)');

    return HiveAesCipher(newKey);
  }

  // ─── Box 오픈 ────────────────────────────────────────────────────────────
  /// 사용자 데이터 Box를 AES 256-bit 암호화로 오픈한다
  static Future<void> _openEncryptedBoxes(HiveAesCipher cipher) async {
    await Future.wait([
      _safeOpenBox(AppConstants.userProfileBox, cipher: cipher),
      _safeOpenBox(AppConstants.eventsBox, cipher: cipher),
      _safeOpenBox(AppConstants.todosBox, cipher: cipher),
      _safeOpenBox(AppConstants.habitsBox, cipher: cipher),
      _safeOpenBox(AppConstants.habitLogsBox, cipher: cipher),
      _safeOpenBox(AppConstants.routinesBox, cipher: cipher),
      _safeOpenBox(AppConstants.routineLogsBox, cipher: cipher),
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
      AppConstants.routineLogsBox,
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
