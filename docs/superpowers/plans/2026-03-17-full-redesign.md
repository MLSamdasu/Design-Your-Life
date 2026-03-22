# 전체 앱 디자인 리뉴얼 + 기능 확장 구현 계획

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 테마 6개→3개 축소, Refined Glass 디자인 적용, RoutineLog 모델 생성, 캘린더 드래그 핸들, 투두 3서브탭 확장, 전체 화면 디자인 리파인을 구현한다.

**Architecture:** 로컬 퍼스트 Hive 기반 + Riverpod 상태관리. RoutineLog는 HabitLog 패턴을 따르며, data_store_providers.dart에 버전 카운터 + raw provider를 추가한다. 테마 시스템은 ThemePreset enum + ThemePresetRegistry 팩토리를 3개로 축소하고 마이그레이션 매핑을 적용한다.

**Tech Stack:** Flutter 3.29 (Dart), Riverpod 2.6, Hive (AES-256), table_calendar, GoRouter 14.x

**Spec:** `docs/superpowers/specs/2026-03-17-full-redesign-design.md`

---

## Chunk 1: Foundation — RoutineLog 모델 + 데이터 스토어

### Task 1: RoutineLog 모델 생성

**Files:**
- Create: `lib/shared/models/routine_log.dart`
- Test: `test/shared/models/routine_log_test.dart`

- [ ] **Step 1: RoutineLog 모델 파일 생성**

`lib/shared/models/routine_log.dart` 생성. HabitLog 패턴(`lib/shared/models/habit_log.dart`)을 따른다:

```dart
// 공유 모델: RoutineLog (루틴 일별 완료 기록)
// Hive routineLogsBox에 저장되는 루틴 완료 기록 모델이다.
// HabitLog 패턴을 따른다.
import '../../core/utils/date_parser.dart';
import '../../core/utils/date_utils.dart';
import '../../core/error/app_exception.dart';

/// 루틴 일별 완료 기록 모델
/// Hive routineLogsBox에 저장된다
class RoutineLog {
  final String id;
  final String routineId;
  final DateTime date;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RoutineLog({
    required this.id,
    required this.routineId,
    required this.date,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Map 데이터에서 RoutineLog 객체를 생성한다
  factory RoutineLog.fromMap(Map<String, dynamic> map) {
    try {
      return RoutineLog(
        id: map['id']?.toString() ?? '',
        routineId: (map['routine_id'] ?? map['routineId']).toString(),
        date: DateParser.parse(
            map['log_date'] ?? map['logDate'] ?? map['date']),
        isCompleted: map['is_completed'] as bool? ??
            map['isCompleted'] as bool? ??
            false,
        createdAt: DateParser.parse(
            map['created_at'] ?? map['createdAt'] ?? DateTime.now()),
        updatedAt: DateParser.parse(
            map['updated_at'] ?? map['updatedAt'] ?? DateTime.now()),
      );
    } on TypeError catch (e) {
      throw AppException.validation(
        'RoutineLog 파싱 실패 (id: ${map['id']}): 필드 타입이 올바르지 않습니다. 원인: $e',
      );
    }
  }

  /// INSERT용 Map (HabitLog.toInsertMap 패턴 — 'id' 제외)
  /// Hive put(boxName, id, map) 호출 시 id를 키로 별도 전달한다
  Map<String, dynamic> toInsertMap(String userId) {
    return {
      'user_id': userId,
      'routine_id': routineId,
      'log_date': AppDateUtils.toDateString(date),
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 불변 업데이트
  RoutineLog copyWith({
    bool? isCompleted,
    DateTime? updatedAt,
  }) {
    return RoutineLog(
      id: id,
      routineId: routineId,
      date: date,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

- [ ] **Step 2: RoutineLog 단위 테스트 작성**

`test/shared/models/routine_log_test.dart` 생성:

```dart
// RoutineLog 모델 단위 테스트
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_web/shared/models/routine_log.dart';

