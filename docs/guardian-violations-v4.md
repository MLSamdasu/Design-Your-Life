# Guardian Violation Report v4 — Pre-Implementation Baseline

> 분석 일자: 2026-03-17
> 분석 범위: lib/ 전체 (features/, shared/, core/)
> 분석 목적: 사용자 요구사항 9건에 대한 사전 정합성 검증 + 구현 Phase 진입 전 기준선 설정
> Phase: Pre-Implementation (설계 문서 작성)

---

## 요약

| 심각도 | 건수 | 설명 |
|--------|------|------|
| **P0** | 0 | 현재 Phase에서는 코드 변경이 없으므로 P0 없음 |
| **P1** | 3 | 구현 시 반드시 준수해야 할 구조적 요구사항 |
| **P2** | 2 | 기존 코드의 지속적 위반 (이전 보고서에서 미해결) |
| **INFO** | 5 | 기준선 정보 (위반 아님, 변경 추적용) |

---

## P1 위반 (구현 Phase 진입 시 즉시 반영 필요)

### [V4-001] P1: RoutineLog 모델 미구현 — 요구사항 #3 구현 전제조건 미충족

- **심각도**: P1
- **위반 유형**: 요구사항 전제조건 미충족
- **위반 상세**:
  사용자 요구사항 #3 "루틴 일일 완료 체크박스 (RoutineLog 모델, HabitLog 패턴)"를 구현하려면
  RoutineLog 모델과 routineLogsBox Hive 박스가 필요하다.
  
  현재 상태:
  - `RoutineLog` 모델: **미존재** (lib/shared/models/ 에 없음)
  - `routineLogsBox` Hive 박스: **미존재** (AppConstants에 정의 없음, HiveInitializer에 등록 없음)
  - RoutineLogRepository: **미존재**
  - routineLogProvider: **미존재**
  
  HabitLog 패턴 참조:
  - `lib/shared/models/habit_log.dart` — id, habitId, date, isCompleted, checkedAt
  - `lib/features/habit/services/habit_log_repository.dart`
  - `lib/features/habit/providers/habit_provider.dart` (habitLogsForDateProvider 등)
  
- **수정 지시**: 구현 Phase에서 다음을 생성해야 한다:
  1. `lib/shared/models/routine_log.dart` — RoutineLog 모델 (HabitLog 패턴 복사)
  2. `lib/core/constants/app_constants.dart` — `routineLogsBox` 상수 추가
  3. `lib/core/cache/hive_initializer.dart` — routineLogsBox 박스 등록 + AES-256 암호화
  4. `lib/features/habit/services/routine_log_repository.dart` — CRUD 작업
  5. Provider 추가 (routineLogsForDateProvider 등)
  6. `lib/core/backup/backup_service.dart` — 백업/복원에 routineLogsBox 포함
- **상태**: OPEN (구현 Phase 대기)

---

### [V4-002] P1: 투두 서브탭 구조 변경 필요 — 현재 2개 → 요구사항 3개

- **심각도**: P1
- **위반 유형**: 요구사항 정합성 (현재 구조와 요구 구조 불일치)
- **위반 상세**:
  사용자 요구사항 #9 "투두 서브탭 3개로 확장: 일정표 / 주간 루틴 / 할 일"
  
  현재 상태:
  - `enum TodoSubTab { dailySchedule, todoList }` (2개)
  - 위치: `lib/features/todo/providers/todo_provider.dart:37-43`
  - TodoScreen의 _SubTabSwitcher에서 2탭 UI 렌더링
  
  변경 필요:
  - `enum TodoSubTab { dailySchedule, weeklyRoutine, todoList }` (3개로 확장)
  - "주간 루틴" 서브탭 UI 신규 구현 필요
  - _SubTabSwitcher에서 3탭 렌더링
  - 주간 루틴 뷰 위젯 신규 생성 필요

- **관련 파일**:
  - `lib/features/todo/providers/todo_provider.dart:37-43` (TodoSubTab enum)
  - `lib/features/todo/presentation/todo_screen.dart:136,147-155` (_SubTabSwitcher + AnimatedSwitcher)
