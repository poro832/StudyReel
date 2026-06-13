plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 한글 경로에서 impellerc.exe 크래시 방지: 빌드 출력 경로를 ASCII 경로로 변경
layout.buildDirectory.set(file("C:/temp/studyreel_build/app"))

android {
    namespace = "com.studyreel.studyreel"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.studyreel.studyreel"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // 배포용 디버그 서명(사이드로드 데모). 정식 출시 시 자체 키스토어로 교체.
            signingConfig = signingConfigs.getByName("debug")
            // R8 최적화 비활성: youtube_player_iframe가 참조하는 androidx.window
            // 선택적 클래스(런타임 OEM 제공)로 R8가 실패하므로 데모 빌드는 미적용.
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