void main() {
  group('RoutineLog.fromMap', () {
    test('정상 Map에서 객체를 생성한다', () {
      final map = {
        'id': 'log-1',
        'routine_id': 'routine-1',
        'log_date': '2026-03-17',
        'is_completed': true,
        'created_at': '2026-03-17T10:00:00.000Z',
        'updated_at': '2026-03-17T10:00:00.000Z',
      };
      final log = RoutineLog.fromMap(map);
      expect(log.id, 'log-1');
      expect(log.routineId, 'routine-1');
      expect(log.isCompleted, true);
    });

    test('camelCase 키도 파싱한다', () {
      final map = {
        'id': 'log-2',
        'routineId': 'routine-2',
        'logDate': '2026-03-17',
        'isCompleted': false,
        'createdAt': '2026-03-17T10:00:00.000Z',
        'updatedAt': '2026-03-17T10:00:00.000Z',
      };
      final log = RoutineLog.fromMap(map);
      expect(log.routineId, 'routine-2');
      expect(log.isCompleted, false);
    });
  });

  group('RoutineLog.toInsertMap', () {
    test('id 필드가 포함되지 않는다 (HabitLog 패턴)', () {
      final log = RoutineLog(
        id: 'log-1',
        routineId: 'routine-1',
        date: DateTime(2026, 3, 17),
        isCompleted: true,
        createdAt: DateTime(2026, 3, 17),
        updatedAt: DateTime(2026, 3, 17),
      );
      final map = log.toInsertMap('local_user');
      expect(map.containsKey('id'), false);
      expect(map['routine_id'], 'routine-1');
      expect(map['user_id'], 'local_user');
    });
  });

  group('RoutineLog.copyWith', () {
    test('isCompleted를 토글한다', () {
      final log = RoutineLog(
        id: 'log-1',
        routineId: 'routine-1',
        date: DateTime(2026, 3, 17),
        isCompleted: false,
        createdAt: DateTime(2026, 3, 17),
        updatedAt: DateTime(2026, 3, 17),
      );
      final toggled = log.copyWith(isCompleted: true);
      expect(toggled.isCompleted, true);
      expect(toggled.id, 'log-1'); // 다른 필드 불변
    });
  });
}
```

- [ ] **Step 3: 테스트 실행 — PASS 확인**

Run: `cd /Users/kimtaekyu/Documents/Develop_Fold/03_ToDoList_Web && flutter test test/shared/models/routine_log_test.dart`
Expected: All tests PASS

- [ ] **Step 4: Commit**

```bash
git add lib/shared/models/routine_log.dart test/shared/models/routine_log_test.dart
git commit -m "feat: RoutineLog 모델 생성 (HabitLog 패턴)"
```

---

### Task 2: Hive 박스 + 데이터 스토어 등록

**Files:**
- Modify: `lib/core/constants/app_constants.dart:100` (routinesBox 아래에 추가)
- Modify: `lib/core/cache/hive_initializer.dart:92,125` (_openEncryptedBoxes + clearAll)
- Modify: `lib/core/providers/data_store_providers.dart:26,79,132-143`
- Modify: `lib/core/backup/backup_service.dart:131,296`

- [ ] **Step 1: AppConstants에 routineLogsBox 상수 추가**

`lib/core/constants/app_constants.dart` line 100 (routinesBox 아래):

```dart
  static const String routineLogsBox = 'routineLogsBox';
```

- [ ] **Step 2: HiveInitializer — 암호화 박스 등록 + clearAll 추가**

`lib/core/cache/hive_initializer.dart`:

(1) `_openEncryptedBoxes()` Future.wait 목록 line 92 (routinesBox 아래):
```dart
      _safeOpenBox(AppConstants.routineLogsBox, cipher: cipher),
```

(2) `clearAll()` boxNames 목록 line 125 (routinesBox 아래):
```dart
      AppConstants.routineLogsBox,
```

- [ ] **Step 3: data_store_providers.dart — 버전 카운터 + raw provider + bumpAll 추가**

`lib/core/providers/data_store_providers.dart`:

(1) Line 26 (routineDataVersionProvider 아래) 버전 카운터 추가:
```dart
/// 루틴 로그 데이터 버전 카운터
final routineLogDataVersionProvider = StateProvider<int>((ref) => 0);
```

(2) Line 83 (allRoutinesRawProvider 아래) raw provider 추가:
```dart
/// 전체 루틴 로그 목록 (Map 형태) — Single Source of Truth
final allRoutineLogsRawProvider = Provider<List<Map<String, dynamic>>>((ref) {
  ref.watch(routineLogDataVersionProvider);
  final cache = ref.watch(hiveCacheServiceProvider);
  return cache.getAll(AppConstants.routineLogsBox);
});
```

(3) `bumpAllDataVersions()` 함수 line 137 (routineDataVersionProvider 아래):
```dart
  ref.read(routineLogDataVersionProvider.notifier).state++;
```

- [ ] **Step 4: BackupService — 백업/복원 범위에 routineLogsBox 추가**

`lib/core/backup/backup_service.dart`:

(1) `backupAll()` boxNames (line 143 routinesBox 아래):
```dart
        AppConstants.routineLogsBox,
```

(2) `restoreFromCloud()` allowedBoxes (line 296 set 내부):
```dart
        AppConstants.routineLogsBox,
