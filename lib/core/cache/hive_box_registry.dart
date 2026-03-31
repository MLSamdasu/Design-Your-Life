// C0.6-B: Hive Box 등록 및 정리
// 암호화/비암호화 Box를 오픈하고, 로그아웃 시 모든 Box를 삭제한다.
import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';

/// Hive Box 등록 및 정리 모듈
/// 암호화 Box(사용자 데이터)와 비암호화 Box(설정/메타)를 관리한다
abstract class HiveBoxRegistry {
  // ─── 안전한 Box 오픈 헬퍼 ──────────────────────────────────────────────────
  /// 이미 열려 있는 Box를 중복으로 열지 않도록 보호한다
  /// clearAll() 후 init() 재호출 시 발생할 수 있는 중복 오픈 오류를 방지한다
  static Future<void> _safeOpenBox(String name,
      {HiveAesCipher? cipher}) async {
    if (!Hive.isBoxOpen(name)) {
      await Hive.openBox<dynamic>(name, encryptionCipher: cipher);
    }
  }

  // ─── Box 오픈 ────────────────────────────────────────────────────────────
  /// 사용자 데이터 Box를 AES 256-bit 암호화로 오픈한다
  static Future<void> openEncryptedBoxes(HiveAesCipher cipher) async {
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
      // 데일리 리추얼 (25/5 법칙 + 3의 법칙)
      _safeOpenBox(AppConstants.dailyRitualBox, cipher: cipher),
      _safeOpenBox(AppConstants.dailyThreeBox, cipher: cipher),
      // 메모 (텍스트/드로잉)
      _safeOpenBox(AppConstants.memosBox, cipher: cipher),
      // 독서 캘린더 (도서 + 독서 계획)
      _safeOpenBox(AppConstants.booksBox, cipher: cipher),
      _safeOpenBox(AppConstants.readingPlansBox, cipher: cipher),
    ]);
  }

  /// 설정 및 메타데이터 Box를 일반 모드로 오픈한다
  /// 민감하지 않은 데이터(테마 설정, 동기화 메타)는 암호화하지 않는다
  static Future<void> openPlainBoxes() async {
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
      AppConstants.dailyRitualBox,
      AppConstants.dailyThreeBox,
      AppConstants.memosBox,
      AppConstants.booksBox,
      AppConstants.readingPlansBox,
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