- **수정 지시**: 구현 Phase에서 enum 확장 + 주간 루틴 뷰 위젯 + 서브탭 전환 로직 구현
- **상태**: OPEN (구현 Phase 대기)

---

### [V4-003] P1: 테마 6개 → 3개 축소 필요 — 현재 구조 변환 계획 필요

- **심각도**: P1
- **위반 유형**: 요구사항 정합성 (현재 구조와 요구 구조 불일치)
- **위반 상세**:
  사용자 요구사항 #8 "테마를 6개에서 3개로 축소: 기본(Refined Glass), 깔끔함(Content-First Minimal), 다크(Dark Glass)"
  
  현재 상태:
  - `enum ThemePreset { glassmorphism, minimal, retro, neon, clean, soft }` (6개)
  - 위치: `lib/core/theme/theme_preset.dart`
  - ThemePresetRegistry에 6개 프리셋 팩토리 메서드 (theme_preset_registry.dart, 965줄)
  - settingsBox에 ThemePreset.name 문자열로 저장
  - 설정 화면에서 6개 프리셋 선택 UI
  
  변경 필요:
  - enum을 3개로 축소: `{ refinedGlass, contentFirstMinimal, darkGlass }`
  - ThemePresetRegistry에서 3개만 유지 (retro, neon, soft 제거)
  - [CRITICAL] 기존 settingsBox에 저장된 테마 프리셋 값 마이그레이션 필요
    - 'retro' → 매핑할 기본값 필요 (예: refinedGlass)
    - 'neon' → 매핑할 기본값 필요 (예: darkGlass)
    - 'soft' → 매핑할 기본값 필요 (예: contentFirstMinimal)
    - 'glassmorphism' → refinedGlass
    - 'minimal' → contentFirstMinimal (또는 신규 매핑)
    - 'clean' → contentFirstMinimal (또는 신규 매핑)
  - 설정 화면에서 3개만 표시

- **관련 파일**:
  - `lib/core/theme/theme_preset.dart` (enum 정의)
  - `lib/core/theme/theme_preset_registry.dart` (프리셋 데이터, 965줄)
  - `lib/features/settings/presentation/settings_theme_card.dart` (테마 선택 UI)
  - `lib/features/settings/presentation/theme_preview_card.dart` (테마 미리보기)
  - `lib/core/theme/app_theme.dart` (ThemeData 생성)
- **수정 지시**:
  1. ThemePreset enum을 3개 값으로 축소
  2. 레거시 프리셋 이름 → 새 프리셋으로 폴백 매핑 로직 추가 (기존 사용자 데이터 보호)
  3. ThemePresetRegistry에서 제거된 프리셋의 팩토리 메서드 삭제
  4. 설정 UI 3개 프리셋만 표시
- **상태**: OPEN (구현 Phase 대기)

---

## P2 위반 (기존 미해결 — 이전 보고서에서 계속)

### [V4-004] P2: 파일 크기 300줄 초과 — 25개+ 파일 (v1-004, v3-001 연속)

- **심각도**: P2
- **위반 유형**: SRP / 파일 크기 규칙 위반
- **위반 상세**: 이전 보고서(v1, v3)에서 보고된 25개+ 파일의 300줄 초과 문제가 미해결 상태이다.
  이번 디자인 전면 수정으로 파일 크기가 더 증가하거나 새로운 대형 파일이 생성될 위험이 있다.
  
  상위 5개:
  1. `theme_preset_registry.dart`: 965줄
  2. `layout_tokens.dart`: 770줄
  3. `daily_schedule_view.dart`: 737줄
  4. `tag_management_screen.dart`: 731줄
  5. `event_provider.dart`: 670줄

- **수정 지시**: 디자인 전면 수정 시 파일 분리를 병행할 것. 특히 theme_preset_registry는 6개→3개로 축소되므로 자연스럽게 크기가 줄어야 한다.
- **상태**: OPEN (지속)

---

### [V4-005] P2: catch(_) 에러 삼킴 패턴 — 8곳 (v3-007~012 연속)