```

- [ ] **Step 5: flutter analyze 실행**

Run: `cd /Users/kimtaekyu/Documents/Develop_Fold/03_ToDoList_Web && flutter analyze`
Expected: No issues found

- [ ] **Step 6: Commit**

```bash
git add lib/core/constants/app_constants.dart lib/core/cache/hive_initializer.dart lib/core/providers/data_store_providers.dart lib/core/backup/backup_service.dart
git commit -m "feat: routineLogsBox Hive 암호화 박스 등록 + 데이터 스토어 연결"
```

---

### Task 3: RoutineLog Provider 체인

**Files:**
- Create: `lib/features/habit/providers/routine_log_provider.dart`
- Test: `test/features/habit/providers/routine_log_provider_test.dart`

- [ ] **Step 1: routine_log_provider.dart 생성**

```dart
// 루틴 로그 Provider 체인
// routineLogDataVersionProvider, allRoutineLogsRawProvider는
// data_store_providers.dart에서 import한다
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/data_store_providers.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/models/routine_log.dart';

/// 특정 날짜의 루틴 로그 목록
final routineLogsForDayProvider = Provider.family<List<RoutineLog>, DateTime>(
  (ref, date) {
    final allRaw = ref.watch(allRoutineLogsRawProvider);
    final dateStr = AppDateUtils.toDateString(date);
    return allRaw
        .map((m) => RoutineLog.fromMap(m))
        .where((log) => AppDateUtils.toDateString(log.date) == dateStr)
        .toList();
  },
);

/// 특정 루틴 + 특정 날짜의 완료 여부
final routineCompletionProvider =
    Provider.family<bool, ({String routineId, DateTime date})>(
  (ref, params) {
    final logs = ref.watch(routineLogsForDayProvider(params.date));
    return logs.any((log) =>
        log.routineId == params.routineId && log.isCompleted);
  },
);

/// 루틴 완료 토글 액션
final toggleRoutineLogProvider = Provider<
    Future<void> Function(String routineId, DateTime date, bool isCompleted)>(
  (ref) => (routineId, date, isCompleted) async {
    final cache = ref.read(hiveCacheServiceProvider);
    final dateStr = AppDateUtils.toDateString(date);
    final existingLogs = cache.query(
      AppConstants.routineLogsBox,
      (m) =>
          m['routine_id'] == routineId &&
          (m['log_date'] ?? m['logDate']) == dateStr,
    );

    if (isCompleted && existingLogs.isEmpty) {
      // 완료 체크: 신규 로그 생성
      final id = const Uuid().v4();
      final now = DateTime.now();
      final log = RoutineLog(
        id: id,
        routineId: routineId,
        date: date,
        isCompleted: true,
        createdAt: now,
        updatedAt: now,
      );
      await cache.put(
        AppConstants.routineLogsBox,
        id,
        log.toInsertMap(AppConstants.localUserId),
      );
    } else if (!isCompleted && existingLogs.isNotEmpty) {
      // 완료 해제: 기존 로그 삭제
      await cache.deleteById(
        AppConstants.routineLogsBox,
        existingLogs.first['id'].toString(),
      );
    }

    // 파생 Provider 갱신
    ref.read(routineLogDataVersionProvider.notifier).state++;
  },
);
```

- [ ] **Step 2: flutter analyze 실행**

Run: `flutter analyze`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/features/habit/providers/routine_log_provider.dart
git commit -m "feat: RoutineLog Provider 체인 (조회/완료토글)"
```

---

## Chunk 2: Theme System — 6개→3개 축소

### Task 4: ThemePreset enum 축소

**Files:**
- Modify: `lib/core/theme/theme_preset.dart`

- [ ] **Step 1: ThemePreset enum 변경**

`lib/core/theme/theme_preset.dart` 전체 교체:

```dart
// C0.5: 테마 프리셋 열거형
// 3가지 시각적 테마 스타일을 정의한다.
// Hive settingsBox에 name 문자열로 저장/복원한다.

/// 앱 테마 프리셋 유형
/// 시각적 처리 방식(배경, 카드, 블러)만 다르며 ColorTokens의 MAIN/SUB는 변경하지 않는다
enum ThemePreset {
  /// 기본 테마: Refined Glass (밝은 배경 + 미묘한 글라스 효과)
  refinedGlass,

  /// 깔끔함 테마: Clean Minimal (밝은 단색 배경 + 블러 없음)
  cleanMinimal,

  /// 다크 테마: Dark Glass (어두운 배경 + 글라스 효과 유지)
  darkGlass,
}
```

- [ ] **Step 2: flutter analyze — 컴파일 에러 확인**

Run: `flutter analyze`
Expected: FAIL — ThemePresetRegistry.dataFor()에서 삭제된 enum 참조 에러. 이것은 예상된 실패이며 Task 5에서 해결한다.

---

### Task 5: ThemePresetRegistry 3개 프리셋 재정의

