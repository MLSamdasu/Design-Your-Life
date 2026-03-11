# Design Your Life - 보안 및 안정성 분석

> 작성자: spec-security
> 작성일: 2026-03-09
> 대상: Flutter Web + Android 생산성 앱 (Firebase 백엔드)

---

## 1. 위협 모델 (Threat Model)

### 1.1 공격 표면 정의

| 공격 표면 | 위협 행위자 | 주요 위협 |
|---|---|---|
| Firebase Auth (Google OAuth) | 외부 공격자, 세션 탈취자 | 토큰 탈취, 세션 하이재킹, OAuth 리다이렉트 조작 |
| Cloud Firestore | 인증된 악의적 사용자 | 타 사용자 데이터 접근, 규칙 우회, 대량 읽기/쓰기 남용 |
| Flutter Web (브라우저) | XSS 공격자, CSRF 공격자 | 스크립트 인젝션, DOM 조작, 쿠키/토큰 탈취 |
| Android APK | 리버스 엔지니어링, 루팅 기기 | API 키 추출, 코드 변조, 로컬 DB 탈취 |
| Hive 로컬 캐시 | 물리적 접근자, 루팅 기기 | 캐시 데이터 평문 노출, 민감 정보 유출 |
| Firebase Hosting | 네트워크 공격자 | MITM, 헤더 조작, 리소스 변조 |
| 네트워크 전송 구간 | MITM 공격자 | 데이터 스니핑, 토큰 인터셉트 |

### 1.2 위험 등급 분류 기준

- **Critical**: 타 사용자 데이터 접근, 인증 우회, 전체 시스템 장애
- **High**: 데이터 유실, 세션 탈취, 개인정보 유출
- **Medium**: 부분적 데이터 불일치, 성능 저하, 제한적 정보 노출
- **Low**: UI 깨짐, 비기능적 엣지 케이스, 사용성 저하

---

## 2. Firebase Security Rules

### 2.1 필수 보안 규칙 구조 [Critical]

