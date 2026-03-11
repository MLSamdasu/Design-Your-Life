plugins {
    id("com.android.application")
    id("kotlin-android")
    // google-services.json 파싱을 위한 Google Services 플러그인
    id("com.google.gms.google-services")
    // Flutter Gradle 플러그인은 Android/Kotlin 플러그인 이후에 적용해야 한다
    id("dev.flutter.flutter-gradle-plugin")
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

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Google Play Store에서 앱을 식별하는 고유 ID
        applicationId = "com.designyourlife.app"
        // Android 5.0 (Lollipop) 이상 지원 (Firebase Auth 최소 요구사항)
        minSdk = flutter.minSdkVersion
        // API 35 (Android 15) 대상
        targetSdk = 35
        // Google Play Store 버전 코드 (업데이트 시 반드시 증가)
        versionCode = 1
        versionName = "1.0.0"
        // 64K 메서드 제한 초과를 대비한 멀티덱스 활성화
        multiDexEnabled = true
    }

    buildTypes {
        // 릴리스 빌드: R8 난독화 + 리소스 축소 활성화 (보안 요구사항)
        release {
            // R8 코드 최소화 및 난독화 활성화
            isMinifyEnabled = true
            // 사용하지 않는 리소스 제거로 APK 크기 최적화
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // 릴리스용 서명 설정
            // 실제 배포 시 key.properties 파일로 서명 키를 구성한다
            signingConfig = signingConfigs.getByName("debug")
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