**Files:**
- Modify: `lib/core/theme/theme_preset_registry.dart` (전면 재작성)

- [ ] **Step 1: ThemePresetRegistry 전면 재작성**

`lib/core/theme/theme_preset_registry.dart`를 설계서 Section 2.2/2.3/2.4에 맞춰 재작성한다.

핵심 변경:
- `dataFor()` switch문: `refinedGlass` / `cleanMinimal` / `darkGlass` 3개만 남긴다
- `_glassmorphism()` → `_refinedGlass()` (설계서 2.2 값 적용)
- `_clean()` → `_cleanMinimal()` (설계서 2.3 값 적용, Tinted Grey 통일)
- `_neon()` 에센스 + glassmorphism dark → `_darkGlass()` (설계서 2.4 값 적용)
- `_minimal()`, `_retro()`, `_soft()` 삭제

`_refinedGlass()` 핵심 값 (설계서 Section 2.2):
- backgroundGradient: `#F5F3FF` → `#EDE9FE` → `#FDF4FF`
- cardDecoration: `white alpha 0.70`, blur sigma `12.0`
- textPrimary: `ColorTokens.gray800` (밝은 배경)

`_cleanMinimal()` 핵심 값 (설계서 Section 2.3):
- backgroundGradient: `#F9FAFB` → `#FFFFFF`
- cardDecoration: `ColorTokens.white` 불투명, 블러 없음
- border: `ColorTokens.gray200`, textPrimary: `ColorTokens.gray800`

`_darkGlass()` 핵심 값 (설계서 Section 2.4):
- backgroundGradient: `#1A1130` → `#0F0B1A`
- cardDecoration: `white alpha 0.12`, blur sigma `16.0`
- border: `ColorTokens.main alpha 0.30`
- textPrimary: `ColorTokens.white`

- [ ] **Step 2: flutter analyze 실행**

Run: `flutter analyze`
Expected: 여전히 에러 있을 수 있음 — global_providers.dart에서 `ThemePreset.glassmorphism` 참조. Task 6에서 해결.

---

### Task 6: 테마 마이그레이션 (global_providers.dart)

**Files:**
- Modify: `lib/core/providers/global_providers.dart:37-47`

- [ ] **Step 1: themePresetProvider + _migrateThemePreset() 변경**

`lib/core/providers/global_providers.dart` line 37-47 교체:

```dart
/// 현재 선택된 테마 프리셋 Provider
/// 기존 6개 프리셋 문자열을 3개 신규 프리셋으로 자동 매핑한다
final themePresetProvider = StateProvider<ThemePreset>((ref) {
  final cacheService = ref.watch(hiveCacheServiceProvider);
  final saved = cacheService.readSetting<String>(AppConstants.settingsKeyThemePreset);
  if (saved == null) return ThemePreset.refinedGlass;
  return _migrateThemePreset(saved);
});

/// Hive에 저장된 기존 테마 프리셋 문자열을 신규 3개 enum으로 매핑한다
ThemePreset _migrateThemePreset(String saved) {
  return switch (saved) {
    'glassmorphism' => ThemePreset.refinedGlass,
    'refinedGlass' => ThemePreset.refinedGlass,
    'minimal' => ThemePreset.cleanMinimal,
    'clean' => ThemePreset.cleanMinimal,
    'cleanMinimal' => ThemePreset.cleanMinimal,
    'neon' => ThemePreset.darkGlass,
    'darkGlass' => ThemePreset.darkGlass,
    _ => ThemePreset.refinedGlass,
  };
}
```

- [ ] **Step 2: flutter analyze 실행**

Run: `flutter analyze`
Expected: No issues found (또는 settings/theme 관련 에러가 남을 수 있음 — Task 7에서 해결)

- [ ] **Step 3: Commit**

```bash
git add lib/core/theme/theme_preset.dart lib/core/theme/theme_preset_registry.dart lib/core/providers/global_providers.dart
git commit -m "feat: 테마 6개→3개 축소 (refinedGlass/cleanMinimal/darkGlass) + 마이그레이션"
```

---

### Task 7: ColorTokens + 설정 화면 정리

**Files:**
- Modify: `lib/core/theme/color_tokens.dart` (그라디언트 토큰 추가, 제거 테마 프리뷰 삭제)
- Modify: `lib/features/settings/presentation/settings_theme_card.dart` (6칸→3칸)
- Modify: `lib/features/settings/presentation/theme_preview_card.dart` (제거 테마 프리뷰 삭제)

- [ ] **Step 1: ColorTokens에 Refined Glass 그라디언트 토큰 추가**

`lib/core/theme/color_tokens.dart` line 86 (Glassmorphism 그라디언트 섹션 위):

