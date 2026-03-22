# 전체 앱 디자인 리뉴얼 + 기능 확장 설계서

## 1. 개요

- **목적**: 전체 앱 시각 디자인 전면 수정 + 캘린더/투두 기능 확장
- **범위**: 디자인만 변경하며, 기존 기능 100% 유지한다
- **접근법**: Refined Glass (A 방안) — 밝은 배경 + 미묘한 글라스 효과 기본, 다크 모드에서 강한 글라스 유지
- **날짜**: 2026-03-17

---

## 2. 테마 시스템 개편

### 2.1 테마 축소 (6개 → 3개)

**현재 구조**: `lib/core/theme/theme_preset.dart`에 `ThemePreset` enum이 6개 값을 가진다.

```dart
// 현재: lib/core/theme/theme_preset.dart
enum ThemePreset {
  glassmorphism,  // 기본
  minimal,        // 미니멀 화이트
  retro,          // 레트로 감성
  neon,           // 네온 나이트
  clean,          // 깔끔한
  soft,           // 부드러운
}
```

**변경**: 3개로 축소한다.

```dart
// 변경: lib/core/theme/theme_preset.dart
enum ThemePreset {
  /// 기본 테마: Refined Glass (밝은 배경 + 미묘한 글라스 효과)
  refinedGlass,

  /// 깔끔함 테마: Clean Minimal (밝은 단색 배경 + 블러 없음)
  cleanMinimal,

  /// 다크 테마: Dark Glass (어두운 배경 + 글라스 효과 유지)
  darkGlass,
}
```

**유지**: `refinedGlass` (기존 glassmorphism 리파인), `cleanMinimal` (기존 clean 리파인), `darkGlass` (기존 glassmorphism/neon 에센스 통합)
**제거**: `minimal`, `retro`, `neon`, `soft`

**마이그레이션**: `ThemePresetRegistry.dataFor()` switch문에서 제거된 프리셋 분기를 삭제하고, Hive `settingsBox`의 `themePreset` 값이 제거된 프리셋 이름이면 `refinedGlass`로 폴백 처리한다.

**기존 문자열 → 새 enum 매핑 테이블**:

| Hive 저장 값 (기존) | 매핑 대상 (신규) | 근거 |
|---|---|---|
| `glassmorphism` | `refinedGlass` | 글라스 계열 리파인 |
| `minimal` | `cleanMinimal` | 미니멀/화이트 계열 통합 |
| `retro` | `refinedGlass` | 제거 → 기본값 폴백 |
| `neon` | `darkGlass` | 다크 계열 통합 |
| `clean` | `cleanMinimal` | 클린 계열 리파인 |
| `soft` | `refinedGlass` | 제거 → 기본값 폴백 |

`global_providers.dart`의 `themePresetProvider`에서 `ThemePreset.values.firstWhere(orElse)` 대신 명시적 매핑 함수를 사용하여 기존 사용자의 테마 설정이 의도한 계열로 전환되도록 한다.

```dart
// 변경: lib/core/providers/global_providers.dart — themePresetProvider
final themePresetProvider = StateProvider<ThemePreset>((ref) {
  final cacheService = ref.watch(hiveCacheServiceProvider);
  final saved = cacheService.readSetting<String>(AppConstants.settingsKeyThemePreset);
  if (saved == null) return ThemePreset.refinedGlass;
  // 기존 프리셋 문자열 → 신규 enum 매핑
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
    _ => ThemePreset.refinedGlass, // retro, soft 등 제거된 프리셋은 기본값
  };
}
```

### 2.2 "기본" 테마 (Refined Glass)

기존 `glassmorphism` 프리셋을 리파인한다. 핵심 방향: **밝은 배경 + 미묘한 글라스 효과**.

**현재 → 변경**:

| 속성 | 현재 (glassmorphism) | 변경 (refinedGlass) |
|---|---|---|
| 배경 그라디언트 | `gradientStart(#667EEA)` → `gradientMid(#764BA2)` → `gradientEnd(#F093FB)` 강한 보라-핑크 | 밝은 라벤더 그라디언트: `#F5F3FF` → `#EDE9FE` → `#FDF4FF` (sub 계열 밝은 톤) |
| 카드 배경 alpha | `white.withValues(alpha: 0.22)` | `white.withValues(alpha: 0.70)` — 가독성 대폭 향상 |
| 카드 보더 alpha | `white.withValues(alpha: 0.35)` | `white.withValues(alpha: 0.50)` |
| 카드 그림자 alpha | `shadowBase 0.1` | `shadowBase 0.06` — 더 가벼운 그림자 |
| 블러 시그마 | `20.0` | `12.0` — 미묘한 블러로 성능 향상 |
| 텍스트 색상 | `ColorTokens.white` (어두운 배경 기준) | `ColorTokens.gray800` (밝은 배경 기준) |
| 보조 텍스트 | `ColorTokens.white` | `ColorTokens.gray500` |

**GlassDecoration 파라미터 조정**:

```dart
// refinedGlass cardDecoration
cardDecoration: () => BoxDecoration(
  color: ColorTokens.white.withValues(alpha: 0.70),
  borderRadius: BorderRadius.circular(AppRadius.huge),  // 20px (radius_tokens.dart 확인: huge = 20)
  border: Border.all(
    color: ColorTokens.white.withValues(alpha: 0.50),
    width: AppLayout.borderThin,
  ),
  boxShadow: [
    BoxShadow(
      color: ColorTokens.shadowBase.withValues(alpha: 0.06),
      blurRadius: AppLayout.blurRadiusMd,  // 16px
      offset: const Offset(0, 4),
    ),
  ],
),
```

