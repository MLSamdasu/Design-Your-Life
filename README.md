# Design Your Life

오늘을 디자인하다 — 투두, 캘린더, 습관 트래킹, 목표 관리, 타이머, 업적 시스템을 하나의 앱에서 처리하는 개인 생산성 대시보드다.

## 주요 기능

| 탭 | 설명 |
|---|---|
| 홈 | 투두 완료율, 습관 달성률, D-day, 주간 요약, 업적 카드를 한 화면에 표시한다 |
| 캘린더 | 월간/주간/일간 뷰 전환, 일반/범위/반복/할일 4가지 일정 유형, Google Calendar 연동 |
| 투두 | 주간 슬라이더 날짜 선택, 하루 타임라인 + 체크리스트, 태그 기반 분류 |
| 습관/루틴 | 습관 체크 + 스트릭 추적, 루틴 주간 시간표, 캘린더 히트맵 |
| 목표 | 연간/월간 목표 관리, 만다라트(9×9) 위저드, 하위 목표 + 태스크 트리 |

추가 기능:
- 6개 테마 프리셋 (Glassmorphism, Minimal, Retro, Neon, Clean, Soft)
- 로컬 퍼스트 아키텍처 (인터넷 없이 완전 동작)
- Google Drive 클라우드 백업 (사용자 본인의 드라이브에 저장)
- Google OAuth 인증 (선택 사항, 백업 시에만 필요)
- AdMob 광고 연동 (인터스티셜 + 리워드)
- 집중 타이머 + 세션 통계
- 업적/배지 시스템
- 라이트/다크 모드

## 아키텍처

```
┌──────────────────────────────────────────────────┐
│                   Flutter App                     │
│                                                   │
│  ┌─────────┐  ┌──────────┐  ┌──────────────────┐ │
│  │  Hive   │  │  Google   │  │   Google Drive   │ │
│  │ (AES암호)│  │ Sign-In  │  │  (appdata 폴더)  │ │
│  │ 로컬 DB │  │  OAuth   │  │  클라우드 백업    │ │
│  └─────────┘  └──────────┘  └──────────────────┘ │
│       ↑              ↑               ↑            │
│     CRUD         인증(선택)      백업/복원         │
│   (오프라인)    (백업 시 필요)   (사용자 요청 시)   │
└──────────────────────────────────────────────────┘
```

- **로컬 퍼스트**: 모든 CRUD는 Hive(AES-256 암호화)에서 수행한다. 인터넷이 없어도 모든 기능을 사용할 수 있다.
- **서버 비용 0원**: 외부 DB 서버 없이 사용자의 기기와 Google Drive만 사용한다.
- **백업**: 사용자가 명시적으로 요청할 때만 Google Drive appdata 폴더에 JSON으로 백업한다.
- **인증**: 앱 시작 시 로그인 없이 바로 사용 가능하다. Google 로그인은 백업 기능 활성화 시에만 필요하다.

## 기술 스택

| 항목 | 기술 | 버전 |
|---|---|---|
| Framework | Flutter | 3.29 |
| 언어 | Dart | 3.7+ |
| 상태관리 | Riverpod | 2.6.1 |
| 라우팅 | GoRouter | 14.8.1 |
| 로컬 DB | Hive (AES-256 암호화) | 2.2.3 |
| 인증 | google_sign_in | 6.2.2 |
| 클라우드 백업 | Google Drive API (googleapis) | 14.0.0 |
| 광고 | Google AdMob (google_mobile_ads) | 5.3.0 |
| 캘린더 UI | table_calendar | 3.2.0 |
| 차트 | fl_chart | 0.70.2 |
| 날짜/i18n | intl | 0.20.2 |
| 폰트 | Google Fonts | 8.0.2 |
| 보안 저장소 | flutter_secure_storage | 9.2.4 |
| ID 생성 | uuid (v4) | 4.5.1 |

## 프로젝트 구조