```dart
  // ─── Refined Glass 라이트 배경 그라디언트 ───────────────────────────────
  /// 밝은 라벤더 시작점
  static const Color refinedGradientStart = Color(0xFFF5F3FF);
  /// sub 색상과 동일한 중간점
  static const Color refinedGradientMid = Color(0xFFEDE9FE);
  /// 밝은 핑크 라벤더 끝점
  static const Color refinedGradientEnd = Color(0xFFFDF4FF);
```

- [ ] **Step 2: 제거 테마 프리뷰 색상 삭제**

`color_tokens.dart`에서 `previewRetroBg`, `previewRetroBorder`, `previewRetroLine`, `previewNeonBg`, `previewSoftBg`, `previewSoftBorder`, `previewSoftLine` 을 검색하여 삭제한다. `previewCleanBorder`, `previewCleanLine`은 cleanMinimal에서 재활용하므로 유지한다.

- [ ] **Step 3: settings_theme_card.dart 수정**

`lib/features/settings/presentation/settings_theme_card.dart`를 열어 6개 테마 그리드를 3개로 줄인다. `ThemePreset.values` 반복문이 자동으로 3개만 렌더링하므로 GridView `crossAxisCount`나 레이아웃만 조정한다.

- [ ] **Step 4: theme_preview_card.dart 수정**

`lib/features/settings/presentation/theme_preview_card.dart`에서 `minimal`/`retro`/`neon`/`soft` 분기를 삭제하고 `refinedGlass`/`cleanMinimal`/`darkGlass` 분기로 교체한다.

- [ ] **Step 5: flutter analyze 실행**

Run: `flutter analyze`
Expected: No issues found

- [ ] **Step 6: Commit**

```bash
git add lib/core/theme/color_tokens.dart lib/features/settings/presentation/settings_theme_card.dart lib/features/settings/presentation/theme_preview_card.dart
git commit -m "feat: ColorTokens 정리 + 설정 화면 3테마 UI 적용"
```

---

## Chunk 3: Shared Widget — SegmentedControl

### Task 8: 공유 SegmentedControl 위젯

**Files:**
- Create: `lib/shared/widgets/segmented_control.dart`
- Test: `test/shared/widgets/segmented_control_test.dart`

- [ ] **Step 1: SegmentedControl 위젯 생성**

`lib/shared/widgets/segmented_control.dart`:

```dart
// 공유 위젯: SegmentedControl<T>
// 투두/습관/목표 화면의 서브탭 스위처를 통일하는 Glass Pill 스타일 세그먼트 컨트롤이다.
// 기존 각 화면의 _SubTabSwitcher를 대체한다.
import 'dart:ui';
import 'package:flutter/material.dart';

import '../../core/theme/animation_tokens.dart';
import '../../core/theme/glassmorphism.dart';
import '../../core/theme/radius_tokens.dart';
import '../../core/theme/spacing_tokens.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/typography_tokens.dart';

/// 범용 세그먼트 컨트롤 위젯
/// Glass Pill 스타일로 서브탭 전환을 표시한다
class SegmentedControl<T> extends StatelessWidget {
  /// 표시할 값 목록
  final List<T> values;

  /// 현재 선택된 값
  final T selected;

  /// 각 값의 라벨 문자열을 반환하는 빌더
  final String Function(T) labelBuilder;

  /// 선택 변경 콜백
  final ValueChanged<T> onChanged;

  const SegmentedControl({
    super.key,
    required this.values,
    required this.selected,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: GlassDecoration.subtleBlurSigma,
          sigmaY: GlassDecoration.subtleBlurSigma,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: context.themeColors.textPrimaryWithAlpha(0.12),
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(
              color: context.themeColors.textPrimaryWithAlpha(0.15),
            ),
          ),
          child: Row(
            children: values.map((tab) {
              final isActive = tab == selected;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(tab),
                  child: AnimatedContainer(
                    duration: AppAnimation.standard,
                    curve: Curves.easeInOutCubic,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.mdLg,
                    ),
                    decoration: isActive
                        ? BoxDecoration(
                            color: context.themeColors
                                .textPrimaryWithAlpha(0.25),
                            borderRadius:
                                BorderRadius.circular(AppRadius.xl),
                          )
                        : null,
                    child: Center(
                      child: Text(
                        labelBuilder(tab),
                        style: AppTypography.bodyMd.copyWith(
                          color: isActive
                              ? context.themeColors.textPrimary
                              : context.themeColors
                                  .textPrimaryWithAlpha(0.55),
                          fontWeight: isActive
                              ? AppTypography.weightSemiBold
                              : AppTypography.weightRegular,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: SegmentedControl 위젯 테스트 작성**

`test/shared/widgets/segmented_control_test.dart`:

```dart
// SegmentedControl 위젯 테스트
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_web/shared/widgets/segmented_control.dart';

