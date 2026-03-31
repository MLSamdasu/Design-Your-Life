import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // google-services.json 파싱을 위한 Google Services 플러그인
    id("com.google.gms.google-services")
    // Firebase Crashlytics 크래시 리포팅 플러그인
    id("com.google.firebase.crashlytics")
    // Flutter Gradle 플러그인은 Android/Kotlin 플러그인 이후에 적용해야 한다
    id("dev.flutter.flutter-gradle-plugin")
}

// 릴리즈 서명 키 정보를 key.properties 파일에서 읽어온다
// key.properties에는 storePassword, keyPassword, keyAlias, storeFile이 정의되어 있다
val keystorePropertiesFile = rootProject.file("app/key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}

android {
    // namespace: R 클래스 생성 기준 패키지 (소스 코드 패키지와 일치)
    namespace = "com.designyourlife.design_your_life"
    // API 36 (Android 16) 기준으로 컴파일한다
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Java 17 호환성 설정 (Kotlin coroutine + Firebase SDK 요구사항)
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Java 8+ API (LocalDate 등) 하위 호환성 지원
        isCoreLibraryDesugaringEnabled = true
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    defaultConfig {
        // Google Play Store에서 앱을 식별하는 고유 ID
        applicationId = "com.designyourlife.app"
        // Android 5.0 (Lollipop) 이상 지원 (Firebase Auth 최소 요구사항)
        minSdk = flutter.minSdkVersion
        // API 35 (Android 15) 대상
        targetSdk = 35
        // Google Play Store 버전 코드 (업데이트 시 반드시 증가)
        versionCode = 2
        versionName = "1.1.0"
        // 64K 메서드 제한 초과를 대비한 멀티덱스 활성화
        multiDexEnabled = true
    }

    // 릴리즈 서명 구성 (key.properties 파일에서 읽어온다)
    // 비밀번호를 소스 코드에 하드코딩하지 않고 외부 파일에서 로드한다
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let(::file)
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        // 릴리스 빌드: R8 난독화 + 리소스 축소 + 프로덕션 서명
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // key.properties 존재 시 릴리즈 서명, 없으면 디버그 서명
            signingConfig = try {
                signingConfigs.getByName("release")
            } catch (_: Exception) {
                signingConfigs.getByName("debug")
            }
        }
        debug {
            // 디버그 빌드: 난독화 비활성화로 디버깅 편의성 확보
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Java 8+ API 하위 호환성 라이브러리 (Firebase SDK 요구사항)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // 멀티덱스 지원 라이브러리
    implementation("androidx.multidex:multidex:2.0.1")
}
