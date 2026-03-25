// C0.6-A: Hive AES 암호화 키 관리
// flutter_secure_storage(모바일) 또는 파일 기반 저장소(데스크톱)에서
// AES 256-bit 키를 읽거나 새로 생성한다.
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

/// Hive AES 암호화 키 관리 모듈
/// 모바일: flutter_secure_storage (iOS Keychain / Android Keystore)
/// 데스크톱: flutter_secure_storage 시도 후 실패 시 파일 기반 폴백
abstract class HiveEncryptionKeyManager {
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

  /// 데스크톱 여부 (macOS/Windows/Linux)
  static bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  // ─── 퍼블릭 API ──────────────────────────────────────────────────────────

  /// AES 암호화 키를 반환한다 (없으면 생성 후 저장)
  /// 모바일(Android/iOS): flutter_secure_storage (Keychain/Keystore)
  /// 데스크톱(macOS/Windows): flutter_secure_storage 시도 후 실패 시 파일 기반 폴백
  static Future<HiveAesCipher> getOrCreateKey() async {
    if (_isDesktop) {
      return _getOrCreateKeyDesktop();
    }
    return _getOrCreateKeyMobile();
  }

  // ─── 모바일 키 관리 ────────────────────────────────────────────────────────

  /// 모바일용 암호화 키 관리 (flutter_secure_storage 사용)
  static Future<HiveAesCipher> _getOrCreateKeyMobile() async {
    String? existingKey =
        await _secureStorage.read(key: _hiveEncryptionKeyName);

    if (existingKey != null) {
      try {
        final keyList = existingKey.split(',').map(int.parse).toList();
        return HiveAesCipher(keyList);
      } catch (e) {
        developer.log(
          '[HiveEncryptionKeyManager] 암호화 키 파싱 실패, 새 키 생성: $e',
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

  // ─── 데스크톱 키 관리 ──────────────────────────────────────────────────────

  /// 데스크톱용 암호화 키 관리
  /// flutter_secure_storage를 타임아웃으로 시도한 후,
  /// 실패 시 파일 기반 키 저장소로 폴백한다
  static Future<HiveAesCipher> _getOrCreateKeyDesktop() async {
    // 1차: flutter_secure_storage 시도 (타임아웃 적용)
    try {
      debugPrint(
          '[Hive] 데스크톱: SecureStorage 시도 ($_secureStorageTimeoutSeconds초 타임아웃)...');
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
      debugPrint(
          '[Hive] 데스크톱: SecureStorage 실패 ($e), 파일 기반 폴백 사용');
    }

    // 2차: 파일 기반 키 저장소 (앱 서포트 디렉토리에 저장)
    return _getOrCreateKeyFromFile();
  }

  /// 파일 기반 암호화 키 저장소 (데스크톱 폴백용)
  /// Application Support 디렉토리에 암호화 키를 JSON 파일로 저장한다
  /// Keychain보다 보안 수준이 낮지만 앱이 정상 동작하도록 보장한다
  static Future<HiveAesCipher> _getOrCreateKeyFromFile() async {
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
          '[HiveEncryptionKeyManager] 파일 기반 키 파싱 실패, 새 키 생성: $e',
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
}