enum TestTab { a, b, c }

void main() {
  testWidgets('3개 탭을 렌더링한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SegmentedControl<TestTab>(
            values: TestTab.values,
            selected: TestTab.a,
            labelBuilder: (t) => t.name.toUpperCase(),
            onChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
  });

  testWidgets('탭 클릭 시 onChanged가 호출된다', (tester) async {
    TestTab? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SegmentedControl<TestTab>(
            values: TestTab.values,
            selected: TestTab.a,
            labelBuilder: (t) => t.name.toUpperCase(),
            onChanged: (t) => tapped = t,
          ),
        ),
      ),
    );
    await tester.tap(find.text('B'));
    expect(tapped, TestTab.b);
  });
}
```

- [ ] **Step 3: 테스트 실행**

Run: `flutter test test/shared/widgets/segmented_control_test.dart`
Expected: All tests PASS

- [ ] **Step 4: Commit**

```bash
git add lib/shared/widgets/segmented_control.dart test/shared/widgets/segmented_control_test.dart
git commit -m "feat: 공유 SegmentedControl<T> 위젯 (서브탭 통일)"
```

---

## Chunk 4: Calendar — 드래그 핸들 + 루틴 편집/완료

### Task 9: MonthlyView 드래그 핸들 리사이즈

**Files:**
- Modify: `lib/features/calendar/presentation/widgets/monthly_view.dart`

- [ ] **Step 1: MonthlyView에 드래그 핸들 상태 + UI 추가**

`monthly_view.dart`의 `MonthlyView`를 `ConsumerStatefulWidget`으로 변경하여 드래그 상태를 관리한다.

핵심 변경:
1. `_calendarRatio` 상태 변수 (기본값 0.5, 범위 0.3~0.7)
2. TableCalendar를 `Flexible(flex: calendarFlex)` 안에 배치
3. 이벤트 리스트를 `Flexible(flex: listFlex)` 안에 배치
4. 사이에 24px 높이 드래그 핸들 `GestureDetector` 배치
5. `onVerticalDragUpdate`에서 `_calendarRatio` 업데이트
6. Hive settingsBox에 비율 저장/복원 (`settingsKeyCalendarRatio`)

설계서 Section 5.1의 디자인 참조.

- [ ] **Step 2: AppConstants에 settingsKeyCalendarRatio 추가**

`lib/core/constants/app_constants.dart`:
```dart
  /// 캘린더 월간뷰 캘린더/리스트 비율 키 (double, 0.3~0.7)
  static const String settingsKeyCalendarRatio = 'calendarRatio';
```

- [ ] **Step 3: flutter analyze 실행**

Run: `flutter analyze`
Expected: No issues found

- [ ] **Step 4: Commit**

```bash
git add lib/features/calendar/presentation/widgets/monthly_view.dart lib/core/constants/app_constants.dart
git commit -m "feat: MonthlyView 드래그 핸들 리사이즈 (30%~70%)"
```

---

### Task 10: 루틴 편집 다이얼로그

**Files:**
- Create: `lib/features/habit/presentation/widgets/routine_edit_dialog.dart`
- Modify: `lib/features/calendar/presentation/widgets/monthly_view.dart` (_RoutineInfoCard에 탭 연결)

- [ ] **Step 1: RoutineEditDialog 생성**

`lib/features/habit/presentation/widgets/routine_edit_dialog.dart` 생성. 기존 `routine_create_dialog.dart`의 구조를 참고하여 편집 모드를 추가한다. 필드: 이름, 요일 선택, 시작/종료 시간, 색상 인덱스.

- [ ] **Step 2: _RoutineInfoCard에 탭→편집 연결**

`monthly_view.dart`의 `_RoutineInfoCard`를 `GestureDetector`로 감싸서 `onTap` 시 `RoutineEditDialog.show(context, routine)` 호출. 저장 시 `routineDataVersionProvider` invalidation.

- [ ] **Step 3: flutter analyze 실행**

Run: `flutter analyze`
Expected: No issues found

- [ ] **Step 4: Commit**

```bash
git add lib/features/habit/presentation/widgets/routine_edit_dialog.dart lib/features/calendar/presentation/widgets/monthly_view.dart
git commit -m "feat: 루틴 편집 다이얼로그 + 캘린더 탭 연결"
```

---

### Task 11: 루틴 완료 체크박스 (캘린더)

**Files:**
- Modify: `lib/features/calendar/presentation/widgets/monthly_view.dart` (_RoutineInfoCard → ConsumerWidget + 체크박스)

- [ ] **Step 1: _RoutineInfoCard를 ConsumerWidget으로 변경 + 체크박스 추가**

설계서 Section 5.3 참조:
1. `_RoutineInfoCard` extends `ConsumerWidget`
2. `routineCompletionProvider` watch
3. 좌측에 AnimatedContainer 체크박스 추가
4. 체크 탭 → `toggleRoutineLogProvider` 호출

`routine_log_provider.dart` import 추가 필요.

- [ ] **Step 2: flutter analyze 실행**

Run: `flutter analyze`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/features/calendar/presentation/widgets/monthly_view.dart
git commit -m "feat: 캘린더 루틴 완료 체크박스 (RoutineLog 연동)"
```