Firestore 보안 규칙은 이 앱의 보안 경계선 그 자체이다. Firebase는 서버리스 아키텍처이므로 별도의 백엔드 미들웨어가 존재하지 않는다. 따라서 Firestore Rules가 곧 유일한 서버 측 인가(Authorization) 레이어이다.

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // 기본 정책: 전부 거부
    match /{document=**} {
      allow read, write: if false;
    }

    // 사용자 데이터: 본인만 접근 가능
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;
    }
  }
}
```

### 2.2 필수 검증 사항

| 항목 | 위험 등급 | 요구사항 |
|---|---|---|
| 와일드카드 매칭 범위 | Critical | `{document=**}` 재귀 매칭이 `users/{userId}/` 하위 전체를 정확히 커버하는지 검증한다 |
| 기본 거부 정책 | Critical | 최상위에 `allow read, write: if false;`를 반드시 선언한다. 화이트리스트 방식으로 운영한다 |
| userId 일치 검증 | Critical | `request.auth.uid == userId` 조건이 모든 하위 컬렉션에 일관 적용되는지 확인한다 |
| 필드 레벨 유효성 검사 | High | 문서 생성/수정 시 필수 필드 존재 여부와 타입을 규칙 내에서 검증한다 |
| 문서 크기 제한 | Medium | `request.resource.data.size()` 등으로 과도한 데이터 쓰기를 방지한다 |

### 2.3 컬렉션별 세부 규칙 권고

#### events 컬렉션
```
match /users/{userId}/events/{eventId} {
  allow create: if request.auth.uid == userId
                && request.resource.data.keys().hasAll(['title', 'type', 'startDate'])
                && request.resource.data.title is string
                && request.resource.data.title.size() > 0
                && request.resource.data.title.size() <= 200
                && request.resource.data.type in ['normal', 'range', 'recurring', 'todo'];
  allow update: if request.auth.uid == userId
                && request.resource.data.title is string
                && request.resource.data.title.size() > 0
                && request.resource.data.title.size() <= 200;
  allow read, delete: if request.auth.uid == userId;
}
```

#### habitLogs 컬렉션 (시간 잠금 관련) [High]
```
match /users/{userId}/habitLogs/{logId} {
  allow create: if request.auth.uid == userId
                && request.resource.data.date is string
                // 서버 타임스탬프와 비교하여 미래 날짜 기록 방지
                && request.resource.data.keys().hasAll(['habitId', 'date', 'completed']);
  allow update: if request.auth.uid == userId
                // 과거일 수정 방지 로직은 Cloud Function에서 처리 권고
                && request.resource.data.completed is bool;
  allow read, delete: if request.auth.uid == userId;
}
```

### 2.4 보안 규칙 테스트 전략 [Critical]

- Firebase Emulator Suite를 사용하여 모든 규칙을 단위 테스트한다.
- 테스트 시나리오 목록:
  1. 인증 없이 접근 시 거부 확인
  2. 인증된 사용자가 타 사용자 문서 접근 시 거부 확인
  3. 인증된 사용자가 본인 문서 CRUD 성공 확인
  4. 잘못된 필드 타입으로 생성 시 거부 확인
  5. 필수 필드 누락 시 거부 확인
  6. 과도한 크기의 문자열 필드 거부 확인

---

## 3. 인증/인가 (Authentication & Authorization)

### 3.1 Google OAuth 플로우 보안 [Critical]

| 위협 | 위험 등급 | 대응 전략 |
|---|---|---|
| OAuth 리다이렉트 URI 조작 | Critical | Firebase Console에서 승인된 도메인만 허용한다. localhost, 프로덕션 도메인을 명시적으로 등록하고 와일드카드 도메인은 절대 사용하지 않는다 |
| CSRF on OAuth callback | High | Firebase Auth SDK가 내부적으로 state 파라미터를 관리하므로 SDK를 우회하는 커스텀 구현을 금지한다 |
| ID 토큰 위조 | Critical | 클라이언트 측에서 토큰을 직접 검증하지 않는다. Firestore Rules가 서버 측에서 `request.auth`를 통해 자동 검증한다 |

### 3.2 세션 관리 [High]

**Firebase Auth 토큰 생명주기:**
- ID 토큰 유효기간: 1시간 (자동 갱신)
- Refresh 토큰 유효기간: 무기한 (명시적 해지 전까지)
- Firebase Auth SDK가 자동으로 토큰 갱신을 처리한다

**보안 요구사항:**

| 항목 | 요구사항 |
|---|---|
| 토큰 저장 위치 (Web) | `indexedDB`에 저장된다 (Firebase SDK 기본값). `localStorage` 변경 금지. `Persistence.LOCAL` 사용 시 보안 영향을 인지한다 |
| 토큰 저장 위치 (Android) | Android Keystore에 의해 보호된다 (Firebase SDK 기본 동작) |
| 세션 해지 | 사용자 비밀번호 변경, 계정 비활성화, 계정 삭제 시 Firebase가 자동으로 Refresh 토큰을 해지한다. 추가로 관리자가 `revokeRefreshTokens()`를 호출할 수 있다 |
| Auth State 변경 감지 | `authStateChanges()` 스트림을 Riverpod Provider로 감싸서 앱 전역에서 반응형으로 인증 상태를 관리한다 |
| 로그아웃 처리 | 로그아웃 시 (1) Firebase signOut (2) Hive 캐시 클리어 (3) Riverpod 상태 초기화 순서를 반드시 지킨다 |

### 3.3 비인가 접근 방지 [Critical]

- GoRouter의 `redirect` 로직에서 인증 상태를 검사한다. 미인증 사용자는 로그인 화면으로 리다이렉트한다.
- 주의: GoRouter redirect는 클라이언트 측 가드일 뿐이다. 실제 데이터 보호는 Firestore Rules에 의존해야 한다. 클라이언트 가드를 우회해도 데이터가 안전해야 한다.
- Flutter Web에서 URL 직접 입력으로 보호된 경로 접근 시도에 대한 방어가 필요하다.

```dart
// GoRouter redirect 예시 구조
redirect: (context, state) {
  final isLoggedIn = ref.read(authProvider).isLoggedIn;
  final isLoginRoute = state.matchedLocation == '/login';

  if (!isLoggedIn && !isLoginRoute) return '/login';
  if (isLoggedIn && isLoginRoute) return '/';
  return null;
}
```

### 3.4 다중 기기/탭 세션 [Medium]

- Firebase Auth는 다중 기기/탭 동시 로그인을 기본 허용한다.
- 한 기기에서 로그아웃해도 다른 기기의 세션은 유지된다 (Refresh Token이 별도이므로).
- 전체 기기 로그아웃이 필요한 경우 `revokeRefreshTokens()` + 최대 1시간 대기 (ID 토큰 만료) 또는 Firestore Rules에서 `auth.token.auth_time` 검증을 추가한다.

---

## 4. 데이터 보호

### 4.1 입력값 검증 및 새니타이징 [High]

모든 사용자 입력 필드에 대해 클라이언트 + 서버(Firestore Rules) 양측에서 검증한다.

| 입력 필드 | 최대 길이 | 허용 문자 | 추가 검증 |
|---|---|---|---|
| 일정 제목 (event title) | 200자 | UTF-8 전체 | 공백만 입력 불가 |
| 투두 이름 (todo name) | 200자 | UTF-8 전체 | 공백만 입력 불가 |
| 습관 이름 (habit name) | 100자 | UTF-8 전체 | 공백만 입력 불가 |
| 목표 이름 (goal name) | 200자 | UTF-8 전체 | 공백만 입력 불가 |
| 목표 설명 (description) | 1000자 | UTF-8 전체 | 선택 필드 |
| 메모 (memo) | 2000자 | UTF-8 전체 | 선택 필드 |
| 위치 (location) | 200자 | UTF-8 전체 | 선택 필드 |
| 사용자 이름 (displayName) | 50자 | UTF-8 전체, 특수기호 제한 | 공백만 입력 불가 |
| 색상 값 | 고정 enum | 사전 정의된 8색 중 선택 | 자유 입력 불가, 서버에서도 enum 검증 |

**클라이언트 측 검증:**
- `TextEditingController`에 `maxLength` 제한을 설정한다.
- `TextFormField`의 `validator`에서 필수값/포맷 검증한다.
- `.trim()` 적용 후 빈 문자열 검사를 수행한다.

**서버 측 검증 (Firestore Rules):**
- `request.resource.data.title.size() <= 200` 등 길이 제한을 적용한다.
- `request.resource.data.type in ['normal', 'range', 'recurring', 'todo']` 등 enum 검증을 적용한다.
- 타입 검사: `is string`, `is bool`, `is number`, `is timestamp` 등을 반드시 적용한다.

### 4.2 XSS 방지 (Flutter Web) [High]

Flutter Web은 Canvas 렌더링(CanvasKit) 또는 HTML 렌더링 두 가지 모드를 지원한다.

- **CanvasKit 렌더러 (권장)**: 모든 UI를 Canvas에 그린다. DOM을 직접 조작하지 않으므로 전통적인 DOM 기반 XSS에 대해 구조적으로 안전하다.
- **HTML 렌더러**: `dart:html`을 사용하여 DOM 요소를 생성한다. `HtmlElementView`나 `IFrameElement` 사용 시 XSS 위험이 존재한다.

**보안 요구사항:**

| 항목 | 위험 등급 | 요구사항 |
|---|---|---|
| 렌더러 선택 | High | 프로덕션 빌드에서 CanvasKit 렌더러를 사용한다. `--web-renderer canvaskit` 플래그를 명시한다 |
| dart:html 사용 금지 | High | `dart:html`의 `innerHtml`, `setInnerHtml` 등 직접 DOM 조작을 금지한다 |
| URL 처리 | Medium | `url_launcher` 패키지 사용 시 `launchUrl`에 전달되는 URL을 검증한다. `javascript:` 스킴을 차단한다 |
| 사용자 입력 표시 | Medium | 사용자가 입력한 텍스트를 Flutter의 `Text` 위젯으로만 표시한다. `Html` 위젯 등으로 렌더링하지 않는다 |

### 4.3 Hive 로컬 캐시 보안 [Medium]

| 항목 | 위험 등급 | 요구사항 |
|---|---|---|
| 암호화 적용 | Medium | Hive 4.x의 암호화 기능을 사용한다. 256-bit AES 키를 `flutter_secure_storage`에 저장하고, 해당 키로 Hive Box를 암호화한다 |
| 캐시 데이터 범위 | Medium | 캐시에는 UI 상태와 최근 조회 데이터만 저장한다. 인증 토큰, API 키 등 민감 정보는 캐시에 저장하지 않는다 |
| 캐시 무효화 | Low | 로그아웃 시 모든 Hive Box를 `deleteFromDisk()`로 완전 삭제한다. `clear()`만으로는 불충분할 수 있다 |
| Web 환경 캐시 | Medium | Flutter Web에서 Hive는 IndexedDB를 사용한다. 브라우저 개발자 도구로 접근 가능하므로 민감 데이터 저장을 최소화한다 |

### 4.4 Firestore 데이터 전송 보안 [Low]

- Firestore SDK는 기본적으로 TLS(HTTPS)를 통해 데이터를 전송한다. 추가 설정이 불필요하다.
- gRPC 기반 통신이므로 별도의 암호화 레이어를 구현할 필요가 없다.

---

## 5. 엣지 케이스 및 에러 핸들링

### 5.1 네트워크 단절 시 쓰기 작업 [High]

| 시나리오 | 위험 등급 | 대응 전략 |
|---|---|---|
| 투두 생성 중 네트워크 끊김 | High | Firestore 오프라인 지속성(Offline Persistence)을 활성화한다. 로컬에 쓰기 후 네트워크 복구 시 자동 동기화된다 |
| 습관 체크 중 네트워크 끊김 | High | 동일하게 오프라인 지속성으로 처리한다. UI에 오프라인 상태 표시(배너/아이콘)를 추가한다 |
| 목표 삭제 중 네트워크 끊김 | Medium | 삭제 작업은 오프라인 큐에 적재된다. 복구 시 자동 실행되지만, 중간에 다른 기기에서 해당 문서를 수정한 경우 충돌 가능성이 있다 |
| 장기간 오프라인 후 대량 동기화 | Medium | Firestore 오프라인 캐시 기본 크기(40MB)를 인지하고, 초과 시 가장 오래된 캐시부터 제거된다. 사용자에게 오프라인 기간이 길어지면 데이터 동기화 지연 가능성을 안내한다 |

**필수 구현:**
- `Stream<ConnectivityResult>`를 감시하여 네트워크 상태를 실시간 표시한다.
- 오프라인 상태에서 저장된 변경 사항에 대해 "동기화 대기 중" 표시를 한다.
- Firestore `waitForPendingWrites()`를 사용하여 모든 로컬 변경이 서버에 반영되었는지 확인할 수 있는 메커니즘을 제공한다.

### 5.2 동시 편집 (다중 탭/기기) [High]

이 앱은 다중 기기 사용 시나리오가 충분히 발생한다 (Web + Android 동시 사용).

| 시나리오 | 위험 등급 | 대응 전략 |
|---|---|---|
| 같은 투두를 두 기기에서 동시 수정 | High | Firestore는 Last-Write-Wins 정책을 적용한다. 후순위 쓰기가 먼저 쓰기를 덮어쓴다. 이를 사용자에게 명확히 인지시키거나, 중요한 필드에 대해 `FieldValue.increment()` 등 원자적 연산을 사용한다 |
| 같은 습관을 두 기기에서 동시 체크 | Medium | `habitLogs` 문서 ID를 `{habitId}_{date}` 형태로 구성하여 동일 날짜에 중복 문서가 생성되지 않도록 한다 |
| 한 기기에서 삭제한 데이터를 다른 기기에서 수정 | Medium | Firestore 실시간 리스너(`snapshots()`)를 사용하여 삭제 이벤트를 즉시 감지한다. 수정 대상 문서가 존재하지 않으면 사용자에게 알리고 편집 화면을 닫는다 |

**권고사항:**
- 실시간 리스너를 적극 활용하여 다른 기기의 변경을 즉시 반영한다.
- 목표 진행률 등 계산값은 하위 문서 변경 시마다 재계산하되, 트랜잭션(`runTransaction`)으로 원자성을 보장한다.
- 만다라트 데이터는 하나의 문서에 9x9 구조를 담을 경우 동시 편집 충돌 가능성이 높다. 셀 단위로 별도 문서를 구성하거나, 전체 문서를 트랜잭션으로 처리한다.

### 5.3 습관 시간 잠금 (Time Lock) [High]

플랜에서 "자정 기준 00:00~23:59만 체크 가능, 과거일 수정 불가"로 명시되어 있다.

**위협:** 클라이언트 시간 조작으로 시간 잠금 우회 가능.

| 검증 위치 | 구현 방법 | 한계 |
|---|---|---|
| 클라이언트 (1차) | `DateTime.now()`를 기반으로 과거 날짜 체크 UI를 비활성화한다 | 클라이언트 시간 조작에 취약하다 |
| Firestore Rules (2차) | `request.time`(서버 타임스탬프)을 사용하여 검증한다 | Firestore Rules에서 날짜 비교 로직이 복잡하다 |
| Cloud Functions (3차, 권고) | `onCreate`/`onUpdate` 트리거로 서버 시간 기준 검증 후 부적합 데이터를 롤백한다 | Cloud Functions 비용이 발생한다 |

**권고 구현 방식:**

서버 측 검증 없이 클라이언트만으로 시간 잠금을 구현하면, 의도적 우회(시스템 시계 변경)뿐 아니라 시간대 차이로 인한 비의도적 우회도 발생한다. 최소한 Firestore Rules 레벨의 검증을 적용한다.

```
// Firestore Rules 내 시간 잠금 검증 예시
allow create: if request.auth.uid == userId
              && request.resource.data.date == request.time.toMillis().date()
              // 주의: Firestore Rules의 시간 비교는 제한적이므로
              // Cloud Function을 권고한다
