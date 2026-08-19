import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "app.spotvibe"
    compileSdk = 36
    ndkVersion = "27.3.13750724"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "app.spotvibe"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26 // Android 8.0
        // Google Play requires new submissions to target Android 16 (API 36)
        // from 2026-08-31. Pin it so the build can never silently target lower.
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Use safe casts so a missing key.properties doesn't crash the build.
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            // Only attach the upload key when it exists. The verification task
            // below fails *release* builds clearly when it does not. Do not
            // throw here: Gradle configures every build type for `flutter run`,
            // including a debug build that does not need release signing.
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

// Release signing must fail loudly, but only when a release artifact is being
// built. `preReleaseBuild` is not part of `assembleDebug`, so this preserves
// normal device testing via `flutter run` without permitting unsigned releases.
val verifyReleaseSigning = tasks.register("verifyReleaseSigning") {
    group = "verification"
    description = "Verifies that the Android upload keystore is configured for release builds."

    doLast {
        val required = listOf("storePassword", "keyPassword", "keyAlias", "storeFile")
        val missing = required.filter { keystoreProperties.getProperty(it).isNullOrBlank() }
        if (!keystorePropertiesFile.exists() || missing.isNotEmpty()) {
            val missingHint = if (missing.isEmpty()) "" else " Missing: ${missing.joinToString()}."
            throw GradleException(
                "Release signing is not configured. Create android/key.properties " +
                    "with your upload keystore before building a release artifact " +
                    "(flutter build appbundle).$missingHint"
            )
        }
    }
}

tasks.configureEach {
    if (name == "preReleaseBuild" || name == "assembleRelease" || name == "bundleRelease") {
        dependsOn(verifyReleaseSigning)
    }
}

flutter {
    source = "../.."
}