- **심각도**: P2
- **위반 유형**: 에러 삼킴 (workaround 인접)
- **위반 상세**: 8곳에서 `catch (_)` 패턴으로 에러를 삼키고 있다:
  - `tag_provider.dart:49`
  - `routine.dart:97`
  - `goal_provider.dart:291,341,421`
  - `auth_service.dart:110`
  - `auth_provider.dart:52`
  - `habit_provider.dart:255`
- **상태**: OPEN (지속)

---

## INFO (기준선 정보 — 위반 아님, 변경 추적용)

### [INFO-001] 현재 5탭 구조 기준선

app_router.dart에서 StatefulShellRoute.indexedStack으로 5개 StatefulShellBranch가 정의됨:
- 탭 0: HomeScreen (/home)
- 탭 1: CalendarScreen (/calendar)
- 탭 2: TodoScreen (/todo)
- 탭 3: HabitScreen (/habit)
- 탭 4: GoalScreen (/goal)

풀스크린 라우트 3개: /timer, /achievements, /tag-management

**이 구조는 구현 Phase에서 변경되면 안 된다.** (CRITICAL 요구사항)

### [INFO-002] 현재 TodoSubTab 기준선

`lib/features/todo/providers/todo_provider.dart:37-43`:
```dart
enum TodoSubTab {
  dailySchedule,
  todoList,
}
```
→ 3개로 확장 예정 (V4-002 참조)

### [INFO-003] 현재 ThemePreset 기준선

`lib/core/theme/theme_preset.dart`:
```dart
enum ThemePreset {
  glassmorphism, minimal, retro, neon, clean, soft,
}
```
→ 3개로 축소 예정 (V4-003 참조)

### [INFO-004] 현재 HabitLog 모델 기준선 (RoutineLog 참조 패턴)

`lib/shared/models/habit_log.dart`:
- 필드: id, habitId, date, isCompleted, checkedAt
- fromMap: snake_case + camelCase 폴백
- toInsertMap: user_id, habit_id, log_date, is_completed, completed_at
- Hive Box: habitLogsBox (암호화)

### [INFO-005] 현재 Routine 모델에 일일 완료 상태 없음

`lib/shared/models/routine.dart`:
- Routine 모델에 isCompleted, completedAt 같은 일일 완료 추적 필드가 없다.
- Routine은 정의(definition) 모델이고, 일일 완료 로그는 별도 RoutineLog 모델이 필요하다.
- 이는 Habit(정의) + HabitLog(일일 기록) 패턴과 동일하다.

---

## Guardian Phase 완료 체크리스트

- [x] 사용자 원래 요구사항 100% 기록
- [x] 모든 CLAUDE.md Non-negotiable 규칙 확인
- [x] 현재 Phase 목표 달성 (기준선 설정 완료)
- [x] P0 미해결 위반 없음
- [ ] P1 미해결 위반 3건 — 구현 Phase에서 해결 예정 (현재 Phase는 설계 단계이므로 차단하지 않음)
- [x] 다음 Phase로 전달할 정보 완비 (기준선, 변경 범위, 주의사항)
- [x] docs/guardian-requirements.md 업데이트 완료

## Guardian 판정

**현재 Phase (Pre-Implementation)에서는 코드 변경이 없으므로 P0 위반은 없다.**

P1 3건(V4-001, V4-002, V4-003)은 구현 Phase에서 반드시 해결해야 하는 구조적 전제조건이다.
이 3건이 구현 Phase 초기에 해결되지 않으면 즉시 P0으로 격상하고 작업을 중단한다.

**구현 Phase 진입 시 특별 감시 항목:**
1. 5탭 구조가 유지되는지 (app_router.dart의 StatefulShellBranch 5개)
2. RoutineLog 모델이 HabitLog 패턴을 정확히 따르는지
3. 테마 축소 시 기존 사용자 데이터(settingsBox의 프리셋 이름)가 마이그레이션되는지
4. 투두 서브탭 확장이 기존 dailySchedule/todoList 기능에 영향을 주지 않는지
5. 디자인 전면 수정 시 기존 기능 로직이 변경되지 않는지 (UI만 변경)
6. 한국어 주석 규칙 준수
7. SRP 기반 파일 크기 제한 (200줄/파일, 150줄/컴포넌트)
8. AES-256 암호화가 신규 routineLogsBox에도 적용되는지
