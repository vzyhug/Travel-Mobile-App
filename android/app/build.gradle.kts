plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Thêm dòng này để app thực sự sử dụng dịch vụ của Google
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.travel_application"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // ID ứng dụng của bạn
        applicationId = "com.example.travel_application"

        // SỬA TẠI ĐÂY: Dùng dấu bằng và gán trực tiếp số
        minSdk = flutter.minSdkVersion.toInt()
        targetSdk = 33

        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