### 2.3 "깔끔함" 테마 (Clean Minimal)

기존 `clean` 프리셋을 기반으로 한다. 핵심 방향: **블러 효과 없음 + 밝은 단색 배경 + 타이포그래피 중심**.

**현재 → 변경**:

| 속성 | 현재 (clean) | 변경 (cleanMinimal) |
|---|---|---|
| 배경 그라디언트 | `#F8F9FA` → `#FFFFFF` | `#F9FAFB` → `#FFFFFF` — 거의 동일, 미세 조정 |
| 카드 배경 | `ColorTokens.white` 불투명 | 유지 |
| 카드 보더 | `#E8ECF0` | `ColorTokens.gray200` (`#E5E3E9`) — Tinted Grey 통일 |
| 카드 그림자 | `#1A1A2E alpha 0.04` | `shadowBase alpha 0.04` — Tinted Grey 기반 통일 |
| 블러 | `false` / `0.0` | 유지 (블러 없음) |
| 텍스트 기본 | `#1A1A2E` | `ColorTokens.gray800` (`#2B2A2D`) — Tinted Grey 통일 |
| 텍스트 보조 | `#6B7280` | `ColorTokens.gray500` (`#7B797F`) — Tinted Grey 통일 |

### 2.4 "다크" 테마 (Dark Glass)

기존 `glassmorphism`의 다크 모드 + `neon` 프리셋의 에센스를 통합한다. 핵심 방향: **어두운 배경 + 글라스 효과 유지 + WCAG 대비 준수**.

**현재 → 변경**:

| 속성 | 현재 (glassmorphism dark) | 변경 (darkGlass) |
|---|---|---|
| 배경 그라디언트 | `darkGradientStart(#2D3561)` → `darkGradientEnd(#5C2E6B)` | `#1A1130` → `#0F0B1A` (neon 배경 톤과 통합, 더 깊은 다크) |
| 카드 배경 alpha | `white 0.14` | `white 0.12` — 약간 더 어두운 카드 |
| 카드 보더 | `white 0.22` | `ColorTokens.main alpha 0.30` — neon에서 가져온 미세 악센트 보더 |
| 카드 그림자 | `shadowBase 0.30` | `shadowBase 0.25` + `main alpha 0.08` — 미세 네온 글로우 |
| 블러 시그마 | `20.0` | `16.0` — 약간 줄여 성능 향상 |
| 텍스트 색상 | `ColorTokens.white` | 유지 |

### 2.5 디자인 토큰 변경 사항

#### ColorTokens (lib/core/theme/color_tokens.dart)

**추가**: Refined Glass 배경 그라디언트용 밝은 색상 토큰

```dart
// Refined Glass 라이트 배경 그라디언트
static const Color refinedGradientStart = Color(0xFFF5F3FF);  // 밝은 라벤더
static const Color refinedGradientMid = Color(0xFFEDE9FE);    // sub 색상과 동일
static const Color refinedGradientEnd = Color(0xFFFDF4FF);    // 밝은 핑크 라벤더
```

**제거**: 테마 프리뷰 전용 색상 중 제거 테마 관련 항목

```dart
// 제거 대상
previewRetroBg, previewRetroBorder, previewRetroLine  // retro 제거
previewNeonBg                                          // neon 제거
previewSoftBg, previewSoftBorder, previewSoftLine     // soft 제거
```

**유지**: `previewCleanBorder`, `previewCleanLine`은 cleanMinimal 프리뷰에 재활용한다.

#### AppSpacing (lib/core/theme/spacing_tokens.dart)

변경 없음. 현재 여백 체계를 유지한다.

#### AppRadius (lib/core/theme/radius_tokens.dart)

변경 없음. 현재 반지름 체계를 유지한다.

#### GlassDecoration (lib/core/theme/glassmorphism.dart)

`GlassDecoration` 클래스 자체는 유지하되, `ThemePresetRegistry`에서 프리셋별로 오버라이드하므로 직접 사용하는 곳이 있으면 프리셋 데코레이션으로 교체한다.

#### AppAnimation (lib/core/theme/animation_tokens.dart)

변경 없음. 현재 애니메이션 토큰 체계를 유지한다.

---

## 3. 전체 디자인 리파인 상세

### 3.1 깊이 체계 (Elevation System)

현재 `ThemePresetData`에 `cardDecoration`, `elevatedCardDecoration`, `subtleCardDecoration`, `modalDecoration` 4단계가 정의되어 있다. 이를 명확한 Elevation Level로 체계화한다.

| Level | 용도 | refinedGlass blur sigma | refinedGlass card alpha | darkGlass card alpha |
|---|---|---|---|---|
| Level 0 (배경) | 페이지 배경 | N/A (그라디언트) | N/A | N/A |
| Level 1 (subtle) | 내부 섹션, 습관 필, D-day 카드 | 8.0 | white 0.50 | white 0.08 |
| Level 2 (default) | 기본 카드/패널 | 12.0 | white 0.70 | white 0.12 |
| Level 3 (elevated) | 강조 카드, 모달 콘텐츠 | 16.0 | white 0.80 | white 0.16 |
| Level 4 (modal) | 모달/다이얼로그 | 20.0 | white 0.90 | white 0.20 |

### 3.2 서브탭 스위처 통일

