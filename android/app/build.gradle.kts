plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
//    id("com.google.firebase.crashlytics")//TODO
}

android {
    namespace = "com.nightowl.nightowlcode"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.14206865"
    compileSdkVersion(36)

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // 🔑 Required for flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
    }



    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.nightowl.nightowlcode"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23 //flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Use forward slashes on Windows with Kotlin DSL, or escape backslashes
            storeFile = file("C:/Users/Magno/Desktop/NightOwl/env/release-key.jks")
            storePassword = "nightowlprod"
            keyAlias = "release_key"          // <-- must match the alias you created
            keyPassword = "nightowlprod"
        }
    }


    buildTypes {
        getByName("debug") {
            // default debug signing is fine
        }
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

dependencies {
//    implementation("androidx.credentials:credentials:1.3.0")
//    implementation("androidx.credentials:credentials-play-services-auth:1.3.0")
//    implementation("com.google.android.libraries.identity.googleid:googleid:1.1.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")

}


flutter {
    source = "../.."
}