```
lib/
├── main.dart                        # 앱 진입점 (Hive 초기화 → AdMob 초기화 → 세션 복원)
├── app.dart                         # MaterialApp.router 설정
│
├── core/                            # 공통 인프라 (C0 모듈)
│   ├── ads/                         # AdMob 광고 서비스 + Provider
│   ├── auth/                        # Google Sign-In 인증 서비스 + Provider
│   ├── backup/                      # Google Drive 백업 서비스 + Provider
│   ├── cache/                       # Hive 초기화 + 캐시 서비스 (AES-256)
│   ├── calendar_sync/               # Google Calendar 연동 서비스
│   ├── constants/                   # 앱 상수 (Hive 박스명, 설정 키)
│   ├── error/                       # 예외 클래스, 에러 핸들링
│   ├── nlp/                         # 자연어 처리 유틸
│   ├── providers/                   # 전역 Provider (DI)
│   ├── router/                      # GoRouter 설정 + 라우트 경로
│   ├── theme/                       # 디자인 토큰 시스템
│   │   ├── color_tokens.dart        #   컬러 토큰 (Main/Sub 2색 + Tinted Grey)
│   │   ├── typography_tokens.dart   #   타이포그래피 토큰
│   │   ├── spacing_tokens.dart      #   간격 토큰 (AppSpacing)
│   │   ├── radius_tokens.dart       #   모서리 반경 토큰 (AppRadius)
│   │   ├── animation_tokens.dart    #   애니메이션 타이밍 토큰 (AppAnimation)
│   │   ├── layout_tokens.dart       #   레이아웃 토큰 (AppLayout)
│   │   ├── theme_preset_registry.dart # 6개 테마 프리셋 정의
│   │   ├── theme_colors.dart        #   테마 인식 색상 확장 (context.themeColors)
│   │   ├── glassmorphism.dart       #   Glassmorphism 데코레이션 팩토리
│   │   └── app_theme.dart           #   Material ThemeData 생성
│   └── utils/                       # 날짜, 색상 유틸
│
├── shared/                          # 공유 모듈
│   ├── enums/                       # 공유 Enum (EventType, GoalPeriod 등)
│   ├── extensions/                  # 확장 메서드 (DateTime, String 등)
│   ├── models/                      # 데이터 모델 (Event, Todo, Habit, Goal 등)
│   ├── services/                    # 공유 서비스 (TagRepository)
│   ├── providers/                   # 공유 Provider
│   └── widgets/                     # 공용 위젯 (GlassCard, DonutChart, MainShell 등)
│
└── features/                        # 기능 모듈 (F1~F10)
    ├── auth/                        # F1: 로그인, 온보딩, 스플래시
    ├── calendar/                    # F2: 캘린더 (월간/주간/일간 뷰)
    ├── todo/                        # F3: 투두 리스트
    ├── habit/                       # F4: 습관 트래커 + F5: 루틴
    ├── goal/                        # F6: 목표 관리 + 만다라트
    ├── timer/                       # F7: 집중 타이머
    ├── achievement/                 # F8: 업적/배지 시스템
    ├── home/                        # F10: 홈 대시보드
    └── settings/                    # 설정 + 태그 관리 + 백업
```

의존 방향: `features/` → `shared/` → `core/` (단방향). features 간 직접 import를 금지한다.

## 테마 시스템

6개 테마 프리셋을 지원하며, 각 테마는 배경, 카드 스타일, 텍스트 색상, 모달 스타일을 독립적으로 정의한다.

| 테마 | 배경 | 특징 |
|---|---|---|
| Glassmorphism (기본) | 보라-핑크 그라디언트 | 반투명 유리 카드, 블러 효과 |
| Minimal | 밝은 회색-흰색 | 깨끗한 라인, 미니멀 카드 |
| Retro | 크림색 | 따뜻한 색감, 빈티지 느낌 |
| Neon | 다크 퍼플 | 네온 글로우 효과, 사이버펑크 |
| Clean | 흰색-연회색 | 선명한 보더, 정돈된 레이아웃 |
| Soft | 아이보리 | 부드러운 그림자, 따뜻한 톤 |

테마 인식 색상 시스템: `context.themeColors.textPrimary`, `.accent`, `.dialogSurface` 등을 통해 현재 테마에 맞는 색상을 자동으로 선택한다.

## 디자인 토큰 시스템

모든 UI 수치는 디자인 토큰으로 중앙 관리한다. 하드코딩을 금지한다.

| 토큰 | 클래스 | 예시 |
|---|---|---|
| 컬러 | `ColorTokens` | `ColorTokens.main`, `ColorTokens.gray800` |
| 타이포그래피 | `AppTypography` | `AppTypography.titleLg`, `AppTypography.bodyMd` |
| 간격 | `AppSpacing` | `AppSpacing.md` (8px), `AppSpacing.xl` (16px) |
| 모서리 반경 | `AppRadius` | `AppRadius.card` (20px), `AppRadius.input` (12px) |
| 애니메이션 | `AppAnimation` | `AppAnimation.normal` (200ms), `AppAnimation.medium` (300ms) |
| 레이아웃 | `AppLayout` | `AppLayout.minTouchTarget` (44px), `AppLayout.iconMd` (16px) |

## Hive 로컬 저장소

14개 Hive 박스를 사용한다. 12개는 AES-256으로 암호화된다.

| 박스 | 용도 | 암호화 |
|---|---|---|
| userProfileBox | 사용자 프로필 | O |
| eventsBox | 캘린더 일정 | O |
| todosBox | 할 일 | O |
| habitsBox | 습관 | O |
| habitLogsBox | 습관 기록 | O |
| routinesBox | 루틴 | O |
| goalsBox | 목표 | O |
| subGoalsBox | 하위 목표 | O |
| goalTasksBox | 목표 태스크 | O |
| timerLogsBox | 타이머 기록 | O |
| achievementsBox | 업적 | O |
| tagsBox | 태그 | O |
| settingsBox | 설정값 | X |
| syncMetaBox | 동기화 메타데이터 | X |

## 설치 및 실행

### 사전 준비

