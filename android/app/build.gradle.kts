import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("../../PlayStore_Keystore/LemonitaApp_aka_TipCalculator/key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.tipcalculator"
    // Pinned explicitly (not flutter.compileSdkVersion) so the Google Play
    // target API requirement does not depend on the local Flutter SDK version.
    compileSdk = 36
    // ndkVersion = flutter.ndkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.pesta.TipsCalculatorByBattousai"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        // Android 16. Required by Google Play from 2026-10-31.
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    //buildTypes {
    //    release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
    //        signingConfig = signingConfigs.getByName("debug")
    //    }
    //}
    // Only declared when the out-of-repo key.properties is present, so debug
    // builds (and machines/CI without the keystore) do not fail at configuration
    // time reading absent properties.
    val hasReleaseKeystore = keystorePropertiesFile.exists()

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }
    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                logger.warn("key.properties not found at ${keystorePropertiesFile.path}; signing release with debug keys.")
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