**현재**: 각 화면마다 `_SubTabSwitcher` 위젯을 개별 구현한다.
- `lib/features/todo/presentation/todo_screen.dart` → `_SubTabSwitcher` (TodoSubTab 2개)
- `lib/features/habit/presentation/habit_screen.dart` → `_SubTabSwitcher` (HabitSubTab 2개)
- `lib/features/goal/presentation/goal_screen.dart` → `_SubTabSwitcher` + `_SubTab` (GoalSubTab 2개)

세 곳 모두 동일한 Glass Pill 스타일(ClipRRect + BackdropFilter + AnimatedContainer)을 사용하지만 코드가 중복된다.

**변경**: 공유 `SegmentedControl<T>` 위젯으로 통일한다.

```dart
// 신규: lib/shared/widgets/segmented_control.dart
class SegmentedControl<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) labelBuilder;
  final IconData Function(T)? iconBuilder;
  final ValueChanged<T> onChanged;
  // ...
}
```

각 화면의 `_SubTabSwitcher`를 `SegmentedControl`로 교체한다.

### 3.3 액션 버튼 변경

**현재**: 각 화면에서 `FloatingActionButton`을 개별 구현한다.
- `lib/features/todo/presentation/todo_screen.dart` → `_AddTodoFab`
- 목표 화면은 `GoalListView` 내부에서 FAB 사용

**변경**: FAB 디자인 통일. `ColorTokens.main` 배경 + `ColorTokens.white` 아이콘은 유지하되, `elevation: 0` + 미세 그림자(`shadowBase 0.15, blur 12`)로 Refined Glass 기조에 맞춘다. FAB 크기/위치/아이콘은 현재와 동일하게 유지한다.

### 3.4 헤더 영역 간소화

**현재**: 각 화면의 헤더 레이아웃이 유사하나 구현이 다르다.
- 투두: `_TodoHeader` — 년/월 텍스트 + 아래 화살표 + `GlobalActionBar` + `DateSlider`
- 습관: `_HabitHeader` — "습관 & 루틴" 텍스트 + `GlobalActionBar` + `_SubTabSwitcher`
- 목표: `_GoalScreenHeader` — 동적 텍스트("목표 관리"/"만다라트") + `GlobalActionBar` + `_SubTabSwitcher`

**변경**: 레이아웃 패턴은 유지하되, `headingSm` 폰트 사이즈와 `pageHorizontal`/`pageVertical` 패딩이 이미 통일되어 있으므로 디자인 토큰 변경은 불필요하다. 서브탭 부분만 `SegmentedControl`로 교체한다.

---

## 4. RoutineLog 모델 (신규)

### 4.1 데이터 모델

기존 `HabitLog` (`lib/shared/models/habit_log.dart`) 패턴을 따른다.

```dart
// 신규: lib/shared/models/routine_log.dart
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

  /// INSERT용 Map (HabitLog.toInsertMap 패턴과 동일하게 'id' 필드를 제외한다)
  /// Hive에서는 put(boxName, id, map) 호출 시 id를 키로 별도 전달하므로
  /// Map 내부에 'id'를 중복 포함하지 않는다
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

### 4.2 Hive 박스 등록

**AppConstants** (`lib/core/constants/app_constants.dart`)에 추가:

```dart
// 추가
static const String routineLogsBox = 'routineLogsBox';
```

**HiveInitializer** (`lib/core/cache/hive_initializer.dart`)에서 `routineLogsBox`를 AES-256 암호화 박스로 등록한다.

`_openEncryptedBoxes()` 메서드의 `Future.wait` 목록에 추가:
```dart
// 추가: lib/core/cache/hive_initializer.dart — _openEncryptedBoxes()
_safeOpenBox(AppConstants.routineLogsBox, cipher: cipher),
```

`clearAll()` 메서드의 `boxNames` 목록에 추가:
```dart
// 추가: lib/core/cache/hive_initializer.dart — clearAll()
AppConstants.routineLogsBox,  // routinesBox 아래에 추가
```

**BackupService** (`lib/core/backup/backup_service.dart`) 백업/복원 범위에 `routineLogsBox`를 추가한다.

`backupAll()` 메서드의 `boxNames` 목록에 추가:
```dart
// 추가: lib/core/backup/backup_service.dart — backupAll()
AppConstants.routineLogsBox,  // routinesBox 아래에 추가
```

`restoreFromCloud()` 메서드의 `allowedBoxes` 집합에 추가:
```dart
// 추가: lib/core/backup/backup_service.dart — restoreFromCloud()
AppConstants.routineLogsBox,  // routinesBox 아래에 추가
```

**HiveCacheService** (`lib/core/cache/hive_cache_service.dart`)는 범용 CRUD 메서드(`put`, `get`, `getAll`, `query`, `delete`, `deleteById`)를 이미 제공하므로 추가 메서드 없이 `routineLogsBox`를 boxName으로 전달하여 사용한다.

### 4.3 data_store_providers.dart 변경 사항

기존 `data_store_providers.dart` 패턴에 맞춰 `routineLogDataVersionProvider`와 `allRoutineLogsRawProvider`를 추가한다. 이 파일은 모든 데이터 타입의 버전 카운터 + 전체 목록 Provider를 중앙에서 관리하는 Single Source of Truth이다.

```dart
// 추가: lib/core/providers/data_store_providers.dart

/// 루틴 로그 데이터 버전 카운터
final routineLogDataVersionProvider = StateProvider<int>((ref) => 0);