- Flutter SDK 3.29 이상
- Android SDK (compileSdk 36)
- Android 에뮬레이터 또는 실기기
- Google Cloud Console 프로젝트 (백업/인증 사용 시)

### 설치

```bash
git clone https://github.com/MLSamdasu/Design-Your-Life.git
cd Design-Your-Life
flutter pub get
```

### Google Cloud Console 설정 (백업/인증 기능)

Google 로그인 및 Drive 백업 기능을 사용하려면 아래 설정이 필요하다.

1. [Google Cloud Console](https://console.cloud.google.com/)에서 프로젝트를 생성하거나 선택한다.
2. **Google Drive API**를 활성화한다.
3. **OAuth 동의 화면**을 설정한다 (External, 앱 이름/이메일 입력).
4. **OAuth 2.0 클라이언트 ID**를 생성한다:
   - Android: 패키지명 `com.designyourlife.app` + SHA-1 지문 입력
   - iOS: 번들 ID 입력
5. `google-services.json`을 다운로드하여 `android/app/` 디렉토리에 배치한다.

> `google-services.json`은 `.gitignore`에 의해 Git에 포함되지 않는다. 각 개발자가 본인의 Google Cloud 프로젝트에서 생성해야 한다.

### AdMob 설정

1. [AdMob 콘솔](https://admob.google.com/)에서 앱을 등록한다.
2. `android/app/src/main/AndroidManifest.xml`에서 AdMob 앱 ID를 교체한다:
   ```xml
   <meta-data
       android:name="com.google.android.gms.ads.APPLICATION_ID"
       android:value="실제_AdMob_앱_ID"/>
   ```
3. `lib/core/ads/ad_constants.dart`에서 광고 유닛 ID를 교체한다.

> 현재 테스트 광고 ID가 설정되어 있다. 프로덕션 배포 전 실제 ID로 교체해야 한다.

### 실행

```bash
# Android 에뮬레이터/실기기
flutter run

# 특정 디바이스 지정
flutter devices                    # 연결된 디바이스 목록 확인
flutter run -d <device-id>         # 해당 디바이스에서 실행
```

### 빌드

```bash
# Android APK (디버그)
flutter build apk --debug

# Android APK (릴리스)
flutter build apk --release

# Android App Bundle (Play Store 업로드용)
flutter build appbundle --release
```

## 배포

### Android (Play Store)

1. `android/key.properties`에 서명 키 설정:
   ```properties
   storePassword=<비밀번호>
   keyPassword=<비밀번호>
   keyAlias=<별칭>
   storeFile=<keystore 경로>
   ```
2. `flutter build appbundle --release`로 AAB 생성
3. Google Play Console에 업로드

### iOS (App Store)

1. Xcode에서 서명 인증서 및 프로비저닝 프로필 설정
2. `flutter build ipa --release`로 IPA 생성
3. App Store Connect에 업로드

## 팀원을 위한 포크 가이드

이 레포지토리를 포크하여 작업하는 경우 아래 절차를 따른다.

### 1. 포크 및 클론

```bash
# GitHub에서 Fork 버튼 클릭 후
git clone https://github.com/<your-username>/Design-Your-Life.git
cd Design-Your-Life
flutter pub get
```

### 2. 환경 설정 파일 생성

포크 후 아래 파일들을 직접 생성해야 한다 (보안상 Git에 포함되지 않음):

| 파일 | 위치 | 용도 | 생성 방법 |
|---|---|---|---|
| `google-services.json` | `android/app/` | Google OAuth + Drive API | Google Cloud Console에서 다운로드 |
| `GoogleService-Info.plist` | `ios/Runner/` | iOS Google 인증 | Google Cloud Console에서 다운로드 |
| `key.properties` | `android/` | APK 서명 키 | 수동 생성 (릴리스 빌드 시) |

### 3. 코드 컨벤션

- 모든 주석/문서는 한국어로 작성한다 (~함/~한다 체)
- `Colors.white`, `Color(0xFF...)` 등 하드코딩 금지 — `ColorTokens`, `context.themeColors` 사용
- `BorderRadius.circular(12)` 등 수치 하드코딩 금지 — `AppRadius`, `AppSpacing` 토큰 사용
- 의존 방향: `features/` → `shared/` → `core/` (역방향 금지)
- 1파일 200줄 이내, 1함수 30줄 이내 권장

## 문서

| 문서 | 경로 | 설명 |
|---|---|---|
| 전체 스펙 | `docs/spec.md` | 기능 요구사항, API 정의, 수용 기준 |
| 모듈 설계서 | `docs/module-design.html` | 46개 모듈 인터랙티브 설계서 (브라우저에서 열기) |
| 디자인 시스템 | `docs/design-system.md` | UI 컴포넌트, 테마 규격 |
| 컬러 시스템 | `docs/color-system.md` | Main/Sub 2색 + Tinted Grey 팔레트 |
| 애니메이션 | `docs/animation-spec.md` | 인터랙션 패턴, 타이밍 규격 |

## 라이선스

MIT License — 자세한 내용은 [NOTICE](./NOTICE) 파일을 참고한다.
