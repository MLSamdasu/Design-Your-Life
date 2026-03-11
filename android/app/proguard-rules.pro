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

# ── Firebase Core ─────────────────────────────────────────────────────────────
# Firebase 초기화에 필요한 클래스 보존
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ── Firebase Auth ─────────────────────────────────────────────────────────────
# 인증 관련 클래스 보존 (리플렉션으로 로드되는 경우가 있음)
-keep class com.google.firebase.auth.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# ── Google Sign-In ────────────────────────────────────────────────────────────
# Google OAuth 처리 클래스 보존
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }

# ── Cloud Firestore ───────────────────────────────────────────────────────────
# Firestore SDK 보존 (직렬화/역직렬화에 리플렉션 사용)
-keep class com.google.firebase.firestore.** { *; }
-dontwarn com.google.firebase.firestore.**

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