---

## Chunk 5: Todo Tab — 3서브탭 확장

### Task 12: TodoSubTab enum + todo_screen.dart 3서브탭

**Files:**
- Modify: `lib/features/todo/providers/todo_provider.dart:37-43` (enum 확장)
- Modify: `lib/features/todo/presentation/todo_screen.dart` (_SubTabSwitcher → SegmentedControl + 3탭 분기)

- [ ] **Step 1: TodoSubTab enum에 weeklyRoutine 추가**

`lib/features/todo/providers/todo_provider.dart` line 37-43:

```dart
/// 투두 서브탭 유형
enum TodoSubTab {
  /// 일정표 (타임라인)
  dailySchedule,

  /// 주간 루틴 (신규)
  weeklyRoutine,

  /// 할 일 (체크리스트)
  todoList,
}
```

- [ ] **Step 2: todo_screen.dart — _SubTabSwitcher를 SegmentedControl로 교체**

`lib/features/todo/presentation/todo_screen.dart`:
1. `_SubTabSwitcher` 클래스를 삭제
2. `SegmentedControl<TodoSubTab>` import + 사용
3. labelBuilder: dailySchedule→'일정표', weeklyRoutine→'주간 루틴', todoList→'할 일'
4. AnimatedSwitcher child에 `TodoSubTab.weeklyRoutine` 분기 추가 → `RoutineWeeklyView`

- [ ] **Step 3: flutter analyze 실행**

Run: `flutter analyze`
Expected: FAIL — RoutineWeeklyView가 아직 없으므로 에러. Task 13에서 생성.

---

### Task 13: RoutineWeeklyView 생성

**Files:**
- Create: `lib/features/todo/presentation/widgets/routine_weekly_view.dart`

- [ ] **Step 1: RoutineWeeklyView 위젯 생성**

설계서 Section 6.2 참조. `routinesForTimelineProvider`를 watch하여 루틴 목록 표시.