/// 전체 루틴 로그 목록 (Map 형태) — Single Source of Truth
final allRoutineLogsRawProvider = Provider<List<Map<String, dynamic>>>((ref) {
  ref.watch(routineLogDataVersionProvider);
  final cache = ref.watch(hiveCacheServiceProvider);
  return cache.getAll(AppConstants.routineLogsBox);
});
```

`bumpAllDataVersions()` 함수에도 `routineLogDataVersionProvider`를 추가한다:

```dart
// 변경: lib/core/providers/data_store_providers.dart — bumpAllDataVersions()
void bumpAllDataVersions(dynamic ref) {
  // ... 기존 카운터들 ...
  ref.read(routineLogDataVersionProvider.notifier).state++;  // 추가
}
```

### 4.4 Provider 체인

기존 `HabitLog` Provider 패턴(`lib/features/habit/providers/habit_provider.dart`)을 따른다.
`routineLogDataVersionProvider`와 `allRoutineLogsRawProvider`는 `data_store_providers.dart`에 정의되므로 (4.3절 참조) routine_log_provider.dart에서는 import하여 사용한다.

```dart
// 신규 Provider (lib/features/habit/providers/routine_log_provider.dart)
// routineLogDataVersionProvider, allRoutineLogsRawProvider는
// data_store_providers.dart에서 import한다 (4.3절 참조)

