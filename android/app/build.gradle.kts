// android/app/build.gradle.kts
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.livenix"

    // Plugins you use (path_provider_android, sqflite_android, etc.) want 36
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.livenix"

        // Flutter now requires minSdk >= 23
        minSdkVersion(24)
        targetSdkVersion(36)

        // Read version from local.properties if present, else default
        versionCode = (project.findProperty("flutter.versionCode") as String?)?.toInt() ?: 1
        versionName = project.findProperty("flutter.versionName") as String? ?: "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            // Debug signing so `flutter run --release` works
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
