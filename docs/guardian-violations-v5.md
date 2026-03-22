# Guardian Violation Report v5 — Implementation Phase Monitoring

> 분석 일자: 2026-03-17
> Phase: Implementation (Chunk 1-6, 16 Tasks)
> 분석 목적: 구현 Phase 진입 시 기준선 확인 + 실시간 위반 추적
> 이전 보고서: v1, v2, v3, v4

---

## 요약

| 심각도 | 건수 | 설명 |
|--------|------|------|
| **P0** | 0 | 구현 미시작 — 아직 P0 위반 없음 |
| **P1** | 3 | 구현 시 반드시 충족해야 하는 전제조건 (V4에서 이관) |
| **P2** | 2 | 기존 미해결 위반 (V4에서 이관) |
| **감시 대상** | 7 | 구현 중 발생 가능한 위반 시나리오 |

---

## 구현 전 기준선 확인

### 1. 신규 파일 미존재 확인 (정상 — 구현 전이므로)

| 신규 파일 (계획) | 현재 상태 |
|---|---|
| `lib/shared/models/routine_log.dart` | 미존재 |
| `lib/features/habit/providers/routine_log_provider.dart` | 미존재 |
| `lib/shared/widgets/segmented_control.dart` | 미존재 |
| `lib/features/todo/presentation/widgets/routine_weekly_view.dart` | 미존재 |
| `lib/features/habit/presentation/widgets/routine_edit_dialog.dart` | 미존재 |

### 2. 기존 파일 기준선

| 파일 | 현재 줄 수 | 변경 예정 |
|---|---|---|
| `lib/core/theme/theme_preset.dart` | 25줄 (6 enum) | enum 3개로 축소 |
| `lib/core/theme/theme_preset_registry.dart` | 965줄 | 3개 프리셋만 유지 (축소 예상) |
| `lib/core/providers/global_providers.dart` | 88줄 | _migrateThemePreset() 추가 |
| `lib/core/providers/data_store_providers.dart` | 145줄 | routineLog 버전 카운터 + raw provider 추가 |
| `lib/core/constants/app_constants.dart` | 196줄 | routineLogsBox + settingsKeyCalendarRatio 추가 |
| `lib/core/cache/hive_initializer.dart` | 148줄 | routineLogsBox 암호화 박스 등록 |
| `lib/core/backup/backup_service.dart` | 405줄 | routineLogsBox 백업/복원 범위 추가 |
| `lib/features/todo/providers/todo_provider.dart` | ~300줄+ | TodoSubTab enum 3개로 확장 |
| `lib/features/todo/presentation/todo_screen.dart` | 391줄 | SegmentedControl 교체 + 3서브탭 |
| `lib/features/calendar/presentation/widgets/monthly_view.dart` | 373줄 | 드래그 핸들 + 루틴 체크박스 |
| `lib/features/habit/presentation/habit_screen.dart` | 180줄 | SegmentedControl 교체 |
| `lib/features/goal/presentation/goal_screen.dart` | 278줄 | SegmentedControl 교체 |

### 3. 5탭 구조 확인 (CRITICAL — 정상)

`app_router.dart`에 `StatefulShellRoute.indexedStack` + 5개 `StatefulShellBranch` 확인 완료.
풀스크린 라우트 3개 (/timer, /achievements, /tag-management) 확인 완료.

### 4. TodoSubTab 현재 상태 (2개 — 확장 예정)

```dart
enum TodoSubTab { dailySchedule, todoList }
```

### 5. ThemePreset 현재 상태 (6개 — 축소 예정)

```dart
enum ThemePreset { glassmorphism, minimal, retro, neon, clean, soft }
```

### 6. routineLogsBox 미등록 확인

`lib/` 전체에서 `routineLogsBox` 문자열 검색 결과: 0건 (정상 — 미구현)

---

## P1 미해결 위반 (V4에서 이관 — 구현 Phase에서 해결 필수)

### [V5-001] P1: RoutineLog 모델 미구현 (V4-001 이관)

- **현재 상태**: OPEN (구현 대기)
- **해결 시점**: Task 1 (Chunk 1)
- **승격 조건**: Task 1 완료 후에도 미해결 시 → P0 승격

### [V5-002] P1: 투두 서브탭 2개→3개 미확장 (V4-002 이관)

- **현재 상태**: OPEN (구현 대기)
- **해결 시점**: Task 12-13 (Chunk 5)
- **승격 조건**: Chunk 5 완료 후에도 미해결 시 → P0 승격

### [V5-003] P1: 테마 6개→3개 미축소 (V4-003 이관)

- **현재 상태**: OPEN (구현 대기)
- **해결 시점**: Task 4-7 (Chunk 2)
- **승격 조건**: Chunk 2 완료 후에도 미해결 시 → P0 승격

