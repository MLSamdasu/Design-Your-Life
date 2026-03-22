# Design Your Life - ProGuard / R8 난독화 규칙
# R8이 필수 클래스를 제거하지 않도록 keep 규칙을 설정한다

# ── Flutter ──────────────────────────────────────────────────────────────────
# Flutter 엔진 진입점 보존 (제거 시 앱 실행 불가)
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
# Flutter 플러그인 레지스트라 보존
-keep class io.flutter.plugin.editing.** { *; }

# ── Google Sign-In ────────────────────────────────────────────────────────────
# Google OAuth 처리 클래스 보존
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-keepattributes Signature
-keepattributes *Annotation*

# ── Google APIs (Drive, Calendar) ─────────────────────────────────────────────
# googleapis 패키지에서 사용하는 클래스 보존
-keep class com.google.api.** { *; }
-dontwarn com.google.api.**

# ── Hive (로컬 캐시) ──────────────────────────────────────────────────────────
# Hive 어댑터 클래스는 리플렉션으로 로드되므로 보존한다
-keep class com.hive.** { *; }
-dontwarn com.hive.**

# ── Kotlin ─────────────────────────────────────────────────────────────────────
# Kotlin 코루틴 내부 클래스 보존
-keep class kotlin.coroutines.** { *; }
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# ── 공통 설정 ─────────────────────────────────────────────────────────────────
# 소스 파일명과 라인 번호 보존 (Crashlytics 스택 트레이스 해독용)
-keepattributes SourceFile,LineNumberTable
# 소스 파일명을 "SourceFile"로 대체하여 리버스 엔지니어링 방지
-renamesourcefileattribute SourceFile

# ── Play Core (앱 업데이트) ──────────────────────────────────────────────────
-dontwarn com.google.android.play.core.**