/// 특정 날짜의 루틴 로그 목록 (allRoutineLogsRawProvider에서 파생)
/// allRoutineLogsRawProvider는 List<Map>을 반환하므로 RoutineLog.fromMap으로 변환한다
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
final toggleRoutineLogProvider = Provider<Future<void> Function(String routineId, DateTime date, bool isCompleted)>(
  (ref) => (routineId, date, isCompleted) async {
    final cache = ref.read(hiveCacheServiceProvider);
    final dateStr = AppDateUtils.toDateString(date);
    final existingLogs = cache.query(
      AppConstants.routineLogsBox,
      (m) => m['routine_id'] == routineId &&
             (m['log_date'] ?? m['logDate']) == dateStr,
    );

    if (isCompleted && existingLogs.isEmpty) {
      // 신규 로그 생성
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
      // 기존 로그 삭제
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

---

## 5. 캘린더 탭 개선

### 5.1 드래그 핸들 리사이즈

**대상 파일**: `lib/features/calendar/presentation/widgets/monthly_view.dart`

**현재**: `MonthlyView`는 `Column` 내부에 `TableCalendar` + `Expanded(ListView)`를 배치한다. 캘린더 그리드와 이벤트 리스트의 비율이 고정되어 있다.

**변경**: `TableCalendar`와 이벤트 리스트 사이에 드래그 핸들을 추가하여 비율을 동적으로 조절한다.

```
┌────────────────────────┐
│    TableCalendar        │  ← 상단: flex = calendarFlex
│                         │
├──── ═══════════ ────────┤  ← 드래그 핸들 (GestureDetector)
│    이벤트/루틴/습관      │  ← 하단: flex = listFlex
│    리스트               │
└────────────────────────┘
```

**구현 방안**:

1. `Column` 대신 `LayoutBuilder` + `Column` with `Flexible` 사용
2. 캘린더 영역과 리스트 영역의 flex 비율을 `StateProvider<double>`로 관리한다
3. 드래그 핸들 위젯: 높이 24px, 중앙에 가로 36px/높이 4px의 핸들 바 표시
4. `GestureDetector.onVerticalDragUpdate`로 드래그 거리에 따라 비율 업데이트
5. 비율 제한: 캘린더 최소 30% ~ 최대 70%
6. 비율 상태를 Hive `settingsBox`에 저장하여 앱 재시작 시 복원한다

**드래그 핸들 디자인**:

```dart
/// 캘린더/리스트 리사이즈 드래그 핸들
Container(
  height: AppSpacing.xxxl,  // 24px
  alignment: Alignment.center,
  child: Container(
    width: AppLayout.handleBarWidth,   // 36px
    height: AppLayout.handleBarHeight, // 4px
    decoration: BoxDecoration(
      color: context.themeColors.textPrimaryWithAlpha(0.25),
      borderRadius: BorderRadius.circular(AppRadius.xs),
    ),
  ),
)
```

### 5.2 루틴 편집 연결

**대상 파일**: `lib/features/calendar/presentation/widgets/monthly_view.dart` — `_RoutineInfoCard` 클래스

**현재**: `_RoutineInfoCard`는 루틴 이름 + 시간 범위를 표시하지만, 탭 동작이 없다.

**변경**: `_RoutineInfoCard`를 탭하면 `RoutineEditDialog`를 열어 이름, 요일, 시간, 색상을 편집할 수 있게 한다.

**신규 파일**: `lib/features/habit/presentation/widgets/routine_edit_dialog.dart`

> **경로 근거**: 기존 `RoutineCreateDialog`가 `lib/features/habit/presentation/widgets/routine_create_dialog.dart`에 위치하므로, 일관성을 위해 `RoutineEditDialog`도 같은 habit 피처 디렉토리에 배치한다. 캘린더 화면에서 사용할 때는 habit 피처에서 import한다.

```dart
/// 루틴 편집 다이얼로그
/// 기존 routine_create_dialog.dart의 RoutineCreateDialog와 유사한 구조로,
/// 편집 모드를 추가한 형태이다.
class RoutineEditDialog extends ConsumerStatefulWidget {
  final Routine routine;
  // ...
}
```

**_RoutineInfoCard 변경점**:
- `GestureDetector`로 감싸서 `onTap` 시 `RoutineEditDialog.show(context, routine)` 호출
- 저장 시 `routinesBox` 업데이트 + `routineDataVersionProvider` invalidation

### 5.3 루틴 완료 체크박스

**대상 파일**: `lib/features/calendar/presentation/widgets/monthly_view.dart` — `_RoutineInfoCard` 클래스

**현재**: `_RoutineInfoCard`는 정보 표시만 한다 (아이콘 + 이름 + 시간).

**변경**: 좌측에 체크박스를 추가한다. 체크박스 탭 시 `RoutineLog`를 생성/삭제(토글)한다.

```dart
// _RoutineInfoCard.build() 내 Row children 변경
Row(
  children: [
    // 완료 체크박스 (신규)
    GestureDetector(
      onTap: () => ref.read(toggleRoutineLogProvider)(
        routine.routineId, selectedDate, !isCompleted,
      ),
      child: AnimatedContainer(
        duration: AppAnimation.normal,
        width: AppLayout.iconMd,
        height: AppLayout.iconMd,
        decoration: BoxDecoration(
          color: isCompleted ? context.themeColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          border: Border.all(
            color: isCompleted
                ? context.themeColors.accent
                : context.themeColors.textPrimaryWithAlpha(0.3),
            width: AppLayout.borderMedium,
          ),
        ),
        child: isCompleted
            ? Icon(Icons.check, size: AppLayout.iconSm, color: context.themeColors.dialogSurface)
            : null,
      ),
    ),
    const SizedBox(width: AppSpacing.md),
    // 기존 아이콘 + 이름 + 시간 ...
  ],
)
```

**routineCompletionProvider** 연동: `_RoutineInfoCard`를 `ConsumerWidget`으로 변경하고 `routineCompletionProvider`를 watch하여 완료 상태를 실시간으로 반영한다.

---

## 6. 투두 탭 확장

### 6.1 서브탭 확장 (2개 → 3개)

**대상 파일**: `lib/features/todo/providers/todo_provider.dart`

**현재**:

```dart
enum TodoSubTab {
  dailySchedule,  // 하루 일정표
  todoList,       // 할 일 목록
}
```

**변경**:

```dart
enum TodoSubTab {
  dailySchedule,   // 일정표
  weeklyRoutine,   // 주간 루틴 (신규)
  todoList,        // 할 일
}
```

**서브탭 라벨**:
- `dailySchedule` → "일정표"
- `weeklyRoutine` → "주간 루틴"
- `todoList` → "할 일"

**대상 파일**: `lib/features/todo/presentation/todo_screen.dart`

**현재**: `_SubTabSwitcher`에서 `TodoSubTab.values.map`으로 2개 탭을 렌더링한다.

**변경**: `SegmentedControl<TodoSubTab>`로 교체하고 3개 탭을 표시한다.

```dart
// todo_screen.dart의 _SubTabSwitcher 교체
SegmentedControl<TodoSubTab>(
  values: TodoSubTab.values,
  selected: subTab,
  labelBuilder: (tab) => switch (tab) {
    TodoSubTab.dailySchedule => '일정표',
    TodoSubTab.weeklyRoutine => '주간 루틴',
    TodoSubTab.todoList => '할 일',
  },
  onChanged: (tab) => ref.read(todoSubTabProvider.notifier).state = tab,
),
```

**AnimatedSwitcher 변경**: 3개 탭에 대응하도록 switch 분기를 추가한다.

```dart
Expanded(
  child: AnimatedSwitcher(
    duration: AppAnimation.medium,
    // ...
    child: switch (subTab) {
      TodoSubTab.dailySchedule => const DailyScheduleView(key: ValueKey('daily')),
      TodoSubTab.weeklyRoutine => const RoutineWeeklyView(key: ValueKey('weekly-routine')),
      TodoSubTab.todoList => const TodoListView(key: ValueKey('list')),
    },
  ),
),
```

### 6.2 "주간 루틴" 서브탭 (신규)

**신규 파일**: `lib/features/todo/presentation/widgets/routine_weekly_view.dart`

**기능**:
1. 오늘 활성화된 루틴 목록을 요일 필터링하여 표시한다
2. 각 루틴: 색상 인디케이터 + 이름 + 시간 범위 + 완료 체크박스
3. `RoutineLog` 연동: `routineCompletionProvider`를 watch하여 완료 상태를 실시간 반영한다

**데이터 소스**: 기존 `routinesForTimelineProvider` (`lib/features/todo/providers/todo_provider.dart`)를 재활용한다. 이 Provider는 `selectedDateProvider`(투두 탭 날짜) 기준으로 해당 요일의 활성 루틴을 `Todo` 형태로 반환한다. `RoutineWeeklyView`에서는 이를 watch하여 루틴 목록을 표시한다.

> **참고**: 캘린더의 `routinesForDayProvider`는 `selectedCalendarDateProvider`(캘린더 탭 날짜)를 사용하므로 투두 탭에서는 사용할 수 없다. `routinesForTimelineProvider`가 이미 투두 탭의 `selectedDateProvider`를 기준으로 루틴을 필터링하므로 신규 Provider를 생성할 필요가 없다.

```dart
/// 주간 루틴 뷰 (투두 탭 서브탭 2)
/// 오늘 활성 루틴 목록을 체크리스트 형태로 표시한다
class RoutineWeeklyView extends ConsumerWidget {
  const RoutineWeeklyView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    // routinesForTimelineProvider: todo_provider.dart에 이미 정의됨
    // selectedDateProvider 기준으로 해당 요일 활성 루틴을 Todo 형태로 반환한다
    final routineEntries = ref.watch(routinesForTimelineProvider);
    // ...
  }
}
```

**루틴 아이템 위젯**:

```dart
/// 루틴 아이템 (체크박스 + 색상 바 + 이름 + 시간)
/// routinesForTimelineProvider가 Todo 형태로 변환하므로 Todo를 받는다
/// 원본 루틴 ID는 todo.id에서 'routine_' 접두사를 제거하여 추출한다
class _RoutineItem extends ConsumerWidget {
  final Todo routineTodo;  // routinesForTimelineProvider가 반환하는 Todo (id: 'routine_xxx')
  final DateTime date;
  // ...
}
```

### 6.3 "할 일" 서브탭 카테고리 그룹화

**대상 파일**: `lib/features/todo/presentation/widgets/todo_list_view.dart`

**현재**: `TodoListView`에서 `_ScheduleSummaryBar` (이벤트/루틴/타이머 카운트) + `_HabitChecklistSection` (습관 체크리스트) + 투두 아이템 리스트를 표시한다.

**변경**: 기존 구조를 유지하되, "주간 루틴" 서브탭이 별도로 존재하므로 `TodoListView`에서 루틴 관련 요약 정보를 제거하거나, `_ScheduleSummaryBar`에서 루틴 카운트를 "주간 루틴 탭" 링크로 변경하는 방안을 검토한다.

현실적으로는 `TodoListView`의 `_ScheduleSummaryBar`에서 루틴 카운트를 유지하되, 탭 시 `weeklyRoutine` 서브탭으로 전환하는 인터랙션을 추가한다.

**`_ScheduleSummaryBar` 변경 사항**:

1. `_ScheduleSummaryBar`를 `ConsumerWidget`으로 변경한다 (현재 `StatelessWidget`)
2. 루틴 카운트 칩에 `GestureDetector`를 감싸서 탭 시 `todoSubTabProvider`를 `weeklyRoutine`으로 전환한다

```dart
// 변경: _ScheduleSummaryBar 내부 루틴 칩
if (routineCount > 0) ...[
  GestureDetector(
    onTap: () => ref.read(todoSubTabProvider.notifier).state =
        TodoSubTab.weeklyRoutine,
    child: _buildInfoChip(
      context,
      icon: Icons.repeat_rounded,
      label: '루틴 $routineCount',
    ),
  ),
  if (timerCount > 0) _buildDot(context),
],
```

---

## 7. 화면별 디자인 변경 상세

### 7.1 홈 탭 (lib/features/home/presentation/home_screen.dart)

**현재**: `HomeScreen`은 `CustomScrollView` 내에 `GreetingHeader` → `DdaySection` → `TodaySummarySection` → `TimerSummaryCard` → `TodoSummaryCard` → `HabitRoutineSummaryCard` → `GoalSummaryCard` 순서로 카드를 배치한다.

**변경**:
- 위젯 순서: 유지 (이미 변경 완료)
- `HabitRoutineSummaryCard`: 유지 (이미 합체 완료)
- 모든 카드의 데코레이션이 `ThemePresetData`의 `cardDecoration()`을 사용하므로, Refined Glass 프리셋의 토큰 변경만으로 자동 반영된다
- 카드 간 간격 `AppSpacing.xl` (16px) 유지

### 7.2 캘린더 탭

**대상 파일들**:
- `lib/features/calendar/presentation/widgets/calendar_header.dart`
- `lib/features/calendar/presentation/widgets/monthly_view.dart`
- `lib/features/calendar/presentation/widgets/weekly_view.dart`
- `lib/features/calendar/presentation/widgets/daily_view.dart`
- `lib/features/calendar/presentation/widgets/event_card.dart`

**변경**:
- `CalendarHeader`: 간소화 — 년/월 표시를 한 줄 컴팩트로 유지 (이미 `headingSm` 사용)
- `MonthlyView`: 드래그 핸들 + 루틴 체크박스 + 루틴 편집 연결 (5장 상세)
- `WeeklyView`/`DailyView`: 테마 프리셋 데코레이션 자동 반영
- `EventCard`: 테마 프리셋 데코레이션 자동 반영

### 7.3 투두 탭

**대상 파일들**:
- `lib/features/todo/presentation/todo_screen.dart`
- `lib/shared/widgets/date_slider.dart`
- `lib/features/todo/presentation/widgets/quick_input_bar.dart`
- `lib/shared/widgets/tag_filter_bar.dart`

**변경**:
- `DateSlider`: 테마 프리셋 색상 자동 반영 (이미 `context.themeColors` 사용)
- `QuickInputBar`: 테마 프리셋 색상 자동 반영
- 3개 서브탭 → `SegmentedControl` (6.1 상세)
- `TagFilterBar`: 테마 프리셋 색상 자동 반영

### 7.4 습관 탭 (lib/features/habit/presentation/habit_screen.dart)

**변경**:
- `_HabitHeader`: 레이아웃 유지, 서브탭 → `SegmentedControl<HabitSubTab>` 교체
- 습관 트래커 그리드: 테마 프리셋 데코레이션 자동 반영
- 습관 관리 리스트: 테마 프리셋 데코레이션 자동 반영

### 7.5 목표 탭 (lib/features/goal/presentation/goal_screen.dart)

**변경**:
- `_GoalScreenHeader`: 레이아웃 유지, 서브탭 → `SegmentedControl<GoalSubTab>` 교체
- 진행률 바: 테마 프리셋 색상 자동 반영 (`context.themeColors.accent`)
- 서브목표 리스트: 테마 프리셋 데코레이션 자동 반영

### 7.6 타이머 화면

**대상 파일들**:
- `lib/features/timer/presentation/timer_screen.dart`
- `lib/features/timer/presentation/widgets/timer_display.dart`
- `lib/features/timer/presentation/widgets/timer_log_list.dart`

**변경**:
- 원형 타이머: 테마 프리셋 악센트 색상 자동 반영
- 제어 버튼: FAB 디자인 통일 (3.3 상세)
- 히스토리 뷰: 테마 프리셋 데코레이션 자동 반영

### 7.7 업적 화면

**대상 파일**:
- `lib/features/achievement/presentation/achievement_screen.dart`
- `lib/features/achievement/presentation/widgets/achievement_card.dart`

**변경**:
- 업적 카드: 테마 프리셋 데코레이션 자동 반영

### 7.8 설정 화면 (lib/features/settings/presentation/settings_screen.dart)

**현재**: `SettingsThemeCard`에서 6개 테마 프리셋을 그리드로 표시한다.

**변경**:
- 테마 선택 UI를 6칸 그리드에서 3칸 그리드로 변경한다
- `SettingsThemeCard` → `ThemePreviewCard`에서 제거된 테마의 프리뷰 코드를 삭제한다
- `settings_theme_card.dart` + `theme_preview_card.dart` 수정

### 7.9 공유 위젯

**FloatingNavRail** (`lib/shared/widgets/main_shell.dart` 내부):
- `MainShell`의 네비게이션 레일 데코레이션이 `ThemePresetData`의 `bottomNavDecoration()`을 사용하므로 자동 반영된다

**DateSlider** (`lib/shared/widgets/date_slider.dart`):
- `context.themeColors` 사용 → 테마 프리셋 변경 시 자동 반영

**TagFilterBar** (`lib/shared/widgets/tag_filter_bar.dart`):
- `context.themeColors` 사용 → 테마 프리셋 변경 시 자동 반영

**GlobalActionBar** (`lib/shared/widgets/global_action_bar.dart`):
- `context.themeColors` 사용 → 테마 프리셋 변경 시 자동 반영

---

## 8. 파일 변경 영향도

### 8.1 신규 파일

| 파일 경로 | 용도 |
|---|---|
| `lib/shared/models/routine_log.dart` | RoutineLog 데이터 모델 |
| `lib/features/habit/providers/routine_log_provider.dart` | RoutineLog Provider 체인 |
| `lib/features/todo/presentation/widgets/routine_weekly_view.dart` | "주간 루틴" 서브탭 위젯 |
| `lib/shared/widgets/segmented_control.dart` | 공유 SegmentedControl 위젯 |
| `lib/features/habit/presentation/widgets/routine_edit_dialog.dart` | 루틴 편집 다이얼로그 (routine_create_dialog.dart와 같은 디렉토리) |

### 8.2 주요 수정 파일

| 파일 경로 | 변경 범위 |
|---|---|
| `lib/core/theme/theme_preset.dart` | enum 값 6개 → 3개 교체 |
| `lib/core/theme/theme_preset_registry.dart` | 3개 프리셋 데이터 재정의, 제거 프리셋 삭제 |
| `lib/core/theme/theme_preset_data.dart` | 구조 변경 없음 (호환) |
| `lib/core/theme/color_tokens.dart` | Refined Glass 그라디언트 토큰 추가, 제거 테마 프리뷰 색상 삭제 |
| `lib/core/theme/theme_colors.dart` | `isOnDarkBackground` 판단 기준 유지 (textPrimary luminance 기반) |
| `lib/core/theme/glassmorphism.dart` | 변경 없음 (프리셋에서 오버라이드) |
| `lib/core/theme/app_theme.dart` | 변경 없음 (MaterialThemeData는 프리셋 독립) |
| `lib/core/constants/app_constants.dart` | `routineLogsBox` 상수 추가 |
| `lib/core/cache/hive_initializer.dart` | `_openEncryptedBoxes()` + `clearAll()`에 `routineLogsBox` 추가 |
| `lib/features/todo/providers/todo_provider.dart` | `TodoSubTab` enum에 `weeklyRoutine` 추가 |
| `lib/features/todo/presentation/todo_screen.dart` | `_SubTabSwitcher` → `SegmentedControl` 교체, 3개 탭 분기 |
| `lib/features/habit/presentation/habit_screen.dart` | `_SubTabSwitcher` → `SegmentedControl` 교체 |
| `lib/features/goal/presentation/goal_screen.dart` | `_SubTabSwitcher` → `SegmentedControl` 교체 |
| `lib/features/calendar/presentation/widgets/monthly_view.dart` | 드래그 핸들 추가, `_RoutineInfoCard` StatelessWidget → ConsumerWidget 변경 + 체크박스/편집 연결 |
| `lib/features/todo/presentation/widgets/todo_list_view.dart` | `_ScheduleSummaryBar` StatelessWidget → ConsumerWidget 변경, 루틴 칩 탭 시 weeklyRoutine 서브탭 전환 |
| `lib/features/settings/presentation/settings_theme_card.dart` | 6칸 → 3칸 그리드 |
| `lib/features/settings/presentation/theme_preview_card.dart` | 제거 테마 프리뷰 코드 삭제 |
| `lib/shared/widgets/main_shell.dart` | 변경 없음 (테마 프리셋 자동 반영) |
| `lib/core/providers/global_providers.dart` | `themePresetProvider` 기존 문자열→신규 enum 매핑 함수 추가, 기본값 `refinedGlass`로 변경 |
| `lib/core/providers/data_store_providers.dart` | `routineLogDataVersionProvider` + `allRoutineLogsRawProvider` 추가, `bumpAllDataVersions()`에 루틴 로그 카운터 추가 |
| `lib/core/backup/backup_service.dart` | `backupAll()` boxNames + `restoreFromCloud()` allowedBoxes에 `routineLogsBox` 추가 |

### 8.3 삭제 코드

| 위치 | 내용 |
|---|---|
| `lib/core/theme/theme_preset.dart` | `minimal`, `retro`, `neon`, `soft` enum 값 |
| `lib/core/theme/theme_preset_registry.dart` | `_minimal()`, `_retro()`, `_neon()`, `_soft()` 메서드 |
| `lib/core/theme/color_tokens.dart` | `previewRetroBg`, `previewRetroBorder`, `previewRetroLine`, `previewNeonBg`, `previewSoftBg`, `previewSoftBorder`, `previewSoftLine` |
| `lib/features/settings/presentation/theme_preview_card.dart` | minimal/retro/neon/soft 프리뷰 분기 코드 |

---

## 9. 수용 기준 (Acceptance Criteria)

1. **기능 보존**: 모든 기존 기능(투두 CRUD, 습관 체크, 캘린더 이벤트, 목표 관리, 타이머, 업적, 백업, Google Calendar 연동)이 정상 동작한다
2. **테마 전환**: 3개 테마(Refined Glass, Clean Minimal, Dark Glass)가 정상 전환된다
3. **테마 마이그레이션**: Hive에 저장된 기존 테마 이름(glassmorphism, minimal, retro, neon, clean, soft)이 3개 신규 테마로 자동 매핑된다
4. **RoutineLog CRUD**: RoutineLog 생성/조회/삭제가 정상 동작하며 Hive 암호화 박스에 저장된다
5. **캘린더 드래그 핸들**: MonthlyView에서 드래그 핸들로 캘린더/리스트 비율을 부드럽게 조절할 수 있다
6. **루틴 편집**: MonthlyView의 `_RoutineInfoCard` 탭 시 `RoutineEditDialog`가 열리고, 저장이 정상 동작한다
7. **루틴 완료**: MonthlyView의 `_RoutineInfoCard` 체크박스로 루틴 완료/미완료 토글이 정상 동작한다
8. **투두 3 서브탭**: "일정표" / "주간 루틴" / "할 일" 3개 서브탭이 정상 전환된다
9. **주간 루틴 뷰**: 오늘 활성 루틴 목록이 올바르게 표시되고, 체크박스 완료가 RoutineLog와 연동된다
10. **SegmentedControl 통일**: 투두/습관/목표 3개 화면의 서브탭이 공유 `SegmentedControl` 위젯을 사용한다
11. **flutter analyze**: 경고 0건
12. **한국어 주석**: 100% 준수 (영어 주석 금지)
13. **WCAG 대비**: 모든 테마에서 텍스트/아이콘의 WCAG 4.5:1(텍스트) / 3:1(비텍스트) 대비 비율을 준수한다
14. **디자인 토큰**: 모든 색상/여백/반지름/애니메이션 값이 토큰 클래스를 통해 참조된다 (하드코딩 금지)
15. **백업 무결성**: BackupService의 백업/복원에 routineLogsBox가 포함되어 데이터 손실 없이 동작한다
16. **HiveInitializer 정합성**: routineLogsBox가 암호화 박스로 등록되고 clearAll()에도 포함된다

### 9.1 테스트 계획

#### 단위 테스트 (Unit Tests)

| 테스트 대상 | 테스트 항목 | 파일 위치 |
|---|---|---|
| `RoutineLog.fromMap()` | 정상 Map 파싱, 필드 누락 시 기본값, snake_case/camelCase 호환 | `test/shared/models/routine_log_test.dart` |
| `RoutineLog.toInsertMap()` | 'id' 필드 미포함 확인 (HabitLog 패턴 일치), 필수 필드 포함 확인 | 동일 파일 |
| `RoutineLog.copyWith()` | 불변 업데이트 확인 (isCompleted 토글) | 동일 파일 |
| `_migrateThemePreset()` | 6개 기존 문자열 → 3개 신규 enum 매핑 정확성 | `test/core/providers/global_providers_test.dart` |

#### Provider 테스트 (Provider Tests)

| 테스트 대상 | 테스트 항목 | 파일 위치 |
|---|---|---|
| `routineLogsForDayProvider` | 날짜 필터링 정확성, 빈 목록 처리 | `test/features/habit/providers/routine_log_provider_test.dart` |
| `routineCompletionProvider` | 특정 루틴+날짜 완료 여부 판단 | 동일 파일 |
| `toggleRoutineLogProvider` | 로그 생성(완료)/삭제(미완료) 토글, 버전 카운터 증가 확인 | 동일 파일 |
| `allRoutineLogsRawProvider` | 버전 카운터 변경 시 재평가 확인 | `test/core/providers/data_store_providers_test.dart` |

#### 위젯 테스트 (Widget Tests)

| 테스트 대상 | 테스트 항목 | 파일 위치 |
|---|---|---|
| `SegmentedControl` | 탭 렌더링 (2개/3개), 선택 상태 표시, onChanged 콜백 호출 | `test/shared/widgets/segmented_control_test.dart` |
| `RoutineWeeklyView` | 루틴 목록 표시, 체크박스 토글 인터랙션, 빈 상태 처리 | `test/features/todo/presentation/widgets/routine_weekly_view_test.dart` |
| `_RoutineInfoCard` (ConsumerWidget) | 체크박스 렌더링, 탭 시 편집 다이얼로그 호출 | `test/features/calendar/presentation/widgets/monthly_view_test.dart` |