---

## P2 미해결 위반 (V4에서 이관)

### [V5-004] P2: 파일 크기 300줄 초과 (V4-004 이관)

상위 5개:
1. `theme_preset_registry.dart`: 965줄
2. `layout_tokens.dart`: 770줄
3. `daily_schedule_view.dart`: 737줄
4. `tag_management_screen.dart`: 731줄
5. `event_provider.dart`: 670줄

**참고**: theme_preset_registry.dart는 Chunk 2에서 6개→3개로 축소되므로 자연스럽게 줄 수 감소 예상.

### [V5-005] P2: catch(_) 에러 삼킴 패턴 8곳 (V4-005 이관)

- `tag_provider.dart:49`
- `routine.dart:97`
- `goal_provider.dart:291,341,421`
- `auth_service.dart:110`
- `auth_provider.dart:52`
- `habit_provider.dart:255`

---

## 구현 Phase 감시 항목

구현 중 다음 시나리오가 발생하면 즉시 개입한다:

### W-001: 5탭 구조 변경 감시

`app_router.dart`에서 `StatefulShellBranch` 5개가 유지되는지 확인.
삭제/추가 시 → P0 즉시 보고.

### W-002: RoutineLog.toInsertMap에 'id' 포함 감시

HabitLog 패턴과 불일치 시 → P0 즉시 보고.
`toInsertMap` 반환 Map에 `'id'` 키가 포함되면 안 된다.

### W-003: ThemePreset 마이그레이션 누락 감시

기존 6개 프리셋 문자열 → 3개 신규 enum 매핑이 누락되면 → P0 보고.
특히 'retro', 'soft' → refinedGlass 폴백이 필수.

### W-004: 기존 기능 삭제/변경 감시

dailySchedule, todoList 서브탭의 기존 기능이 유지되는지 확인.
투두 CRUD, 캘린더 이벤트, 습관 체크, 목표 관리, 타이머, 업적, 백업 기능이 모두 보존되는지 감시.

### W-005: 한국어 주석 위반 감시

신규 생성 파일에서 영어 주석이 발견되면 → P1 보고.

### W-006: 우회 패턴 도입 감시

`@ts-ignore`, `as dynamic`, `catch (_) {}` (빈 catch), `// ignore:` 등 신규 우회 패턴 도입 시 → P1 보고.

### W-007: 파일 크기 증가 감시

구현으로 인해 기존 파일이 300줄을 초과하거나, 이미 초과한 파일이 더 증가하면 → P2 보고.
특히:
- `monthly_view.dart` (373줄 → 드래그 핸들/체크박스 추가로 증가 예상)
- `todo_screen.dart` (391줄 → 3서브탭 추가로 증가 예상)
- `todo_list_view.dart` (441줄 → 카테고리 그룹화로 증가 예상)

---

## 워크아웃 패턴 스캔 결과 (기준선)

| 패턴 | 검출 수 | 상태 |
|-------|---------|------|
| `@ts-ignore` / `@ts-expect-error` | 0 | PASS |
| `eslint-disable` / `noqa` | 0 | PASS |
| `as dynamic` | 0 | PASS |
| `!important` | 0 | PASS |
| 순수 무채색 (#000000 등) | 0 | PASS (주석 내 설명만 검출) |
| `debugPrint` (V3-006) | 1 | 기존 위반 (미해결) |
| `catch (_)` 에러 삼킴 | 8 | 기존 위반 (V5-005) |

---

## Guardian Phase 진입 체크리스트

- [x] 사용자 원래 요구사항 100% 기록 (docs/guardian-requirements.md 업데이트)
- [x] 모든 CLAUDE.md Non-negotiable 규칙 확인
- [x] 기준선 파일 상태 스냅샷 완료
- [x] P0 미해결 위반 없음 (구현 미시작)
- [ ] P1 미해결 위반 3건 — 구현 Chunk 1, 2, 5에서 해결 예정
- [x] 감시 항목 7건 설정 완료
- [x] docs/guardian-requirements.md 업데이트 완료

## Guardian 판정

**구현 Phase 진입 허가.**

P1 3건(V5-001, V5-002, V5-003)은 구현 계획(Task 1-7, 12-13)에 명시적으로 포함되어 있으므로
구현 Phase 진입을 차단하지 않는다. 다만, 각 Chunk 완료 시점에서 해결 여부를 확인한다.

**구현 중 실시간 모니터링 개시:**
- Chunk 1 완료 후 → V5-001 해결 확인
- Chunk 2 완료 후 → V5-003 해결 확인
- Chunk 5 완료 후 → V5-002 해결 확인
- 전체 완료 후 → 최종 검증 (flutter analyze, 기능 보존, 한국어 주석, SRP)
