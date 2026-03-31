// C0: 백업 복원 헬퍼
// 복원 프로세스에서 사용하는 JSON 파싱, 무결성 검증, 원자적 교체 로직을 담당한다.
// BackupService의 restoreFromCloud()가 이 헬퍼를 통해 복원 작업을 수행한다.

import 'dart:convert';
import 'dart:developer' as developer;

import 'package:crypto/crypto.dart';

import '../cache/hive_cache_service.dart';
import '../constants/app_constants.dart';

/// 복원 시 허용된 박스 이름 집합 — 알 수 없는 박스 이름의 데이터 주입을 방지한다
const allowedRestoreBoxes = {
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
};

/// 백업 JSON 파싱 결과
class BackupParseResult {
  /// 파싱된 데이터 (성공 시 non-null)
  final Map<String, dynamic>? data;

  /// 오류 메시지 (실패 시 non-null)
  final String? error;

  const BackupParseResult({this.data, this.error});
}

/// 백업 복원에 필요한 파싱/검증/교체 로직을 담당한다
class BackupRestoreHelper {
  final HiveCacheService _cache;

  BackupRestoreHelper({required HiveCacheService cache}) : _cache = cache;

  /// 백업 JSON을 파싱하고 무결성을 검증한다
  BackupParseResult parseAndVerifyBackup(String jsonString) {
    final backupJson = jsonDecode(jsonString) as Map<String, dynamic>;
    final data = backupJson['data'] as Map<String, dynamic>?;
    if (data == null) {
      return const BackupParseResult(error: '백업 파일 형식이 올바르지 않습니다');
    }

    final version = backupJson['version'] as int? ?? 1;
    if (version >= 2) {
      final storedChecksum = backupJson['checksum'] as String?;
      if (storedChecksum == null) {
        return const BackupParseResult(error: '백업 파일의 무결성 정보가 없습니다');
      }
      final computedChecksum =
          sha256.convert(utf8.encode(jsonEncode(data))).toString();
      if (storedChecksum != computedChecksum) {
        developer.log(
          '[BackupRestoreHelper] 체크섬 불일치: stored=$storedChecksum, computed=$computedChecksum',
          name: 'backup',
        );
        return const BackupParseResult(
            error: '백업 파일이 손상되었습니다. 다시 백업해주세요.');
      }
    }

    return BackupParseResult(data: data);
  }

  /// 복원 대상 박스별로 데이터 항목을 파싱한다
  Map<String, List<MapEntry<String, Map<String, dynamic>>>> parseBoxItems(
    Map<String, dynamic> data,
  ) {
    final boxNames = data.keys
        .where((name) => allowedRestoreBoxes.contains(name))
        .toList();
    final parsedData =
        <String, List<MapEntry<String, Map<String, dynamic>>>>{};

    for (final boxName in boxNames) {
      final items = data[boxName] as List<dynamic>?;
      if (items == null) continue;
      final parsed = <MapEntry<String, Map<String, dynamic>>>[];
      for (final item in items) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final id = map['id']?.toString();
        if (id == null || id.isEmpty) continue;
        parsed.add(MapEntry(id, map));
      }
      if (parsed.isNotEmpty) parsedData[boxName] = parsed;
    }

    return parsedData;
  }

  /// 원자적 교체: 원본을 스냅샷 → clear+write → 실패 시 롤백
  /// 실패한 박스 이름 목록을 반환한다
  Future<List<String>> atomicReplace(
    Map<String, List<MapEntry<String, Map<String, dynamic>>>> parsedData,
    void Function(double progress)? onProgress,
  ) async {
    final failedBoxes = <String>[];
    final totalBoxes = parsedData.isEmpty ? 1 : parsedData.length;
    var processedBoxes = 0;

    // 교체 대상 박스의 원본 데이터를 메모리에 스냅샷한다
    final originalSnapshots =
        <String, List<MapEntry<String, Map<String, dynamic>>>>{};
    for (final boxName in parsedData.keys) {
      final allItems = _cache.getAll(boxName);
      originalSnapshots[boxName] = allItems
          .where((m) => m['id'] != null)
          .map((m) => MapEntry(m['id'].toString(), m))
          .toList();
    }

    // 박스별로 clear+write 교체한다. 실패 시 원본으로 롤백한다
    for (final entry in parsedData.entries) {
      try {
        await _cache.clearBox(entry.key);
        for (final item in entry.value) {
          await _cache.put(entry.key, item.key, item.value);
        }
      } catch (e) {
        developer.log(
          '[BackupRestoreHelper] 복원 중 박스 쓰기 실패, 롤백 시도: ${entry.key} - $e',
          name: 'backup',
        );
        // 롤백: 해당 박스의 원본 데이터를 복원한다
        try {
          await _cache.clearBox(entry.key);
          final original = originalSnapshots[entry.key];
          if (original != null) {
            for (final item in original) {
              await _cache.put(entry.key, item.key, item.value);
            }
          }
        } catch (rollbackErr) {
          developer.log(
            '[BackupRestoreHelper] 롤백도 실패: ${entry.key} - $rollbackErr',
            name: 'backup',
          );
        }
        failedBoxes.add(entry.key);
      }
      processedBoxes++;
      onProgress?.call(0.6 + (0.35 * processedBoxes / totalBoxes));
    }

    return failedBoxes;
  }
}