```

**위험 수용 판단:**
- 이 앱은 개인 생산성 도구이다. 타 사용자에게 영향을 주는 소셜/경쟁 기능이 없다면, 시간 잠금 우회의 실질적 피해는 자기 자신의 기록 왜곡에 그친다.
- 구현 비용 대비 효용을 고려하면, 클라이언트 검증 + Firestore Rules 기본 검증으로 충분할 수 있다. Cloud Functions는 향후 게이미피케이션(스트릭 보상 등) 도입 시 반드시 추가한다.

### 5.4 캘린더 날짜 경계 (타임존) [Medium]

| 시나리오 | 위험 등급 | 대응 전략 |
|---|---|---|
| UTC vs 로컬 시간대 불일치 | Medium | 모든 날짜/시간을 Firestore에 UTC timestamp로 저장한다. 표시 시 로컬 타임존으로 변환한다 |
| 자정 경계 일정 | Medium | 00:00 시작 일정의 소속일을 명확히 정의한다 (시작일 소속) |
| 범위 일정 타임존 전환 | Low | 출장/여행 중 타임존 변경 시 범위 일정 표시가 밀리는 현상을 방지한다. 날짜(date-only) 일정과 시간(datetime) 일정을 구분하여 처리한다 |
| DST(서머타임) 전환 | Low | 한국 사용자 대상이므로 DST 이슈는 낮지만, 해외 사용자 확장 시 고려가 필요하다. `timezone` 패키지 사용을 권고한다 |

**핵심 원칙:**
- 저장: UTC Timestamp (Firestore `Timestamp` 타입)
- 날짜 전용 필드: `YYYY-MM-DD` 문자열 (타임존 무관)
- 표시: `intl` 패키지의 `DateFormat`으로 로컬 시간 변환
- 비교: 항상 UTC 기준으로 비교 후 표시만 로컬로 변환

### 5.5 Firestore 오프라인 지속성 동작 [Medium]

| 항목 | Web | Android |
|---|---|---|
| 기본 활성화 | 비활성화 (명시적 활성화 필요) | 활성화 |
| 캐시 크기 | 기본 40MB | 기본 100MB (설정 가능) |
| 멀티탭 지원 | `enableMultiTabIndexedDbPersistence()` 필요 | N/A (앱 인스턴스 하나) |

**Web에서 반드시 설정할 사항:**
```dart
// Web용 오프라인 지속성 활성화
await FirebaseFirestore.instance.enablePersistence(
  const PersistenceSettings(synchronizeTabs: true),
);
```

- `synchronizeTabs: true` 미설정 시, 여러 탭에서 같은 앱을 열었을 때 한 탭에서만 오프라인 지속성이 동작하고 나머지 탭은 온라인 전용이 된다.
- 이 설정을 빠뜨리면 다중 탭 사용자가 데이터 불일치를 경험한다.

---

## 6. 안정성 (Stability)

### 6.1 Firestore 쿼리 제한 및 페이지네이션 [High]

| 제한사항 | 값 | 대응 |
|---|---|---|
| 단일 문서 최대 크기 | 1MB | 만다라트 문서 설계 시 9x9 데이터가 1MB를 초과하지 않도록 한다 (현실적으로 초과 불가능하지만 검증 필수) |
| 단일 쿼리 최대 반환 문서 수 | 제한 없음 (과금 발생) | 반드시 `limit()`을 적용한다 |
| 복합 인덱스 | 수동 생성 필요 | 복합 쿼리 사용 전 인덱스를 미리 생성한다 |
| 하위 컬렉션 쿼리 | 컬렉션 그룹 쿼리 필요 | goals/subGoals/tasks 계층 구조에서 전체 tasks 조회 시 컬렉션 그룹 쿼리와 해당 보안 규칙을 설정한다 |

**페이지네이션 필수 적용 대상:**
- `events` 컬렉션: 월별로 쿼리 범위를 제한한다. 전체 기간 일정을 한 번에 가져오지 않는다.
- `habitLogs` 컬렉션: 월별 페이지네이션을 적용한다. 오래된 로그는 필요 시에만 로드한다.
- `todos` 컬렉션: 주 단위 또는 일 단위로 쿼리한다.

### 6.2 Rate Limiting [Medium]

Firebase는 자체적으로 다음 제한을 적용한다:

| 항목 | 제한 | 영향 |
|---|---|---|
| 문서 쓰기 속도 | 초당 1회/문서 | 빠른 연속 체크 시 충돌 가능. 습관 빠르게 연속 체크 시 debounce 적용 필요 |
| 프로젝트 쓰기 속도 | 초당 10,000 (Spark 플랜은 더 낮음) | 개인 앱으로 초과 가능성은 낮음 |
| 인증 요청 | IP당 제한 존재 | 로그인 반복 시도 시 Firebase가 자동 제한. 사용자에게 적절한 에러 메시지를 표시한다 |

**클라이언트 측 Rate Limiting 구현:**
- 습관 체크박스: 300ms debounce를 적용한다. 빠른 연타로 인한 중복 쓰기를 방지한다.
- 투두 생성 버튼: 버튼 비활성화 + 낙관적 UI 업데이트로 중복 생성을 방지한다.
- 검색/필터: 500ms debounce를 적용한다.

### 6.3 앱 크래시 후 상태 복구 [Medium]

| 시나리오 | 대응 전략 |
|---|---|
| 일정 생성 모달 작성 중 크래시 | 임시 저장(draft)을 Hive에 저장한다. 앱 재시작 시 임시 저장 데이터가 존재하면 복원 여부를 묻는다 |
| 만다라트 위저드 중간 단계에서 크래시 | 각 단계 완료 시 중간 상태를 Hive에 저장한다. 재시작 시 마지막 완료 단계에서 이어서 진행한다 |
| Riverpod 상태 유실 | `authStateChanges()` 스트림으로 인증 상태를 자동 복구한다. Firestore 실시간 리스너로 데이터 상태를 자동 복구한다 |

### 6.4 데이터 마이그레이션 전략 [High]

Firestore는 스키마리스(schemaless)이지만, 앱 버전에 따른 데이터 구조 변경은 불가피하다.

**권고 전략:**
1. 각 사용자 프로필 문서에 `schemaVersion` 필드를 추가한다.
2. 앱 시작 시 `schemaVersion`을 확인하고, 현재 앱 버전과 불일치하면 마이그레이션을 실행한다.
3. 마이그레이션은 버전별 순차 실행한다 (v1->v2->v3, v1->v3 직접 이동 금지).
4. 마이그레이션 실패 시 롤백 가능해야 한다. 원본 필드를 즉시 삭제하지 않고 일정 기간 유지한다.
5. Cloud Functions에서 백그라운드 마이그레이션을 실행하는 방안도 고려한다.

```dart
// 마이그레이션 예시 구조
Future<void> migrateUserData(String userId, int fromVersion) async {
  if (fromVersion < 2) await _migrateV1ToV2(userId);
  if (fromVersion < 3) await _migrateV2ToV3(userId);
  // schemaVersion 업데이트
  await _updateSchemaVersion(userId, currentSchemaVersion);
}
```

---

## 7. 개인정보 보호

### 7.1 GDPR / 개인정보보호법 준수 [High]

이 앱은 사용자의 일정, 습관, 목표 등 민감한 개인 생활 데이터를 수집한다.

| 요구사항 | 위험 등급 | 구현 방법 |
|---|---|---|
| 개인정보 처리방침 | High | 앱 내 접근 가능한 개인정보 처리방침 페이지를 제공한다. Google Play Store 등록 시 필수이다 |
| 데이터 수집 동의 | High | 최초 로그인 시 개인정보 수집/이용 동의를 받는다. 동의 거부 시 서비스 이용 불가로 처리한다 |
| 데이터 열람 권한 | Medium | 사용자가 자신의 데이터를 조회할 수 있어야 한다. Firestore 구조상 기본적으로 가능하지만, 데이터 내보내기(export) 기능 제공을 권고한다 |
| 데이터 삭제 권한 | High | 계정 삭제 시 모든 사용자 데이터를 완전 삭제해야 한다. 아래 7.2에서 상세히 다룬다 |
| 데이터 이동 권한 | Low | JSON/CSV 형식으로 데이터 내보내기 기능을 향후 제공한다 |

### 7.2 계정 삭제 시 데이터 처리 [Critical]

계정 삭제 시 `users/{userId}/` 하위 모든 데이터를 완전히 삭제해야 한다. Google Play Store 정책(2022년부터)에서 필수 요구사항이다.

**삭제 대상 체크리스트:**

| 저장소 | 삭제 대상 | 구현 방법 |
|---|---|---|
| Firestore | `users/{userId}/` 하위 전체 (profile, events, todos, routines, habits, habitLogs, goals, goals/subGoals, goals/subGoals/tasks, mandalart) | Cloud Function `onDelete` 트리거 또는 Firebase Extensions `Delete User Data` 사용 |
| Firebase Auth | 사용자 인증 정보 | `FirebaseAuth.instance.currentUser?.delete()` |
| Hive (로컬) | 모든 캐시 데이터 | 모든 Box `deleteFromDisk()` |
| Firebase Analytics | 사용자 식별 데이터 | `setUserId(null)` 호출 후, Analytics 데이터는 익명화되어 유지된다 |

**중요:** Firestore 하위 컬렉션 삭제는 상위 문서 삭제만으로 자동 삭제되지 않는다. `goals/{goalId}` 삭제 시 `goals/{goalId}/subGoals/` 하위 문서는 남는다. Cloud Function에서 재귀적 삭제를 구현하거나 `firebase-tools`의 `recursiveDelete()`를 사용한다.

### 7.3 로컬 vs 클라우드 데이터 분류

| 데이터 유형 | 저장 위치 | 민감도 |
|---|---|---|
| 인증 토큰 | Firebase SDK 관리 (Web: IndexedDB, Android: Keystore) | 높음 |
| 사용자 프로필 | Firestore + Hive 캐시 | 중간 |
| 일정/투두/습관/목표 | Firestore (원본) + Hive 캐시 (복사본) | 중간 |
| 앱 설정 (테마, 언어) | Hive (로컬만) | 낮음 |
| 습관 스트릭 계산값 | 클라이언트 계산 + Hive 캐시 | 낮음 |

---

## 8. Web 전용 보안

### 8.1 Firebase Hosting 헤더 설정 [High]

`firebase.json`에 보안 헤더를 설정한다.

```json
{
  "hosting": {
    "headers": [
      {
        "source": "**",
        "headers": [
          {
            "key": "X-Frame-Options",
            "value": "DENY"
          },
          {
            "key": "X-Content-Type-Options",
            "value": "nosniff"
          },
          {
            "key": "X-XSS-Protection",
            "value": "1; mode=block"
          },
          {
            "key": "Referrer-Policy",
            "value": "strict-origin-when-cross-origin"
          },
          {
            "key": "Permissions-Policy",
            "value": "camera=(), microphone=(), geolocation=()"
          },
          {
            "key": "Content-Security-Policy",
            "value": "default-src 'self'; script-src 'self' https://apis.google.com https://www.gstatic.com https://www.googleapis.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: https://*.googleusercontent.com; connect-src 'self' https://*.googleapis.com https://*.firebaseio.com wss://*.firebaseio.com https://firestore.googleapis.com; frame-src https://accounts.google.com https://*.firebaseapp.com;"
          }
        ]
      }
    ]
  }
}
```

**CSP 주의사항:**
- Flutter Web CanvasKit 모드에서 WASM 로딩을 위해 `script-src`에 `'wasm-unsafe-eval'`이 필요할 수 있다. 빌드 후 테스트하여 확인한다.
- Google OAuth 팝업을 위해 `frame-src`에 Google 도메인을 허용해야 한다.
- CSP를 과도하게 엄격하게 설정하면 Flutter Web 자체가 동작하지 않을 수 있으므로, 빌드 후 반드시 동작 검증을 수행한다.

### 8.2 CORS 설정 [Medium]

- Firebase Hosting은 같은 프로젝트의 Firestore/Auth에 대한 CORS를 자동 처리한다.
- Cloud Functions를 사용하는 경우, CORS 미들웨어를 명시적으로 설정한다.
- 허용 Origin을 프로덕션 도메인으로 제한한다. `*` 와일드카드를 사용하지 않는다.

### 8.3 HTTPS 강제 [Low]

- Firebase Hosting은 기본적으로 HTTPS를 강제한다. HTTP 요청은 자동으로 HTTPS로 리다이렉트된다.
- 커스텀 도메인 사용 시 SSL 인증서가 자동 프로비저닝된다. 수동 설정이 불필요하다.

---

## 9. Android 전용 보안

### 9.1 코드 난독화 (ProGuard/R8) [Medium]

| 항목 | 요구사항 |
|---|---|
| R8 활성화 | 릴리스 빌드에서 R8 난독화를 활성화한다. `build.gradle`에서 `minifyEnabled true`, `shrinkResources true`를 설정한다 |
| ProGuard 규칙 | Firebase, Hive 등 사용 라이브러리의 ProGuard keep 규칙을 추가한다. 누락 시 런타임 크래시가 발생한다 |
| Flutter 특화 | Flutter는 AOT 컴파일되므로 Dart 코드 자체는 이미 난독화되어 있다. Native 코드(Kotlin/Java) 부분에 R8을 적용한다 |

### 9.2 API 키 보호 [High]

| 항목 | 위험 등급 | 요구사항 |
|---|---|---|
| google-services.json | High | Git 저장소에 커밋하지 않는다. `.gitignore`에 추가한다. CI/CD에서 환경변수로 주입한다 |
| Firebase API 키 | Medium | Firebase Web API 키는 공개되어도 Firestore Rules가 보호한다. 다만 불필요한 API(예: Cloud Translation)가 해당 키로 호출되지 않도록 API 제한을 설정한다 |
| AndroidManifest.xml | Medium | Google Maps API 키 등 추가 키가 있다면 `<meta-data>` 대신 `local.properties` + `BuildConfig`로 주입한다 |
| SHA-1/SHA-256 지문 | High | Firebase Console에 등록된 SHA 지문과 앱 서명 키의 지문이 일치해야 한다. 불일치 시 Google 로그인이 실패한다 |

### 9.3 앱 서명 및 Play Store 요구사항 [High]

| 항목 | 요구사항 |
|---|---|
| Play App Signing | Google Play App Signing을 사용한다. 업로드 키와 서명 키를 분리하여 키 유실 위험을 줄인다 |
| 키 저장 | 업로드 키스토어를 안전한 위치에 보관한다. Git 저장소에 포함하지 않는다 |
| 타겟 API 레벨 | Google Play의 최신 타겟 API 레벨 요구사항을 충족한다 (2026년 기준 API 35 이상) |
| 데이터 안전 섹션 | Play Store의 Data Safety 섹션에 수집 데이터, 사용 목적, 공유 여부를 정확히 기재한다 |
| 앱 삭제 안내 | 앱 삭제만으로 서버 데이터가 삭제되지 않음을 안내한다. 계정 삭제 기능을 앱 내에 제공한다 |

### 9.4 루팅 기기 대응 [Low]

- 이 앱은 금융/의료 앱이 아니므로 루팅 탐지는 필수가 아니다.
- 다만 Hive 캐시가 루팅 기기에서 평문 노출될 수 있음을 인지하고, 캐시 암호화(4.3항)를 적용한다.
- 루팅 탐지를 구현하려면 `flutter_jailbreak_detection` 패키지를 사용하되, 차단이 아닌 경고 수준으로 처리한다.

---

## 10. 보안 요구사항 체크리스트

### Critical (반드시 구현)
- [ ] Firestore Rules: 기본 거부 정책 + `request.auth.uid == userId` 검증
- [ ] Firestore Rules: 모든 하위 컬렉션에 인가 규칙 적용
- [ ] Firebase Auth: 승인 도메인 목록에 프로덕션 도메인만 등록
- [ ] 계정 삭제 시 Firestore 하위 컬렉션 재귀 삭제 구현
- [ ] GoRouter 인증 가드 구현 (클라이언트 보조 수단)
- [ ] Firestore Rules 단위 테스트 (Firebase Emulator Suite)

### High (강력 권고)
- [ ] 모든 입력 필드 클라이언트 + 서버 양측 검증
- [ ] Flutter Web CanvasKit 렌더러 사용 (XSS 구조적 방어)
- [ ] Hive 캐시 AES 암호화 적용
- [ ] 로그아웃 시 Hive 캐시 완전 삭제
- [ ] Web 오프라인 지속성 + 멀티탭 설정
- [ ] firebase.json 보안 헤더 설정 (CSP, X-Frame-Options 등)
- [ ] google-services.json .gitignore 등록
- [ ] 데이터 마이그레이션 전략 (schemaVersion)
- [ ] 개인정보 처리방침 페이지 구현
- [ ] Firestore 쿼리 페이지네이션 적용

### Medium (권고)
- [ ] 습관 시간 잠금 서버 측 검증 (Firestore Rules 또는 Cloud Function)
- [ ] 동시 편집 충돌 감지 및 사용자 알림
- [ ] 네트워크 상태 실시간 표시 (오프라인 배너)
- [ ] 클라이언트 측 debounce/rate limiting
- [ ] Android R8 난독화 활성화
- [ ] 날짜/시간 UTC 저장 원칙 준수

### Low (선택)
- [ ] 루팅 기기 경고
- [ ] 데이터 내보내기(export) 기능
- [ ] DST/타임존 확장 대응

---

## 11. 에러 핸들링 전략

### 11.1 에러 분류 체계

| 등급 | 정의 | 사용자 대응 | 개발자 대응 |
|---|---|---|---|
| Fatal | 앱 사용 불가 (인증 실패, Firestore 접속 불가) | 에러 화면 + 재시도 버튼 | Crashlytics 자동 보고 |
| Recoverable | 특정 기능 실패 (문서 저장 실패, 네트워크 일시 단절) | SnackBar로 에러 알림 + 자동 재시도 | 에러 로그 기록 |
| Warning | 비정상적이지만 계속 사용 가능 (캐시 불일치, 부분 로드 실패) | 무음 처리 또는 미세한 표시 | 디버그 로그 기록 |
| Validation | 사용자 입력 오류 | 인라인 에러 메시지 | 로그 불필요 |

### 11.2 에러 핸들링 구현 원칙

1. **Firestore 에러**: `FirebaseException`을 catch하고 에러 코드(`permission-denied`, `not-found`, `unavailable` 등)별로 분기 처리한다.
2. **Auth 에러**: `FirebaseAuthException`의 에러 코드(`user-disabled`, `user-not-found`, `network-request-failed` 등)에 따라 사용자 친화적 메시지를 표시한다.
3. **네트워크 에러**: `SocketException`, `TimeoutException`을 감지하여 오프라인 모드로 전환한다.
4. **글로벌 에러 핸들러**: `FlutterError.onError`와 `PlatformDispatcher.instance.onError`를 설정하여 미처리 예외를 포착한다.
5. **Riverpod AsyncValue**: `AsyncValue.guard()`를 사용하여 비동기 작업의 loading/error/data 상태를 일관되게 관리한다.

```dart
// 에러 핸들링 패턴 예시
ref.listen(someProvider, (prev, next) {
  next.whenOrNull(
    error: (error, stack) {
      if (error is FirebaseException) {
        _handleFirebaseError(error);
      } else {
        _showGenericError();
      }
    },
  );
});
```

---

## 12. 타 분석관 의견에 대한 피드백

### spec-architect (기술 아키텍처) 관점에 대한 보안 의견

1. **Firestore 데이터 모델 설계**: `users/{userId}/goals/{goalId}/subGoals/{subGoalId}/tasks/{taskId}` 3단계 중첩 구조는 기능적으로 적절하지만, 계정 삭제 시 재귀 삭제 구현이 복잡해진다. 삭제 누락 위험이 존재하므로 Cloud Function 기반 재귀 삭제를 필수로 구현해야 한다.

2. **Riverpod 상태 관리**: 인증 상태를 Riverpod으로 관리할 때, `authStateChanges()` 스트림이 끊기는 엣지 케이스(토큰 만료 + 네트워크 단절 동시 발생)에 대한 복구 로직을 반드시 포함해야 한다. 단순히 스트림을 구독하는 것만으로는 부족하다.

3. **GoRouter 라우팅**: 라우팅은 클라이언트 가드일 뿐이라는 점을 모든 개발자가 인식해야 한다. "GoRouter에서 막았으니 안전하다"는 착각이 가장 위험하다. Firestore Rules가 유일한 진짜 보안 경계이다.

### spec-product (제품/UX) 관점에 대한 보안 의견

1. **온보딩 간소화 vs 동의 수집**: 진입장벽 완화를 위해 온보딩을 최소화하려 할 수 있으나, 개인정보 처리 동의는 반드시 첫 로그인 시 받아야 한다. Google Play Store 정책 위반 시 앱 삭제 조치를 받을 수 있다. 동의 화면을 사용자 친화적으로 디자인하되 생략은 불가하다.

2. **습관 프리셋**: 인기 습관 프리셋은 서버(Firestore)가 아닌 앱 번들에 정적으로 포함시키는 것을 권고한다. 서버에 프리셋을 저장하면 인증 전에도 접근 가능한 공개 컬렉션이 필요해지고, 이는 보안 규칙을 복잡하게 만든다.

3. **만다라트 공유 기능 (향후)**: 만다라트를 다른 사용자와 공유하는 기능이 추가될 경우, 현재의 단순한 `userId == request.auth.uid` 규칙으로는 부족하다. 공유 권한 모델(읽기 전용 / 편집 가능)을 사전에 설계해야 한다. 향후 확장을 고려하여 데이터 모델에 `sharedWith` 필드를 예약해두는 것도 방법이다.

4. **빈 상태 UI의 보안 관점**: "오늘 일정이 없습니다" 등 빈 상태 메시지는 보안상 문제없지만, 에러 상태와 빈 상태를 명확히 구분해야 한다. Firestore 접근 권한이 없어서 데이터를 못 가져온 것인지, 실제로 데이터가 없는 것인지를 사용자에게 다르게 표시해야 한다.

---

## 13. 종합 위험 평가

| 위험 영역 | 등급 | 현재 상태 | 권고 조치 |
|---|---|---|---|
| Firestore Rules 미설정 | Critical | 미구현 | Phase 2에서 최우선 구현 |
| 계정 삭제 시 데이터 잔존 | Critical | 미구현 | Cloud Function 또는 Firebase Extension 적용 |
| 입력값 서버 측 검증 부재 | High | 미구현 | Firestore Rules에 필드 검증 추가 |
| Hive 캐시 평문 저장 | Medium | 미구현 | AES 암호화 적용 |
| 다중 탭 오프라인 지속성 | Medium | 미구현 | Web 지속성 설정 적용 |
| 보안 헤더 미설정 | High | 미구현 | firebase.json 헤더 설정 |
| 시간 잠금 서버 검증 | Medium | 미구현 | 비용 대비 효용 판단 후 결정 |

**최종 판단:** 이 앱은 개인 생산성 도구이므로 금융/의료 수준의 보안은 불필요하다. 그러나 Firebase 서버리스 아키텍처 특성상 Firestore Rules가 유일한 서버 측 보안 레이어이므로, 규칙 설계와 테스트에 가장 높은 우선순위를 부여해야 한다. 나머지 보안 조치는 위험 등급에 따라 순차 적용한다.