```dart
// 투두 탭 서브탭 2: 주간 루틴 뷰
// 오늘 활성 루틴 목록을 체크리스트 형태로 표시한다
// routinesForTimelineProvider (todo_provider.dart)를 데이터 소스로 사용한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../shared/models/todo.dart';
import '../../providers/todo_provider.dart';
import '../../../habit/providers/routine_log_provider.dart';

/// 주간 루틴 뷰 (투두 탭 서브탭)
class RoutineWeeklyView extends ConsumerWidget {
  const RoutineWeeklyView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final routineEntries = ref.watch(routinesForTimelineProvider);

    if (routineEntries.isEmpty) {
      return Center(
        child: Text(
          '오늘의 루틴이 없습니다',
          style: AppTypography.bodyMd.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.5),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
        vertical: AppSpacing.md,
      ),
      itemCount: routineEntries.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final todo = routineEntries[index];
        return _RoutineItem(routineTodo: todo, date: selectedDate);
      },
    );
  }
}

/// 루틴 아이템 (체크박스 + 색상 바 + 이름 + 시간)
class _RoutineItem extends ConsumerWidget {
  final Todo routineTodo;
  final DateTime date;

  const _RoutineItem({required this.routineTodo, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 원본 루틴 ID 추출 (todo.id에서 'routine_' 접두사 제거)
    final routineId = routineTodo.id.startsWith('routine_')
        ? routineTodo.id.substring(8)
        : routineTodo.id;

    final isCompleted = ref.watch(
      routineCompletionProvider((routineId: routineId, date: date)),
    );

    return GestureDetector(
      onTap: () => ref.read(toggleRoutineLogProvider)(
        routineId, date, !isCompleted,
      ),
      child: AnimatedContainer(
        duration: AppAnimation.normal,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.themeColors.textPrimaryWithAlpha(
            isCompleted ? 0.06 : 0.10,
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Row(
          children: [
            // 완료 체크박스
            AnimatedContainer(
              duration: AppAnimation.normal,
              width: AppLayout.iconMd,
              height: AppLayout.iconMd,
              decoration: BoxDecoration(
                color: isCompleted
                    ? context.themeColors.accent
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.xs),
                border: Border.all(
                  color: isCompleted
                      ? context.themeColors.accent
                      : context.themeColors.textPrimaryWithAlpha(0.3),
                  width: AppLayout.borderMedium,
                ),
              ),
              child: isCompleted
                  ? Icon(Icons.check,
                      size: AppLayout.iconSm,
                      color: context.themeColors.dialogSurface)
                  : null,
            ),
            const SizedBox(width: AppSpacing.lg),
            // 색상 인디케이터
            Container(
              width: 4,
              height: AppLayout.iconXl,
              decoration: BoxDecoration(
                color: ColorTokens.main,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // 루틴 이름 + 시간
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routineTodo.title,
                    style: AppTypography.bodyMd.copyWith(
                      color: context.themeColors.textPrimary,
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (routineTodo.startTime != null)
                    Text(
                      '${routineTodo.startTime!.hour.toString().padLeft(2, '0')}:${routineTodo.startTime!.minute.toString().padLeft(2, '0')}'
                      '${routineTodo.endTime != null ? ' ~ ${routineTodo.endTime!.hour.toString().padLeft(2, '0')}:${routineTodo.endTime!.minute.toString().padLeft(2, '0')}' : ''}',
                      style: AppTypography.bodySm.copyWith(
                        color: context.themeColors
                            .textPrimaryWithAlpha(0.6),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: todo_screen.dart에 RoutineWeeklyView import 추가**

```dart
import 'widgets/routine_weekly_view.dart';
```

- [ ] **Step 3: flutter analyze 실행**

Run: `flutter analyze`
Expected: No issues found

- [ ] **Step 4: Commit**

```bash
git add lib/features/todo/presentation/widgets/routine_weekly_view.dart lib/features/todo/providers/todo_provider.dart lib/features/todo/presentation/todo_screen.dart
git commit -m "feat: 투두 3서브탭 (일정표/주간루틴/할일) + RoutineWeeklyView"
```

---

### Task 14: TodoListView 카테고리 그룹화 (루틴 링크)

**Files:**
- Modify: `lib/features/todo/presentation/widgets/todo_list_view.dart`

- [ ] **Step 1: _ScheduleSummaryBar를 ConsumerWidget으로 변경 + 루틴 칩 탭 인터랙션**

설계서 Section 6.3 참조:
1. `_ScheduleSummaryBar` → `ConsumerWidget`
2. 루틴 카운트 칩을 `GestureDetector`로 감싸기
3. 탭 시 `todoSubTabProvider` → `TodoSubTab.weeklyRoutine` 전환

- [ ] **Step 2: flutter analyze 실행**

Run: `flutter analyze`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/features/todo/presentation/widgets/todo_list_view.dart
git commit -m "feat: TodoListView 루틴 칩 → 주간루틴 서브탭 연결"
```

---

## Chunk 6: Screen Integration — 서브탭 교체 + 최종 정리

### Task 15: 습관/목표 탭 서브탭 → SegmentedControl 교체

**Files:**
- Modify: `lib/features/habit/presentation/habit_screen.dart`
- Modify: `lib/features/goal/presentation/goal_screen.dart`

- [ ] **Step 1: habit_screen.dart — _SubTabSwitcher를 SegmentedControl로 교체**

1. `_SubTabSwitcher` (또는 `_HabitHeader` 내부의 서브탭 부분) 삭제
2. `SegmentedControl<HabitSubTab>` import + 사용
3. labelBuilder: tracker→'습관 추적', manage→'습관 관리' (또는 기존 라벨)

- [ ] **Step 2: goal_screen.dart — 서브탭을 SegmentedControl로 교체**

1. `_GoalScreenHeader` 내부의 서브탭 부분 교체
2. `SegmentedControl<GoalSubTab>` import + 사용
3. labelBuilder: goalList→'목표 리스트', mandalart→'만다라트'

- [ ] **Step 3: flutter analyze 실행**

Run: `flutter analyze`
Expected: No issues found

- [ ] **Step 4: Commit**

```bash
git add lib/features/habit/presentation/habit_screen.dart lib/features/goal/presentation/goal_screen.dart
git commit -m "feat: 습관/목표 서브탭 → SegmentedControl 통일"
```

---

### Task 16: 최종 빌드 검증 + 정리

**Files:**
- All modified files

- [ ] **Step 1: flutter analyze 전체 실행**

Run: `flutter analyze`
Expected: No issues found

- [ ] **Step 2: 전체 테스트 실행**

Run: `flutter test`
Expected: All tests PASS

- [ ] **Step 3: 빌드 확인 (Android)**

Run: `flutter build apk --debug`
Expected: BUILD SUCCESSFUL

- [ ] **Step 4: 최종 Commit**

```bash
git add -A
git commit -m "chore: 전체 앱 디자인 리뉴얼 최종 정리 + 빌드 검증"
```
