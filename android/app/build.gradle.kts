plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.flutter_application_1"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

   defaultConfig {
        applicationId = "com.example.flutter_application_1"
        // استبدلي flutter.minSdkVersion بالرقم 26 مباشرة:
        minSdk = 26 
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.mediapipe:tasks-vision:0.10.21")
    implementation("androidx.exifinterface:exifinterface:1.3.7")
}

tasks.configureEach {
    if (name.contains("NativeLibs", ignoreCase = true)) {
        doNotTrackState("Native libraries are generated build outputs and can be recreated if Gradle cache state is stale.")
    }
}
